pragma solidity 0.8.10;

import "./SafeMath.sol";
import "./Context.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IStakingMaster.sol";
import "./IProvider.sol";
import "./EpochHelpers.sol";
import "./RewardHelpers.sol";
import "./ReentrancyGuard.sol";
import "./console.sol";

contract Provider is
    IProvider,
    Context,
    ReentrancyGuard,
    EpochHelpers,
    RewardHelpers
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private UniSwapToken;

    IERC20 private AuroxToken;

    IStakingMaster private StakingMasterContract;

    address public migrationContractAddress;

    // For storing user details
    mapping(address => UserDetails) public userInvestments;

    // If the user accidentally transfers ETH into the contract, revert the transfer
    fallback() external payable {
        revert("Cannot send ether to this contract");
    }

    // Events for the various actions
    event AddLiquidity(address indexed _from, uint256 _amount);

    event RemoveLiquidity(address indexed _from, uint256 _amount);

    event ClaimRewards(
        address indexed _from,
        uint256 _amount,
        bool indexed _sendRewardsToStaking
    );

    constructor(
        address _uniSwapTokenAddress,
        address _auroxTokenAddress,
        address _stakingMaster,
        uint256 _epochStart,
        address _migrationContractAddress
    ) {
        epochStart = _epochStart;
        UniSwapToken = IERC20(_uniSwapTokenAddress);
        AuroxToken = IERC20(_auroxTokenAddress);
        StakingMasterContract = IStakingMaster(_stakingMaster);

        migrationContractAddress = _migrationContractAddress;
    }

    // Return the users total investment amount
    function returnUsersInvestmentTotal(address _user)
        public
        view
        override
        returns (uint256)
    {
        EpochInvestmentDetails memory latestInvestmentDetails = userInvestments[
            _user
        ].epochTotals[userInvestments[_user].lastEpochUpdate];
        // Return the users investment total based on the epoch they edited last
        uint256 investmentTotal = _returnEpochAmountIncludingCurrentTotal(
            latestInvestmentDetails
        );
        return (investmentTotal);
    }

    // Returns a user's epoch totals for a given epoch
    function returnUsersEpochTotals(uint256 epoch, address _user)
        public
        view
        override
        returns (
            uint256 shareTotal,
            uint256 currentInvestmentTotal,
            uint256 allPrevInvestmentTotals
        )
    {
        EpochInvestmentDetails memory investmentDetails = userInvestments[_user]
            .epochTotals[epoch];
        return (
            investmentDetails.shareTotal,
            investmentDetails.currentInvestmentTotal,
            investmentDetails.allPrevInvestmentTotals
        );
    }

    function returnEpochShare(uint256 _amount, uint256 currentEpoch)
        public
        returns (uint256 share)
    {
        uint256 secondsToEpochEnd = _getSecondsToEpochEnd(currentEpoch);

        return _amount.mul(secondsToEpochEnd).div(epochLength);
    }

    function _updateUserDetailsAndEpochAmounts(
        address _userAddress,
        uint256 _amount
    ) internal {
        // Get the current epoch
        uint256 currentEpoch = _returnEpochToTimestamp(block.timestamp);

        UserDetails storage currentUser = userInvestments[_userAddress];

        if (currentUser.lastEpochUpdate == 0) {
            // Set the epoch for grabbing values to be this epoch.
            currentUser.lastLiquidityAddedEpochReference = currentEpoch;

            // Update when they last claimed to now, so they can't claim rewards for past epochs
            currentUser.lastClaimedTimestamp = block.timestamp;
        }

        uint256 usersTotal = _returnEpochAmountIncludingCurrentTotal(
            currentUser.epochTotals[currentUser.lastEpochUpdate]
        );
        // If they havent had an amount in the liquidity provider reset their boost reward, so they don't unexpectedly have a 100% boost reward immediately
        if (usersTotal == 0) {
            // TODO potentially a problem
            // Breaking tests when removed
            currentUser.lastEpochLiquidityWithdrawn = currentEpoch;

            // If they've claimed all rewards for their past investments, reset their last claimed timestamp to prevent them from looping uselessly
            uint256 lastClaimedEpoch = _returnEpochToTimestamp(
                currentUser.lastClaimedTimestamp
            );
            if (lastClaimedEpoch > currentUser.lastEpochUpdate) {
                currentUser.lastClaimedTimestamp = block.timestamp;
            }
        }

        // Normalise the epoch share as amount * secondsToEpochEnd / epochlength;
        uint256 epochShare = returnEpochShare(_amount, currentEpoch);

        // If the user hasn't added to the current epoch, carry over their investment total into the current epoch totals and update the reference for grabbing up to date user totals
        if (currentUser.lastEpochUpdate < currentEpoch) {
            // The pulled forward user's total investment amount
            uint256 allPrevInvestmentTotals = currentUser
                .epochTotals[currentUser.lastEpochUpdate]
                .allPrevInvestmentTotals;

            // Add the allPrevInvestmentTotals to the currentInvestmentTotal to reflect the new overall investment total
            uint256 pulledForwardTotal = allPrevInvestmentTotals.add(
                currentUser
                    .epochTotals[currentUser.lastEpochUpdate]
                    .currentInvestmentTotal
            );

            // Update the investment total by pulling forward the total amount from when the user last added liquidity
            currentUser
                .epochTotals[currentEpoch]
                .allPrevInvestmentTotals = pulledForwardTotal;

            // Update when liquidity was added last
            currentUser.lastEpochUpdate = currentEpoch;
        }

        // Update the share total for the current epoch

        currentUser.epochTotals[currentEpoch].shareTotal = currentUser
            .epochTotals[currentEpoch]
            .shareTotal
            .add(epochShare);

        // Update the user's currentInvestmentTotal to include the added amount
        currentUser
            .epochTotals[currentEpoch]
            .currentInvestmentTotal = currentUser
            .epochTotals[currentEpoch]
            .currentInvestmentTotal
            .add(_amount);

        /* Do the same calculations but add it to the overall totals not the users */

        // If the investment total hasn't been carried over into the "new" epoch
        if (lastEpochUpdate < currentEpoch) {
            // The pulled forward everyone's total amount
            uint256 allPrevInvestmentTotals = epochAmounts[lastEpochUpdate]
                .allPrevInvestmentTotals;

            // The total pulled forward amount, including investments made on that epoch.
            uint256 overallPulledForwardTotal = allPrevInvestmentTotals.add(
                epochAmounts[lastEpochUpdate].currentInvestmentTotal
            );

            // Update the current epoch investment total to have the pulled forward totals from all other epochs.
            epochAmounts[currentEpoch]
                .allPrevInvestmentTotals = overallPulledForwardTotal;

            // Update the lastEpochUpdate value
            lastEpochUpdate = currentEpoch;
        }

        // Update the share total for everyone to include the additional amount
        epochAmounts[currentEpoch].shareTotal = epochAmounts[currentEpoch]
            .shareTotal
            .add(epochShare);

        // Update the current investment total for everyone
        epochAmounts[currentEpoch].currentInvestmentTotal = epochAmounts[
            currentEpoch
        ].currentInvestmentTotal.add(_amount);
    }

    function addLiquidity(uint256 _amount) external override nonReentrant {
        require(block.timestamp > epochStart, "Epoch one hasn't started yet");
        require(_amount != 0, "Cannot add a 0 amount");

        require(
            UniSwapToken.allowance(_msgSender(), address(this)) >= _amount,
            "Allowance of Provider not large enough for the required amount"
        );
        // Require the user to have enough balance for the transfer amount
        require(
            UniSwapToken.balanceOf(_msgSender()) >= _amount,
            "Balance of the sender not large enough for the required amount"
        );

        UniSwapToken.safeTransferFrom(_msgSender(), address(this), _amount);

        _updateUserDetailsAndEpochAmounts(_msgSender(), _amount);

        emit AddLiquidity(_msgSender(), _amount);
    }

    function applyEpochRewardBonus(
        uint256 _epochBonusMultiplier,
        uint256 _epochRewards
    ) private pure returns (uint256) {
        if (_epochBonusMultiplier > 10) {
            _epochBonusMultiplier = 10;
        }

        return
            _epochRewards.add(_epochRewards.mul(_epochBonusMultiplier).div(10));
    }

    function saveMigrationUserDetails(
        MigrateArgs calldata migrateArgs,
        uint256 currentEpoch
    ) private {
        UserDetails storage currentUser = userInvestments[migrateArgs._user];

        // Set all the epoch tracking values
        currentUser.lastEpochUpdate = currentEpoch;

        currentUser.lastClaimedTimestamp = block.timestamp;

        currentUser.lastEpochLiquidityWithdrawn = currentEpoch;

        currentUser.lastLiquidityAddedEpochReference = currentEpoch;

        currentUser.bonusRewardMultiplier = migrateArgs._bonusRewardMultiplier;

        // Calculate the epoch share for the user
        uint256 epochShare = returnEpochShare(
            migrateArgs._amount,
            currentEpoch
        );

        // Update this specific users total
        currentUser.epochTotals[currentEpoch].shareTotal = epochShare;

        currentUser
            .epochTotals[currentEpoch]
            .currentInvestmentTotal = migrateArgs._amount;

        // Update the totals for all the users
        epochAmounts[currentEpoch].shareTotal = epochAmounts[currentEpoch]
            .shareTotal
            .add(epochShare);

        epochAmounts[currentEpoch].currentInvestmentTotal = epochAmounts[
            currentEpoch
        ].currentInvestmentTotal.add(migrateArgs._amount);
    }

    function migrateUsersLPPositions(MigrateArgs[] calldata allMigrateArgs)
        external
        override
    {
        // TODO Double checking with giorgi
        require(block.timestamp > epochStart, "Epoch one hasn't started yet");

        require(
            _msgSender() == migrationContractAddress,
            "Provider: Only the migration contract can call this function"
        );

        uint256 currentEpoch = _returnEpochToTimestamp(block.timestamp);
        uint256 transferTotal;

        for (uint8 i = 0; i < allMigrateArgs.length; i++) {
            transferTotal += allMigrateArgs[i]._amount;
            saveMigrationUserDetails(allMigrateArgs[i], currentEpoch);
        }

        lastEpochUpdate = currentEpoch;

        UniSwapToken.transferFrom(
            migrationContractAddress,
            address(this),
            transferTotal
        );
    }

    function returnAllClaimableRewardAmounts(address _user)
        public
        view
        override
        returns (
            uint256 rewardTotal,
            uint256 lastLiquidityAddedEpochReference,
            uint256 lastEpochLiquidityWithdrawn
        )
    {
        UserDetails storage currentUser = userInvestments[_user];

        // If the user has no investments return 0
        if (currentUser.lastEpochUpdate == 0) {
            return (0, 0, 0);
        }

        uint256 currentEpoch = _returnEpochToTimestamp(block.timestamp);

        // uint256 rewardTotal;

        // The last epoch they claimed from, to seed the start of the for-loop
        uint256 lastEpochClaimed = _returnEpochToTimestamp(
            currentUser.lastClaimedTimestamp
        );

        // To hold the users total in a given epoch
        uint256 usersEpochTotal;

        // To hold the overall total in a given epoch
        uint256 overallEpochTotal;

        // Reference to grab the user's latest epoch totals
        uint256 lastLiquidityAddedEpochReference = currentUser
            .lastLiquidityAddedEpochReference;

        // Reference to grab the overall epoch totals
        uint256 overallLastLiquidityAddedEpochReference = lastLiquidityAddedEpochReference;

        uint256 lastEpochLiquidityWithdrawn = currentUser
            .lastEpochLiquidityWithdrawn;

        for (uint256 epoch = lastEpochClaimed; epoch <= currentEpoch; epoch++) {
            // If the user withdrew liquidity in this epoch, update their reference for when they last withdrew liquidity
            if (currentUser.epochTotals[epoch].withdrewLiquidity) {
                lastEpochLiquidityWithdrawn = epoch;
            }

            // If the user did invest in this epoch, then their total investment amount is allTotals + shareAmount
            if (currentUser.epochTotals[epoch].shareTotal != 0) {
                // Update the reference for where to find values
                if (lastLiquidityAddedEpochReference != epoch) {
                    lastLiquidityAddedEpochReference = epoch;
                }
                // Update the user's total to include the share amount, as they invested in this epoch
                usersEpochTotal = _returnEpochAmountIncludingShare(
                    currentUser.epochTotals[epoch]
                );
            } else {
                // Prevent this statement executing multiple times by only executing it after the epoch reference is updated or if the value hasn't been set yet
                if (
                    epoch == lastLiquidityAddedEpochReference.add(1) ||
                    usersEpochTotal == 0
                ) {
                    usersEpochTotal = _returnEpochAmountIncludingCurrentTotal(
                        currentUser.epochTotals[
                            lastLiquidityAddedEpochReference
                        ]
                    );
                }
            }

            // If no rewards to be claimed for the current epoch, skip this loop
            if (usersEpochTotal == 0) continue;

            // If any user added amounts during this epoch, then update the overall total to include their share totals
            if (epochAmounts[epoch].shareTotal != 0) {
                // Update the reference of where to find an epoch total
                if (overallLastLiquidityAddedEpochReference != epoch) {
                    overallLastLiquidityAddedEpochReference = epoch;
                }
                // Set the overall epoch total to include the share
                overallEpochTotal = _returnEpochAmountIncludingShare(
                    epochAmounts[epoch]
                );
            } else {
                // Prevent this statement executing multiple times by only executing it after the epoch reference is updated or if the value hasn't been set yet
                if (
                    epoch == overallLastLiquidityAddedEpochReference.add(1) ||
                    overallEpochTotal == 0
                ) {
                    overallEpochTotal = _returnEpochAmountIncludingCurrentTotal(
                        epochAmounts[overallLastLiquidityAddedEpochReference]
                    );
                }
            }

            // Calculate the reward share for the epoch
            uint256 epochRewardShare = _calculateRewardShareForEpoch(
                epoch,
                currentEpoch,
                lastEpochClaimed,
                currentUser.lastClaimedTimestamp,
                usersEpochTotal,
                overallEpochTotal
            );

            // TODO this could be incorrect
            uint256 epochsCompleteWithoutWithdrawal = 0;

            if (lastEpochLiquidityWithdrawn < epoch) {
                epochsCompleteWithoutWithdrawal = epoch.sub(
                    lastEpochLiquidityWithdrawn
                );
            }

            if (epoch != currentEpoch) {
                epochRewardShare = applyEpochRewardBonus(
                    // Add the bonus reward multiplier to the reward multiplier
                    epochsCompleteWithoutWithdrawal.add(
                        currentUser.bonusRewardMultiplier
                    ),
                    epochRewardShare
                );
            }

            rewardTotal = rewardTotal.add(epochRewardShare);
        }

        return (
            rewardTotal,
            lastLiquidityAddedEpochReference,
            lastEpochLiquidityWithdrawn
        );
    }

    function claimRewards(bool _sendRewardsToStaking, uint256 stakeDuration)
        public
        override
        nonReentrant
    {
        UserDetails storage currentUser = userInvestments[_msgSender()];

        // require the user to actually have an investment amount
        require(
            currentUser.lastEpochUpdate > 0,
            "User has no rewards to claim, as they have never added liquidity"
        );

        (
            uint256 allClaimableAmounts,
            uint256 lastLiquidityAddedEpochReference,
            uint256 lastEpochLiquidityWithdrawn
        ) = returnAllClaimableRewardAmounts(_msgSender());

        // If the user has never added liquidity, simply return and don't update any details onchain
        if (lastLiquidityAddedEpochReference == 0) {
            return;
        }

        currentUser
            .lastLiquidityAddedEpochReference = lastLiquidityAddedEpochReference;

        currentUser.lastEpochLiquidityWithdrawn = lastEpochLiquidityWithdrawn;

        // Update their last claim to now
        currentUser.lastClaimedTimestamp = block.timestamp;

        // Return if no rewards to claim. Don't revert otherwise the user's details won't update to now and they will continually loop over epoch's that contain no rewards.
        if (allClaimableAmounts == 0) {
            return;
        }

        if (_sendRewardsToStaking) {
            // Return a valid stake for the user
            address usersStake = StakingMasterContract
                .returnValidUsersProviderStake(_msgSender());

            // If the stake is valid add the amount to it
            if (usersStake != address(0)) {
                StakingMasterContract.addToStake(
                    usersStake,
                    allClaimableAmounts
                );
                // Otherwise create a new stake for the user
            } else {
                StakingMasterContract.createStaking(
                    allClaimableAmounts,
                    stakeDuration,
                    _msgSender()
                );
            }
            // If not sending the rewards to staking simply sends the rewards back to the user
        } else {
            AuroxToken.safeTransferFrom(
                address(AuroxToken),
                _msgSender(),
                allClaimableAmounts
            );
        }

        emit ClaimRewards(
            _msgSender(),
            allClaimableAmounts,
            _sendRewardsToStaking
        );
    }

    function removeLiquidity(uint256 _amount) public override nonReentrant {
        UserDetails storage currentUser = userInvestments[_msgSender()];

        // The epoch the user last added liquidity, this will give the latest version of their total amounts

        EpochInvestmentDetails
            storage usersLastAddedLiquidityEpochInvestmentDetails = currentUser
                .epochTotals[currentUser.lastEpochUpdate];

        // Calculate the user's total based on when they last added liquidity

        uint256 usersTotal = _returnEpochAmountIncludingCurrentTotal(
            usersLastAddedLiquidityEpochInvestmentDetails
        );

        // Ensure the user has enough amount to deduct the balance
        require(
            usersTotal >= _amount,
            "User doesn't have enough balance to withdraw the amount"
        );

        uint256 currentEpoch = _returnEpochToTimestamp(block.timestamp);

        // The users investment details for the current epoch
        EpochInvestmentDetails
            storage usersCurrentEpochInvestmentDetails = currentUser
                .epochTotals[currentEpoch];

        /* Calculate how much to remove from the user's share total if they have invested in the same epoch they are removing from */

        // How many seconds they can claim from the current epoch
        uint256 claimSecondsForPulledLiquidity = _returnClaimSecondsForPulledLiquidity(
                currentUser.lastClaimedTimestamp,
                currentEpoch
            );

        // How much the _amount is claimable since epoch start or when they last claimed rewards
        uint256 claimAmountOnPulledLiquidity = _amount
            .mul(claimSecondsForPulledLiquidity)
            .div(epochLength);

        // In the very rare case that they have no claim to the pulled liquidity, set the value to 1. This negates issues in the claim rewards function
        if (claimAmountOnPulledLiquidity == 0) {
            claimAmountOnPulledLiquidity = 1;
        }

        // If they have a share total in this epoch, then deduct it from the overall total and add the new calculated share total
        if (usersCurrentEpochInvestmentDetails.shareTotal != 0) {
            epochAmounts[currentEpoch].shareTotal = epochAmounts[currentEpoch]
                .shareTotal
                .sub(usersCurrentEpochInvestmentDetails.shareTotal);
        }

        // NOTE: They lose the reward amount they've earnt on a share total. If they add liqudiity and pull in same epoch they lose rewards earnt on the share total.
        usersCurrentEpochInvestmentDetails
            .shareTotal = claimAmountOnPulledLiquidity;

        // If they haven't updated in this epoch. Pull the total forward minus the amount
        if (currentUser.lastEpochUpdate != currentEpoch) {
            // Update the overall total to refelct the updated amount
            usersCurrentEpochInvestmentDetails
                .allPrevInvestmentTotals = usersTotal.sub(_amount);

            // Update when it was last updated
            currentUser.lastEpochUpdate = currentEpoch;
        } else {
            // If there isn't enough in the allPrevInvestmentTotal for the subtracted amount
            if (
                usersLastAddedLiquidityEpochInvestmentDetails
                    .allPrevInvestmentTotals < _amount
            ) {
                // Update the amount so it deducts the allPrevAmount
                uint256 usersRemainingAmount = _amount.sub(
                    usersLastAddedLiquidityEpochInvestmentDetails
                        .allPrevInvestmentTotals
                );

                // Set the prev investment total to 0
                usersCurrentEpochInvestmentDetails.allPrevInvestmentTotals = 0;

                // Deduct from the currentInvestmentTotal the remaining _amount
                usersCurrentEpochInvestmentDetails
                    .currentInvestmentTotal = usersLastAddedLiquidityEpochInvestmentDetails
                    .currentInvestmentTotal
                    .sub(usersRemainingAmount);
            } else {
                // Subtract from their allPrevInvestmentTotal the amount to deduct and then update the user's total on the current epoch to be the new amounts
                usersCurrentEpochInvestmentDetails
                    .allPrevInvestmentTotals = usersLastAddedLiquidityEpochInvestmentDetails
                    .allPrevInvestmentTotals
                    .sub(_amount);

                // Pull forward the current investment total
                usersCurrentEpochInvestmentDetails
                    .currentInvestmentTotal = usersLastAddedLiquidityEpochInvestmentDetails
                    .currentInvestmentTotal;
            }
        }

        // Update when the user last withdrew liquidity
        // currentUser.lastEpochLiquidityWithdrawn = currentEpoch;
        usersCurrentEpochInvestmentDetails.withdrewLiquidity = true;

        // Update the share total
        epochAmounts[currentEpoch].shareTotal = epochAmounts[currentEpoch]
            .shareTotal
            .add(claimAmountOnPulledLiquidity);
        // If the epoch amounts for this epoch haven't been updated
        if (lastEpochUpdate != currentEpoch) {
            uint256 overallEpochTotal = _returnEpochAmountIncludingCurrentTotal(
                epochAmounts[lastEpochUpdate]
            );

            // Update the overall total to refelct the updated amount
            epochAmounts[currentEpoch]
                .allPrevInvestmentTotals = overallEpochTotal.sub(_amount);

            // Update when it was last updated
            lastEpochUpdate = currentEpoch;
        } else {
            // If there isnt enough in the total investment totals for the amount
            if (epochAmounts[currentEpoch].allPrevInvestmentTotals < _amount) {
                // Update the amount so it deducts the allPrevAmount
                uint256 overallRemainingAmount = _amount.sub(
                    epochAmounts[currentEpoch].allPrevInvestmentTotals
                );

                // Set the prev investment total to 0
                epochAmounts[currentEpoch].allPrevInvestmentTotals = 0;

                // Deduct from the currentInvestmentTotal the remaining _amount
                epochAmounts[currentEpoch]
                    .currentInvestmentTotal = epochAmounts[currentEpoch]
                    .currentInvestmentTotal
                    .sub(overallRemainingAmount);
            } else {
                // Subtract from their allPrevInvestmentTotal the amount to deduct and then update the user's total on the current epoch to be the new amounts
                epochAmounts[currentEpoch]
                    .allPrevInvestmentTotals = epochAmounts[currentEpoch]
                    .allPrevInvestmentTotals
                    .sub(_amount);

                // Pull forward the current investment total
                epochAmounts[currentEpoch]
                    .currentInvestmentTotal = epochAmounts[currentEpoch]
                    .currentInvestmentTotal;
            }
        }

        // If the user is withdrawing in the first day of the epoch, then they get penalised no rewards
        if (returnIfInFirstDayOfEpoch(currentEpoch)) {
            UniSwapToken.safeTransfer(_msgSender(), _amount);
        } else {
            // Transfer 90% of the _amount to the user
            UniSwapToken.safeTransfer(_msgSender(), _amount.mul(9).div(10));
            // Transfer 10% to the burn address
            UniSwapToken.safeTransfer(
                0x0000000000000000000000000000000000000001,
                _amount.div(10)
            );
        }

        emit RemoveLiquidity(_msgSender(), _amount);
    }
}
