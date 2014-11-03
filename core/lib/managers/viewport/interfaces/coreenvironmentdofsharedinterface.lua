core:module("CoreEnvironmentDOFSharedInterface")
core:import("CoreClass")
core:import("CoreEnvironmentDOFInterface")
EnvironmentDOFSharedInterface = EnvironmentDOFSharedInterface or CoreClass.class(CoreEnvironmentDOFInterface.core:import("CoreClass"))
EnvironmentDOFSharedInterface.SHARED = true
