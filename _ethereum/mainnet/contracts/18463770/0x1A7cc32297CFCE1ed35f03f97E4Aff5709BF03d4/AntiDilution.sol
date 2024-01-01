// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./AccessControl.sol";

import "./IAntiDilution.sol";

contract AntiDilution is IAntiDilution, AccessControl {
    using EnumerableSet for EnumerableSet.UintSet;

    Ruler private _ruler;

    // #################
    // ##   修饰器    ##
    // #################

    modifier onlyMarked(uint256 class) {
        require(isMarked(class), "AD.mf.OM: class not marked");
        _;
    }

    // ################
    // ## Write I/O ##
    // ################

    function addBenchmark(uint256 class, uint price) external onlyAttorney {        

        require (class > 0, "AD.AB: zero class");
        require (price > 0, "AD.AB: zero price");

        _ruler.marks[class].classOfShare = uint16(class);
        _ruler.marks[class].floorPrice = uint32(price);

        _ruler.classes.add(class);
    }

    function removeBenchmark(uint256 class) external onlyAttorney {
        if (_ruler.classes.remove(class)) 
            delete _ruler.marks[class];
    }

    function addObligor(uint256 class, uint256 obligor) external onlyMarked(class) onlyAttorney {
        _ruler.marks[class].obligors.add(obligor);
    }

    function removeObligor(uint256 class, uint256 obligor) external onlyMarked(class) onlyAttorney {
        _ruler.marks[class].obligors.remove(obligor);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function isMarked(uint256 class) public view returns (bool flag) {
        flag = _ruler.classes.contains(class);
    }

    function getClasses() external view returns (uint256[] memory) {
        return _ruler.classes.values();
    }

    function getFloorPriceOfClass(uint256 class)
        public
        view
        returns (uint32 price)
    {
        price = _ruler.marks[class].floorPrice;
    }

    function isObligor(uint256 class, uint256 acct) external view returns (bool flag)
    {
        flag = _ruler.marks[class].obligors.contains(acct);
    }

    function getObligorsOfAD(uint256 class)
        external
        view
        returns (uint256[] memory)
    {
        return _ruler.marks[class].obligors.values();
    }

    function getGiftPaid(address ia, uint256 seqOfDeal, uint256 seqOfShare)
        external
        view
        returns (uint64)
    {
        DealsRepo.Deal memory deal = 
            IInvestmentAgreement(ia).getDeal(seqOfDeal);

        SharesRepo.Share memory share = 
            _gk.getROS().getShare(seqOfShare);

        require (isTriggered(deal, share.head.class), "AD.getGiftPaid: AD not triggered");

        uint32 floorPrice = getFloorPriceOfClass(share.head.class);

        require (share.head.priceOfPaid >= floorPrice, "AD.getGiftPaid: price of target share lower than floor");

        return (share.body.paid * floorPrice / deal.head.priceOfPaid - share.body.paid);
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(DealsRepo.Deal memory deal, uint class) public view returns (bool) {

        if (deal.head.typeOfDeal != uint8(DealsRepo.TypeOfDeal.CapitalIncrease)) 
            return false;

        if (deal.head.priceOfPaid < getFloorPriceOfClass(class)) return true;

        return false;
    }
}
