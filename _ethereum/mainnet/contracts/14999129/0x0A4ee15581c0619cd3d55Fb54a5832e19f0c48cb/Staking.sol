// SPDX-License-Identifier: AGPL-3.0-only
// ERC20 Extensions v1.1.1
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./IStaking.sol";

contract Staking is ERC20, IStaking {
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    uint256 private constant MAX_UINT256 = type(uint256).max;
    // allows to distribute small amounts of ETH correctly
    uint256 private constant MAGNITUDE = 10**40;

    IERC20 token;
    uint256 private _magnifiedRewardPerShare;
    mapping(address => int256) private _magnifiedRewardCorrections;
    mapping(address => uint256) public claimedRewards;

    constructor(
        string memory name,
        string memory symbol,
        address underlyingToken
    ) ERC20(name, symbol) {
        token = IERC20(underlyingToken);
    }

    /// @notice when the smart contract receives ETH, register payment
    /// @dev can only receive ETH when tokens are staked
    receive() external payable virtual {
        require(totalSupply() > 0, "NO_TOKENS_STAKED");
        if (msg.value > 0) {
            _magnifiedRewardPerShare += (msg.value * MAGNITUDE) / totalSupply();
            emit RewardsReceived(_msgSender(), msg.value);
        }
    }

    function deposit(uint256 amount) public virtual returns (uint256) {
        uint256 share = 0;
        if (totalSupply() > 0) {
            share = (totalSupply() * amount) / token.balanceOf(address(this));
        } else {
            share = amount;
        }
        token.transferFrom(_msgSender(), address(this), amount);
        _mint(_msgSender(), share);
        emit Deposit(_msgSender(), amount, share);
        return share;
    }

    function withdraw(uint256 amount, bool claim) external virtual returns (uint256) {
        if (claim) {
            claimRewards(_msgSender());
        }
        uint256 withdrawnTokens = (amount * token.balanceOf(address(this))) / totalSupply();
        _burn(_msgSender(), amount);
        token.transfer(_msgSender(), withdrawnTokens);
        emit Withdraw(_msgSender(), withdrawnTokens, amount);
        return withdrawnTokens;
    }

    function claimRewards(address to) public virtual returns (uint256) {
        uint256 claimableRewards = claimableRewardsOf(_msgSender());
        if (claimableRewards > 0) {
            claimedRewards[_msgSender()] += claimableRewards;
            (bool success, ) = to.call{value: claimableRewards}("");
            require(success, "ETH_TRANSFER_FAILED");
            emit RewardClaimed(_msgSender(), to, claimableRewards);
        }
        return claimableRewards;
    }

    /// @dev on mint, burn and transfer adjust corrections so that ETH rewards don't change on these events
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _magnifiedRewardCorrections[to] -= (_magnifiedRewardPerShare * amount).toInt256Safe();
        } else if (to == address(0)) {
            // burn
            _magnifiedRewardCorrections[from] += (_magnifiedRewardPerShare * amount).toInt256Safe();
        } else {
            // transfer
            require(_isTransferable(), "TRANSFER_FORBIDDEN");
            int256 magnifiedCorrection = (_magnifiedRewardPerShare * amount).toInt256Safe();
            _magnifiedRewardCorrections[from] += (magnifiedCorrection);
            _magnifiedRewardCorrections[to] -= (magnifiedCorrection);
        }
    }

    function tokenBalance(address user) public view virtual returns (uint256) {
        if (totalSupply() == 0) {
            return 0;
        }
        return (balanceOf(user) * token.balanceOf(address(this))) / totalSupply();
    }

    function totalRewardsEarned(address user) public view virtual returns (uint256) {
        int256 magnifiedRewards = (_magnifiedRewardPerShare * balanceOf(user)).toInt256Safe();
        uint256 correctedRewards = (magnifiedRewards + _magnifiedRewardCorrections[user]).toUint256Safe();
        return correctedRewards / MAGNITUDE;
    }

    function claimableRewardsOf(address user) public view virtual returns (uint256) {
        return totalRewardsEarned(user) - claimedRewards[user];
    }

    function _isTransferable() internal view virtual returns (bool) {
        return false;
    }
}
