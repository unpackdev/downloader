// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./ITransparentUpgradeableProxy.sol";

contract ChangeAdmin {
    function executeChangeAdmin(
        address proxy,
        address newAdmin
    ) external {
        bytes memory data = abi.encodeWithSelector(
            ITransparentUpgradeableProxy.changeAdmin.selector,
            newAdmin
        );

        (bool success, ) = proxy.delegatecall(data);
        require(success, "changeAdmin failed");
    }
}