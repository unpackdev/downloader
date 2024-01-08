// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./TransparentUpgradeableProxy.sol";

import "./AdminableUpgradeable.sol";

import "./IMerkleDistributorCreator.sol";
import "./IMerkleDistributor.sol";

contract MerkleDistributorCreator is AdminableUpgradeable {
    string internal constant DISTRIBUTOR_HASH = "__MerkleDistributor_init(address,bytes32)";

    address public distributorImpl;
    address public proxyAdmin;
    address public defaultAdmin;

    event SetDistributorImpl(address distributorImpl);
    event SetProxyAdmin(address proxyAdmin);
    event SetDefaultAdmin(address defaultAdmin);

    event DistributorCreated(address distributor, address token, bytes32 merkleRoot);

    function __MerkleDistributorCreator_init(address _distributorImpl, address _proxyAdmin, address _defaultAdmin) public initializer {
        __Adminable_init();

        distributorImpl = _distributorImpl;
        proxyAdmin = _proxyAdmin;
        defaultAdmin = _defaultAdmin;
    }


    // ** ONLY OWNER OR ADMIN functions **

    function createDistributor(address _token, bytes32 _merkleRoot) public onlyOwnerOrAdmin returns (address) {
        require(distributorImpl != address(0), "createDistributor: distributorImpl has not been set");

        bytes memory data = abi.encodeWithSignature(
            DISTRIBUTOR_HASH,
            _token,
            _merkleRoot
        );
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(distributorImpl, proxyAdmin, data);

        // set admin permission to msg.sender
        if (isAdmin[msg.sender]) {
            IMerkleDistributor(address(proxy)).setAdminPermission(msg.sender, true);
        }

        // set admin permission to defaultAdmin
        if (defaultAdmin != address(0) && defaultAdmin != msg.sender) {
            IMerkleDistributor(address(proxy)).setAdminPermission(defaultAdmin, true);
        }

        // transfer ownership to owner
        IMerkleDistributor(address(proxy)).transferOwnership(owner());

        emit DistributorCreated(address(proxy), _token, _merkleRoot);

        return address(proxy);
    }


    // ** ONLY OWNER functions **

    function setDistributorImpl(address _distributorImpl) external onlyOwner {
        distributorImpl = _distributorImpl;

        emit SetDistributorImpl(_distributorImpl);
    }

    function setProxyAdmin(address _proxyAdmin) external onlyOwner {
        proxyAdmin = _proxyAdmin;

        emit SetProxyAdmin(_proxyAdmin);
    }

    function setDefaultAdmin(address _defaultAdmin) external onlyOwner {
        defaultAdmin = _defaultAdmin;

        emit SetDefaultAdmin(_defaultAdmin);
    }
}
