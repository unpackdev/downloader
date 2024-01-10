// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

interface IIdleCDO {
    function virtualPrice(address _tranche) external view returns (uint256);
}
