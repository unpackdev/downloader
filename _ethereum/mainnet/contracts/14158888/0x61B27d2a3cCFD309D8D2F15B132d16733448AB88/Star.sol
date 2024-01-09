//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IStar.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract Star is IStar, ERC20, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public maxDonate = 1 ether;
    uint256 public minDonate = maxDonate.div(100);
    uint256 public reward = 100000000;
    uint256 public rewardBase = 10000;

    constructor() ERC20("SC_APPS_STAR", "Star") {}

    /* ================ UTIL FUNCTIONS ================ */

    modifier _question(uint256 answer) {
        require(answer == msg.value.mul(reward).div(rewardBase), "Star: error answer");
        _;
    }

    modifier _noContract() {
        require(msg.sender == tx.origin, "Star: no contract");
        _;
    }

    /* ================ VIEW FUNCTIONS ================ */

    /* ================ TRANSACTION FUNCTIONS ================ */

    function donate(uint256 answer) external payable override _question(answer) _noContract {
        require(msg.value <= maxDonate && msg.value >= minDonate, "Star: error value");
        uint256 amount = msg.value.mul(reward).div(rewardBase);
        _mint(msg.sender, amount);
        reward = reward.mul(996).div(1000);
        emit Donate(msg.sender, msg.value, amount);
    }

    /* ================ ADMIN FUNCTIONS ================ */

    function get(address receiver) external override onlyOwner {
        (bool success, ) = receiver.call{value: address(this).balance}("");
        require(success, "Star: error receiver");
    }

    function transferAnyERC20Token(
        address token,
        address to,
        uint256 amount
    ) external override onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
}
