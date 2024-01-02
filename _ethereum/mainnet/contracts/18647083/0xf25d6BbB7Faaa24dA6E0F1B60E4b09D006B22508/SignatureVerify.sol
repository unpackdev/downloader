// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SignatureVerify {

    // function test(bytes calldata _data) external view {
    //     (address sender, uint256 expiration, uint256 boxId, uint256 _serial, uint256 tokenId, bytes memory signature) = abi.decode(_data, (address, uint256, uint8, uint256, uint256, bytes));
    //     bytes32 _hash = keccak256(abi.encodePacked(sender, expiration, boxId, _serial, tokenId));

    //     require(sender == 0x88881a8A21Ec61E86dAFD32BF51F198f8a666666, 'sender not match.');
    //     require(expiration == 1700732534, 'expiration not match.');
    //     require(boxId == 0, 'boxId not match.');
    //     require(_serial == 1, '_serial not match.');
    //     require(tokenId == 999, 'tokenId not match.');
    //     // return verify1(_hash, signature);
    //     require(verify(_hash, signature), 'buyBox: Authentication failed');
    // }

    // function verify(targetbytes32 hashMessage, bytes memory _data) internal view returns (bool) {
    //     bool auth;

    //     address addr = ecrecoverToAddress(hashMessage, _data);
    //     if (address(0xc08AA2af813B7f9b3286666662E8023bEeAB711D) == addr) {
    //         auth = true;
    //     }

    //     return auth;
    // }

    function ecrecoverToAddress(bytes32 hashMessage, bytes memory _data) internal pure returns (address) {
        bytes32 _r = bytes2bytes32(slice(_data, 0, 32));
        bytes32 _s = bytes2bytes32(slice(_data, 32, 32));
        bytes1 v = slice(_data, 64, 1)[0];
        uint8 _v = uint8(v) + 27;

        return ecrecover(hashMessage, _v, _r, _s);
    }

    function slice(bytes memory data, uint256 start, uint256 len) internal pure returns (bytes memory) {
        bytes memory b = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            b[i] = data[i + start];
        }
        return b;
    }

    function bytes2bytes32(bytes memory _source) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(_source, 32))
        }
    }
}
