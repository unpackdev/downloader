// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
    }

    function logUint(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
    }

    function log(uint p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
    }

    function log(uint p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
    }

    function log(uint p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
    }

    function log(string memory p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
    }

    function log(uint p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
    }

    function log(uint p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
    }

    function log(uint p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
    }

    function log(uint p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
    }

    function log(uint p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
    }

    function log(uint p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
    }

    function log(uint p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
    }

    function log(uint p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
    }

    function log(uint p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
    }

    function log(uint p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
    }

    function log(uint p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
    }

    function log(bool p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
    }

    function log(bool p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
    }

    function log(bool p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
    }

    function log(address p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
    }

    function log(address p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
    }

    function log(address p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

/// @notice Minimalist and modern Wrapped Ether implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/WETH.sol)
/// @author Inspired by WETH9 (https://github.com/dapphub/ds-weth/blob/master/src/weth9.sol)
contract WETH is ERC20("Wrapped Ether", "WETH", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}

/// https://etherscan.io/address/0xdf0770dF86a8034b3EFEf0A1Bb3c889B8332FF56#code
abstract contract LPTokenERC20 is ERC20 {
    function amountLPtoLD(uint256 _lpAmount) external view virtual returns (uint256);

    function totalLiquidity() external view virtual returns (uint256);
}

/// @dev
/// https://etherscan.io/address/0xB0D502E938ed5f4df2E681fE6E419ff29631d62b#code
/// basically a Goose MasterChef
interface ILPStaking {
    function poolInfo(uint256 _pid)
        external
        view
        returns (address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accStargatePerShare);

    function userInfo(uint256 _pid, address _address) external view returns (uint256 amount, uint256 rewardDebt);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;
}

/// @dev https://etherscan.io/address/0x8731d54E9D02c286767d56ac03e8037C07e01e98#code
interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(uint256 _poolId, uint256 _amountLD, address _to) external;

    function instantRedeemLocal(uint16 _srcPoolId, uint256 _amountLP, address _to) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function callDelta(uint256 _poolId, bool _fullMode) external;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// https://github.com/Uniswap/swap-router-contracts/blob/main/contracts/interfaces/ISwapRouter02.sol

interface ISwapRouter02 {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

// https://etherscan.io/address/0xd9e1ce17f2641f24ae83637ab66a2cca9c378b9f
// it's actually a UniswapV2Router02 but renamed for clarity vs actual uniswap

interface ISushiRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

/// https://etherscan.io/address/0xBA12222222228d8Ba445958a75a0704d566BF2C8#code

interface IAsset {}

interface IVault {
    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    enum PoolSpecialization {
        GENERAL,
        MINIMAL_SWAP_INFO,
        TWO_TOKEN
    }

    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (address[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

    function getPoolTokenInfo(bytes32 poolId, address token)
        external
        view
        returns (uint256 cash, uint256 managed, uint256 lastChangedBlock, address assetManager);

    function queryExit(bytes32 poolId, address sender, address recipient, IVault.ExitPoolRequest memory request)
        external
        returns (uint256 bptIn, uint256[] memory amountsOut);

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline)
        external
        returns (uint256 amountCalculated);

    function exitPool(bytes32 poolId, address sender, address payable recipient, ExitPoolRequest memory request)
        external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }
}

abstract contract Ownable {
    address public owner;
    address public nominatedOwner;

    error Unauthorized();

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    // Public Functions

    function acceptOwnership() external {
        if (msg.sender != nominatedOwner) revert Unauthorized();
        emit OwnerChanged(owner, msg.sender);
        owner = msg.sender;
        nominatedOwner = address(0);
    }

    // Restricted Functions: onlyOwner

    /// @dev nominating zero address revokes a pending nomination
    function nominateOwnership(address _newOwner) external onlyOwner {
        nominatedOwner = _newOwner;
    }

    // Modifiers

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }
}

// https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/Path.sol

//https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol

library BytesLib {
    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } { mstore(mc, mload(cc)) }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Returns the number of pools in the path
    /// @param path The encoded swap path
    /// @return The number of pools in the path
    function numPools(bytes memory path) internal pure returns (uint256) {
        // Ignore the first token address. From then on every fee and token offset indicates a pool.
        return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path) internal pure returns (address tokenA, address tokenB, uint24 fee) {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}

/**
 * @notice
 * Swap contract used by strategies to:
 * 1. swap strategy rewards to 'asset'
 * 2. zap similar tokens to asset (e.g. USDT to USDC)
 */
contract Swap is Ownable {
    using SafeTransferLib for ERC20;
    using Path for bytes;

    enum Route {
        Unsupported,
        UniswapV2,
        UniswapV3Direct,
        UniswapV3Path,
        SushiSwap,
        BalancerBatch,
        BalancerSingle
    }

    /**
     * @dev info depends on route:
     * 		UniswapV2: address[] path
     * 		UniswapV3Direct: uint24 fee
     * 		UniswapV3Path: bytes path (address, uint24 fee, address, uint24 fee, address)
     */
    struct RouteInfo {
        Route route;
        bytes info;
    }

    ISushiRouter internal constant sushiswap = ISushiRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    /// @dev single address which supports both uniswap v2 and v3 routes
    ISwapRouter02 internal constant uniswap = ISwapRouter02(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);

    IVault internal constant balancer = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    /// @dev tokenIn => tokenOut => routeInfo
    mapping(address => mapping(address => RouteInfo)) public routes;

    /*//////////////////
    /      Events      /
    //////////////////*/

    event RouteSet(address indexed tokenIn, address indexed tokenOut, RouteInfo routeInfo);
    event RouteRemoved(address indexed tokenIn, address indexed tokenOut);

    /*//////////////////
    /      Errors      /
    //////////////////*/

    error UnsupportedRoute(address tokenIn, address tokenOut);
    error InvalidRouteInfo();

    constructor() Ownable() {
        address CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
        address CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
        address LDO = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;

        address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

        address STG = 0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6;
        address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

        address BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
        address AURA = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;

        _setRoute(CRV, WETH, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(3_000))}));
        _setRoute(CVX, WETH, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(10_000))}));
        _setRoute(LDO, WETH, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(3_000))}));

        _setRoute(CRV, USDC, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(10_000))}));
        _setRoute(
            CVX,
            USDC,
            RouteInfo({route: Route.UniswapV3Path, info: abi.encodePacked(CVX, uint24(10_000), WETH, uint24(500), USDC)})
        );

        _setRoute(USDC, USDT, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(100))}));

        _setRoute(
            STG,
            USDC,
            RouteInfo({
                route: Route.BalancerSingle,
                info: abi.encode(0x3ff3a210e57cfe679d9ad1e9ba6453a716c56a2e0002000000000000000005d5)
            })
        );
        IAsset[] memory stgWethAssets = new IAsset[](4);
        stgWethAssets[0] = IAsset(STG);
        stgWethAssets[1] = IAsset(USDC);
        stgWethAssets[2] = IAsset(0x79c58f70905F734641735BC61e45c19dD9Ad60bC); // 3pool
        stgWethAssets[3] = IAsset(WETH);

        bytes32[] memory stgWethPoolIds = new bytes32[](3);
        stgWethPoolIds[0] = 0x3ff3a210e57cfe679d9ad1e9ba6453a716c56a2e0002000000000000000005d5; // STG/USDC
        stgWethPoolIds[1] = 0x79c58f70905f734641735bc61e45c19dd9ad60bc0000000000000000000004e7; // 3pool
        stgWethPoolIds[2] = 0x08775ccb6674d6bdceb0797c364c2653ed84f3840002000000000000000004f0; // 3pool/WETH

        IVault.BatchSwapStep[] memory stgWethSteps = _constructBalancerBatchSwapSteps(stgWethPoolIds);

        _setRoute(STG, WETH, RouteInfo({route: Route.BalancerBatch, info: abi.encode(stgWethSteps, stgWethAssets)}));

        bytes32 balWethPoolId = 0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014;
        _setRoute(BAL, WETH, RouteInfo({route: Route.BalancerSingle, info: abi.encode(balWethPoolId)}));

        bytes32 auraWethPoolId = 0xcfca23ca9ca720b6e98e3eb9b6aa0ffc4a5c08b9000200000000000000000274;
        _setRoute(AURA, WETH, RouteInfo({route: Route.BalancerSingle, info: abi.encode(auraWethPoolId)}));
    }

    /*///////////////////////
    /      Public View      /
    ///////////////////////*/

    function getRoute(address _tokenIn, address _tokenOut) external view returns (RouteInfo memory routeInfo) {
        return routes[_tokenIn][_tokenOut];
    }

    /*////////////////////////////
    /      Public Functions      /
    ////////////////////////////*/

    function swapTokens(address _tokenIn, address _tokenOut, uint256 _amount, uint256 _minReceived)
        external
        returns (uint256 received)
    {
        RouteInfo memory routeInfo = routes[_tokenIn][_tokenOut];

        ERC20 tokenIn = ERC20(_tokenIn);
        tokenIn.safeTransferFrom(msg.sender, address(this), _amount);

        Route route = routeInfo.route;
        bytes memory info = routeInfo.info;

        if (route == Route.UniswapV2) {
            received = _uniswapV2(_amount, _minReceived, info);
        } else if (route == Route.UniswapV3Direct) {
            received = _uniswapV3Direct(_tokenIn, _tokenOut, _amount, _minReceived, info);
        } else if (route == Route.UniswapV3Path) {
            received = _uniswapV3Path(_amount, _minReceived, info);
        } else if (route == Route.SushiSwap) {
            received = _sushiswap(_amount, _minReceived, info);
        } else if (route == Route.BalancerBatch) {
            received = _balancerBatch(_amount, _minReceived, info);
        } else if (route == Route.BalancerSingle) {
            received = _balancerSingle(_tokenIn, _tokenOut, _amount, _minReceived, info);
        } else {
            revert UnsupportedRoute(_tokenIn, _tokenOut);
        }

        // return unswapped amount to sender
        uint256 balance = tokenIn.balanceOf(address(this));
        if (balance > 0) tokenIn.safeTransfer(msg.sender, balance);
    }

    /*///////////////////////////////////////////
    /      Restricted Functions: onlyOwner      /
    ///////////////////////////////////////////*/

    function setRoute(address _tokenIn, address _tokenOut, RouteInfo memory _routeInfo) external onlyOwner {
        _setRoute(_tokenIn, _tokenOut, _routeInfo);
    }

    function unsetRoute(address _tokenIn, address _tokenOut) external onlyOwner {
        delete routes[_tokenIn][_tokenOut];
        emit RouteRemoved(_tokenIn, _tokenOut);
    }

    /*//////////////////////////////
    /      Internal Functions      /
    //////////////////////////////*/

    function _setRoute(address _tokenIn, address _tokenOut, RouteInfo memory _routeInfo) internal {
        Route route = _routeInfo.route;
        bytes memory info = _routeInfo.info;

        if (route == Route.UniswapV2 || route == Route.SushiSwap) {
            address[] memory path = abi.decode(info, (address[]));

            if (path[0] != _tokenIn) revert InvalidRouteInfo();
            if (path[path.length - 1] != _tokenOut) revert InvalidRouteInfo();
        }

        // just check that this doesn't throw an error
        if (route == Route.UniswapV3Direct) abi.decode(info, (uint24));

        if (route == Route.UniswapV3Path) {
            bytes memory path = info;

            // check first tokenIn
            (address tokenIn,,) = path.decodeFirstPool();
            if (tokenIn != _tokenIn) revert InvalidRouteInfo();

            // check last tokenOut
            while (path.hasMultiplePools()) path = path.skipToken();
            (, address tokenOut,) = path.decodeFirstPool();
            if (tokenOut != _tokenOut) revert InvalidRouteInfo();
        }

        // just check that these don't throw an error, i.e. the poolId contains both _tokenIn
        if (route == Route.BalancerSingle) {
            bytes32 poolId = abi.decode(info, (bytes32));
            balancer.getPoolTokenInfo(poolId, _tokenIn);
            balancer.getPoolTokenInfo(poolId, _tokenOut);
        }

        address router = _getRouterAddress(route);

        ERC20(_tokenIn).safeApprove(router, 0);
        ERC20(_tokenIn).safeApprove(router, type(uint256).max);

        routes[_tokenIn][_tokenOut] = _routeInfo;
        emit RouteSet(_tokenIn, _tokenOut, _routeInfo);
    }

    function _uniswapV2(uint256 _amount, uint256 _minReceived, bytes memory _path) internal returns (uint256) {
        address[] memory path = abi.decode(_path, (address[]));

        return uniswap.swapExactTokensForTokens(_amount, _minReceived, path, msg.sender);
    }

    function _sushiswap(uint256 _amount, uint256 _minReceived, bytes memory _path) internal returns (uint256) {
        address[] memory path = abi.decode(_path, (address[]));

        uint256[] memory received =
            sushiswap.swapExactTokensForTokens(_amount, _minReceived, path, msg.sender, type(uint256).max);

        return received[received.length - 1];
    }

    function _uniswapV3Direct(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        uint256 _minReceived,
        bytes memory _info
    ) internal returns (uint256) {
        uint24 fee = abi.decode(_info, (uint24));

        return uniswap.exactInputSingle(
            ISwapRouter02.ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: fee,
                recipient: msg.sender,
                amountIn: _amount,
                amountOutMinimum: _minReceived,
                sqrtPriceLimitX96: 0
            })
        );
    }

    function _uniswapV3Path(uint256 _amount, uint256 _minReceived, bytes memory _path) internal returns (uint256) {
        return uniswap.exactInput(
            ISwapRouter02.ExactInputParams({
                path: _path,
                recipient: msg.sender,
                amountIn: _amount,
                amountOutMinimum: _minReceived
            })
        );
    }

    function _balancerBatch(uint256 _amount, uint256 _minReceived, bytes memory _info) internal returns (uint256) {
        (IVault.BatchSwapStep[] memory steps, IAsset[] memory assets) =
            abi.decode(_info, (IVault.BatchSwapStep[], IAsset[]));

        steps[0].amount = _amount;

        int256[] memory limits = new int256[](assets.length);

        limits[0] = int256(_amount);
        limits[limits.length - 1] = -int256(_minReceived);

        int256[] memory received = balancer.batchSwap(
            IVault.SwapKind.GIVEN_IN,
            steps,
            assets,
            IVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(msg.sender)),
                toInternalBalance: false
            }),
            limits,
            type(uint256).max
        );

        return uint256(-received[received.length - 1]);
    }

    function _balancerSingle(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        uint256 _minReceived,
        bytes memory _info
    ) internal returns (uint256) {
        bytes32 poolId = abi.decode(_info, (bytes32));

        return balancer.swap(
            IVault.SingleSwap({
                poolId: poolId,
                kind: IVault.SwapKind.GIVEN_IN,
                assetIn: IAsset(_tokenIn),
                assetOut: IAsset(_tokenOut),
                amount: _amount,
                userData: ""
            }),
            IVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(msg.sender)),
                toInternalBalance: false
            }),
            _minReceived,
            type(uint256).max
        );
    }

    function _getRouterAddress(Route _route) internal pure returns (address) {
        if (_route == Route.SushiSwap) {
            return address(sushiswap);
        } else if (_route == Route.UniswapV2 || _route == Route.UniswapV3Direct || _route == Route.UniswapV3Path) {
            return address(uniswap);
        } else if (_route == Route.BalancerBatch || _route == Route.BalancerSingle) {
            return address(balancer);
        } else {
            revert InvalidRouteInfo();
        }
    }

    function _constructBalancerBatchSwapSteps(bytes32[] memory _poolIds)
        internal
        pure
        returns (IVault.BatchSwapStep[] memory steps)
    {
        uint256 length = _poolIds.length;
        steps = new IVault.BatchSwapStep[](length);

        for (uint8 i = 0; i < length; ++i) {
            steps[i] = IVault.BatchSwapStep({
                poolId: _poolIds[i],
                assetInIndex: i,
                assetOutIndex: i + 1,
                amount: 0,
                userData: ""
            });
        }
    }
}

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

