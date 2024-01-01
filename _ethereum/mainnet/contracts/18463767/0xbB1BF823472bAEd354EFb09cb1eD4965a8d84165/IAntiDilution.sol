// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

// import "./IInvestmentAgreement.sol";

import "./DealsRepo.sol";
// import "./EnumerableSet.sol";
// import "./SharesRepo.sol";

interface IAntiDilution {

    struct Benchmark{
        uint16 classOfShare;
        uint32 floorPrice;
        EnumerableSet.UintSet obligors; 
    }

    struct Ruler {
        // classOfShare => Benchmark
        mapping(uint256 => Benchmark) marks;
        EnumerableSet.UintSet classes;        
    }

    // ################
    // ##   Write    ##
    // ################

    function addBenchmark(uint256 class, uint price) external;

    function removeBenchmark(uint256 class) external;

    function addObligor(uint256 class, uint256 obligor) external;

    function removeObligor(uint256 class, uint256 obligor) external;

    // ############
    // ##  read  ##
    // ############

    function isMarked(uint256 class) external view returns (bool flag);

    function getClasses() external view returns (uint256[] memory);

    function getFloorPriceOfClass(uint256 class) external view
        returns (uint32 price);

    function getObligorsOfAD(uint256 class)
        external view returns (uint256[] memory);

    function isObligor(uint256 class, uint256 acct) 
        external view returns (bool flag);

    function getGiftPaid(address ia, uint256 seqOfDeal, uint256 seqOfShare)
        external view returns (uint64 gift);

    function isTriggered(DealsRepo.Deal memory deal, uint seqOfShare) external view returns (bool);
}
