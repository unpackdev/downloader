// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ISFIRewarder.sol";

/**
 * @dev Implementation of the ISFIRewarder interface.
 *
 * This contract holds SFI tokens minted by governance for liquidity mining rewards.
 * It distributes rewards to users based on the SaffronStakingV2 contract. This is
 * an extension of the Sushiswap Masterchef contract. It allows SFI in the rewards
 * pool to be separate from SFI staked in single-asset staking via SaffronStakingV2.
 *
 * NOTE: Before opening staking send enough SFI here otherwise distribution can fail.
 *
 * NOTE: Partial rewards are impossible because the contract always tries to pay out 
 *       in full.
 */
contract SFIRewarder is Ownable, ISFIRewarder {
    using SafeERC20 for IERC20;

    // SFI governance token
    IERC20 public sfi;

    // SaffronStakingV2 contract address
    address public saffronStaking;

    constructor(address _sfi) {
        require(_sfi != address(0), "invalid _sfi address");
        sfi = IERC20(_sfi);
    }

    /**
     * @dev Set the address for the live SaffronStakingV2 contract.
     * @param _saffronStaking The address of the deployed SaffronStakingV2 contract.
     *
     * Note that the SFIRewarder  must be deployed before SaffronStakingV2 contract
     * and then this function called with the SaffronStakingV2 address
     */
    function setStakingAddress(address _saffronStaking) external onlyOwner {
        require(_saffronStaking != address(0), "invalid _staking address");
        saffronStaking = _saffronStaking;
    }

    /**
     * @dev Reward the user with SFI. Should be called by the SaffronStakingV2 contract.
     * @param to The account to reward with SFI.
     * @param amount The amount of SFI to reward.
     */
    function rewardUser(address to, uint256 amount) external override onlyStaking {
        sfi.safeTransfer(to, amount);
        emit UserRewarded(to, amount);
    }

    /**
     * @dev Emergency withdraw all SFI from the contract.
     * @param token The ERC20 token address to withdraw from the contract.
     * @param to The account that will receive the withdrawn tokens.
     * @param amount The amount (wei) of tokens to be transferred.
     */
    function emergencyWithdraw(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }

    /**
     * @dev Modifier to make a function callable only by a deployed SaffronStakingV2 contract.
     *
     * Requirements:
     *
     * - saffronStaking must be set by governance first.
     */
    modifier onlyStaking {
        require(msg.sender == saffronStaking, "requires staking pool");
        _;
    }
}