abstract contract Ownership {
    address public owner;
    address public nominatedOwner;

    address public admin;

    mapping(address => bool) public authorized;

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
    event AuthAdded(address indexed newAuth);
    event AuthRemoved(address indexed oldAuth);

    error Unauthorized();
    error AlreadyRole();
    error NotRole();

    /// @param _authorized maximum of 256 addresses in constructor
    constructor(address _nominatedOwner, address _admin, address[] memory _authorized) {
        owner = msg.sender;
        nominatedOwner = _nominatedOwner;
        admin = _admin;
        for (uint8 i = 0; i < _authorized.length; ++i) {
            authorized[_authorized[i]] = true;
            emit AuthAdded(_authorized[i]);
        }
    }

    // Public Functions

    function acceptOwnership() external {
        if (msg.sender != nominatedOwner) revert Unauthorized();
        emit OwnerChanged(owner, msg.sender);
        owner = msg.sender;
        nominatedOwner = address(0);
    }

    // Restricted Functions: onlyOwner

    /// @dev nominating zero address revokes a pending nomination
    function nominateOwnership(address _newOwner) external onlyOwner {
        nominatedOwner = _newOwner;
    }

    function setAdmin(address _newAdmin) external onlyOwner {
        if (admin == _newAdmin) revert AlreadyRole();
        admin = _newAdmin;
    }

    // Restricted Functions: onlyAdmins

    function addAuthorized(address _authorized) external onlyAdmins {
        if (authorized[_authorized]) revert AlreadyRole();
        authorized[_authorized] = true;
        emit AuthAdded(_authorized);
    }

    function removeAuthorized(address _authorized) external onlyAdmins {
        if (!authorized[_authorized]) revert NotRole();
        authorized[_authorized] = false;
        emit AuthRemoved(_authorized);
    }

    // Modifiers

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier onlyAdmins() {
        if (msg.sender != owner && msg.sender != admin) revert Unauthorized();
        _;
    }

    modifier onlyAuthorized() {
        if (msg.sender != owner && msg.sender != admin && !authorized[msg.sender]) revert Unauthorized();
        _;
    }
}

