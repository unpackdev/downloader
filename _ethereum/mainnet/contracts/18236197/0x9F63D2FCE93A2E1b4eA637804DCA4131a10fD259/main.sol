//
// THE SUM GAME 
// May the luck be on your side
// 
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract main {
    address public governanceToken;
    address private owner;

    modifier onlyOwner {
        require(owner == msg.sender, "!owner");
        _;
    }

    constructor(address _governanceToken) {
        owner = msg.sender;
        governanceToken = _governanceToken;
    }

    function distributePrize(address winner, address[] calldata loserAddresses, uint256[] calldata loserAmounts) external onlyOwner {
        require(loserAddresses.length == loserAmounts.length, "length mismatch");

        IERC20 token = IERC20(governanceToken);

        for (uint256 i = 0; i < loserAddresses.length; i++) {
            token.transferFrom(loserAddresses[i], winner, loserAmounts[i]);
        }
    }
}