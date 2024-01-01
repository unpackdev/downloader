// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./LinksRepo.sol";
// import "./IRegisterOfAgreements.sol";

interface IAlongs {

    // ################
    // ##   Write    ##
    // ################

    function addDragger(bytes32 rule, uint256 dragger) external;

    function removeDragger(uint256 dragger) external;

    function addFollower(uint256 dragger, uint256 follower) external;

    function removeFollower(uint256 dragger, uint256 follower) external;


    // ###############
    // ##  查询接口  ##
    // ###############

    function isDragger(uint256 dragger) external view returns (bool);

    function getLinkRule(uint256 dragger) external view 
        returns (RulesParser.LinkRule memory);

    function isFollower(uint256 dragger, uint256 follower)
        external view returns (bool);

    function getDraggers() external view returns (uint256[] memory);

    function getFollowers(uint256 dragger) external view returns (uint256[] memory);

    function priceCheck(
        DealsRepo.Deal memory deal
    ) external view returns (bool);

    function isTriggered(address ia, DealsRepo.Deal memory deal) external view returns (bool);
}