abstract contract BlockDelay {
    /// @notice delay before functions with 'useBlockDelay' can be called by the same address
    /// @dev 0 means no delay
    uint256 public blockDelay;
    uint256 internal constant MAX_BLOCK_DELAY = 10;

    mapping(address => uint256) public lastBlock;

    error AboveMaxBlockDelay();
    error BeforeBlockDelay();

    constructor(uint8 _delay) {
        _setBlockDelay(_delay);
    }

    function _setBlockDelay(uint8 _newDelay) internal {
        if (_newDelay > MAX_BLOCK_DELAY) revert AboveMaxBlockDelay();
        blockDelay = _newDelay;
    }

    modifier useBlockDelay(address _address) {
        if (block.number < lastBlock[_address] + blockDelay) revert BeforeBlockDelay();
        lastBlock[_address] = block.number;
        _;
    }
}

/// @notice https://eips.ethereum.org/EIPS/eip-4626
interface IERC4626 {
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );

    function asset() external view returns (ERC20);

    function totalAssets() external view returns (uint256 assets);

    function convertToShares(uint256 assets) external view returns (uint256 shares);

    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    function maxDeposit(address receiver) external view returns (uint256 assets);

    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function maxMint(address receiver) external view returns (uint256 shares);

    function previewMint(uint256 shares) external view returns (uint256 assets);

    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    function maxWithdraw(address owner) external view returns (uint256 assets);

    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    function maxRedeem(address owner) external view returns (uint256 shares);

    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

