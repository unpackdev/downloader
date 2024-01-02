// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISFTIssuableConcrete {
    function createSlotOnlyDelegate(address txSender_, bytes calldata inputSlotInfo_) external returns (uint256 slot_);
    function mintOnlyDelegate(address txSender_, address currency_, address mintTo_, uint256 slot_, uint256 tokenId_, uint256 amount_) external;
}