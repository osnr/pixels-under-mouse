local ffi = require('ffi')

function love.load()
   ffi.cdef[[
typedef double CGFloat;
typedef struct CGPoint { CGFloat x; CGFloat y; } CGPoint;
typedef struct CGSize { CGFloat width; CGFloat height; } CGSize;
typedef struct CGRect { CGPoint origin; CGSize size; } CGRect;
]]

   cg = ffi.load('/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics')
   ffi.cdef[[
typedef uint32_t CGDirectDisplayID;
CGDirectDisplayID CGMainDisplayID(void);
typedef uint32_t CGError;
CGError CGDisplayMoveCursorToPoint(CGDirectDisplayID display, CGPoint point);
typedef struct CGImage* CGImageRef;
CGImageRef CGDisplayCreateImageForRect(CGDirectDisplayID display, CGRect rect);
typedef struct __CFData* CFDataRef;
typedef struct CGDataProvider* CGDataProviderRef;
CFDataRef CGDataProviderCopyData(CGDataProviderRef provider);
CGDataProviderRef CGImageGetDataProvider(CGImageRef image);
const uint8_t * CFDataGetBytePtr(CFDataRef theData);
typedef struct __CGEvent* CGEventRef;
typedef struct __CGEventSource* CGEventSourceRef;
CGEventRef CGEventCreate(CGEventSourceRef source);
CGPoint CGEventGetLocation(CGEventRef event);
size_t CGImageGetBytesPerRow(CGImageRef image);
size_t CGImageGetWidth(CGImageRef image); size_t CGImageGetHeight(CGImageRef image);
typedef const void *CFTypeRef; void CFRelease(CFTypeRef cf);
]]

   display = cg.CGMainDisplayID()
end

local image, data, pixels

function love.update(dt)
   -- hot reload support (when you edit this file, the new code swaps
   -- into the running program w/o needing to restart love)
   pcall(function() require('vendor.lurker').update() end)
   
   -- get mouse location
   local event = cg.CGEventCreate(nil)
   local loc = cg.CGEventGetLocation(event)
   ffi.C.CFRelease(event)

   if image then ffi.C.CFRelease(image); image = nil end
   if data then ffi.C.CFRelease(data); data = nil end

   -- get screen pixels under mouse location
   local rect = ffi.new('CGRect', {loc.x - 20, loc.y - 20}, {40, 40}) -- edit this!
   image = cg.CGDisplayCreateImageForRect(display, rect)
   data = cg.CGDataProviderCopyData(cg.CGImageGetDataProvider(image))
   pixels = ffi.C.CFDataGetBytePtr(data)
end

function love.draw()
   if not pixels then return end

   local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
   local cols, rows = tonumber(cg.CGImageGetWidth(image)), tonumber(cg.CGImageGetHeight(image))
   local bytes_per_row = cg.CGImageGetBytesPerRow(image)
   for y = 0, rows - 1 do
      for x = 0, cols - 1 do
         local k = bytes_per_row*y + x*4
         love.graphics.setColor(pixels[k+2]/255, pixels[k+1]/255, pixels[k]/255)
         love.graphics.rectangle('fill', x*(sw/cols), y*(sh/rows), sw/cols, sh/rows)
      end
   end

   love.graphics.setColor(1, 1, 1)
   -- pcall(function() love.graphics.print(require('memoryusage')(), 20, 20) end) -- to spot memory leaks
end
