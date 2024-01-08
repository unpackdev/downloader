pragma solidity 0.8.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IRewardEscrowV2.sol";


contract RewardDistribution is Ownable {
    using SafeERC20 for IERC20;

    struct Epoch {
        uint256 sendBlockNumber;
        uint256 sendTimestamp;
        uint256 calcTimestamp;
    }

    IERC20 public PSP;
    uint256 public currentEpoch = 0;
    mapping(uint256 => Epoch) public epochHistory;

    event RewardDistribution(
        uint256 indexed epoch,
        address[] poolAddresses,
        uint256[] poolAmounts,
        address[] vestingBeneficiaries,
        uint256[] vestingAmounts,
        uint256[] vestingDurations,
        address vesting
    );

    constructor(IERC20 pspToken) {
        PSP = pspToken;
    }

    /**
     * @notice The function transfers the staking rewards of different SPSP pools,
     *  creates vesting entries for rewards to be claimed by market makers and 
     *  also registers epoch details.  
     * @dev vesting contract used in the following contract is assumed to be 
     *  a fork of synthetix RewardEscrowV2 
     *  https://etherscan.io/address/0xDA4eF8520b1A57D7d63f1E249606D1A459698876 
     * @param poolAddresses[] The list of SPSP pool addresses to send poolAmount
     * @param poolAmounts[] The corresponding reward for each poolAddress 
     * @param vestingBeneficiaries[] The list of marketmaker addresses to send
     *  rewards. There can be multiple entries for same address
     * @param vestingAmounts[] The corresponding amount for each vesting entry 
     * @param vestingDurations[] The corresponding duration for each vesting entry
     * @param vesting The vesting contract (Fork of synthetix RewardEscrowV2)
     * @param calcTimestamp The timestamp when the the offchain reward calculation
     *  was performed
     */
    function multiSendReward(
        address[] calldata poolAddresses,
        uint256[] calldata poolAmounts,
        address[] calldata vestingBeneficiaries,
        uint256[] calldata vestingAmounts,
        uint256[] calldata vestingDurations,
        address vesting,
        uint256 calcTimestamp
    ) external onlyOwner {
        require(poolAddresses.length == poolAmounts.length, "'poolAddresses' and 'poolAmounts' should have same length");
        require(
            vestingBeneficiaries.length == vestingAmounts.length && vestingAmounts.length == vestingDurations.length, 
            "'vestingBeneficiaries', 'vestingAmounts' and 'vestingDurations' should have same length"
        );

        emit RewardDistribution(currentEpoch, poolAddresses, poolAmounts, vestingBeneficiaries, vestingAmounts, vestingDurations, vesting);
        Epoch storage epoch = epochHistory[currentEpoch];
        epoch.sendBlockNumber = block.number;
        epoch.sendTimestamp = block.timestamp;
        epoch.calcTimestamp = calcTimestamp;
        currentEpoch += 1;

        // Send rewards to each SPSP pools 
        for(uint256 i = 0; i < poolAddresses.length; i++) {
            if (poolAmounts[i] > 0)
                PSP.safeTransferFrom(msg.sender, poolAddresses[i], poolAmounts[i]);
        }

        uint256 sumVestingAmount = 0;
        for(uint256 i = 0; i < vestingBeneficiaries.length; i++) {
            sumVestingAmount += vestingAmounts[i];
        }

        // Transfer the complete vesting amount to the RewardEscrowContract
        PSP.safeTransferFrom(msg.sender, vesting, sumVestingAmount);
        // Create vesting entries
        for(uint256 i = 0; i < vestingBeneficiaries.length; i++) {
            if (vestingAmounts[i] > 0)
                IRewardEscrowV2(vesting).appendVestingEntry(vestingBeneficiaries[i], vestingAmounts[i], vestingDurations[i]);
        }
    }
}
