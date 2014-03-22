/*
 * Copyright (C)2005-2012 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
package anette;

class NodeBytesBuffer {
	var b : Array<Int>;

	/** The length of the buffer in bytes. **/
	public var length(get,never) : Int;

	public function new() {
		b = new Array();
	}

	inline function get_length() : Int {
		return b.length;
	}

	public inline function addByte( byte : Int ) {
		b.push(byte);
	}

	public inline function add( src : haxe.io.Bytes ) {
		var b1 = b;
		var b2 = src.getData();
		for( i in 0...src.length )
			b.push(b2[i]);
	}

	public inline function addBytes( src : haxe.io.Bytes, pos : Int, len : Int ) {
		var b1 = b;
		var b2 = src.getData();
		for( i in pos...pos+len )
			b.push(b2[i]);
	}

	/**
		Returns either a copy or a reference of the current bytes.
		Once called, the buffer can no longer be used.
	**/
	public function getBytes() : haxe.io.Bytes untyped {
		var bytes = new haxe.io.Bytes(b.length,b);
		b = null;
		return bytes;
	}

}
