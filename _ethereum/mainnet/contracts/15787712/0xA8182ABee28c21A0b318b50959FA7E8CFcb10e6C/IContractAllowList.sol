// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IContractAllowList {
    // --------------------------------------------------------------------------
    // For maintain
    // --------------------------------------------------------------------------
    function addAllowed(address allowd,uint256 level) external;
    
    function removeAllowed(address allowd,uint256 level) external;

    function getAllowedList(uint256 level) external view returns(address[] memory);

    event ChangeAllowList(address target, uint256 level, bool allowd);

    // --------------------------------------------------------------------------
    // For user
    // --------------------------------------------------------------------------
    function isAllowed(address transferer,uint256 level)
        external
        view
        returns (bool);
}
