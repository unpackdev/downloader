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
import "./IhPalVotes.sol";
import "./SafeMath.sol";
import "./Admin.sol";

/** @title Multiplier Calculator for Paladin hPAL  */
/// @author Paladin
contract HolyPalMultiplier is IMultiplierCalculator, Admin {
    using SafeMath for uint256;

    address[] public pools;

    IhPalVotes public hPal;

    uint256 public activationFactor = 1000; //BPS

    // Percentage of the total Supply needed to reach Quorum on votes
    uint256 public quorumFactor = 1500; //BPS

    uint256 public baseMultiplier = 10e18;

    constructor(
        address _hPalAddress,
        address[] memory _pools
    ){
        admin = msg.sender;

        hPal = IhPalVotes(_hPalAddress);
        
        for(uint256 i = 0; i < _pools.length; i++){
            pools.push(_pools[i]);
        }
    }

    function getCurrentMultiplier() external override view returns(uint256){
        uint256 totalBorrowed = getTotalBorrowedMultiPools();

        uint256 currentQuorum = getCurrentQuorum();
        uint256 activationThreshold = currentQuorum.mul(activationFactor).div(10000);

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


    function getCurrentQuorum() public view returns(uint256){
        uint256 _totalSupply = hPal.totalSupply();
        return _totalSupply.mul(quorumFactor).div(10000);
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

    function updateActivationFactor(uint256 newFactor) external adminOnly {
        require(newFactor <= 10000);
        require(newFactor != 0);
        activationFactor = newFactor;
    }

    function updateQuorumFactor(uint256 newFactor) external adminOnly {
        require(newFactor <= 10000);
        require(newFactor != 0);
        quorumFactor = newFactor;
    }

}