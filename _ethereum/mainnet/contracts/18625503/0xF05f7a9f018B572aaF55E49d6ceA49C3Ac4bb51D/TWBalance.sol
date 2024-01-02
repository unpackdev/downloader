// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ITWBalance.sol";

//import "./console.sol";


abstract contract TWBalance is ITWBalance
{

    mapping(address => TWItem) private twapUserMap;
    TWItem private twapTotalSupply;



    //view
    function balanceOfTW(address user) public view returns (TWItem memory)
    {
        uint256 currentAmount=balanceOf0(user);
        return calcNewTW(twapUserMap[user], uint160(currentAmount));
    }
    function balanceOfAvg(address user, TWItem memory itemStart) view public returns (uint256)
    {
        TWItem memory itemNew=balanceOfTW(user);
        return avgAmount(itemStart,itemNew);
    }

    function totalSupplyTW() public view returns (TWItem memory)
    {
        uint256 currentAmount=totalSupply0();
        return calcNewTW(twapTotalSupply, uint160(currentAmount));
    }
    function totalSupplyAvg(TWItem memory itemStart) view public returns (uint256)
    {
        TWItem memory itemNew=totalSupplyTW();
        return avgAmount(itemStart,itemNew);
    }



    //internal
    function writeTWBalances(address user) internal
    {
        twapUserMap[user]=balanceOfTW(user);
        twapTotalSupply=totalSupplyTW();
    }

    function calcNewTW(TWItem memory itemOld, uint160 amount)internal view returns (TWItem memory itemNew)
    {
        uint48 blockTimestamp = uint48(block.timestamp);
        uint48 timeElapsed = blockTimestamp - itemOld.timestamp;
        itemNew.amountTW = itemOld.amountTW + uint208(timeElapsed)*uint208(amount);
        itemNew.timestamp = blockTimestamp;
    }

    function avgAmount(TWItem memory itemStart,TWItem memory itemNew) pure internal returns (uint256)
    {
        uint256 timeElapsed = uint256(itemNew.timestamp) - uint256(itemStart.timestamp);
        if(timeElapsed>0)
        {
            uint256 deltaTW=itemNew.amountTW-itemStart.amountTW;
            //return deltaTW/timeElapsed;//balance0
            return amountAt(deltaTW/timeElapsed, itemStart.timestamp+timeElapsed/2);//баланс приводится по времени на середину отрезка
        }
        else
        {
            return 0;
        }
    }


    //virtual
    function balanceOf(address account) public view virtual returns (uint256);
    function totalSupply() public view virtual returns (uint256);
    function balanceOf0(address account) public view virtual returns (uint256);
    function totalSupply0() public view virtual returns (uint256);
    function amountAt(uint256 amount,uint256 time) public pure virtual returns (uint256);

}
