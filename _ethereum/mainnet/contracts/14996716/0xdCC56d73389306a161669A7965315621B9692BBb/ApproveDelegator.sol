// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ProxyRegistry.sol";

contract ApproveDelegator {
    address private _proxyRegistryAddress;
    address private _allOperatorAddress;
    bool private inited = false;

    function _initializeApproveDelegator() internal {
        require(!inited, "ApproveDelegator is already inited"); // solhint-disable reason-string
        address proxyRegistryAddress = address(0);
        address allOperatorAddress = address(0);
        uint256 chainId;

        assembly {
            chainId := chainid()
            switch chainId
            case 1 {
                // mainnet
                proxyRegistryAddress := 0xa5409ec958c83c3f309868babaca7c86dcb077c1
            }
            case 137 {
                // polygon
                allOperatorAddress := 0x58807baD0B376efc12F5AD86aAc70E78ed67deaE
            }
            case 4 {
                // rinkeby
                // https://github.com/ProjectOpenSea/opensea-creatures/blob/master/migrations/2_deploy_contracts.js#L29
                proxyRegistryAddress := 0x1E525EEAF261cA41b809884CBDE9DD9E1619573A
            }
            case 80001 {
                // mumbai
                allOperatorAddress := 0xff7Ca10aF37178BdD056628eF42fD7F799fAc77c
            }
            case 1337 {
                proxyRegistryAddress := 0xE1a2bbc877b29ADBC56D2659DBcb0ae14ee62071
            }
        }

        _proxyRegistryAddress = proxyRegistryAddress;
        _allOperatorAddress = allOperatorAddress;
        inited = true;
    }

    function _setApproveDelegator(address proxyRegistryAddress, address allOperatorAddress) internal {
        _proxyRegistryAddress = proxyRegistryAddress;
        _allOperatorAddress = allOperatorAddress;
    }

    function _isApprovedForAllByDelegator(address owner, address operator) internal view returns (bool) {
        if (_proxyRegistryAddress != address(0)) {
            if (address(ProxyRegistry(_proxyRegistryAddress).proxies(owner)) == operator) {
                return true;
            }
        } else if (_allOperatorAddress != address(0)) {
            if (_allOperatorAddress == operator) {
                return true;
            }
        }
        
        return false;
    }
}
