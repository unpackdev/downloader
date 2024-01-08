
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Ownable.sol";


/*
roundId: The round ID.
answer: The price.
startedAt: Timestamp of when the round started.
updatedAt: Timestamp of when the round was updated.
answeredInRound: The round ID of the round in which the answer
was computed.
*/
interface IPriceFeed  {
    function latestRoundData() external view 
        returns (
            uint80 roundId, 
            int256 answer, 
            uint256 startedAt, 
            uint256 updatedAt, 
            uint80 answeredInRound
        );
    function checkPriceError() external view returns ( bool error );     
}