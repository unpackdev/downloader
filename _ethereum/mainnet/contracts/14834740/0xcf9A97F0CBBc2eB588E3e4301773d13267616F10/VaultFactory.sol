//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./AccessibleCommon.sol";

import "./IVaultFactory.sol";
import "./IProxyAction.sol";

/// @title A factory that creates a Vault
contract VaultFactory is AccessibleCommon, IVaultFactory {

    modifier nonZero(uint256 val) {
        require(val > 0 , 'zero vaule');
        _;
    }

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "VaultFactory: zero");
        _;
    }

    struct ContractInfo {
        address contractAddress;
        string name;
    }

    /// @dev Total number of contracts created
    uint256 public override totalCreatedContracts;

    /// @dev Contract information by index
    mapping(uint256 => ContractInfo) public createdContracts;

    address public override upgradeAdmin;
    address public override vaultLogic;

    address public logEventAddress;

    /// @dev constructor of VaultFactory
    constructor() {
        totalCreatedContracts = 0;

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);
        upgradeAdmin = msg.sender;
    }

    /// @inheritdoc IVaultFactory
    function setLogEventAddress(
        address addr
    )   external override
        onlyOwner
        nonZeroAddress(addr)
    {
        require(addr != logEventAddress, "same addrs");
        logEventAddress = addr;
    }

    /// @inheritdoc IVaultFactory
    function setUpgradeAdmin(
        address addr
    )   external override
        onlyOwner
        nonZeroAddress(addr)
    {
        require(addr != upgradeAdmin, "same addrs");
        upgradeAdmin = addr;
    }

    /// @inheritdoc IVaultFactory
    function upgradeContractLogic(
        address _contract,
        address _logic,
        uint256 _index,
        bool _alive
    )   external override
        onlyOwner
        nonZeroAddress(_contract)
    {
        IProxyAction(_contract).setImplementation2(_logic, _index, _alive);
    }

    /// @inheritdoc IVaultFactory
    function upgradeContractFunction(
        address _contract,
        bytes4[] calldata _selectors,
        address _imp
    )   external override
        onlyOwner
        nonZeroAddress(_contract)
    {
        IProxyAction(_contract).setSelectorImplementations2(_selectors, _imp);
    }


    /// @inheritdoc IVaultFactory
    function setLogic(
        address _logic
    )
        external override
        nonZeroAddress(_logic)
        onlyOwner
    {
        require(vaultLogic != _logic, "already set this version");
        vaultLogic = _logic;
    }

    /// @inheritdoc IVaultFactory
    function lastestCreated() external view override returns (address contractAddress, string memory name){
        if(totalCreatedContracts > 0){
            return (createdContracts[totalCreatedContracts-1].contractAddress, createdContracts[totalCreatedContracts-1].name);
        }else {
            return (address(0), '');
        }
    }

    /// @inheritdoc IVaultFactory
    function getContracts(uint256 _index) external view override returns (address contractAddress, string memory name){
        if(_index < totalCreatedContracts){
            return (createdContracts[_index].contractAddress, createdContracts[_index].name);
        }else {
            return (address(0), '');
        }
    }


}