//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title FRZ token
/// @author chalex.eth - CharlieDAO

import "IERC20.sol";
import "Address.sol";

interface IGauge {
    function deposit_reward_token(address, uint256) external;
}

contract Distributor {
    address constant FRZ_TOKEN = 0x55b1e2D8b13E7acad03353FAD58fc3FA065C5822;
    IGauge constant Gauge = IGauge(0x25530F3C929d3f4137A766dE3d37700d2Fc00FF8);
    uint256 constant WEEK = 7 * 86400;
    uint256 constant REWARD_AMOUNT = 200000 * (10**18);
    uint256 public lastTimeDistributed;
    uint256 internal constant MAX_UINT = 2**256 - 1;
    address constant owner = 0x0fBb8D17027b16810795B12cBEadc65B252530C4;

    error InsufficientBalance();
    error TooSoon();

    constructor() {
        IERC20(FRZ_TOKEN).approve(address(Gauge), MAX_UINT);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function sendRewardToGauge() external {
        if (IERC20(FRZ_TOKEN).balanceOf(address(this)) < REWARD_AMOUNT) {
            revert InsufficientBalance();
        }
        if (block.timestamp < lastTimeDistributed + WEEK) {
            revert TooSoon();
        }
        Gauge.deposit_reward_token(FRZ_TOKEN, REWARD_AMOUNT);
        lastTimeDistributed = block.timestamp;
    }

    function sendBackFRZ(uint256 _amount) external onlyOwner {
        IERC20(FRZ_TOKEN).transfer(owner, _amount);
    }

    function sendBackETH(uint256 _amount) external onlyOwner {
        Address.sendValue(payable(owner), _amount);
    }
}
