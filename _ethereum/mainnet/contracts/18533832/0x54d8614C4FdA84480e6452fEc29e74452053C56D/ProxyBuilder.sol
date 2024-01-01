// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./Ownable.sol";
import "./TransparentUpgradeableProxy.sol";
import "./ProxyAdmin.sol";

contract ProxyBuilder is Ownable {
    address public proxyAdmin;
    error AdminAlreadyCreated();

    event Build(address proxy, address implementation);
    event ProxyAdminCreate(address proxyAdmin, address owner);

    constructor(address _proxyAdmin) public {
        proxyAdmin = _proxyAdmin;
    }

    function createNewProxyAdmin(address _owner) external onlyOwner returns (address) {
        if (proxyAdmin != address(0)) {
            revert AdminAlreadyCreated();
        }
        ProxyAdmin proxyAdm = new ProxyAdmin();
        proxyAdmin = address(proxyAdm);
        emit ProxyAdminCreate(proxyAdmin, _owner);

        proxyAdm.transferOwnership(_owner);
        return proxyAdmin;
    }

    function build(
        address _implementation,
        bytes calldata _initDdata
    ) external onlyOwner returns (address) {
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(_implementation, proxyAdmin, _initDdata);
        emit Build(address(proxy), _implementation);
        return address(proxy);
    }
}
