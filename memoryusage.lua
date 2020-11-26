-- run with LuaJIT on macOS
-- based on excellent answer here: https://stackoverflow.com/questions/63166/how-to-determine-cpu-and-memory-consumption-from-inside-a-process/1911863

local ffi = require('ffi')
ffi.cdef[[
typedef unsigned int            __darwin_natural_t;
typedef __darwin_natural_t      natural_t;
typedef int                     integer_t;

typedef __darwin_natural_t __darwin_mach_port_name_t;
typedef __darwin_mach_port_name_t __darwin_mach_port_t;
typedef __darwin_mach_port_t mach_port_t;

typedef mach_port_t             task_name_t;
typedef natural_t       task_flavor_t;
typedef integer_t       *task_info_t;
typedef natural_t mach_msg_type_number_t;
typedef int             kern_return_t;
kern_return_t task_info
(
	task_name_t target_task,
	task_flavor_t flavor,
	task_info_t task_info_out,
	mach_msg_type_number_t *task_info_outCnt
);

typedef uintptr_t               vm_size_t;
struct time_value {
	integer_t seconds;
	integer_t microseconds;
};
typedef struct time_value       time_value_t;
typedef int                             policy_t;
#pragma pack(push, 4)
struct task_basic_info {
	integer_t       suspend_count;  /* suspend count for task */
	vm_size_t       virtual_size;   /* virtual memory size (bytes) */
	vm_size_t       resident_size;  /* resident memory size (bytes) */
	time_value_t    user_time;      /* total user run time for
	                                 *  terminated threads */
	time_value_t    system_time;    /* total system run time for
	                                 *  terminated threads */
	policy_t        policy;         /* default policy for new threads */
};
#pragma pack(pop)
typedef struct task_basic_info          task_basic_info_data_t;

extern mach_port_t mach_task_self_;
]]

local TASK_BASIC_INFO_64 = 5
local TASK_BASIC_INFO = TASK_BASIC_INFO_64
local TASK_BASIC_INFO_COUNT = ffi.sizeof('task_basic_info_data_t') / ffi.sizeof('natural_t')

function get_task_info()
   local t_info = ffi.new('struct task_basic_info')
   local t_info_count = ffi.new('mach_msg_type_number_t[1]', TASK_BASIC_INFO_COUNT)
   ffi.C.task_info(ffi.C.mach_task_self_, TASK_BASIC_INFO, ffi.cast('task_info_t', t_info), t_info_count)
   return t_info
end

if not ... then
   local t_info = get_task_info()
   print("t_info.resident_size = ", t_info.resident_size)
   print("t_info.virtual_size = ", t_info.virtual_size)

   print("Allocating 1MB of stuff.")
   local megabyte = ffi.new("char[?]", 1024*1024)

   t_info = get_task_info()
   print("t_info.resident_size = ", t_info.resident_size)
   print("t_info.virtual_size = ", t_info.virtual_size)
end

return function() return tonumber(get_task_info().resident_size) end
