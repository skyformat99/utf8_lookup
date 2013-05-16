--[[
   DOC ME HERE ASWELL!.
   version 0.1, march, 2012

   Copyright (C) 2012- Fredrik Kihlander

   This software is provided 'as-is', without any express or implied
   warranty.  In no event will the authors be held liable for any damages
   arising from the use of this software.

   Permission is granted to anyone to use this software for any purpose,
   including commercial applications, and to alter it and redistribute it
   freely, subject to the following restrictions:

   1. The origin of this software must not be misrepresented; you must not
      claim that you wrote the original software. If you use this software
      in a product, an acknowledgment in the product documentation would be
      appreciated but is not required.
   2. Altered source versions must be plainly marked as such, and must not be
      misrepresented as being the original software.
   3. This notice may not be removed or altered from any source distribution.

   Fredrik Kihlander
--]]

BUILD_PATH = "local"

platform = "linux_x86_64"
if family == "windows" then
    platform = "winx64"
end
config   = "debug"

local settings       = NewSettings()
local gtest_settings = NewSettings()

local output_path = PathJoin( BUILD_PATH, PathJoin( config, platform ) )
local output_func = function(settings, path) return PathJoin(output_path, PathFilename(PathBase(path)) .. settings.config_ext) end
settings.cc.Output = output_func
settings.lib.Output = output_func
settings.link.Output = output_func
gtest_settings.cc.Output = output_func
gtest_settings.lib.Output = output_func
gtest_settings.link.Output = output_func

settings.cc.includes:Add("include")

if family ~= "windows" then
    settings.cc.flags:Add( "-Wconversion", "-Wextra", "-Wall", "-Werror", "-Wstrict-aliasing=2", "-std=gnu++0x" )
    settings.link.libs:Add( 'gtest', 'pthread', 'rt' )
else
    settings.link.flags:Add( "/NODEFAULTLIB:LIBCMT.LIB" );
	
    settings.link.libs:Add( 'gtest' )
    settings.cc.defines:Add("_ITERATOR_DEBUG_LEVEL=0")
    settings.cc.flags:Add("/EHsc")
    gtest_settings.cc.defines:Add("_ITERATOR_DEBUG_LEVEL=0")
    gtest_settings.cc.flags:Add("/EHsc")
end

local objs  = Compile( settings, 'src/utf8_lookup.cpp' )
local lib   = StaticLibrary( settings, 'utf8_lookup', objs )

settings.cc.includes:Add( 'test/gtest/include' )
settings.link.libpath:Add( 'local/' .. config .. '/' .. platform )

gtest_settings.cc.includes:Add( 'test/gtest' )
gtest_settings.cc.includes:Add( 'test/gtest/include' )
local gtest      = StaticLibrary( gtest_settings, 'gtest', Compile( gtest_settings, Collect( 'test/gtest/src/gtest-all.cc' ) ) )

local test_objs  = Compile( settings, 'test/utf8_lookup_tests.cpp' )
local tests      = Link( settings, 'utf8_lookup_tests', test_objs, lib, gtest )

local bench_objs = Compile( settings, 'benchmark/utf8_bench.cpp' )
local benchmark  = Link( settings, 'utf8_lookup_bench', bench_objs, lib )

function test_args()
    if ScriptArgs["test_filter"] then
        return ' --gtest_filter=' .. ScriptArgs["test_filter"]
    end
    return ''
end

if family == "windows" then
	AddJob( "test",  "unittest",  string.gsub( tests, "/", "\\" ) .. test_args(), tests, tests )
	AddJob( "bench", "benchmark", string.gsub( benchmark, "/", "\\" ), benchmark, benchmark )
else
	AddJob( "test",  "unittest",  "valgrind -v --leak-check=full --track-origins=yes " .. tests .. test_args(), tests, tests )
	AddJob( "bench", "benchmark", benchmark, benchmark )
end

PseudoTarget( "all", tests, benchmark )
DefaultTarget( "all" )
