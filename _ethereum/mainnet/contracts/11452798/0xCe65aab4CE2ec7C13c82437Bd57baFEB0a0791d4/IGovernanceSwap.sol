// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.8;

interface IGovernanceSwap {
    function isGovernanceSwap() external pure returns (bool);

    function setDefaultHandler(address _defaultHandler) external /*onlyGovernance*/;
    function addDexHandler(address _dex, address _handler) external /*onlyGovernance*/;
    function removeDexHandler(address _dex) external /*onlyGovernance*/;
    function setPairDefaults(address _in, address _out, address _dex, bytes calldata _data) external /*onlyGovernance*/;

    function getPairDefaultDex(address _in, address _out, bool _strict) external view returns (address _dex);
    function getPairDefaultDexHandler(address _in, address _out, bool _strict) external view returns (address _handler);
    function getDexHandler(address _dex, bool _strict) external view returns (address _handler);
    function getPairDefaultData(address _in, address _out, bool _strict) external view returns (bytes memory _data);
}
