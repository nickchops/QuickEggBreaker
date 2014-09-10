Corona to Marmalade Quick Mapper and Example
============================================

An set of mapping lua files and the EggBreaker simple example game from *Corona* to
demonstrate mapping Corona code to *Marmalade Quick* automatically.

See http://nickchops.github.io/QuickEggBreaker for full blog piece on this project.

Porting is all done via addition of new lua files that map Corona calls to Quick
equivalents. Original code is not changed at all apart from currently the movieclip
functionality is replaced by simple image loading. That was partly working but buggy -
should be easy to fix.

Mapping is done largely with a combination of metatable overloads (__index and
__newindex) and also manually caching functions and calling intermediate ones in their
place.

In general, *objects* are tables with Quick nodes inside them and metatable redirecting
indexing to the node (or usually its own metatables!)

I had to rebuild Quick internals to add setBodyType() to QPhysicsNodeProps.h/cpp
This code will crash without that change. Basically copy the files in /Quick-fixes/ to
MARMALADE/modules/third_party/openquick/include (and source) and run openquick_tolua to
rebuild bindings. I'll request that function gets added to official version.


**Things to note:**

- PostCollision seems to work differently. Called early in Corona but takes ages in Quick.
  Might be waiting till no objects are touching at all!
- Text support is minimal. Doesn't support system fonts or font sizes.
- The porting layer mostly supports things this example needed. I added some useful unused
  code here and there, but it needs lots of work to support other games. A good proof of
  concept and easy to expand.


**Original game description:**

A simplified "Crush the Castle" game demo, where objects have internal listeners for
collision events.



------------------------------------------------------------------------------------------
(C) 2014 Nick Smith.

All code is provided under the MIT license unless stated otherwise:

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
