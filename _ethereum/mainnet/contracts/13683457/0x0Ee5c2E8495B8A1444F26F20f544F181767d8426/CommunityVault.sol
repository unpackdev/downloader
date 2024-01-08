// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./IERC20.sol";

contract CommunityVault is Ownable {
    IERC20 private token;

    event SetAllowance(address indexed caller, address indexed spender, uint256 amount);

    constructor (address tokenAddress) {
        token = IERC20(tokenAddress);
    }

    function setAllowance(address spender, uint256 amount) public onlyOwner {
        token.approve(spender, amount);

        emit SetAllowance(msg.sender, spender, amount);
    }
}
