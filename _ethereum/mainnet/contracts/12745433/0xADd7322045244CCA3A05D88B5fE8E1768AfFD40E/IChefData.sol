//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface IOptionChefData {
    function uIds(uint k) external view returns (uint);
    function ids(uint k) external view returns (uint);
    function optionType(uint k) external view returns (uint8);

    function setuid(uint k, uint v) external;
    function setid(uint k, uint v) external;
    function setoptiontype(uint k, uint8 v) external;
    function transferOwnership(address newOwner) external;
}
