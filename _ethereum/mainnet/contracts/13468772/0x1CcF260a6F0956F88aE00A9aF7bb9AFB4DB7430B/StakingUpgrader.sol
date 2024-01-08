// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IFNFTHandler.sol";
import "./IAddressRegistry.sol";
import "./IRevest.sol";
import "./IOutputReceiver.sol";
import "./IOracleDispatch.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC165.sol";
import "./Staking.sol";
import "./RewardsHandler.sol";

/**
 * @title
 * @dev
 */
contract StakingUpgrader is Ownable  {

    address public constant MULTISIG = 0x801e08919a483ceA4C345b5f8789E506e2624ccf;
    address public stakingContract;
    address public rewardsHandler;
    address public addressRegistry;
    address internal immutable WETH;

    uint[4] internal interestRates = [4, 13, 27, 56];

    constructor(address _registry, address _stake, address _rewards, address _weth) {
        stakingContract = _stake;
        rewardsHandler = _rewards;
        addressRegistry = _registry;
        WETH = _weth;
    }

    function upgradeStakingPosition(uint fnftId, uint newMaturity) external {
        require(newMaturity == 3 || newMaturity == 6 || newMaturity == 12, 'E055');
        require(IFNFTHandler(getRegistry().getRevestFNFT()).getBalance(_msgSender(), fnftId) == 1, 'E061');
        // This may be unnecessary and constraining
        require(IOutputReceiver(stakingContract).getValue(fnftId) == 0, 'Must claim staking rewards to upgrade');
        Staking stake = Staking(stakingContract);
        RewardsHandler rewards = RewardsHandler(rewardsHandler);
        (uint allocPoints, uint timePeriod) = stake.config(fnftId);
        require(newMaturity > timePeriod, 'Can only upgrade staking maturity');
        // Determine if this is a single-asset or LP position
        bool isBasic;
        {
            // Will be zero if this is an LP stake
            uint wethTokenAlloc = IRewardsHandler(rewardsHandler).getAllocPoint(fnftId, WETH, true);
            isBasic = wethTokenAlloc > 0;
        }
        // Fetch alloc points total and subtract old alloc points from it
        uint pointsToAdjust = (isBasic ? rewards.totalBasicAllocPoint() : rewards.totalLPAllocPoint()) - allocPoints;
        // Adjust alloc points up
        allocPoints = allocPoints * getInterestRate(newMaturity) / getInterestRate(timePeriod);
        // Add new alloc points back to total
        pointsToAdjust += allocPoints;
        uint[] memory ids = new uint[](1);
        uint[] memory allocs = new uint[](1);
        ids[0] = fnftId;
        allocs[0] = allocPoints;
            {
                uint[] memory times = new uint[](1);
                times[0] = newMaturity;
                // Calls will only succeed if this contract owns Staking.sol
                stake.manualMapConfig(ids, allocs, times);
            }
        if(isBasic) {
            // Will implicitly set pending rewards to zero
            // For this reason, rewards must be claimed prior to upgarde
            rewards.manualMapRVSTBasic(ids, allocs);
            rewards.manualMapWethBasic(ids, allocs);
            // Zero argument will cause no change to that value
            rewards.manualSetAllocPoints(pointsToAdjust, 0);
        } else {
            rewards.manualMapRVSTLP(ids, allocs);
            rewards.manualMapWethLP(ids, allocs);
            rewards.manualSetAllocPoints(0, pointsToAdjust);
        }
    }

    /// Calling this function will break upgradeability and return ownership to multisig
    function revertStakingOwnership() external onlyOwner {
        Ownable(stakingContract).transferOwnership(MULTISIG);
    }

    /// Calling this function will break upgradeability and return ownership to multisig
    function revertRewardsOwnership() external onlyOwner {
        Ownable(rewardsHandler).transferOwnership(MULTISIG);
    }

    function setRegistry(address _registry) external onlyOwner() {
        addressRegistry = _registry;
    }

    function getRegistry() public view returns (IAddressRegistry) {
        return IAddressRegistry(addressRegistry);
    }

    function getInterestRate(uint months) public view returns (uint) {
        if (months <= 1) {
            return interestRates[0];
        } else if (months <= 3) {
            return interestRates[1];
        } else if (months <= 6) {
            return interestRates[2];
        } else {
            return interestRates[3];
        }
    }

}