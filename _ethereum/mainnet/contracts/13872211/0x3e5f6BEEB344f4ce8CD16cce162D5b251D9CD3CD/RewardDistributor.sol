// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

/// @author crypt0s0nic
/// @title Fee distributor for StellarInu token
contract RewardDistributor is Ownable, ReentrancyGuard {
    mapping(address => uint256) public amounts;
    mapping(address => uint256) public realised;
    mapping(address => bool) public excludes;
    uint256 public totalRewarded;
    bool public claimable;

    receive() external payable {}

    /// @notice Set rewards of multiple accounts
    /// @dev `accounts` and `values` must have the same length
    /// Should be called when owner wants to distribute rewards
    /// Called by owner only
    /// @param accounts addresses of the rewarded accounts
    /// @param values balances of the shareholders
    function setRewards(address[] calldata accounts, uint256[] calldata values) external onlyOwner {
        require(accounts.length == values.length, "setRewards: INVALID_INPUT");
        for (uint256 i = 0; i < accounts.length; i++) {
            amounts[accounts[i]] += values[i];
        }
    }

    /// @notice Set claimable
    /// @dev claiming will be active is this is set to true and vice versa
    /// Called by owner only
    /// @param _claimable status of claiming activity
    function setClaimable(bool _claimable) external onlyOwner {
        claimable = _claimable;
    }

    /// @notice Set rewards of multiple accounts
    /// @dev Should be called when owner wants to remove any addresses from reward
    /// Called by owner only
    /// @param accounts addresses of the excluded accounts
    /// @param excluded whether accounts should be excluded or not
    function setExcludes(address[] calldata accounts, bool excluded) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            excludes[accounts[i]] = excluded;
        }
    }

    /// @notice Distribute the ETH reward to the sender
    /// @dev Revert if the sender is excluded from reward or unpaid reward is 0
    /// If the unpaid reward is bigger than current balance of the contract, send current balance.
    function claim() external nonReentrant {
        require(claimable, "claim: NOT_CLAIMABLE");
        require(!excludes[msg.sender], "claim: EXCLUDED_FROM_REWARD");
        uint256 amount = getUnpaidReward(msg.sender);
        if (amount > address(this).balance) {
            amount = address(this).balance;
        }
        require(amount > 0, "claim: INSUFFICIENT");
        realised[msg.sender] += amount;
        totalRewarded += amount;
        safeTransferETH(msg.sender, amount);
    }

    /// @notice View the unpaid reward of an account
    /// @param account The address of an account
    /// @return The amount of reward in wei that `account` can withdraw
    function getUnpaidReward(address account) public view returns (uint256) {
        if (amounts[account] > realised[account]) {
            return amounts[account] - realised[account];
        }
        return 0;
    }

    /// @notice Rescue ETH from the contract
    /// @dev Called by owner only
    /// @param receiver The payable address to receive ETH
    /// @param amount The amount in wei
    function withdrawETH(address receiver, uint256 amount) external onlyOwner {
        require(receiver != address(0), "withdrawETH: BURN_ADDRESS");
        if (amount > address(this).balance) {
            amount = address(this).balance;
        }
        safeTransferETH(receiver, amount);
    }

    /// @dev Private function that safely transfers ETH to an address
    /// It fails if to is 0x0 or the transfer isn't successful
    /// @param to The address to transfer to
    /// @param value The amount to be transferred
    function safeTransferETH(address to, uint256 value) private {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "safeTransferETH: ETH_TRANSFER_FAILED");
    }
}
