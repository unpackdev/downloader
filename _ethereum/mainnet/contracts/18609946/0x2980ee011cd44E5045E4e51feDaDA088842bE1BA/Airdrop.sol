/**

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
}

contract Airdrop {
    IERC20 public token;
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
        owner = msg.sender;
    }

    function airdropTokens(address[] calldata _recipients, uint256[] calldata _amounts) external onlyOwner {
        require(_recipients.length == _amounts.length, "Recipients and amounts length mismatch");

        for (uint256 i = 0; i < _recipients.length; i++) {
            require(token.transfer(_recipients[i], _amounts[i]), "Failed to transfer tokens");
        }
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        owner = newOwner;
    }
}