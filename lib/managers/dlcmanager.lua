DLCManager = DLCManager or class()
DLCManager.PLATFORM_CLASS_MAP = {}
function DLCManager:new(...)
	local platform = SystemInfo:platform()
	return self.PLATFORM_CLASS_MAP[platform:key()] or GenericDLCManager:new(...)
end
GenericDLCManager = GenericDLCManager or class()
function GenericDLCManager:init()
	self._debug_on = Application:production_build()
end
function GenericDLCManager:has_dlc(dlc)
	local dlc_data = Global.dlc_manager.all_dlc_data[dlc]
	if not dlc_data then
		Application:error("Didn't have dlc data for", dlc)
		return
	end
	return dlc_data.verified
end
function GenericDLCManager:has_full_game()
	local dlc_data = Global.dlc_manager.all_dlc_data.full_game
	return dlc_data.verified
end
function GenericDLCManager:is_trial()
	return not self:has_full_game()
end
function GenericDLCManager:dlcs_string()
	local s = ""
	s = s .. (self:has_dlc1() and "dlc1 " or "")
	s = s .. (self:has_dlc2() and "dlc2 " or "")
	s = s .. (self:has_dlc3() and "dlc3 " or "")
	s = s .. (self:has_dlc4() and "dlc4 " or "")
	return s
end
function GenericDLCManager:has_pre_dlc()
	return false
end
PS3DLCManager = PS3DLCManager or class(GenericDLCManager)
DLCManager.PLATFORM_CLASS_MAP[Idstring("PS3"):key()] = PS3DLCManager
PS3DLCManager.SERVICE_ID = "EP0017-NPEA00331_00"
function PS3DLCManager:init()
	PS3DLCManager.super.init(self)
	if not Global.dlc_manager then
		Global.dlc_manager = {}
		Global.dlc_manager.all_dlc_data = {
			full_game = {
				filename = "full_game_key.edat",
				product_id = "EP0017-NPEA00331_00-KPAYDAYGAME00000"
			},
			dlc1 = {
				filename = "dlc1_key.edat",
				product_id = "EP0017-NPEA00331_00-PAYDAYHEISTDLC01"
			}
		}
		self:_verify_dlcs()
	end
end
function PS3DLCManager:_verify_dlcs()
	local all_dlc = {}
	for dlc_name, dlc_data in pairs(Global.dlc_manager.all_dlc_data) do
		table.insert(all_dlc, dlc_data.filename)
	end
	local verified_dlcs = PS3:check_dlc_availability(all_dlc)
	Global.dlc_manager.verified_dlcs = verified_dlcs
	for _, verified_filename in pairs(verified_dlcs) do
		for dlc_name, dlc_data in pairs(Global.dlc_manager.all_dlc_data) do
			if dlc_data.filename == verified_filename then
				print("DLC verified:", verified_filename)
				dlc_data.verified = true
			else
			end
		end
	end
end
function PS3DLCManager:_init_NPCommerce()
	PS3:set_service_id(self.SERVICE_ID)
	local result = NPCommerce:init()
	print("init result", result)
	if not result then
		MenuManager:show_np_commerce_init_fail()
		NPCommerce:destroy()
		return
	end
	local result = NPCommerce:open(callback(self, self, "cb_NPCommerce"))
	print("open result", result)
	if result < 0 then
		MenuManager:show_np_commerce_init_fail()
		NPCommerce:destroy()
		return
	end
	return true
end
function PS3DLCManager:buy_full_game()
	print("[PS3DLCManager:buy_full_game]")
	if self._activity then
		return
	end
	if not self:_init_NPCommerce() then
		return
	end
	managers.menu:show_waiting_NPCommerce_open()
	self._request = {
		type = "buy_product",
		product = "full_game"
	}
	self._activity = {type = "open"}
end
function PS3DLCManager:buy_product(product_name)
	print("[PS3DLCManager:buy_product]", product_name)
	if self._activity then
		return
	end
	if not self:_init_NPCommerce() then
		return
	end
	managers.menu:show_waiting_NPCommerce_open()
	self._request = {
		type = "buy_product",
		product = product_name
	}
	self._activity = {type = "open"}
