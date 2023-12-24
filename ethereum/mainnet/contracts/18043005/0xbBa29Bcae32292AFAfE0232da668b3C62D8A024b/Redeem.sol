// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";

contract Rewarder {
    address payable public tokenAddress;
    address payable public owner;

    constructor(address payable _tokenAddress) {
        owner = payable(msg.sender);
        tokenAddress = _tokenAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this function.");
        _;
    }

    function changeTokenAddress(address payable newTokenAddress)
        public
        onlyOwner
    {
        tokenAddress = newTokenAddress;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = payable(_newOwner);
    }

    function releaseRedeemToken(
        address[] memory _walletAddresses,
        uint256[] memory _amounts
    ) public onlyOwner {
        require(
            _walletAddresses.length == _amounts.length,
            "Array lengths must match"
        );
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }
        require(
            IERC20(tokenAddress).allowance(owner, address(this)) >= totalAmount,
            "Insufficient NAPA Tokens allowed to Rewarder by owner"
        );
        for (uint256 i = 0; i < _walletAddresses.length; i++) {
            address walletAddress = _walletAddresses[i];
            uint256 amount = _amounts[i];

            if (walletAddress != address(0)) {
                IERC20 token = IERC20(tokenAddress);
                token.transferFrom(owner, payable(walletAddress), amount);
            }
        }
    }
}