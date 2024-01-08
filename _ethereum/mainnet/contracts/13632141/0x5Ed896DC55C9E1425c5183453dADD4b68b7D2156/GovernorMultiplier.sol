//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./IMultiplierCalculator.sol";
import "./IGovernor.sol";
import "./IPalPoolSimplified.sol";
import "./SafeMath.sol";
import "./Admin.sol";

/** @title Multiplier Calculator for Governor type systems  */
/// @author Paladin
contract GovernorMultiplier is IMultiplierCalculator, Admin {
    using SafeMath for uint;

    IGovernor public governor;

    address[] public pools;

    uint256 public activationThreshold;

    constructor(
        address _governor,
        address[] memory _pools
    ){
        admin = msg.sender;

        governor = IGovernor(_governor);

        activationThreshold = 0.75e18;
        
        for(uint i = 0; i < _pools.length; i++){
            pools.push(_pools[i]);
        }
    }

    function getCurrentMultiplier() external override view returns(uint){
        uint totalBorrowed = getTotalBorrowedMultiPools();
        uint proposalThreshold = governor.proposalThreshold();

        if(totalBorrowed > proposalThreshold.mul(activationThreshold).div(1e18)){
            uint quorumAmount = governor.quorumVotes();

            uint leftPart = (totalBorrowed.mul(1e18).div(proposalThreshold.mul(activationThreshold).div(1e18))).sub(1e18);
            uint rightPart = quorumAmount.mul(1e18).div(totalBorrowed);

            return uint(1e18).add(leftPart.mul(rightPart).div(1e18));
        }
        //default case
        return 1e18;
    }


    function getTotalBorrowedMultiPools() internal view returns(uint){
        uint total = 0;
        address[] memory _pools = pools;
        for(uint i = 0; i < _pools.length; i++){
            total = total.add(IPalPoolSimplified(_pools[i]).totalBorrowed());
        }
        return total;
    }



    //Admin functions

    function addPool(address _pool) external adminOnly {
        pools.push(_pool);
    }

    function removePool(address _pool) external adminOnly {
        address[] memory _pools = pools;
        for(uint i; i < _pools.length; i++){
            if(_pools[i] == _pool){
                uint lastIndex = _pools.length.sub(1);
                if(i != lastIndex){
                    pools[i] = pools[lastIndex];
                }
                pools.pop();
            }
        }
    }

    function updateGovernor(address _governor) external adminOnly {
        governor = IGovernor(_governor);
    }

    function updateActivationThreshold(uint newThreshold) external adminOnly {
        require(newThreshold >= 0.5e18);
        require(newThreshold < 1e18);
        activationThreshold = newThreshold;
    }

}