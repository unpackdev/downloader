// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./VaultProxy.sol";
import "./BaseVault.sol";
import "./Ownable.sol";

/**
 * @title Factory
 * @notice Contract to deploy Proxy Vaults.
 */
contract Factory is Ownable {

    // deployed instance of the base vault.
    address private baseVaultImpl;

    // Emitted for every new deployment of a proxy vault contract.
    event NewVaultDeployed(address indexed newProxy, address indexed owner, address[] modules, bytes[] initData);

    // Emitted when base vault implementation address is changed.
    event BaseVaultImplChanged(address indexed _newBaseVaultImpl);

    /**
     * @param _baseVaultImpl - deployed instance of the implementation base vault.
     */
    constructor(address _baseVaultImpl) {
        require(
            _baseVaultImpl != address(0),
            "F: Invalid address"
        );
        baseVaultImpl = _baseVaultImpl;
    }

    /**
     * Function to be executed by Kresus deployer to deploy a new instance of {Proxy}.
     * @param _owner - address of the owner of base vault contract.
     * @param _modules - Modules to be authorized to make changes to the state of vault contract.
     */
    function deployVault(
        address _owner,
        address[] calldata _modules,
        bytes[] calldata _initData
    ) 
        external
        onlyOwner()
    {
        address payable newProxy = payable(new VaultProxy(baseVaultImpl));
        BaseVault(newProxy).init(_owner, _modules, _initData);
        emit NewVaultDeployed(newProxy, _owner, _modules, _initData);
    }

    /**
     * Function to change base vault implrmrntation address.
     * @param _newBaseVaultImpl - implementation address of new base vault.
     */
    function changeBaseVaultImpl(address _newBaseVaultImpl) external onlyOwner() {
        baseVaultImpl =  _newBaseVaultImpl;
        emit BaseVaultImplChanged(_newBaseVaultImpl);
    }

    /**
     * Function to get current base vault implementation contract address.
     */
    function getBaseVaultImpl() external view returns(address) {
        return baseVaultImpl;
    }
}
