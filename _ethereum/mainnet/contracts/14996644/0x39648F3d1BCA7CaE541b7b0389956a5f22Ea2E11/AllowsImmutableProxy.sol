// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./Ownable.sol";
import "./ProxyRegistry.sol";
import "./IAllowsProxy.sol";

/**
 *
 * ██████╗░██╗████████╗  ██████╗░██████╗░██╗███████╗███████╗░██████╗
 * ██╔══██╗██║╚══██╔══╝  ██╔══██╗██╔══██╗██║╚════██║██╔════╝██╔════╝
 * ██████╔╝██║░░░██║░░░  ██████╔╝██████╔╝██║░░███╔═╝█████╗░░╚█████╗░
 * ██╔═══╝░██║░░░██║░░░  ██╔═══╝░██╔══██╗██║██╔══╝░░██╔══╝░░░╚═══██╗
 * ██║░░░░░██║░░░██║░░░  ██║░░░░░██║░░██║██║███████╗███████╗██████╔╝
 * ╚═╝░░░░░╚═╝░░░╚═╝░░░  ╚═╝░░░░░╚═╝░░╚═╝╚═╝╚══════╝╚══════╝╚═════╝░
 *
 */

contract AllowsImmutableProxy is IAllowsProxy, Ownable {
    address internal immutable _proxyAddress;
    bool internal _isProxyActive;

    constructor(address proxyAddress_, bool isProxyActive_) {
        _proxyAddress = proxyAddress_;
        _isProxyActive = isProxyActive_;
    }

    function setIsProxyActive(bool isProxyActive_) external onlyOwner {
        _isProxyActive = isProxyActive_;
    }

    function proxyAddress() public view returns (address) {
        return _proxyAddress;
    }

    function isProxyActive() public view returns (bool) {
        return _isProxyActive;
    }

    function isApprovedForProxy(address owner_, address operator_)
        public
        view
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyAddress);
        return
            _isProxyActive &&
            address(proxyRegistry.proxies(owner_)) == operator_;
    }
}
