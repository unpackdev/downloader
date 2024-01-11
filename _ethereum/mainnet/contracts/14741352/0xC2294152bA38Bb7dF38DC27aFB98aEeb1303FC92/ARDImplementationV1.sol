// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";

/**
 * @title ARDImplementation
 * @dev this contract is a Pausable ERC20 token with Burn and Mint
 * controlled by a SupplyController. By implementing ARDImplementation
 * this contract also includes external methods for setting
 * a new implementation contract for the Proxy.
 * NOTE: The storage defined here will actually be held in the Proxy
 * contract and all calls to this contract should be made through
 * the proxy, including admin actions done as owner or supplyController.
 * Any call to transfer against this contract should fail
 * with insufficient funds since no tokens will be issued there.
 */
contract ARDImplementationV1 is ERC20Upgradeable, 
                                OwnableUpgradeable, 
                                AccessControlUpgradeable,
                                PausableUpgradeable, 
                                ReentrancyGuardUpgradeable {

    /*****************************************************************
    ** MATH                                                         **
    ******************************************************************/
    using SafeMath for uint256;

    /*****************************************************************
    ** ROLES                                                        **
    ******************************************************************/
    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant ASSET_PROTECTION_ROLE = keccak256("ASSET_PROTECTION_ROLE");
    bytes32 public constant SUPPLY_CONTROLLER_ROLE = keccak256("SUPPLY_CONTROLLER_ROLE");

    /*****************************************************************
    ** MODIFIERS                                                    **
    ******************************************************************/
    modifier onlySuperAdminRole() {
        require(hasRole(SUPER_ADMIN_ROLE, _msgSender()), "only super admin role");
        _;
    }

    modifier onlyAssetProtectionRole() {
        require(hasRole(ASSET_PROTECTION_ROLE, _msgSender()), "only asset protection role");
        _;
    }

    modifier onlySupplyController() {
        require(hasRole(SUPPLY_CONTROLLER_ROLE, _msgSender()), "only supply controller role");
        _;
    }

    modifier onlyMinterRole() {
        require(hasRole(MINTER_ROLE, _msgSender()), "only minter role");
        _;
    }

    modifier onlyBurnerRole() {
        require(hasRole(BURNER_ROLE, _msgSender()), "only burner role");
        _;
    }

    modifier notPaused() {
        require(!paused(), "is paused");
        _;
    }
    /*****************************************************************
    ** EVENTS                                                       **
    ******************************************************************/
    // ASSET PROTECTION EVENTS
    event AddressFrozen(address indexed addr);
    event AddressUnfrozen(address indexed addr);
    event FrozenAddressWiped(address indexed addr);
    event AssetProtectionRoleSet (
        address indexed oldAssetProtectionRole,
        address indexed newAssetProtectionRole
    );

    // SUPPLY CONTROL EVENTS
    event SupplyIncreased(address indexed to, uint256 value);
    event SupplyDecreased(address indexed from, uint256 value);
    event SupplyControllerSet(
        address indexed oldSupplyController,
        address indexed newSupplyController
    );

    /*****************************************************************
    ** DATA                                                         **
    ******************************************************************/

    uint8 internal _decimals;

    address internal _curSuperadmin;

    // ASSET PROTECTION DATA
    mapping(address => bool) internal frozen;

    /*****************************************************************
    ** FUNCTIONALITY                                                **
    ******************************************************************/
    /**
     * @dev sets 0 initials tokens, the owner, and the supplyController.
     * this serves as the constructor for the proxy but compiles to the
     * memory model of the Implementation contract.
     */
    //uint256 private _totalSupply;
    function _initialize(string memory name_, string memory symbol_, address newowner_) internal {
        __Ownable_init();
        __ERC20_init(name_, symbol_);

        // it lets deployer set other address as owner rather than sender. It helps to make contract owned by multisig wallet 
        address owner_ =  newowner_==address(0) ?  _msgSender() : newowner_;
        
        //set super admin role for manage admins
        _setRoleAdmin(SUPER_ADMIN_ROLE, SUPER_ADMIN_ROLE);
        _curSuperadmin = owner_;
        //set default admin role for all roles
        _setRoleAdmin(ADMIN_ROLE, SUPER_ADMIN_ROLE);
        //setup other roles
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(BURNER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ASSET_PROTECTION_ROLE, ADMIN_ROLE);
        _setRoleAdmin(SUPPLY_CONTROLLER_ROLE, ADMIN_ROLE);

        // Grant the contract deployer the default super admin role
        // super admin is able to grant and revoke admin roles
        _setupRole(SUPER_ADMIN_ROLE, owner_);
        // Grant the contract deployer all other roles by default
        _grantAllRoles(owner_);

        if (owner_!=_msgSender()) {
            _transferOwnership(owner_);
        }
        // set the number of decimals to 6
        _decimals = 6;
    }

    /**
    The number of decimals
    */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
    The protocol implementation version
    */
    function protocolVersion() public pure returns (bytes32) {
        return "1.0";
    }
    ///////////////////////////////////////////////////////////////////////
    // OWNERSHIP                                                         //
    ///////////////////////////////////////////////////////////////////////
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * it transfers all the roles as well
     * Can only be called by the current owner.
     */
    function transferOwnershipAndRoles(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _revokeAllRoles(owner());
        _grantAllRoles(newOwner);
        if (_curSuperadmin==owner()) {
            transferSupeAdminTo(newOwner);
        }
        _transferOwnership(newOwner);
    }
    ///////////////////////////////////////////////////////////////////////
    // BEFORE/AFTER TOKEN TRANSFER                                       //
    ///////////////////////////////////////////////////////////////////////

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override virtual {
        // check to not to be paused
        require(!paused(),"is paused");
        // amount has to be more than 0
        require(amount>0, "zero amount");
        // check the addresses no to be frozen
        require(!frozen[_msgSender()], "caller is frozen");
        require(!frozen[from] || from==address(0), "address from is frozen");
        require(!frozen[to] || to==address(0), "address to is frozen");
        // check the roles in case of minting or burning
        // if (from == address(0)) {       // is minting
        //     require(hasRole(MINTER_ROLE,_msgSender()) || hasRole(SUPPLY_CONTROLLER_ROLE,_msgSender()), "Caller is not a minter");
        // } else if (to == address(0)) {  // is burning
        //     require(hasRole(BURNER_ROLE,_msgSender()) || hasRole(SUPPLY_CONTROLLER_ROLE,_msgSender()), "Caller is not a burner");
        // }
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override virtual {

        require(amount>0,"zero amount");
        if (from == address(0)) {       // is minted
            emit SupplyIncreased( to, amount);
        } else if (to == address(0)) {  // is burned
            emit SupplyDecreased( from, amount);
        }
        
    }

    ///////////////////////////////////////////////////////////////////////
    // APPROVE                                                           //
    ///////////////////////////////////////////////////////////////////////
    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        require(!paused(),"is paused");
        require(!frozen[_msgSender()], "caller is frozen");
        require(!frozen[spender], "address spender is frozen");
        _approve(_msgSender(), spender, amount);
        return true;
    }

    ///////////////////////////////////////////////////////////////////////
    // PAUSE / UNPAUSE                                                   //
    ///////////////////////////////////////////////////////////////////////
    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public onlySuperAdminRole {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public onlySuperAdminRole {
        _unpause();
    }

    ///////////////////////////////////////////////////////////////////////
    // ROLE MANAGEMENT                                                   //
    ///////////////////////////////////////////////////////////////////////
    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     * - contract not to be paused
     * - account can't be zero address 
     */
    function grantRole(bytes32 role, address account) public override notPaused onlyRole(getRoleAdmin(role)) {
        require(account!=address(0),"zero account");
        require(role!=SUPER_ADMIN_ROLE,"invalid role");
        _grantRole(role, account);
    }

    /**
     * @dev Grants all roles to `account`.
     *
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     * - contract not to be paused
     * - account can't be zero address 
     */
    function _grantAllRoles(address account) internal {
        require(account!=address(0),"zero account");
        _grantRole(ADMIN_ROLE, account);
        _grantRole(MINTER_ROLE, account);
        _grantRole(BURNER_ROLE, account);
        _grantRole(ASSET_PROTECTION_ROLE, account);
        _grantRole(SUPPLY_CONTROLLER_ROLE, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     * - contract not to be paused
     * - account can't be zero address 
     */
    function revokeRole(bytes32 role, address account) public override notPaused onlyRole(getRoleAdmin(role)) {
        require(account!=address(0),"zero account");
        require(role!=SUPER_ADMIN_ROLE,"invalid role");
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes all roles from `account`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     * - contract not to be paused
     * - account can't be zero address 
     */
    function _revokeAllRoles(address account) internal {
        require(account!=address(0),"zero account");
        _revokeRole(ADMIN_ROLE, account);
        _revokeRole(MINTER_ROLE, account);
        _revokeRole(BURNER_ROLE, account);
        _revokeRole(ASSET_PROTECTION_ROLE, account);
        _revokeRole(SUPPLY_CONTROLLER_ROLE, account);
    }

    /**
     * @dev transfer the Super Admin role to specific account. Only one account can be super admin
     * @param _addr The address to assign super admin role.
     */
    function transferSupeAdminTo(address _addr) public notPaused onlyOwner {
        _revokeRole(SUPER_ADMIN_ROLE, _curSuperadmin);
        _grantRole(SUPER_ADMIN_ROLE, _addr);
        _curSuperadmin=_addr;
    }
    function superAdmin() public view returns (address) {
        return _curSuperadmin;
    }

    /**
     * @dev set/revoke the Role's Admin role to specific account
     * @param _addr The address to assign minter role.
     */
    function setAdminRole(address _addr) public {
        grantRole(ADMIN_ROLE, _addr);
    }
    function revokeAdminRole(address _addr) public {
        revokeRole(ADMIN_ROLE, _addr);
    }
    function isAdmin(address _addr) public view returns (bool) {
        return hasRole(ADMIN_ROLE, _addr);
    }

    /**
     * @dev set/revoke the Minter role to specific account
     * @param _addr The address to assign minter role.
     */
    function setMinterRole(address _addr) public {
        grantRole(MINTER_ROLE, _addr);
    }
    function revokeMinterRole(address _addr) public {
        revokeRole(MINTER_ROLE, _addr);
    }
    function isMinter(address _addr) public view returns (bool) {
        return hasRole(MINTER_ROLE, _addr);
    }

    /**
     * @dev set/revoke the Burner role to specific account
     * @param _addr The address to assign burner role.
     */
    function setBurnerRole(address _addr) public {
        grantRole(BURNER_ROLE, _addr);
    }
    function revokeBurnerRole(address _addr) public {
        revokeRole(BURNER_ROLE, _addr);
    }
    function isBurner(address _addr) public view returns (bool) {
        return hasRole(BURNER_ROLE, _addr);
    }

    /**
     * @dev set/revoke the Asset Protection role to specific account
     * @param _addr The address to assign asset protection role.
     */
    function setAssetProtectionRole(address _addr) public {
        grantRole(ASSET_PROTECTION_ROLE, _addr);
    }
    function revokeAssetProtectionRole(address _addr) public {
        revokeRole(ASSET_PROTECTION_ROLE, _addr);
    }
    function isAssetProtection(address _addr) public view returns (bool) {
        return hasRole(ASSET_PROTECTION_ROLE, _addr);
    }

    /**
     * @dev set/revoke the Supply Controller role to specific account
     * @param _addr The address to assign supply controller role.
     */
    function setSupplyControllerRole(address _addr) public {
        grantRole(SUPPLY_CONTROLLER_ROLE, _addr);
    }
    function revokeSupplyControllerRole(address _addr) public {
        revokeRole(SUPPLY_CONTROLLER_ROLE, _addr);
    }
    function isSupplyController(address _addr) public view returns (bool) {
        return hasRole(SUPPLY_CONTROLLER_ROLE, _addr);
    }

    ///////////////////////////////////////////////////////////////////////
    // ASSET PROTECTION FUNCTIONALITY                                    //
    ///////////////////////////////////////////////////////////////////////
    /**
     * @dev Freezes an address balance from being transferred.
     * @param _addr The new address to freeze.
     */
    function freeze(address _addr) public notPaused onlyAssetProtectionRole {
        require(_addr!=owner(), "can't freeze owner");
        require(_addr!=_msgSender(), "can't freeze itself");
        require(!frozen[_addr], "address already frozen");
        //TODO: shouldn't be able to freeze admin,minter,burner,asset protection,supply controller roles
        frozen[_addr] = true;
        emit AddressFrozen(_addr);
    }

    /**
     * @dev Unfreezes an address balance allowing transfer.
     * @param _addr The new address to unfreeze.
     */
    function unfreeze(address _addr) public notPaused onlyAssetProtectionRole {
        require(frozen[_addr], "address already unfrozen");
        frozen[_addr] = false;
        emit AddressUnfrozen(_addr);
    }

    /**
     * @dev Wipes the balance of a frozen address, burning the tokens
     * and setting the approval to zero.
     * @param _addr The new frozen address to wipe.
     */
    function wipeFrozenAddress(address _addr) public notPaused onlyAssetProtectionRole {
        require(frozen[_addr], "address is not frozen");
        uint256 _balance = balanceOf(_addr);
        frozen[_addr] = false;
        _burn(_addr,_balance);
        frozen[_addr] = true;
        emit FrozenAddressWiped(_addr);
    }

    /**
    * @dev Gets whether the address is currently frozen.
    * @param _addr The address to check if frozen.
    * @return A bool representing whether the given address is frozen.
    */
    function isFrozen(address _addr) public view returns (bool) {
        return frozen[_addr];
    }


    ///////////////////////////////////////////////////////////////////////
    // MINTING / BURNING                                                 //
    ///////////////////////////////////////////////////////////////////////

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function mint(address account, uint256 amount) public onlyMinterRole {
        _mint(account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function burn(address account, uint256 amount) public onlyBurnerRole {
        _burn(account, amount);
    }

    ///////////////////////////////////////////////////////////////////////
    // SUPPLY CONTROL                                                    //
    ///////////////////////////////////////////////////////////////////////
    /**
     * @dev Increases the total supply by minting the specified number of tokens to the supply controller account.
     * @param _value The number of tokens to add.
     * @return A boolean that indicates if the operation was successful.
     */
    function increaseSupply(uint256 _value) public onlySupplyController returns (bool) {
        _mint(_msgSender(), _value);
        return true;
    }

    /**
     * @dev Decreases the total supply by burning the specified number of tokens from the supply controller account.
     * @param _value The number of tokens to remove.
     * @return A boolean that indicates if the operation was successful.
     */
    function decreaseSupply(uint256 _value) public onlySupplyController returns (bool) {
        require(_value <= balanceOf(_msgSender()), "not enough supply");
        _burn(_msgSender(), _value);
        return true;
    }

    // storage gap for adding new states in upgrades 
    uint256[50] private __stgap0;
}
