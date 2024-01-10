// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./SafeOwnable.sol";
import "./console.sol";

contract TestHash {

    function encode(address _user, uint _amount) external pure returns (bytes memory result) {
        result = abi.encode(_user, _amount);
    }
    
    function encodePacked(address _user, uint _amount) external pure returns (bytes memory result) {
        result = abi.encodePacked(_user, _amount);
    }

    function doHash (bytes memory _data) external pure returns (bytes32) {
        return keccak256(_data);
    }

    function merkle(bytes32 hash1, bytes32 hash2) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(hash1, hash2));
    }
}
