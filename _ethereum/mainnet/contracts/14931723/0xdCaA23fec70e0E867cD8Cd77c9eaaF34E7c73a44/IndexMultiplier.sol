//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./IMultiplierCalculator.sol";
import "./IPalPoolSimplified.sol";
import "./SafeMath.sol";
import "./Admin.sol";

/** @title Multiplier Calculator for Index Coop Governance  */
/// @author Paladin
contract IndexMultiplier is IMultiplierCalculator, Admin {
    using SafeMath for uint256;

    address[] public pools;

    uint256 public activationThreshold;
    uint256 public activationFactor = 1000; //BPS

    uint256 public currentQuorum;

    uint256 public baseMultiplier = 10e18;

    constructor(
        uint256 _currentQuorum,
        address[] memory _pools
    ){
        admin = msg.sender;

        currentQuorum = _currentQuorum;

        activationThreshold = _currentQuorum.mul(activationFactor).div(10000);
        
        for(uint256 i = 0; i < _pools.length; i++){
            pools.push(_pools[i]);
        }
    }

    function getCurrentMultiplier() external override view returns(uint256){
        uint256 totalBorrowed = getTotalBorrowedMultiPools();

        if(totalBorrowed > activationThreshold){

            return baseMultiplier.mul(totalBorrowed).div(currentQuorum);
        }
        //default case
        return 1e18;
    }


    function getTotalBorrowedMultiPools() internal view returns(uint256){
        uint256 total;
        address[] memory _pools = pools;
        uint256 length = _pools.length;
        for(uint256 i; i < length; i++){
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
        uint256 length = _pools.length;
        for(uint256 i; i < length; i++){
            if(_pools[i] == _pool){
                uint256 lastIndex = length.sub(1);
                if(i != lastIndex){
                    pools[i] = pools[lastIndex];
                }
                pools.pop();
            }
        }
    }

    function updateBaseMultiplier(uint256 newBaseMultiplier) external adminOnly {
        require(newBaseMultiplier != 0);
        baseMultiplier = newBaseMultiplier;
    }

    function updateQuorum(uint256 newQuorum) external adminOnly {
        require(newQuorum != 0);
        currentQuorum = newQuorum;

        //Update activationThreshold
        activationThreshold = newQuorum.mul(activationFactor).div(10000);
    }

    function updateActivationFactor(uint256 newFactor) external adminOnly {
        require(newFactor <= 10000);
        require(newFactor != 0);
        activationFactor = newFactor;

        //Update activationThreshold
        activationThreshold = currentQuorum.mul(newFactor).div(10000);
    }

}