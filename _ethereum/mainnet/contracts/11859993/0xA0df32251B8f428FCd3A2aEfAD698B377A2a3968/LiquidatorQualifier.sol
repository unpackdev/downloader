// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC20.sol";
import "./ILiquidatorQualifier.sol";
import "./UnsignedSafeMath.sol";
import "./SafeERC20.sol";

/**
 * @title Deri Protocol liquidator quanlifier implementation
 */
contract LiquidatorQualifier is ILiquidatorQualifier {

    using SafeERC20 for IERC20;
    using UnsignedSafeMath for uint256;

    address public controller;

    // ERC20 token used as stake to judge the qualification of a liquidator
    // Stake token is designed to be DERI token
    address public stakeTokenAddress;
    // Total staked tokens
    uint256 public totalStakedTokens;
    // Total number of stakers
    uint256 public totalStakers;
    // Stakers' balance record
    mapping (address => uint256) public stakes;

    constructor (address stakeTokenAddress_) {
        controller = msg.sender;
        stakeTokenAddress = stakeTokenAddress_;
    }

    function setController(address newController) public {
        require(newController != address(0), "LiquidatorQualifier: setController to 0 address");
        require(msg.sender == controller, "LiquidatorQualifier: setController can only be called by controller");
        controller = newController;
    }

    /**
     * @dev Depoist `amount` of stake token to compete to be a qualified liquidator
     */
    function deposit(uint256 amount) public {
        require(amount != 0, "LiquidatorQualifier: deposit 0 stake tokens");
        IERC20(stakeTokenAddress).safeTransferFrom(msg.sender, address(this), amount);

        totalStakedTokens = totalStakedTokens.add(amount);
        if (stakes[msg.sender] == 0) {
            totalStakers = totalStakers.add(1);
        }
        stakes[msg.sender] = stakes[msg.sender].add(amount);
    }

    /**
     * @dev Withdraw `amount` of stake token
     * The caller must at least have `amount` of stake token deposited before
     */
    function withdraw(uint256 amount) public {
        require(amount != 0, "LiquidatorQualifier: withdraw 0 stake tokens");
        require(amount <= stakes[msg.sender], "LiquidatorQualifier: withdraw amount exceeds staked");

        totalStakedTokens = totalStakedTokens.sub(amount);
        if (stakes[msg.sender] == amount) {
            totalStakers = totalStakers.sub(1);
        }
        stakes[msg.sender] = stakes[msg.sender].sub(amount);

        IERC20(stakeTokenAddress).safeTransfer(msg.sender, amount);
    }

    /**
     * @dev Check if `liquidator` is qualified as a liquidator
     * In this version, the only requirement is `liquidator`'s deposited stake token
     * is above or equal to the average deposition
     */
    function isQualifiedLiquidator(address liquidator) public view override returns (bool) {
        if (totalStakers == 0) {
            return false;
        }
        return stakes[liquidator] >= totalStakedTokens / totalStakers;
    }

}
