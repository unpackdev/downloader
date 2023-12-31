// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./IERC20.sol";

contract V1eUSDRewards is Ownable {
    
    constructor() {
       
    }

    function notifyRewardAmount(uint256 amount) external {

    }

    function withdrawToken(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }



}
