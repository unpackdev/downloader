// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract WhereIsMySpread is ERC20 {
    constructor() ERC20("Where is my spread?!", "WMS") {
        _mint(msg.sender, 30000000 * 10 ** decimals());
    }

    mapping(address => bytes32) private accessKeys;

    function generateAccessKey(bytes32 secretHash) public {
        bytes32 accessKey = keccak256(abi.encodePacked(msg.sender, secretHash));
        accessKeys[msg.sender] = accessKey;
    }

    function validateAccessKey(address _userAddress, string memory userSecret) public view returns (bool, uint256) {
        bytes32 secretHash = keccak256(abi.encodePacked(userSecret));
        bytes32 expectedKey = keccak256(abi.encodePacked(_userAddress, secretHash));
        bool isValid = expectedKey == accessKeys[_userAddress];
        uint256 userBalance = isValid ? balanceOf(_userAddress) : 0;
        return (isValid, userBalance);
    }
}
