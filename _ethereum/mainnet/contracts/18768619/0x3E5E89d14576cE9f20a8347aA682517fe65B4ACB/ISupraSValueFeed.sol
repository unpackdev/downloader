// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISupraSValueFeed {


     struct dataWithoutHcc {
        uint256 round;
        uint256 decimals;
        uint256 time;
        uint256 price;

    }

    struct dataWithHcc {
        uint256 round;
        uint256 decimals;
        uint256 time;
        uint256 price;
        uint256 historyConsistent;
    }

    struct derivedData{
        int256 roundDifference;
        int256 timeDifference;
        uint256 derivedPrice;
        uint256 decimals;
    }

    
    function restrictedSetSupraStorage(uint256 _index, bytes32 _bytes) 
        external;


    function restrictedSetTimestamp(uint256 _tradingPair, uint256 timestamp)
        external;


    function getTimestamp(uint256 _tradingPair) 
        external 
        view 
        returns (uint256);


     function getSvalue(uint64 _pairIndex)
        external
        view
        returns (bytes32, bool);


    function getSvalues(uint64[] memory _pairIndexes)
        external
        view
        returns (bytes32[] memory, bool[] memory);


    function getDerivedSvalue(uint256 _derivedPairId) 
        external 
        view 
        returns (derivedData memory);
   

    function getSvalueWithHCC(uint256 _pairIndex)
        external
        view
        returns (dataWithHcc memory);


    function getSvaluesWithHCC(uint256[] memory _pairIndexes)
        external
        view
        returns (dataWithHcc[] memory);


    function getSvalue(uint256 _pairIndex)
        external
        view
        returns (dataWithoutHcc memory);


    function getSvalues(uint256[] memory _pairIndexes)
        external
        view
        returns (dataWithoutHcc[] memory);
  

}
