pragma solidity ^0.4.16;
pragma experimental "v0.5.0";
pragma experimental "ABIEncoderV2";

import {Memory} from "../unsafe/Memory.sol";

/*
 * title: Bytes
 * author: Andreas Olofsson (androlo@tutanota.de)
 *
 * description:
 */
library Bytes {

    // Check if two 'bytes memory' are equal. Equality is defined as such:
    // firstBytes.length == secondBytes.length (= length)
    // for 0 <= i < length, firstBytes[i] == secondBytes[i]
    function equals(bytes memory self, bytes memory other) internal pure returns (bool equal) {
        if (self.length != other.length) {
            return false;
        }
        uint addr;
        uint addr2;
        assembly {
            addr := add(self, 0x20)
            addr2 := add(other, 0x20)
        }
        equal = Memory.equals(addr, addr2, self.length);
    }

    // Check if two bytes references are the same, i.e. has the same memory address.
    // If 'equals(self, other) == true', but 'equalsRef(self, other) == false', then
    // 'self' and 'other' must be independent copies of each other.
    function equalsRef(bytes memory self, bytes memory other) internal pure returns (bool equal) {
        equal = Memory.ptr(self) == Memory.ptr(other);
    }

    function copy(bytes memory self) internal pure returns (bytes memory) {
        if (self.length == 0) {
            return;
        }
        var addr = Memory.dataPtr(self);
        return Memory.toBytes(addr, self.length);
    }

    function copy(bytes memory self, uint startIdx) internal pure returns (bytes memory) {
        require(startIdx < self.length);
        var len = self.length - startIdx;
        var addr = Memory.dataPtr(self);
        return Memory.toBytes(addr + startIdx, len);
    }

    function copy(bytes memory self, uint startIdx, uint len) internal pure returns (bytes memory) {
        require(startIdx < self.length && startIdx + len <= self.length);
        if (len == 0) {
            return;
        }
        var addr = Memory.dataPtr(self);
        return Memory.toBytes(addr + startIdx, len);
    }

    function concat(bytes memory self, bytes memory other) internal pure returns (bytes memory) {
        bytes memory ret = new bytes(self.length + other.length);
        var (src, srcLen) = Memory.fromBytes(self);
        var (src2, src2Len) = Memory.fromBytes(other);
        var (dest,) = Memory.fromBytes(ret);
        var dest2 = dest + src2Len;
        Memory.copy(src, dest, srcLen);
        Memory.copy(src2, dest2, src2Len);
        return ret;
    }

    // Find the lowest byte set of a bytes32. This function uses the same convention
    // as bytesN index access, and counts from the most significant byte.
    // lowestByteSet(0x01) = 31;
    // lowestByteSet(0x0100) = 30;
    // lowestByteSet("abc") = 0;
    function lowestByteSet(bytes32 self) internal pure returns (uint) {
        return 31 - highestByteSet(uint(self));
    }

    // Find the lowest byte set of a bytes32. This function uses the same convention
    // as bytesN index access, and counts from the most significant byte.
    // lowestByteSet(0x01) = 31;
    // lowestByteSet(0x0100) = 30;
    // lowestByteSet("abc") = 2;
    function highestByteSet(bytes32 self) internal pure returns (uint) {
        return 31 - lowestByteSet(uint(self));
    }

    // Find the lowest byte set of a uint. This function counts from the least
    // significant byte.
    // lowestByteSet(0x01) = 0;
    // lowestByteSet(0xbb00aa00) = 1; (aa)
    function lowestByteSet(uint self) internal pure returns (uint) {
        require(self != 0);
        uint ret;
        if (self & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self >>= 128;
        }
        if (self & 0xffffffffffffffff == 0) {
            ret += 8;
            self >>= 64;
        }
        if (self & 0xffffffff == 0) {
            ret += 4;
            self >>= 32;
        }
        if (self & 0xffff == 0) {
            ret += 2;
            self >>= 16;
        }
        if (self & 0xff == 0) {
            ret += 1;
        }
        return ret;
    }

    // Find the lowest byte set of a uint. This function counts from the least
    // significant byte.
    // highestByteSet(0x01) = 0;
    // highestByteSet(0xbb00aa00) = 3; (bb)
    function highestByteSet(uint self) internal pure returns (uint) {
        require(self != 0);
        uint ret;
        if (self & 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000 != 0) {
            ret += 16;
            self >>= 128;
        }
        if (self & 0xffffffffffffffff0000000000000000 != 0) {
            ret += 8;
            self >>= 64;
        }
        if (self & 0xffffffff00000000 != 0) {
            ret += 4;
            self >>= 32;
        }
        if (self & 0xffff0000 != 0) {
            ret += 2;
            self >>= 16;
        }
        if (self & 0xff00 != 0) {
            ret += 1;
        }
        return ret;
    }

    // Shaves of trailing 0-bytes and writes the remaining string to a 'memory bytes'
    function toBytes(bytes32 b32) internal pure returns (bytes memory bts) {
        if (b32 == 0) {
            return;
        }
        uint hbs = highestByteSet(b32);
        bts = new bytes(hbs + 1);
        assembly {
            mstore(add(bts, 0x20), b32)
        }
        return bts;
    }

}