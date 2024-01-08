//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;


import "./Ownable.sol";

// file storage inside
contract OptionChefData is Ownable {
    mapping (uint => uint) public uIds;
    mapping (uint => uint) public ids;
    mapping (uint => uint8) public optionType;

    function setuid(uint k, uint v) public onlyOwner {
        uIds[k] = v;
    }

    function setid(uint k, uint v) public onlyOwner {
        ids[k] = v;
    }

    function setoptiontype(uint k, uint8 v) public onlyOwner {
        optionType[k] = v;
    }
}