contract Vault is ERC20, IERC4626, Ownership, BlockDelay {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /// @notice token which the vault uses and accumulates
    ERC20 public immutable asset;

    /// @notice whether deposits and withdrawals are paused
    bool public paused;

    uint256 private _lockedProfit;
    /// @notice timestamp of last report, used for locked profit calculations
    uint256 public lastReport;
    /// @notice period over which profits are gradually unlocked, defense against sandwich attacks
    uint256 public lockedProfitDuration = 24 hours;
    uint256 internal constant MAX_LOCKED_PROFIT_DURATION = 3 days;

    /// @dev maximum user can deposit in a single tx
    uint256 private _maxDeposit = type(uint256).max;

    struct StrategyParams {
        bool added;
        uint256 debt;
        uint256 debtRatio;
    }

    Strategy[] private _queue;
    mapping(Strategy => StrategyParams) public strategies;

    uint8 internal constant MAX_QUEUE_LENGTH = 20;

    uint256 public totalDebt;
    /// @dev proportion of funds kept in vault to facilitate user withdrawals
    uint256 public floatDebtRatio;
    uint256 public totalDebtRatio;
    uint256 internal constant MAX_TOTAL_DEBT_RATIO = 1_000;

    /*//////////////////
    /      Events      /
    //////////////////*/

    event Report(Strategy indexed strategy, uint256 harvested, uint256 gain, uint256 loss);
    event Lend(Strategy indexed strategy, uint256 assets, uint256 slippage);
    event Collect(Strategy indexed strategy, uint256 received, uint256 slippage, uint256 bonus);

    event StrategyAdded(Strategy indexed strategy, uint256 debtRatio);
    event StrategyDebtRatioChanged(Strategy indexed strategy, uint256 newDebtRatio);
    event StrategyRemoved(Strategy indexed strategy);
    event StrategyQueuePositionsSwapped(uint8 i, uint8 j, Strategy indexed newI, Strategy indexed newJ);

    event LockedProfitDurationChanged(uint256 newDuration);
    event MaxDepositChanged(uint256 newMaxDeposit);
    event FloatDebtRatioChanged(uint256 newFloatDebtRatio);

    /*//////////////////
    /      Errors      /
    //////////////////*/

    error Zero();
    error BelowMinimum(uint256);
    error AboveMaximum(uint256);

    error AboveMaxDeposit();

    error AlreadyStrategy();
    error NotStrategy();
    error StrategyDoesNotBelongToQueue();
    error StrategyQueueFull();

    error AlreadyValue();

    error Paused();

    /// @dev e.g. USDC becomes 'Unagii USD Coin Vault v3' and 'uUSDCv3'
    constructor(
        ERC20 _asset,
        uint8 _blockDelay,
        uint256 _floatDebtRatio,
        address _nominatedOwner,
        address _admin,
        address[] memory _authorized
    )
        ERC20(
            string(abi.encodePacked("Unagii ", _asset.name(), " Vault v3")),
            string(abi.encodePacked("u", _asset.symbol(), "v3")),
            _asset.decimals()
        )
        Ownership(_nominatedOwner, _admin, _authorized)
        BlockDelay(_blockDelay)
    {
        asset = _asset;
        _setFloatDebtRatio(_floatDebtRatio);
    }

    /*///////////////////////
    /      Public View      /
    ///////////////////////*/

    function queue() external view returns (Strategy[] memory) {
        return _queue;
    }

    function totalAssets() public view returns (uint256 assets) {
        return asset.balanceOf(address(this)) + totalDebt;
    }

    function lockedProfit() public view returns (uint256 lockedAssets) {
        uint256 last = lastReport;
        uint256 duration = lockedProfitDuration;

        unchecked {
            // won't overflow since time is nowhere near uint256.max
            if (block.timestamp >= last + duration) return 0;
            // can overflow if _lockedProfit * difference > uint256.max but in practice should never happen
            return _lockedProfit - _lockedProfit.mulDivDown(block.timestamp - last, duration);
        }
    }

    function freeAssets() public view returns (uint256 assets) {
        return totalAssets() - lockedProfit();
    }

    function convertToShares(uint256 _assets) public view returns (uint256 shares) {
        uint256 supply = totalSupply;
        return supply == 0 ? _assets : _assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 _shares) public view returns (uint256 assets) {
        uint256 supply = totalSupply;
        return supply == 0 ? _shares : _shares.mulDivDown(totalAssets(), supply);
    }

    function maxDeposit(address) external view returns (uint256 assets) {
        return _maxDeposit;
    }

    function previewDeposit(uint256 _assets) public view returns (uint256 shares) {
        return convertToShares(_assets);
    }

    function maxMint(address) external view returns (uint256 shares) {
        return convertToShares(_maxDeposit);
    }

    function previewMint(uint256 shares) public view returns (uint256 assets) {
        uint256 supply = totalSupply;
        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function maxWithdraw(address owner) external view returns (uint256 assets) {
        return convertToAssets(balanceOf[owner]);
    }

    function previewWithdraw(uint256 assets) public view returns (uint256 shares) {
        uint256 supply = totalSupply;
        return supply == 0 ? assets : assets.mulDivUp(supply, freeAssets());
    }

    function maxRedeem(address _owner) external view returns (uint256 shares) {
        return balanceOf[_owner];
    }

    function previewRedeem(uint256 shares) public view returns (uint256 assets) {
        uint256 supply = totalSupply;
        return supply == 0 ? shares : shares.mulDivDown(freeAssets(), supply);
    }

    /*////////////////////////////
    /      Public Functions      /
    ////////////////////////////*/

    function safeDeposit(uint256 _assets, address _receiver, uint256 _minShares) external returns (uint256 shares) {
        shares = deposit(_assets, _receiver);
        if (shares < _minShares) revert BelowMinimum(shares);
    }

    function safeMint(uint256 _shares, address _receiver, uint256 _maxAssets) external returns (uint256 assets) {
        assets = mint(_shares, _receiver);
        if (assets > _maxAssets) revert AboveMaximum(assets);
    }

    function safeWithdraw(uint256 _assets, address _receiver, address _owner, uint256 _maxShares)
        external
        returns (uint256 shares)
    {
        shares = withdraw(_assets, _receiver, _owner);
        if (shares > _maxShares) revert AboveMaximum(shares);
    }

    function safeRedeem(uint256 _shares, address _receiver, address _owner, uint256 _minAssets)
        external
        returns (uint256 assets)
    {
        assets = redeem(_shares, _receiver, _owner);
        if (assets < _minAssets) revert BelowMinimum(assets);
    }

    /*////////////////////////////////////
    /      ERC4626 Public Functions      /
    ////////////////////////////////////*/

    function deposit(uint256 _assets, address _receiver) public whenNotPaused returns (uint256 shares) {
        if ((shares = previewDeposit(_assets)) == 0) revert Zero();

        _deposit(_assets, shares, _receiver);
    }

    function mint(uint256 _shares, address _receiver) public whenNotPaused returns (uint256 assets) {
        if (_shares == 0) revert Zero();
        assets = previewMint(_shares);

        _deposit(assets, _shares, _receiver);
    }

    function withdraw(uint256 _assets, address _receiver, address _owner) public returns (uint256 shares) {
        if (_assets == 0) revert Zero();
        shares = previewWithdraw(_assets);

        _withdraw(_assets, shares, _owner, _receiver);
    }

    function redeem(uint256 _shares, address _receiver, address _owner) public returns (uint256 assets) {
        if ((assets = previewRedeem(_shares)) == 0) revert Zero();

        return _withdraw(assets, _shares, _owner, _receiver);
    }

    /*///////////////////////////////////////////
    /      Restricted Functions: onlyOwner      /
    ///////////////////////////////////////////*/

    function addStrategy(Strategy _strategy, uint256 _debtRatio) external onlyOwner {
        if (_strategy.vault() != this) revert StrategyDoesNotBelongToQueue();
        if (strategies[_strategy].added) revert AlreadyStrategy();
        if (_queue.length >= MAX_QUEUE_LENGTH) revert StrategyQueueFull();

        totalDebtRatio += _debtRatio;
        if (totalDebtRatio > MAX_TOTAL_DEBT_RATIO) revert AboveMaximum(totalDebtRatio);

        strategies[_strategy] = StrategyParams({added: true, debt: 0, debtRatio: _debtRatio});
        _queue.push(_strategy);

        emit StrategyAdded(_strategy, _debtRatio);
    }

    /*////////////////////////////////////////////
    /      Restricted Functions: onlyAdmins      /
    ////////////////////////////////////////////*/

    function removeStrategy(Strategy _strategy, bool _shouldHarvest, uint256 _minReceived)
        external
        onlyAdmins
        returns (uint256 received)
    {
        if (!strategies[_strategy].added) revert NotStrategy();

        _setDebtRatio(_strategy, 0);

        uint256 balanceBefore = asset.balanceOf(address(this));

        if (_shouldHarvest) _harvest(_strategy);
        else _report(_strategy, 0);

        received = asset.balanceOf(address(this)) - balanceBefore;

        if (received < _minReceived) revert BelowMinimum(received);

        // reorganize queue, filling in the empty strategy
        Strategy[] memory newQueue = new Strategy[](_queue.length - 1);

        bool found;
        uint8 length = uint8(newQueue.length);
        for (uint8 i = 0; i < length; ++i) {
            if (_queue[i] == _strategy) found = true;

            if (found) newQueue[i] = _queue[i + 1];
            else newQueue[i] = _queue[i];
        }

        delete strategies[_strategy];
        _queue = newQueue;

        emit StrategyRemoved(_strategy);
    }

    function swapQueuePositions(uint8 _i, uint8 _j) external onlyAdmins {
        Strategy s1 = _queue[_i];
        Strategy s2 = _queue[_j];

        _queue[_i] = s2;
        _queue[_j] = s1;

        emit StrategyQueuePositionsSwapped(_i, _j, s2, s1);
    }

    function setDebtRatio(Strategy _strategy, uint256 _newDebtRatio) external onlyAdmins {
        if (!strategies[_strategy].added) revert NotStrategy();
        _setDebtRatio(_strategy, _newDebtRatio);
    }

    /// @dev locked profit duration can be 0
    function setLockedProfitDuration(uint256 _newDuration) external onlyAdmins {
        if (_newDuration > MAX_LOCKED_PROFIT_DURATION) revert AboveMaximum(_newDuration);
        if (_newDuration == lockedProfitDuration) revert AlreadyValue();
        lockedProfitDuration = _newDuration;
        emit LockedProfitDurationChanged(_newDuration);
    }

    function setBlockDelay(uint8 _newDelay) external onlyAdmins {
        _setBlockDelay(_newDelay);
    }

    /*///////////////////////////////////////////////
    /      Restricted Functions: onlyAuthorized     /
    ///////////////////////////////////////////////*/

    function suspendStrategy(Strategy _strategy) external onlyAuthorized {
        if (!strategies[_strategy].added) revert NotStrategy();
        _setDebtRatio(_strategy, 0);
    }

    function collectFromStrategy(Strategy _strategy, uint256 _assets, uint256 _minReceived)
        external
        onlyAuthorized
        returns (uint256 received)
    {
        if (!strategies[_strategy].added) revert NotStrategy();
        (received,) = _collect(_strategy, _assets, address(this));
        if (received < _minReceived) revert BelowMinimum(received);
    }

    function pause() external onlyAuthorized {
        if (paused) revert AlreadyValue();
        paused = true;
    }

    function unpause() external onlyAuthorized {
        if (!paused) revert AlreadyValue();
        paused = false;
    }

    function setMaxDeposit(uint256 _newMaxDeposit) external onlyAuthorized {
        if (_maxDeposit == _newMaxDeposit) revert AlreadyValue();
        _maxDeposit = _newMaxDeposit;
        emit MaxDepositChanged(_newMaxDeposit);
    }

    /// @dev costs less gas than multiple harvests if active strategies > 1
    function harvestAll() external onlyAuthorized updateLastReport {
        uint8 length = uint8(_queue.length);
        for (uint8 i = 0; i < length; ++i) {
            _harvest(_queue[i]);
        }
    }

    /// @dev costs less gas than multiple reports if active strategies > 1
    function reportAll() external onlyAuthorized updateLastReport {
        uint8 length = uint8(_queue.length);
        for (uint8 i = 0; i < length; ++i) {
            _report(_queue[i], 0);
        }
    }

    function harvest(Strategy _strategy) external onlyAuthorized updateLastReport {
        if (!strategies[_strategy].added) revert NotStrategy();

        _harvest(_strategy);
    }

    function report(Strategy _strategy) external onlyAuthorized updateLastReport {
        if (!strategies[_strategy].added) revert NotStrategy();

        _report(_strategy, 0);
    }

    function setFloatDebtRatio(uint256 _floatDebtRatio) external onlyAuthorized {
        _setFloatDebtRatio(_floatDebtRatio);
    }

    /*///////////////////////////////////////////
    /      Internal Override: useBlockDelay     /
    ///////////////////////////////////////////*/

    /// @dev address cannot mint/burn/send/receive share tokens on same block, defense against flash loan exploits
    function _mint(address _to, uint256 _amount) internal override useBlockDelay(_to) {
        if (_to == address(0)) revert Zero();
        ERC20._mint(_to, _amount);
    }

    /// @dev address cannot mint/burn/send/receive share tokens on same block, defense against flash loan exploits
    function _burn(address _from, uint256 _amount) internal override useBlockDelay(_from) {
        ERC20._burn(_from, _amount);
    }

    /// @dev address cannot mint/burn/send/receive share tokens on same block, defense against flash loan exploits
    function transfer(address _to, uint256 _amount)
        public
        override
        useBlockDelay(msg.sender)
        useBlockDelay(_to)
        returns (bool)
    {
        return ERC20.transfer(_to, _amount);
    }

    /// @dev address cannot mint/burn/send/receive share tokens on same block, defense against flash loan exploits
    function transferFrom(address _from, address _to, uint256 _amount)
        public
        override
        useBlockDelay(_from)
        useBlockDelay(_to)
        returns (bool)
    {
        return ERC20.transferFrom(_from, _to, _amount);
    }

    /*//////////////////////////////
    /      Internal Functions      /
    //////////////////////////////*/

    function _deposit(uint256 _assets, uint256 _shares, address _receiver) internal {
        if (_assets > _maxDeposit) revert AboveMaxDeposit();

        asset.safeTransferFrom(msg.sender, address(this), _assets);
        _mint(_receiver, _shares);
        emit Deposit(msg.sender, _receiver, _assets, _shares);
    }

    function _withdraw(uint256 _assets, uint256 _shares, address _owner, address _receiver)
        internal
        returns (uint256 received)
    {
        if (msg.sender != _owner) {
            uint256 allowed = allowance[_owner][msg.sender];
            if (allowed != type(uint256).max) allowance[_owner][msg.sender] = allowed - _shares;
        }

        _burn(_owner, _shares);

        emit Withdraw(msg.sender, _receiver, _owner, _assets, _shares);

        // first, withdraw from balance
        uint256 balance = asset.balanceOf(address(this));

        if (balance > 0) {
            uint256 amount = _assets > balance ? balance : _assets;
            asset.safeTransfer(_receiver, amount);
            _assets -= amount;
            received += amount;
        }

        // next, withdraw from strategies
        uint8 length = uint8(_queue.length);
        for (uint8 i = 0; i < length; ++i) {
            if (_assets == 0) break;
            (uint256 receivedFromStrategy, uint256 slippage) = _collect(_queue[i], _assets, _receiver);
            _assets -= receivedFromStrategy + slippage; // user pays for slippage, if any
            received += receivedFromStrategy;
        }
    }

    /// @dev do not touch debt outside of _lend(), _collect() and _report()
    function _lend(Strategy _strategy, uint256 _assets) internal {
        uint256 balance = asset.balanceOf(address(this));
        uint256 amount = _assets > balance ? balance : _assets;

        asset.safeTransfer(address(_strategy), amount);
        _strategy.invest();

        uint256 debtBefore = strategies[_strategy].debt;
        uint256 debtAfter = _strategy.totalAssets();

        uint256 diff = debtAfter - debtBefore;

        uint256 slippage = amount > diff ? amount - diff : 0;

        // ignore bonus if diff > amount, safeguard against imprecise `strategy.totalAsset()` calculations that open vault to being drained
        uint256 debt = amount - slippage;

        strategies[_strategy].debt += debt;
        totalDebt += debt;

        emit Lend(_strategy, amount, slippage);
    }

    function _collect(Strategy _strategy, uint256 _assets, address _receiver)
        internal
        returns (uint256 received, uint256 slippage)
    {
        uint256 bonus;
        (received, slippage, bonus) = _strategy.withdraw(_assets);

        uint256 total = received + slippage;

        uint256 debt = strategies[_strategy].debt;

        uint256 amount = debt > total ? received : total;

        strategies[_strategy].debt -= amount;
        totalDebt -= amount;

        // do not pass bonuses on to users withdrawing, prevents exploits draining vault
        if (_receiver == address(this)) emit Collect(_strategy, received, slippage, bonus);
        else asset.safeTransfer(_receiver, received);
    }

    function _harvest(Strategy _strategy) internal {
        _report(_strategy, _strategy.harvest());
    }

    /// @dev do not touch debt outside of _lend(), _collect() and _report()
    function _report(Strategy _strategy, uint256 _harvested) internal {
        uint256 assets = _strategy.totalAssets();
        uint256 debt = strategies[_strategy].debt;

        strategies[_strategy].debt = assets; // update debt

        uint256 gain;
        uint256 loss;

        uint256 lockedProfitBefore = lockedProfit();

        if (assets > debt) {
            unchecked {
                gain = assets - debt;
            }
            totalDebt += gain;

            _lockedProfit = lockedProfitBefore + gain + _harvested;
        } else if (debt > assets) {
            unchecked {
                loss = debt - assets;
                totalDebt -= loss;

                _lockedProfit = lockedProfitBefore + _harvested > loss ? lockedProfitBefore + _harvested - loss : 0;
            }
        }

        uint256 possibleDebt =
            totalDebtRatio == 0 ? 0 : totalAssets().mulDivDown(strategies[_strategy].debtRatio, totalDebtRatio);

        if (possibleDebt > assets) _lend(_strategy, possibleDebt - assets);
        else if (assets > possibleDebt) _collect(_strategy, assets - possibleDebt, address(this));

        emit Report(_strategy, _harvested, gain, loss);
    }

    function _setDebtRatio(Strategy _strategy, uint256 _newDebtRatio) internal {
        uint256 currentDebtRatio = strategies[_strategy].debtRatio;
        if (_newDebtRatio == currentDebtRatio) revert AlreadyValue();

        uint256 newTotalDebtRatio = totalDebtRatio + _newDebtRatio - currentDebtRatio;
        if (newTotalDebtRatio > MAX_TOTAL_DEBT_RATIO) revert AboveMaximum(newTotalDebtRatio);

        strategies[_strategy].debtRatio = _newDebtRatio;
        totalDebtRatio = newTotalDebtRatio;

        emit StrategyDebtRatioChanged(_strategy, _newDebtRatio);
    }

    function _setFloatDebtRatio(uint256 _floatDebtRatio) internal {
        uint256 newTotalDebtRatio = totalDebtRatio + _floatDebtRatio - floatDebtRatio;
        if (newTotalDebtRatio > MAX_TOTAL_DEBT_RATIO) revert AboveMaximum(newTotalDebtRatio);

        floatDebtRatio = _floatDebtRatio;
        totalDebtRatio = newTotalDebtRatio;

        emit FloatDebtRatioChanged(_floatDebtRatio);
    }

    /*/////////////////////
    /      Modifiers      /
    /////////////////////*/

    modifier updateLastReport() {
        _;
        lastReport = block.timestamp;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }
}

/**
 * @dev
 * Strategies have to implement the following virtual functions:
 *
 * totalAssets()
 * _withdraw(uint256, address)
 * _harvest()
 * _invest()
 */
abstract contract Strategy is Ownership {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    Vault public immutable vault;
    ERC20 public immutable asset;

    /// @notice address which performance fees are sent to
    address public treasury;
    /// @notice performance fee sent to treasury / FEE_BASIS of 10_000
    uint16 public fee = 1_000;
    uint16 internal constant MAX_FEE = 1_000;
    uint16 internal constant FEE_BASIS = 10_000;

    /// @notice used to calculate slippage / SLIP_BASIS of 10_000
    /// @dev default to 99% (or 1%)
    uint16 public slip = 9_900;
    uint16 internal constant SLIP_BASIS = 10_000;

    /*//////////////////
    /      Events      /
    //////////////////*/

    event FeeChanged(uint16 newFee);
    event SlipChanged(uint16 newSlip);
    event TreasuryChanged(address indexed newTreasury);

    /*//////////////////
    /      Errors      /
    //////////////////*/

    error Zero();
    error NotVault();
    error InvalidValue();
    error AlreadyValue();

    constructor(Vault _vault, address _treasury, address _nominatedOwner, address _admin, address[] memory _authorized)
        Ownership(_nominatedOwner, _admin, _authorized)
    {
        vault = _vault;
        asset = vault.asset();
        treasury = _treasury;
    }

    /*//////////////////////////
    /      Public Virtual      /
    //////////////////////////*/

    /// @notice amount of 'asset' currently managed by strategy
    function totalAssets() public view virtual returns (uint256);

    /*///////////////////////////////////////////
    /      Restricted Functions: onlyVault      /
    ///////////////////////////////////////////*/

    function withdraw(uint256 _assets) external onlyVault returns (uint256 received, uint256 slippage, uint256 bonus) {
        uint256 total = totalAssets();
        if (total == 0) revert Zero();

        uint256 assets = _assets > total ? total : _assets;

        received = _withdraw(assets);

        unchecked {
            if (assets > received) {
                slippage = assets - received;
            } else if (received > assets) {
                bonus = received - assets;
                // received cannot > assets for vault calcuations
                received = assets;
            }
        }
    }

    /*//////////////////////////////////////////////////
    /      Restricted Functions: onlyAdminOrVault      /
    //////////////////////////////////////////////////*/

    function harvest() external onlyAdminOrVault returns (uint256 received) {
        _harvest();

        received = asset.balanceOf(address(this));

        if (fee > 0) {
            uint256 feeAmount = _calculateFee(received);
            received -= feeAmount;
            asset.safeTransfer(treasury, feeAmount);
        }

        asset.safeTransfer(address(vault), received);
    }

    function invest() external onlyAdminOrVault {
        _invest();
    }

    /*///////////////////////////////////////////
    /      Restricted Functions: onlyOwner      /
    ///////////////////////////////////////////*/

    function setFee(uint16 _fee) external onlyOwner {
        if (_fee > MAX_FEE) revert InvalidValue();
        if (_fee == fee) revert AlreadyValue();
        fee = _fee;
        emit FeeChanged(_fee);
    }

    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == treasury) revert AlreadyValue();
        treasury = _treasury;
        emit TreasuryChanged(_treasury);
    }

    /*////////////////////////////////////////////
    /      Restricted Functions: onlyAdmins      /
    ////////////////////////////////////////////*/

    function setSlip(uint16 _slip) external onlyAdmins {
        if (_slip > SLIP_BASIS) revert InvalidValue();
        if (_slip == slip) revert AlreadyValue();
        slip = _slip;
        emit SlipChanged(_slip);
    }

    /*////////////////////////////
    /      Internal Virtual      /
    ////////////////////////////*/

    function _withdraw(uint256 _assets) internal virtual returns (uint256 received);

    /// @dev return harvested assets
    function _harvest() internal virtual;

    function _invest() internal virtual;

    /*//////////////////////////////
    /      Internal Functions      /
    //////////////////////////////*/

    function _calculateSlippage(uint256 _amount) internal view returns (uint256) {
        return _amount.mulDivDown(slip, SLIP_BASIS);
    }

    function _calculateFee(uint256 _amount) internal view returns (uint256) {
        return _amount.mulDivDown(fee, FEE_BASIS);
    }

    modifier onlyVault() {
        if (msg.sender != address(vault)) revert NotVault();
        _;
    }

    /*//////////////////////////////
    /      Internal Functions      /
    //////////////////////////////*/

    modifier onlyAdminOrVault() {
        if (msg.sender != owner && msg.sender != admin && msg.sender != address(vault)) revert Unauthorized();
        _;
    }
}

