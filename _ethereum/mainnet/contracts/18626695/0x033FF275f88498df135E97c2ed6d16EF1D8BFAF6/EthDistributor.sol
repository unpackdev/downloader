// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

error SumOfSharesOverOne();
error UpdateLocked();
error WithdrawFailed(address user, uint256 amount);
error NoTokensToWithdraw(address erc20address);
error ZeroAddress();

struct EthDistributorConfig {
    address owner;
    uint256 updateLockPeriod;
    uint256 distributionThreshold;
    address stakingPoolAddress;
    uint256 stakingRewardsShareInPermille;
}

contract EthDistributor is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 internal constant SHARE_PRECISION = 1000;
    uint256 public immutable updateLockPeriod;

    address public stakingPoolAddress;
    uint256 public stakingRewardsShare;
    uint256 public distributionThreshold;
    uint256 public lastModified;
    uint256 public ownerBalance;
    uint256 public failedStakingPoolTransferAmount;

    event ThresholdUpdated(uint256 newThreshold);
    event StakingPoolAddresUpdated(address newAddress);
    event StakingRewardsShareUpdated(uint256 newShare);
    event FundsDistributed(uint256 newRewards);
    event TransferFailed(address indexed user, uint256 amount);
    event OwnerWithdrawal(address indexed user, uint256 amount);
    event OwnerERC20Withdrawal(address indexed user, address indexed erc20address, uint256 amount);

    modifier withValidShares() {
        _;
        if (stakingRewardsShare > SHARE_PRECISION) {
            revert SumOfSharesOverOne();
        }
    }

    /**
     * @dev Contract properties can only be updated once in {{updateLockPeriod}} seconds.
     * After updating there is a period of 1 day, during which additional updates can be made.
     * After that, the contract is locked for edits until the {{updateLockPeriod}} is over.
     */
    modifier withLockPeriod() {
        uint256 secondsSinceLastModified = block.timestamp - lastModified;

        if (secondsSinceLastModified >= updateLockPeriod) {
            lastModified = block.timestamp;
        } else if (secondsSinceLastModified > 1 days) {
            revert UpdateLocked();
        }
        _;
    }

    constructor(EthDistributorConfig memory config) Ownable(config.owner) withValidShares {
        updateLockPeriod = config.updateLockPeriod;
        distributionThreshold = config.distributionThreshold;
        stakingPoolAddress = config.stakingPoolAddress;
        stakingRewardsShare = config.stakingRewardsShareInPermille;
        lastModified = block.timestamp;
    }

    /**
     * @dev Funds are distributed automatically, if balance of the contract reaches distributionThreshold.
     */
    receive() external payable {
        uint256 amount = getDistributableAmount();

        if (amount >= distributionThreshold) {
            _distribute(amount);
        }
    }

    /**
     * @dev Returns amount of ETH in contract, that hasn't been distributed yet.
     */
    function getDistributableAmount() public view returns (uint256) {
        return address(this).balance - ownerBalance - failedStakingPoolTransferAmount;
    }

    /**
     * @dev To trigger the distribution manually by the owner.
     */
    function distribute() external onlyOwner {
        uint256 amount = getDistributableAmount();
        _distribute(amount);
    }

    /**
     * @dev Internal function to distribute the funds. Failed transfer amounts are saved in the
     *  failedStakingPoolTransfers and failedGoodPassRewardsTransfers variables and will be retried on the next call.
     *
     */
    function _distribute(uint256 amount) internal nonReentrant {
        uint256 stakingRewardsAmount = (amount * stakingRewardsShare) / SHARE_PRECISION;
        uint256 ownerAmount = amount - stakingRewardsAmount;
        ownerBalance += ownerAmount;

        uint256 stakingRewardsToDistribute = stakingRewardsAmount + failedStakingPoolTransferAmount;

        (bool isSent,) = stakingPoolAddress.call{value: stakingRewardsToDistribute}("");
        if (!isSent) {
            failedStakingPoolTransferAmount = stakingRewardsToDistribute;
            emit TransferFailed(stakingPoolAddress, stakingRewardsAmount);
        } else {
            failedStakingPoolTransferAmount = 0;
        }

        emit FundsDistributed(amount);
    }

    /**
     * @dev Function to withdraw funds for owner, as owner funds are not distributed in _distribute function to save gas.
     */
    function withdraw() external onlyOwner {
        uint256 amount = ownerBalance;
        ownerBalance = 0;
        (bool isSent,) = msg.sender.call{value: amount}("");

        if (!isSent) {
            revert WithdrawFailed(msg.sender, amount);
        }

        emit OwnerWithdrawal(msg.sender, amount);
    }

    /**
     * @dev Function to withdraw any ERC20 tokens that were sent to the contract by mistake.
     */
    function withdrawERC20(address erc20address) external onlyOwner {
        uint256 balance = IERC20(erc20address).balanceOf(address(this));

        if (balance == 0) {
            revert NoTokensToWithdraw(erc20address);
        }

        IERC20(erc20address).safeTransfer(msg.sender, balance);

        emit OwnerERC20Withdrawal(msg.sender, erc20address, balance);
    }

    /**
     * @dev Setters for contract properties.
     * Only callable by the owner and only during 1 day in {{updateLockPeriod}} seconds.
     */
    function updateDistributionThreshold(uint256 newThreshold) external onlyOwner withLockPeriod {
        distributionThreshold = newThreshold;
        emit ThresholdUpdated(newThreshold);
    }

    function updateStakingRewardShare(uint256 newShare) external onlyOwner withLockPeriod withValidShares {
        stakingRewardsShare = newShare;
        emit StakingRewardsShareUpdated(newShare);
    }

    function updateStakingPoolAddress(address newAddress) external onlyOwner withLockPeriod {
        if (newAddress == address(0)) {
            revert ZeroAddress();
        }

        stakingPoolAddress = newAddress;
        emit StakingPoolAddresUpdated(newAddress);
    }
}
