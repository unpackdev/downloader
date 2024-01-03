// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.8;

interface IDefaultHandler {
    function getPairDefaultDex(address _in, address _out) external view returns(address _dex);
    function getPairDefaultData(address _in, address _out) external view returns(bytes memory _data);
}