contract WethStrategyStargate is Strategy {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for LPTokenERC20;
    using SafeTransferLib for WETH;
    using FixedPointMathLib for uint256;

    IStargateRouter internal constant router = IStargateRouter(0x8731d54E9D02c286767d56ac03e8037C07e01e98);
    ILPStaking internal constant staking = ILPStaking(0xB0D502E938ed5f4df2E681fE6E419ff29631d62b);
    ERC20 internal constant STG = ERC20(0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6);

    /// @dev Stargate's version of WETH that automatically unwraps on transfer. Annoyingly, not canonical WETH
    WETH internal constant SGETH = WETH(payable(0x72E2F4830b9E45d52F80aC08CB2bEC0FeF72eD9c));
    /// @dev canonical WETH
    WETH internal constant WETH9 = WETH(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));

    /// @dev pid of asset in their router
    uint16 public constant routerPoolId = 13;
    /// @dev pid of asset in their LP staking contract
    uint256 public constant stakingPoolId = 2;
    LPTokenERC20 public constant lpToken = LPTokenERC20(0x101816545F6bd2b1076434B54383a1E633390A2E);

    /// @notice contract used to swap STG rewards to asset
    Swap public swap;

    /*///////////////
    /     Errors    /
    ///////////////*/

    error NoRewards();
    error NothingToInvest();
    error BelowMinimum(uint256);
    error InvalidAsset();

    constructor(
        Vault _vault,
        address _treasury,
        address _nominatedOwner,
        address _admin,
        address[] memory _authorized,
        Swap _swap
    ) Strategy(_vault, _treasury, _nominatedOwner, _admin, _authorized) {
        swap = _swap;

        if (address(_vault.asset()) != address(WETH9)) revert InvalidAsset();

        _approve();
    }

    receive() external payable {
        if (msg.sender == address(WETH9)) return; // do nothing when unwrapping WETH

        // SGETH automatically unwraps to ETH upon transfer in `redeemLocal` and `instantRedeemLocal`. We wrap and send
        // WETH from other sources (namely router) to vault as ETH.
        WETH9.deposit{value: msg.value}();
        asset.safeTransfer(address(vault), msg.value);
    }

    /*///////////////////////
    /      Public View      /
    ///////////////////////*/

    function totalAssets() public view override returns (uint256 assets) {
        (uint256 stakedBalance,) = staking.userInfo(stakingPoolId, address(this));
        return lpToken.amountLPtoLD(stakedBalance);
    }

    /*///////////////////////////////////////////
    /      Restricted Functions: onlyOwner      /
    ///////////////////////////////////////////*/

    function changeSwap(Swap _swap) external onlyOwner {
        _unapproveSwap();
        swap = _swap;
        _approveSwap();
    }

    /*////////////////////////////////////////////////
    /      Restricted Functions: onlyAuthorized      /
    ////////////////////////////////////////////////*/

    function reapprove() external onlyAuthorized {
        _unapprove();
        _approve();
    }

    /**
     * @notice Safeguard to manually withdraw if insufficient delta in Stargate local pool.
     * 	@dev Use router.quoteLayerZeroFee to estimate 'msg.value' (excess will be refunded to `msg.sender`).
     * 	@param _dstChainId STG chainId, see https://stargateprotocol.gitbook.io/stargate/developers/contract-addresses/mainnet, ideally we want to use the chain with cheapest gas
     * 	@param _assets amount of LP to redeem, use type(uint256).max to withdraw everything
     * 	@param _lzTxObj usually can just be (0, 0, "0x")
     */
    function manualWithdraw(uint16 _dstChainId, uint256 _assets, IStargateRouter.lzTxObj calldata _lzTxObj)
        external
        payable
        onlyAuthorized
    {
        uint256 assets = totalAssets();

        uint256 amount = assets > _assets ? _assets : assets;
        uint256 lpAmount = _convertAssetToLP(amount);

        staking.withdraw(stakingPoolId, lpAmount);

        router.redeemLocal{value: msg.value}(
            _dstChainId,
            routerPoolId,
            routerPoolId,
            payable(msg.sender),
            lpAmount,
            abi.encodePacked(address(this)),
            _lzTxObj
        );
    }

    /*/////////////////////////////
    /      Internal Override      /
    /////////////////////////////*/

    function _withdraw(uint256 _assets) internal override returns (uint256 received) {
        uint256 lpAmount = _convertAssetToLP(_assets);

        // lpAmount can round down to 0 which will cause the withdraw to fail
        if (lpAmount == 0) return received;

        // 1. withdraw from staking contract
        staking.withdraw(stakingPoolId, lpAmount);

        // withdraw from stargate router
        received = router.instantRedeemLocal(routerPoolId, lpAmount, address(this));
        if (received < _calculateSlippage(_assets)) revert BelowMinimum(received);
    }

    function _harvest() internal override {
        // empty deposit/withdraw claims rewards withdraw as with all Goose clones
        staking.withdraw(stakingPoolId, 0);

        uint256 rewardBalance = STG.balanceOf(address(this));
        if (rewardBalance == 0) revert NoRewards(); // nothing to harvest

        swap.swapTokens(address(STG), address(asset), rewardBalance, 1);
    }

    function _invest() internal override {
        uint256 assetBalance = asset.balanceOf(address(this));
        if (assetBalance == 0) revert NothingToInvest();

        WETH9.withdraw(assetBalance);
        SGETH.deposit{value: assetBalance}();

        router.addLiquidity(routerPoolId, assetBalance, address(this));

        uint256 balance = lpToken.balanceOf(address(this));

        if (balance < _calculateSlippage(assetBalance)) revert BelowMinimum(balance);

        staking.deposit(stakingPoolId, balance);
    }

    /*//////////////////////////////
    /      Internal Functions      /
    //////////////////////////////*/

    function _approve() internal {
        // approve deposit SGETH into router
        SGETH.safeApprove(address(router), type(uint256).max);
        // approve deposit lpToken into staking contract
        lpToken.safeApprove(address(staking), type(uint256).max);

        _approveSwap();
    }

    function _unapprove() internal {
        SGETH.safeApprove(address(router), 0);
        lpToken.safeApprove(address(staking), 0);

        _unapproveSwap();
    }

    // approve swap rewards to asset
    function _unapproveSwap() internal {
        STG.safeApprove(address(swap), 0);
    }

    // approve swap rewards to asset
    function _approveSwap() internal {
        STG.safeApprove(address(swap), type(uint256).max);
    }

    function _convertAssetToLP(uint256 _amount) internal view returns (uint256) {
        return _amount.mulDivDown(lpToken.totalSupply(), lpToken.totalLiquidity());
    }
}