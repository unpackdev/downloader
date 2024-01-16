// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "./ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";
import "./Address.sol";
import "./Proxy.sol";
import "./IProxyImplementation.sol";
import "./IProxyFactory.sol";
import "./console.sol";

contract OwnableDelegateProxy is ERC1967UpgradeUpgradeable, Proxy {
    using Address for address;

    function initialize (IProxyImplementation _impl, address _user, address _factory) external initializer {
        _upgradeToAndCall(address(_impl), abi.encodeWithSignature("initialize(address,address)", _user, _factory), true);
    }

    function _implementation() internal view virtual override returns (address) {
        return _getImplementation(); 
    }

    function implementation() external view returns (address) {
        return _implementation();
    }

    /*
    function upgradeTo(address newImplementation) external onlyOwner {
        _upgradeTo(newImplementation);
    }
    */
}
