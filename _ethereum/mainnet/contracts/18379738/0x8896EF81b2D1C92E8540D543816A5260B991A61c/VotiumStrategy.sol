// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./AbstractStrategy.sol";
import "./AggregatorV3Interface.sol";
import "./VotiumStrategyCore.sol";

/// @title Votium Strategy Token
/// @author Asymmetry Finance
contract VotiumStrategy is VotiumStrategyCore, AbstractStrategy {
    event WithdrawRequest(
        address indexed user,
        uint256 amount,
        uint256 withdrawId
    );

    struct WithdrawRequestInfo {
        uint256 cvxOwed;
        bool withdrawn;
        uint256 epoch;
        address owner;
    }

    mapping(uint256 => WithdrawRequestInfo)
        public withdrawIdToWithdrawRequestInfo;

    /**
     * @notice Gets price in eth
     * @return Price of token in eth
     */
    function price(bool _validate) external view override returns (uint256) {
        return (cvxPerVotium() * ethPerCvx(_validate)) / 1e18;
    }

    /**
     * @notice Deposit eth to mint this token at current price
     * @return mintAmount Amount of tokens minted
     */
    function deposit()
        external
        payable
        override
        onlyManager
        returns (uint256 mintAmount)
    {
        uint256 priceBefore = cvxPerVotium();
        uint256 cvxAmount = buyCvx(msg.value);
        IERC20(CVX_ADDRESS).approve(VLCVX_ADDRESS, cvxAmount);
        ILockedCvx(VLCVX_ADDRESS).lock(address(this), cvxAmount, 0);
        mintAmount = ((cvxAmount * 1e18) / priceBefore);
        _mint(msg.sender, mintAmount);
        trackedCvxBalance -= cvxAmount;
    }

    /**
     * @notice Request to withdraw from strategy emits event with eligible withdraw epoch
     * @notice Burns afEth tokens and determines equivilent amount of cvx to start unlocking
     * @param _amount Amount to request withdraw
     * @return Id of withdraw request
     */
    function requestWithdraw(
        uint256 _amount
    ) external override onlyManager returns (uint256) {
        latestWithdrawId++;
        uint256 _priceInCvx = cvxPerVotium();

        _burn(msg.sender, _amount);

        uint256 currentEpoch = ILockedCvx(VLCVX_ADDRESS).findEpochId(
            block.timestamp
        );
        (
            ,
            uint256 unlockable,
            ,
            ILockedCvx.LockedBalance[] memory lockedBalances
        ) = ILockedCvx(VLCVX_ADDRESS).lockedBalances(address(this));
        uint256 cvxAmount = (_amount * _priceInCvx) / 1e18;
        cvxUnlockObligations += cvxAmount;
        uint256 unlockObligations = cvxUnlockObligations;
        uint256 totalLockedBalancePlusUnlockable = unlockable +
            trackedCvxBalance;

        if (totalLockedBalancePlusUnlockable >= unlockObligations) {
            withdrawIdToWithdrawRequestInfo[
                latestWithdrawId
            ] = WithdrawRequestInfo({
                cvxOwed: cvxAmount,
                withdrawn: false,
                epoch: currentEpoch + 1,
                owner: msg.sender
            });
            emit WithdrawRequest(msg.sender, cvxAmount, latestWithdrawId);

            return latestWithdrawId;
        }

        (, uint32 currentEpochStartingTime) = ILockedCvx(VLCVX_ADDRESS).epochs(
            currentEpoch
        );
        uint256 duration = ILockedCvx(VLCVX_ADDRESS).rewardsDuration();
        for (uint256 i = 0; i < lockedBalances.length; i++) {
            totalLockedBalancePlusUnlockable += lockedBalances[i].amount;
            // we found the epoch at which there is enough to unlock this position
            if (totalLockedBalancePlusUnlockable >= unlockObligations) {
                uint256 timeDifference = lockedBalances[i].unlockTime -
                    currentEpochStartingTime;
                uint256 epochOffset = timeDifference / duration;
                uint256 withdrawEpoch = currentEpoch + epochOffset;
                withdrawIdToWithdrawRequestInfo[
                    latestWithdrawId
                ] = WithdrawRequestInfo({
                    cvxOwed: cvxAmount,
                    withdrawn: false,
                    epoch: withdrawEpoch,
                    owner: msg.sender
                });

                emit WithdrawRequest(msg.sender, cvxAmount, latestWithdrawId);
                return latestWithdrawId;
            }
        }
        // should never get here
        revert InvalidLockedAmount();
    }

    /**
     * @notice Withdraws from requested withdraw if eligible epoch has passed
     * @param _withdrawId Id of withdraw request
     */
    function withdraw(uint256 _withdrawId) external override onlyManager {
        if (withdrawIdToWithdrawRequestInfo[_withdrawId].owner != msg.sender)
            revert NotOwner();
        if (!canWithdraw(_withdrawId)) revert WithdrawNotReady();

        if (withdrawIdToWithdrawRequestInfo[_withdrawId].withdrawn)
            revert AlreadyWithdrawn();

        relock();

        uint256 cvxWithdrawAmount = withdrawIdToWithdrawRequestInfo[_withdrawId]
            .cvxOwed;

        uint256 ethReceived = cvxWithdrawAmount > 0
            ? sellCvx(cvxWithdrawAmount)
            : 0;
        cvxUnlockObligations -= cvxWithdrawAmount;
        withdrawIdToWithdrawRequestInfo[_withdrawId].withdrawn = true;
        // solhint-disable-next-line
        if (ethReceived > 0) {
            (bool sent, ) = msg.sender.call{value: ethReceived}("");
            if (!sent) revert FailedToSend();
        }
    }

    /**
     * @notice Relocks cvx while ensuring there is enough to cover all withdraw requests
     * @dev This happens automatically on withdraw but will need to be manually called if no withdraws happen in an epoch where locks are expiring
     */
    function relock() public {
        (, uint256 unlockable, , ) = ILockedCvx(VLCVX_ADDRESS).lockedBalances(
            address(this)
        );
        uint256 unlockObligations = cvxUnlockObligations;
        if (unlockable > 0) {
            uint256 cvxBalanceBefore = IERC20(CVX_ADDRESS).balanceOf(
                address(this)
            );
            ILockedCvx(VLCVX_ADDRESS).processExpiredLocks(false);
            uint256 cvxBalanceAfter = IERC20(CVX_ADDRESS).balanceOf(
                address(this)
            );
            trackedCvxBalance += (cvxBalanceAfter - cvxBalanceBefore);
        }
        uint256 cvxAmountToRelock;
        unchecked {
            cvxAmountToRelock = trackedCvxBalance > unlockObligations
                ? trackedCvxBalance - unlockObligations
                : 0;
        }
        if (
            cvxAmountToRelock > 0 && !(ILockedCvx(VLCVX_ADDRESS).isShutdown())
        ) {
            IERC20(CVX_ADDRESS).approve(VLCVX_ADDRESS, cvxAmountToRelock);
            ILockedCvx(VLCVX_ADDRESS).lock(address(this), cvxAmountToRelock, 0);
            trackedCvxBalance -= cvxAmountToRelock;
        }
    }

    /**
     * @notice Checks if withdraw request is eligible to be withdrawn
     * @param _withdrawId Id of withdraw request
     */
    function canWithdraw(
        uint256 _withdrawId
    ) public view virtual override returns (bool) {
        uint256 currentEpoch = ILockedCvx(VLCVX_ADDRESS).findEpochId(
            block.timestamp
        );
        WithdrawRequestInfo
            storage withdrawRequest = withdrawIdToWithdrawRequestInfo[
                _withdrawId
            ];
        return
            withdrawRequest.epoch <= currentEpoch && !withdrawRequest.withdrawn;
    }

    /**
     * @notice Checks how long it will take to withdraw a given amount
     * @param _amount Amount of afEth to check how long it will take to withdraw
     * @return When it would be withdrawable based on the amount
     */
    function withdrawTime(
        uint256 _amount
    ) external view virtual override returns (uint256) {
        uint256 _priceInCvx = cvxPerVotium();
        (
            ,
            uint256 unlockable,
            ,
            ILockedCvx.LockedBalance[] memory lockedBalances
        ) = ILockedCvx(VLCVX_ADDRESS).lockedBalances(address(this));
        uint256 cvxAmount = (_amount * _priceInCvx) / 1e18;
        uint256 totalLockedBalancePlusUnlockable = unlockable +
            trackedCvxBalance;

        if (
            totalLockedBalancePlusUnlockable >= cvxUnlockObligations + cvxAmount
        ) {
            uint256 currentEpoch = ILockedCvx(VLCVX_ADDRESS).findEpochId(
                block.timestamp
            );
            (, uint32 date) = ILockedCvx(VLCVX_ADDRESS).epochs(
                currentEpoch + 1
            );
            return date;
        }

        for (uint256 i = 0; i < lockedBalances.length; i++) {
            totalLockedBalancePlusUnlockable += lockedBalances[i].amount;
            // we found the epoch at which there is enough to unlock this position
            if (
                totalLockedBalancePlusUnlockable >=
                cvxUnlockObligations + cvxAmount
            ) {
                return lockedBalances[i].unlockTime;
            }
        }
        revert InvalidLockedAmount();
    }
}
