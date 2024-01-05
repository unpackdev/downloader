// SPDX-License-Identifier: UNLICENSED
// DELTA-BUG-BOUNTY
pragma solidity ^0.7.6;
pragma abicoder v2;
import "./IDeltaToken.sol";
// import "./IDeepFarmingVault.sol";
// import "./IDeltaDistributor.sol";

contract DELTA_Deep_Farming_Storage {
    struct UserInformationDFV {
        // Reward debts is used for math trick to achieve O(1) farmed amount
        // We set rewardDebts to exactly amount of accumulted*shares every time a claim is done
        uint256 rewardDebtETH;
        uint256 rewardDebtDELTA;
        // Users farming power this includes, multiplier, rlp,delta principle. And can be stale - meaning too high and 
        // is adjusted every time there is a interaction
        uint256 farmingPower; // rlp*rlpratio + deltaTotal * multipleir
        // Delta balances and total of them to save gas
        uint256 deltaPermanent; // Never withdrawable
        uint256 deltaVesting; // Amount that needs to vest 12 months to be claimable 
        uint256 deltaWithdrawable; // Amount that can be withdrawn right away (with 2 week vesting)
        uint256 totalDelta; // Sum of them all (delta only no rlp)
        uint256 rlp; // amount of rlp this user has
        uint256 lastBoosterDepositTimestamp; // timestamp of the last booster deposit
        uint256 lastBooster; // last booster recorded for this person, this might be too high and is subject to adjustment 
        uint256 lastInteractionBlock; // Block of last interaction, we allow 1 interaction per block of an address
        bool compoundBurn; // A boolean that sets compounding effect, either burn maintaining multiplier or just adding. 
    }
    struct VaultInformation {
        uint256 totalFarmingPower; // A sum of farming power of all users (includes stale ones) // rlp*rlpratio + deltaTotal * multipleir * all users
        // Accumulated balances of each reward token stored in e12 for change
        uint256 accumulatedDELTAPerShareE12; // pending rewards / totalshares *1e12
        uint256 accumulatedETHPerShareE12;
    }
    struct Rewards {
        uint256 DELTA;
        uint256 ETH;
    }
    struct RecycledFarmingValues {
        uint256 delta;
        uint256 eth;
        uint256 percentLegit;
        uint256 calculatedBooster;
    }
    
    bool internal _isNotPaniced;
    uint256 public farmingStartedTimestamp;
    Rewards internal pendingRewards; // Rewards that are pending to be added to vault and splut per share with the updateVault()
    VaultInformation public vaultInfo; // Stores info of this vault
    mapping(address => address []) public withdrawalContracts; // All withdrawal contracts of a person
    mapping(address => UserInformationDFV) public userInfo; // stores all userinformation 
    mapping(address => bool) public isAGuardian;
}