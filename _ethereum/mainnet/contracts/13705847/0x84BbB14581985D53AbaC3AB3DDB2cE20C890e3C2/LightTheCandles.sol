// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./SafeMath.sol";

contract Menorah {

//                           (
//   )     (     )     (    (_)    (     (     )     (
//  (_)   (_)   (_)   (_)   |~|   (_)   (_)   (_)   (_)
//  |~|   |~|   |~|   |~|   |:|   |~|   |~|   |~|   |~|
//  |:|   |:|   |:|   |:|   |:|   |:|   |:|   |:|   |:|
//  |:|   |:|   |:|   |:|   |:|   |:|   |:|   |:|   |:|
//  |:|   |:|   |:|   |:|   |:|   |:|   |:|   |:|   |:|
//  |:|   |:|   |:|   |:|   |:|   |:|   |:|   |:|   |:|
//  |:|   |:|   |:|   |:|   |:|   |:|   |:|   |:|   |:|
//  |:|   |:|   |:|   |:|   |:|   |:|   |:|   |:|   |:|
//  |:|   |:|   |:|   |:|   |:|   |:|   |:|   |:|   |:|
//  |:|   |:|   |:|   |:|  <+++>  |:|   |:|   |:|   |:|
// <+++> <+++> <+++> <+++>  }~{  <+++> <+++> <+++> <+++>
//  }~{   }~{   }~{   }~{   {+}   }~{   }~{   }~{   }~{
//  {+}   {+}   {+}   {+}   {+}   {+}   {+}   {+}   {+}
//   {}    {}     {}    {}  {+}  {}    {}     {}    {}
//    `{}   `{}    `{}   {} {+} {}   {}`    {}`   {}`
//       `{}   `{}   `{}  {}{+}{}  {}`   {}`   {}`
//         `'{}{}{}{}{}{}{}{}+{}{}{}{}{}{}{}{}'`
//               `{}{}{}{}__/_\__{}{}{}{}`
//                        \/   \/
//                        /\___/\
//                        ~~\_/~~
//                          {+}
//                          {+}
//                       __<+++>__
//                   ___{}{}\O/{}{}___
//                __<+++++++++++++++++>__
//               {}{}{}{}{}{/O\}{}{}{}{}{}
//               `"""""""""""""""""""""""`
// Artwork by JGS, AsciiArt.website
// Smart Contract by AtlasCorp

    using SafeMath for uint256;

    bool[8] public candles;
    address[8] public shamashList;

    uint256 public candlesLit = 0;

    function lightTheCandles() public {
        require(candlesLit < 8, "All candles lit. Happy Hanukkah and See you next year!");

        uint256 tonightsCandle = 7 - candlesLit;

        //Candles can be lit at 6pm EST daily starting on November 28, 2021
        require(block.timestamp >= candlesLit.mul(86400).add(1638140400), "Too early to light the next candle. Happy Hanukkah!");
        require(candles[tonightsCandle]==false, "Tonight's candle already lit. Happy Hanukkah!");

        candles[tonightsCandle] = true;
        candlesLit++;

        shamashList[tonightsCandle] = msg.sender;
    }

    function getCandles() public view returns (bool[8] memory){
        return candles;
    }

    function getShamashList() public view returns (address[8] memory) {
        return shamashList;
    }

}