//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity 0.8.10;
//SPDX-License-Identifier: MIT

import "./IMultiplierCalculator.sol";
import "./IPalPoolSimplified.sol";
import "./IProposalValidator.sol";
import "./IAaveGovernanceV2.sol";
import "./IGovernanceStrategy.sol";
import "./Admin.sol";
import {Errors} from  "../../utils/Errors.sol";

/** @title Multiplier Calculator for Aave Governance */
/// @author Paladin
contract AaveMultiplierV2 is IMultiplierCalculator, Admin {

    address[] public pools;

    // Aave Governance contracts
    IProposalValidator public executor;
    IAaveGovernanceV2 public governance;
    IGovernanceStrategy public strategy;

    uint256 public activationFactor = 1000; //BPS

    uint256 public baseMultiplier = 10e18;

    constructor(
        address _governance,
        address _executor,
        address[] memory _pools
    ){
        admin = msg.sender;

        executor = IProposalValidator(_executor);
        governance = IAaveGovernanceV2(_governance);
        strategy = IGovernanceStrategy(governance.getGovernanceStrategy());
        
        for(uint256 i = 0; i < _pools.length; i++){
            pools.push(_pools[i]);
        }
    }

    function getCurrentMultiplier() external override view returns(uint256){
        uint256 totalBorrowed = getTotalBorrowedMultiPools();

        uint256 currentQuorum = getCurrentQuorum();
        uint256 activationThreshold = (currentQuorum * activationFactor) / 10000;

        if(totalBorrowed > activationThreshold){

            return (baseMultiplier * totalBorrowed) / currentQuorum;
        }
        //default case
        return 1e18;
    }


    function getTotalBorrowedMultiPools() internal view returns(uint256){
        uint256 total;
        address[] memory _pools = pools;
        uint256 length = _pools.length;
        for(uint256 i; i < length; i++){
            total += IPalPoolSimplified(_pools[i]).totalBorrowed();
        }
        return total;
    }


    function getCurrentQuorum() public view returns(uint256){
        return executor.getMinimumVotingPowerNeeded(
            strategy.getTotalVotingSupplyAt(block.number)
        );
    }


    //Admin functions

    function addPool(address _pool) external adminOnly {
        pools.push(_pool);
    }

    function removePool(address _pool) external adminOnly {
        address[] memory _pools = pools;
        uint256 length = _pools.length;
        for(uint256 i; i < length; i++){
            if(_pools[i] == _pool){
                uint256 lastIndex = length - 1;
                if(i != lastIndex){
                    pools[i] = pools[lastIndex];
                }
                pools.pop();
            }
        }
    }

    function updateBaseMultiplier(uint256 newBaseMultiplier) external adminOnly {
        if(newBaseMultiplier == 0) revert Errors.InvalidParameters();
        baseMultiplier = newBaseMultiplier;
    }

    function updateActivationFactor(uint256 newFactor) external adminOnly {
        if(newFactor > 10000) revert Errors.InvalidParameters();
        if(newFactor == 0) revert Errors.InvalidParameters();
        activationFactor = newFactor;
    }

    function updateGovernance(address newGovernance) external adminOnly {
        if(newGovernance == address(0)) revert Errors.ZeroAddress();
        governance = IAaveGovernanceV2(newGovernance);
        strategy = IGovernanceStrategy(governance.getGovernanceStrategy());
    }

    function updateGovernanceStrategy() external adminOnly {
        strategy = IGovernanceStrategy(governance.getGovernanceStrategy());
    }


    function updateExecutor(address newExecutor) external adminOnly {
        if(newExecutor == address(0)) revert Errors.ZeroAddress();
        executor = IProposalValidator(newExecutor);
    }

}