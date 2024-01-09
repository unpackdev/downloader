// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract BaseVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    struct Investor {
        uint256 paidAmount;
        uint256 timeRewardPaid;
    }

    uint256 internal constant PERIOD = 1 days;
    uint256 internal constant PERCENTAGE = 1e20;

    IERC20 public immutable token;
    uint256 public immutable startDate;
    uint256 public immutable totalAllocatedAmount;
    uint256 public immutable vestingDuration;
    uint256 public immutable tokensForLP;
    uint256 public immutable tokensForNative;

    uint256 public vestingTimeEnd;
    uint256 public everyDayReleasePercentage;

    event RewardPaid(address indexed investor, uint256 amount);

    mapping(address => Counters.Counter) public nonces;
    mapping(address => bool) public trustedSigner;
    mapping(address => Investor) public investorInfo;

    constructor(
        address signer_,
        address token_,
        uint256 startDate_,
        uint256 vestingDuration_,
        uint256 totalAllocatedAmount_
    ) {
        require(signer_ != address(0), "Invalid signer address");
        require(token_ != address(0), "Invalid reward token address");
        require(
            startDate_ > block.timestamp,
            "TGE timestamp can't be less than block timestamp"
        );
        require(vestingDuration_ > 0, "The vesting duration cannot be 0");
        require(
            totalAllocatedAmount_ > 0,
            "The number of tokens for distribution cannot be 0"
        );
        token = IERC20(token_);
        startDate = startDate_;
        vestingDuration = vestingDuration_;
        vestingTimeEnd = startDate_.add(vestingDuration_);
        uint256 periods = vestingDuration_.div(PERIOD);
        everyDayReleasePercentage = PERCENTAGE.div(periods);
        totalAllocatedAmount = totalAllocatedAmount_;
        uint256 nativeTokens = totalAllocatedAmount_.div(3);
        tokensForNative = nativeTokens;
        tokensForLP = totalAllocatedAmount_.sub(nativeTokens);
        trustedSigner[signer_] = true;
    }

    /**
     * @notice Adds new signer or removes permission from existing
     * @param signer signer address
     * @param permission set permission for signer address
     */
    function changeSignerList(address signer, bool permission)
        external
        onlyOwner
    {
        _changePermission(signer, permission);
    }

    /**
     * @dev emergency tokens withdraw
     * @param tokenAddress_ token address
     * @param amount amount to withdraw
     */
    function emergencyTokenWithdraw(address tokenAddress_, uint256 amount)
        external
        onlyOwner
    {
        require(block.timestamp > vestingTimeEnd, "Vesting is still running");
        IERC20 tokenAddress = IERC20(tokenAddress_);
        tokenAddress.safeTransfer(msg.sender, amount);
    }

    /**
     * @dev Withdraw reward tokens from distribution contract by investor
     * @param portionLP investor portion for LP stake
     * @param portionNative investor portion for Native stake
     * @dev Last three parameters is signature from signer
     */
    function withdrawReward(
        uint256 portionLP,
        uint256 portionNative,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(
            portionLP <= PERCENTAGE && portionNative <= PERCENTAGE,
            "The percentage cannot be greater than 100"
        );
        require(deadline >= block.timestamp, "Expired");
        bool access = _isValidData(
            msg.sender,
            portionLP,
            portionNative,
            deadline,
            v,
            r,
            s
        );
        require(access, "Permission not granted");
        _withdrawReward(msg.sender, portionLP, portionNative);
    }

    /**
     * @dev Returns current available rewards for investor
     * @param percentageLP investor percenage for LP stake
     * @param percentageNative investor percentage for Native stake
     */
    function getRewardBalance(
        address beneficiary,
        uint256 percentageLP,
        uint256 percentageNative
    ) public view returns (uint256 amount) {
        uint256 reward = _getRewardBalance(percentageLP, percentageNative);
        Investor storage investor = investorInfo[beneficiary];
        uint256 balance = token.balanceOf(address(this));
        if (reward <= investor.paidAmount) {
            return 0;
        } else {
            uint256 amountToPay = reward.sub(investor.paidAmount);
            if (amountToPay >= balance) {
                return balance;
            }
            return amountToPay;
        }
    }

    function _withdrawReward(
        address beneficiary,
        uint256 percentageLP,
        uint256 percentageNative
    ) private {
        uint256 reward = _getRewardBalance(percentageLP, percentageNative);
        Investor storage investor = investorInfo[beneficiary];
        uint256 balance = token.balanceOf(address(this));
        require(reward > investor.paidAmount, "No rewards available");
        uint256 amountToPay = reward - investor.paidAmount;
        if (amountToPay >= balance) {
            amountToPay = balance;
            investor.paidAmount = amountToPay.add(investor.paidAmount);
        } else {
            investor.paidAmount = reward;
        }
        investor.timeRewardPaid = block.timestamp;
        token.safeTransfer(beneficiary, amountToPay);
        emit RewardPaid(beneficiary, amountToPay);
    }

    function _getRewardBalance(uint256 lpPercentage, uint256 nativePercentage)
        private
        view
        returns (uint256)
    {
        uint256 vestingAvailablePercentage = _calculateAvailablePercentage();
        uint256 amountAvailableForLP = tokensForLP
            .mul(vestingAvailablePercentage)
            .div(PERCENTAGE);
        uint256 amountAvailableForNative = tokensForNative
            .mul(vestingAvailablePercentage)
            .div(PERCENTAGE);
        uint256 rewardToPayLP = amountAvailableForLP.mul(lpPercentage).div(
            PERCENTAGE
        );
        uint256 rewardToPayNative = amountAvailableForNative
            .mul(nativePercentage)
            .div(PERCENTAGE);
        return rewardToPayLP.add(rewardToPayNative);
    }

    function _calculateAvailablePercentage()
        internal
        view
        virtual
        returns (uint256)
    {
        uint256 currentTimeStamp = block.timestamp;
        if (currentTimeStamp < vestingTimeEnd) {
            uint256 noOfDays = currentTimeStamp.sub(startDate).div(PERIOD);
            uint256 currentUnlockedPercentage = noOfDays.mul(
                everyDayReleasePercentage
            );
            return currentUnlockedPercentage;
        } else {
            return PERCENTAGE;
        }
    }

    /**
     * @dev data and signature validation
     * @param addr investor address
     * @param portionLP investor portion for LP stake
     * @param portionNative investor portion for Native stake
     * @dev Last three parameters is signature from signer
     */
    function _isValidData(
        address addr,
        uint256 portionLP,
        uint256 portionNative,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal returns (bool) {
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");
        bytes32 message = keccak256(
            abi.encodePacked(
                address(this),
                addr,
                portionLP,
                portionNative,
                nonces[addr].current(),
                deadline
            )
        );

        address sender = ecrecover(message, v, r, s);
        if (trustedSigner[sender]) {
            nonces[addr].increment();
            return true;
        } else {
            return false;
        }
    }

    function _changePermission(address signer, bool permission) internal {
        require(signer != address(0), "Invalid signer address");
        trustedSigner[signer] = permission;
    }
}
