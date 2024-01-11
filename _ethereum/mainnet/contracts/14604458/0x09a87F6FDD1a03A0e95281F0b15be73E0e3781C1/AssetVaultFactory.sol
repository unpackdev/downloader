// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "./Clones.sol";
import "./Context.sol";
import "./AssetVault.sol";
import "./IAssetVault.sol";

/// @author Philippe Dumonet
contract AssetVaultFactory is Context {
    address public immutable vaultImplementation;

    event NewVaultCreated(
        address indexed newVault,
        address indexed _initialOwner,
        bytes32 indexed guardiansMerkleRoot
    );

    constructor() {
        vaultImplementation = address(new AssetVault());
    }

    function createNewVault(bytes32 _guardiansMerkleRoot) external returns (address) {
        return createNewVaultFor(_msgSender(), _guardiansMerkleRoot);
    }

    function createNewVaultFor(address _initialOwner, bytes32 _guardiansMerkleRoot)
        public
        returns (address)
    {
        IAssetVault newVault = IAssetVault(Clones.clone(vaultImplementation));
        newVault.initialize(_initialOwner, _guardiansMerkleRoot);
        emit NewVaultCreated(address(newVault), _initialOwner, _guardiansMerkleRoot);
        return address(newVault);
    }
}
