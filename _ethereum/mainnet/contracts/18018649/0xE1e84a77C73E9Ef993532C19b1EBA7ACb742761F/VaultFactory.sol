// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./Ownable.sol";
import "./Clones.sol";
import "./IVaultFactory.sol";
import "./MintableBurnablePermitableERC20.sol";
import "./Vault.sol";
import "./FeeManager.sol";

contract VaultFactory is IVaultFactory, Ownable {

    /* ========== STATES ========== */

    IERC20 public immutable override collateral;
    IMintableBurnableERC20 public immutable override token;
    address public immutable vaultImplementation;

    mapping(address => address) public override getVault;
    address[] public override allVaults;
    mapping(address => bool) public override isVault;
    mapping(address => bool) public override isVaultManager;

    address public override feeManager;
    address public feeManagerSetter;

    /* ========== CONSTRUCTOR ========== */

    constructor(IERC20 _collateral, string memory _name, string memory _symbol) {
        collateral = _collateral;
        token = new MintableBurnablePermitableERC20(_name, _symbol);
        vaultImplementation = address(new Vault());
        feeManager = address(new FeeManager(this, msg.sender, msg.sender));
        Ownable(feeManager).transferOwnership(msg.sender);
        feeManagerSetter = msg.sender;
    }

    /* ========== VIEWS ========== */

    function vaultsLength() external override view returns (uint) {
        return allVaults.length;
    }

    /* ========== USER FUNCTIONS ========== */

    function createVault(address _owner) external override returns (address) {
        require(getVault[_owner] == address(0), 'exists');
        bytes32 salt = keccak256(abi.encodePacked(_owner));
        address vault = Clones.cloneDeterministic(vaultImplementation, salt);
        IVault(vault).initialize(_owner);
        token.setMinter(vault, true);
        getVault[_owner] = vault;
        allVaults.push(vault);
        isVault[vault] = true;
        emit VaultCreated(_owner, vault, allVaults.length - 1);
        return vault;
    }

    /* ========== ADMIN FUNCTIONS ========== */

    function setVaultManager(address _manager, bool _status) external onlyOwner {
        isVaultManager[_manager] = _status;
        emit SetVaultManager(_manager, _status);
    }

    function setFeeManagerSetter(address _setter) external onlyFeeManagerSetter {
        feeManagerSetter = _setter;
        emit SetFeeManagerSetter(_setter);
    }

    function setFeeManager(address _feeManager) external onlyFeeManagerSetter {
        require(_feeManager != address(0));
        feeManager = _feeManager;
        emit SetFeeManager(_feeManager);
    }

    // Factory should not have any balances, allow rescuing of accidental transfers
    function rescue(address _token, address _recipient) external onlyOwner {
        uint _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_recipient, _balance);
    }


    modifier onlyFeeManagerSetter() {
        require(msg.sender == feeManagerSetter, "!feeManagerSetter");
        _;
    }

    /* ========== EVENTS ========== */

    event VaultCreated(address indexed owner, address indexed vault, uint id);
    event SetVaultManager(address indexed manager, bool status);
    event SetFeeManagerSetter(address indexed setter);
    event SetFeeManager(address indexed manager);
}
