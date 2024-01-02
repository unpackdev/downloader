// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

interface IGlobalsLike {

    function governor() external view returns (address);

    function isFunctionPaused(bytes4 sig_) external view returns (bool isFunctionPaused_);

    function isInstanceOf(bytes32 key, address account) external view returns (bool);

    function operationalAdmin() external view returns (address operationalAdmin);

    function poolDelegates(address poolDelegate) external view returns (address ownedPoolManager, bool isPoolDelegate);

}
