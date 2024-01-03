// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.8;

interface IGovernanceSwap {
    function isGovernanceSwap() external pure returns (bool);
    function addDexHandler(address _dex, address _handler) external /*onlyGovernance*/ returns (bool);
    function removeDexHandler(address _dex) external /*onlyGovernance*/ returns (bool);
    function setPairDefaults(address _in, address _out, address _dex, bytes calldata _data) external /*onlyGovernance*/ returns (bool);
    function getPairDefaultDex(address _in, address _out) external returns (address _dex);
    function getPairDefaultDexHandler(address _in, address _out) external returns (address _handler);
    function getDexHandler(address _dex) external returns (address _handler);
    function getPairDefaultData(address _in, address _out) external returns (bytes memory _data);
}