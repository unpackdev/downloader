// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./Clones.sol";

import "./IAuthorizationManager.sol";
import "./AuthenticatedProxy.sol";

contract AuthorizationManager is Ownable, IAuthorizationManager {
    using Clones for address;

    mapping(address => address) public override proxies;
    address public immutable override authorizedAddress;
    address public immutable WETH;
    bool public override revoked;
    address public immutable proxyImplemention;

    event Revoked();

    constructor(address _WETH, address _authorizedAddress) {
        WETH = _WETH;
        authorizedAddress = _authorizedAddress;
        proxyImplemention = address(new AuthenticatedProxy());
    }

    function revoke() external override onlyOwner {
        revoked = true;
        emit Revoked();
    }

    function registerProxy() external override returns (address) {
        return _registerProxyFor(msg.sender);
    }

    function _registerProxyFor(address user) internal returns (address) {
        require(address(proxies[user]) == address(0), "Authorization: user already has a proxy");
        address proxy = proxyImplemention.clone();
        IAuthenticatedProxy(proxy).initialize(user, address(this), WETH);
        proxies[user] = proxy;
        return proxy;
    }
}
