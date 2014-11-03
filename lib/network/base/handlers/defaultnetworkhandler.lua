DefaultNetworkHandler = DefaultNetworkHandler or class()
function DefaultNetworkHandler:init()
end
function DefaultNetworkHandler._get_peer_from_rpc(peer_rpc)
	if peer_rpc:protocol_at_index(0) == "TCP_IP" then
		return managers.network:session():peer_by_ip(peer_rpc:ip_at_index(0))
	else
		return managers.network:session():peer_by_user_id(peer_rpc:ip_at_index(0))
	end
end
function DefaultNetworkHandler.lost_peer(peer_rpc)
	cat_print("multiplayer_base", "Lost Peer (DefaultNetworkHandler)")
	if not managers.network:session() or managers.network:session():closing() then
		return
	end
	local peer = DefaultNetworkHandler._get_peer_from_rpc(peer_rpc)
	if not peer then
		return
	end
	managers.network:session():on_peer_lost(peer, peer:id())
end
function DefaultNetworkHandler.lost_client(peer_rpc)
	debug_pause("[DefaultNetworkHandler] Lost client", peer_rpc:ip_at_index(0))
	if not managers.network:session() or managers.network:session():closing() then
		return
	end
	local peer = DefaultNetworkHandler._get_peer_from_rpc(peer_rpc)
	if not peer then
		return
	end
	managers.network:session():on_peer_lost(peer, peer:id())
end
function DefaultNetworkHandler.lost_server(peer_rpc)
	debug_pause("[DefaultNetworkHandler] Lost server", peer_rpc:ip_at_index(0))
	if not managers.network:session() or managers.network:session():closing() then
		return
	end
	local peer = DefaultNetworkHandler._get_peer_from_rpc(peer_rpc)
	if not peer then
		return
	end
	managers.network:session():on_peer_lost(peer, peer:id())
end
