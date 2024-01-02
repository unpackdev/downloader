// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "./HexStableCoin.sol";
import "./ERC20WithRolesUpgradeable.sol";
import "./BlacklistableWithRolesUpgradeable.sol";
import "./PausableWithRolesUpgradeable.sol";
import "./AccessControlDefaultAdminRulesUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./IERC165.sol";
import "./IERC5313.sol";
import "./IAccessControlDefaultAdminRules.sol";
import "./IAccessControl.sol";
import "./PausableUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./draft-IERC6093.sol";
import "./IERC20Metadata.sol";
import "./IERC20.sol";
import "./ContextUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./draft-IERC1822.sol";
import "./Initializable.sol";
import "./Context.sol";
import "./RoleConstant.sol";
import "./SafeCast.sol";
import "./Math.sol";
import "./ERC1967Utils.sol";
import "./IBeacon.sol";
import "./Address.sol";
import "./StorageSlot.sol";

contract $HexTrustUSD is HexTrustUSD {
    bytes32 public constant __hh_exposed_bytecode_marker = "hardhat-exposed";

    event return$_grantRole(bool ret0);

    event return$_revokeRole(bool ret0);

    constructor() payable {
    }

    function $_authorizeUpgrade(address newImplementation) external {
        super._authorizeUpgrade(newImplementation);
    }

    function $__ERC20WithRoles_init(string calldata _name,string calldata _symbol,uint8 _decimals) external {
        super.__ERC20WithRoles_init(_name,_symbol,_decimals);
    }

    function $_update(address from,address to,uint256 value) external {
        super._update(from,to,value);
    }

    function $__BlacklistableWithRoles_init() external {
        super.__BlacklistableWithRoles_init();
    }

    function $__PausableWithRoles_init() external {
        super.__PausableWithRoles_init();
    }

    function $__AccessControlDefaultAdminRules_init(address initialDefaultAdmin) external {
        super.__AccessControlDefaultAdminRules_init(initialDefaultAdmin);
    }

    function $__AccessControlDefaultAdminRules_init_unchained(address initialDefaultAdmin) external {
        super.__AccessControlDefaultAdminRules_init_unchained(initialDefaultAdmin);
    }

    function $_grantRole(bytes32 role,address account) external returns (bool ret0) {
        (ret0) = super._grantRole(role,account);
        emit return$_grantRole(ret0);
    }

    function $_revokeRole(bytes32 role,address account) external returns (bool ret0) {
        (ret0) = super._revokeRole(role,account);
        emit return$_revokeRole(ret0);
    }

    function $_setRoleAdmin(bytes32 role,bytes32 adminRole) external {
        super._setRoleAdmin(role,adminRole);
    }

    function $_beginDefaultAdminTransfer(address newAdmin) external {
        super._beginDefaultAdminTransfer(newAdmin);
    }

    function $_cancelDefaultAdminTransfer() external {
        super._cancelDefaultAdminTransfer();
    }

    function $_acceptDefaultAdminTransfer() external {
        super._acceptDefaultAdminTransfer();
    }

    function $__AccessControl_init() external {
        super.__AccessControl_init();
    }

    function $__AccessControl_init_unchained() external {
        super.__AccessControl_init_unchained();
    }

    function $_checkRole(bytes32 role) external view {
        super._checkRole(role);
    }

    function $_checkRole(bytes32 role,address account) external view {
        super._checkRole(role,account);
    }

    function $__ERC165_init() external {
        super.__ERC165_init();
    }

    function $__ERC165_init_unchained() external {
        super.__ERC165_init_unchained();
    }

    function $__Pausable_init() external {
        super.__Pausable_init();
    }

    function $__Pausable_init_unchained() external {
        super.__Pausable_init_unchained();
    }

    function $_requireNotPaused() external view {
        super._requireNotPaused();
    }

    function $_requirePaused() external view {
        super._requirePaused();
    }

    function $_pause() external {
        super._pause();
    }

    function $_unpause() external {
        super._unpause();
    }

    function $__ERC20_init(string calldata name_,string calldata symbol_) external {
        super.__ERC20_init(name_,symbol_);
    }

    function $__ERC20_init_unchained(string calldata name_,string calldata symbol_) external {
        super.__ERC20_init_unchained(name_,symbol_);
    }

    function $_transfer(address from,address to,uint256 value) external {
        super._transfer(from,to,value);
    }

    function $_mint(address account,uint256 value) external {
        super._mint(account,value);
    }

    function $_burn(address account,uint256 value) external {
        super._burn(account,value);
    }

    function $_approve(address owner,address spender,uint256 value) external {
        super._approve(owner,spender,value);
    }

    function $_approve(address owner,address spender,uint256 value,bool emitEvent) external {
        super._approve(owner,spender,value,emitEvent);
    }

    function $_spendAllowance(address owner,address spender,uint256 value) external {
        super._spendAllowance(owner,spender,value);
    }

    function $__Context_init() external {
        super.__Context_init();
    }

    function $__Context_init_unchained() external {
        super.__Context_init_unchained();
    }

    function $_msgSender() external view returns (address ret0) {
        (ret0) = super._msgSender();
    }

    function $_msgData() external view returns (bytes memory ret0) {
        (ret0) = super._msgData();
    }

    function $__UUPSUpgradeable_init() external {
        super.__UUPSUpgradeable_init();
    }

    function $__UUPSUpgradeable_init_unchained() external {
        super.__UUPSUpgradeable_init_unchained();
    }

    function $_checkProxy() external view {
        super._checkProxy();
    }

    function $_checkNotDelegated() external view {
        super._checkNotDelegated();
    }

    function $_checkInitializing() external view {
        super._checkInitializing();
    }

    function $_disableInitializers() external {
        super._disableInitializers();
    }

    function $_getInitializedVersion() external view returns (uint64 ret0) {
        (ret0) = super._getInitializedVersion();
    }

    function $_isInitializing() external view returns (bool ret0) {
        (ret0) = super._isInitializing();
    }

    receive() external payable {}
}
