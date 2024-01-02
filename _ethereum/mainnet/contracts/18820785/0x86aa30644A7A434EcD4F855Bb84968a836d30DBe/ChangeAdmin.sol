// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
//import "./ITransparentUpgradeableProxy.sol";

contract ChangeAdmin {
    function executeChangeAdmin(
        address proxy,
        address newAdmin
    ) external {
        (bool success, ) = proxy.delegatecall(
            abi.encodeWithSelector(0x8f283970, newAdmin)
        );
        require(success, "changeAdmin failed");
    }
}