end
function PS3DLCManager:cb_NPCommerce(result, info)
	print("[PS3DLCManager:cb_NPCommerce]", result, info)
	for i, k in pairs(info) do
		print(i, k)
	end
	self._NPCommerce_cb_results = self._NPCommerce_cb_results or {}
	print("self._activity", self._activity and inspect(self._activity))
	table.insert(self._NPCommerce_cb_results, {result, info})
	if not self._activity then
		return
	elseif self._activity.type == "open" then
		if info.category_error or info.category_done == false then
			self._activity = nil
			managers.system_menu:close("waiting_for_NPCommerce_open")
			self:_close_NPCommerce()
		else
			managers.system_menu:close("waiting_for_NPCommerce_open")
			local product_id = Global.dlc_manager.all_dlc_data[self._request.product].product_id
			print("starting storebrowse", product_id)
			local ret = NPCommerce:storebrowse("product", product_id, true)
			if not ret then
				self._activity = nil
				managers.menu:show_NPCommerce_checkout_fail()
				self:_close_NPCommerce()
			end
			self._activity = {type = "browse"}
		end
	elseif self._activity.type == "browse" then
		if info.browse_succes then
			self._activity = nil
			managers.menu:show_NPCommerce_browse_success()
			self:_close_NPCommerce()
		elseif info.browse_back then
			self._activity = nil
			self:_close_NPCommerce()
		elseif info.category_error then
			self._activity = nil
			managers.menu:show_NPCommerce_browse_fail()
			self:_close_NPCommerce()
		end
	elseif self._activity.type == "checkout" then
		if info.checkout_error then
			self._activity = nil
			managers.menu:show_NPCommerce_checkout_fail()
			self:_close_NPCommerce()
		elseif info.checkout_cancel then
			self._activity = nil
			self:_close_NPCommerce()
		elseif info.checkout_success then
			self._activity = nil
			self:_close_NPCommerce()
		end
	end
	print("/[PS3DLCManager:cb_NPCommerce]")
end
function PS3DLCManager:_close_NPCommerce()
	print("[PS3DLCManager:_close_NPCommerce]")
	NPCommerce:destroy()
end
function PS3DLCManager:cb_confirm_purchase_yes(sku_data)
	NPCommerce:checkout(sku_data.skuid)
end
function PS3DLCManager:cb_confirm_purchase_no()
	self._activity = nil
	self:_close_NPCommerce()
end
function PS3DLCManager:has_dlc1()
	return Global.dlc_manager.all_dlc_data.dlc1.verified
end
function PS3DLCManager:has_dlc2()
	return self:has_dlc1()
end
function PS3DLCManager:has_dlc3()
	return self:has_dlc1()
end
function PS3DLCManager:has_dlc4()
	return false
end
WINDLCManager = WINDLCManager or class(GenericDLCManager)
DLCManager.PLATFORM_CLASS_MAP[Idstring("WIN32"):key()] = WINDLCManager
function WINDLCManager:init()
	WINDLCManager.super.init(self)
	if not Global.dlc_manager then
		Global.dlc_manager = {}
		Global.dlc_manager.all_dlc_data = {
			full_game = {app_id = "24240", verified = true},
			weapon_pack_1 = {app_id = "207811", no_install = true},
			counterfeit = {app_id = "207812", no_install = true},
			undercover = {app_id = "207813", no_install = true},
			hospital = {
				app_id = "207814",
				no_install = true,
				verified = true
			}
		}
		self:_verify_dlcs()
	end
end
function WINDLCManager:_verify_dlcs()
	for dlc_name, dlc_data in pairs(Global.dlc_manager.all_dlc_data) do
		if not dlc_data.verified then
			if dlc_data.no_install then
				if Steam:is_product_owned(dlc_data.app_id) then
					dlc_data.verified = true
				end
			elseif Steam:is_product_installed(dlc_data.app_id) then
				dlc_data.verified = true
			end
		end
	end
end
function WINDLCManager:has_dlc1()
	return not self:has_pre_dlc() and (self._debug_on or Global.dlc_manager.all_dlc_data.weapon_pack_1.verified)
end
function WINDLCManager:has_dlc2()
	return not self:has_pre_dlc() and (self._debug_on or Global.dlc_manager.all_dlc_data.counterfeit.verified)
end
function WINDLCManager:has_dlc3()
	return not self:has_pre_dlc() and (self._debug_on or Global.dlc_manager.all_dlc_data.undercover.verified)
end
function WINDLCManager:has_dlc4()
	return self._debug_on or Global.dlc_manager.all_dlc_data.hospital.verified
end
