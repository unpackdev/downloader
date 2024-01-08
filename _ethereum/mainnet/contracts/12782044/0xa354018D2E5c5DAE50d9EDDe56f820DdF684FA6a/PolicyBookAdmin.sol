// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./Math.sol";
import "./SafeMath.sol";
import "./Address.sol";

import "./OwnableUpgradeable.sol";

import "./IPolicyBookAdmin.sol";
import "./IPolicyBookRegistry.sol";
import "./IContractsRegistry.sol";
import "./IPolicyBook.sol";

import "./AbstractDependant.sol";

import "./Upgrader.sol";

contract PolicyBookAdmin is IPolicyBookAdmin, OwnableUpgradeable, AbstractDependant {
    using Math for uint256;
    using SafeMath for uint256;

    IContractsRegistry public contractsRegistry;
    IPolicyBookRegistry public policyBookRegistry;

    Upgrader internal upgrader;
    address private policyBookImplementationAddress;

    event PolicyBookWhitelisted(address policyBookAddress, bool trigger);

    function __PolicyBookAdmin_init(address _policyBookImplementationAddress)
        external
        initializer
    {
        require(_policyBookImplementationAddress != address(0), "PolicyBookAdmin: Zero address");

        __Ownable_init();

        upgrader = new Upgrader();

        policyBookImplementationAddress = _policyBookImplementationAddress;
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        contractsRegistry = _contractsRegistry;

        policyBookRegistry = IPolicyBookRegistry(
            _contractsRegistry.getPolicyBookRegistryContract()
        );
    }

    function injectDependenciesToExistingPolicies(uint256 offset, uint256 limit)
        external
        onlyOwner
    {
        address[] memory _policies = policyBookRegistry.list(offset, limit);
        IContractsRegistry _contractsRegistry = contractsRegistry;

        uint256 to = (offset.add(limit)).min(_policies.length).max(offset);

        for (uint256 i = offset; i < to; i++) {
            AbstractDependant dependant = AbstractDependant(_policies[i]);

            if (dependant.injector() == address(0)) {
                dependant.setInjector(address(this));
            }

            dependant.setDependencies(_contractsRegistry);
        }
    }

    function getUpgrader() external view override returns (address) {
        require(address(upgrader) != address(0), "PolicyBookAdmin: Bad upgrader");

        return address(upgrader);
    }

    function getImplementationOfPolicyBook(address policyBookAddress)
        external
        override
        returns (address)
    {
        require(
            policyBookRegistry.isPolicyBook(policyBookAddress),
            "PolicyBookAdmin: Not a policybook"
        );

        return upgrader.getImplementation(policyBookAddress);
    }

    function getCurrentPolicyBooksImplementation() external view override returns (address) {
        return policyBookImplementationAddress;
    }

    function _setPolicyBookImplementation(address policyBookImpl) internal {
        if (policyBookImplementationAddress != policyBookImpl) {
            policyBookImplementationAddress = policyBookImpl;
        }
    }

    function upgradePolicyBooks(
        address policyBookImpl,
        uint256 offset,
        uint256 limit
    ) external onlyOwner {
        _upgradePolicyBooks(policyBookImpl, offset, limit, "");
    }

    /// @notice can only call functions that have no parameters
    function upgradePolicyBooksAndCall(
        address policyBookImpl,
        uint256 offset,
        uint256 limit,
        string calldata functionSignature
    ) external onlyOwner {
        _upgradePolicyBooks(policyBookImpl, offset, limit, functionSignature);
    }

    function _upgradePolicyBooks(
        address policyBookImpl,
        uint256 offset,
        uint256 limit,
        string memory functionSignature
    ) internal {
        require(policyBookImpl != address(0), "PolicyBookAdmin: Zero address");
        require(Address.isContract(policyBookImpl), "PolicyBookAdmin: Invalid address");

        _setPolicyBookImplementation(policyBookImpl);

        address[] memory _policies = policyBookRegistry.list(offset, limit);

        for (uint256 i = 0; i < _policies.length; i++) {
            if (bytes(functionSignature).length > 0) {
                upgrader.upgradeAndCall(
                    _policies[i],
                    policyBookImpl,
                    abi.encodeWithSignature(functionSignature)
                );
            } else {
                upgrader.upgrade(_policies[i], policyBookImpl);
            }
        }
    }

    /// @notice set whitelisted to true is you want to whitelist or false to blacklist
    function whitelist(address policyBookAddress, bool whitelisted) public onlyOwner {
        require(policyBookRegistry.isPolicyBook(policyBookAddress), "PolicyBookAdmin: Not a PB");

        IPolicyBook(policyBookAddress).whitelist(whitelisted);
        policyBookRegistry.whitelist(policyBookAddress, whitelisted);

        emit PolicyBookWhitelisted(policyBookAddress, whitelisted);
    }

    function whitelistBatch(address[] calldata policyBooksAddresses, bool[] calldata whitelists)
        external
        onlyOwner
    {
        require(
            policyBooksAddresses.length == whitelists.length,
            "PolicyBookAdmin: Length mismatch"
        );

        for (uint256 i = 0; i < policyBooksAddresses.length; i++) {
            whitelist(policyBooksAddresses[i], whitelists[i]);
        }
    }
}
