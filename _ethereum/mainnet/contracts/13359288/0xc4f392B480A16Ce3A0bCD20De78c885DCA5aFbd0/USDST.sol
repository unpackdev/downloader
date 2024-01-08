// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./Claimer.sol";
import "./IUserRegistry.sol";

/**
 * @title USDST
 * @author WALLEXTRUST
 * @dev Implementation of the USDST stablecoin.
 */
contract USDST is ERC20, AccessControl, Claimer {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant WIPER_ROLE = keccak256("WIPER_ROLE");
    bytes32 public constant REGISTRY_MANAGER_ROLE =
        keccak256("REGISTRY_MANAGER_ROLE");

    IUserRegistry public userRegistry;

    event Burn(address indexed burner, uint256 value);
    event Mint(address indexed to, uint256 value);
    event SetUserRegistry(IUserRegistry indexed userRegistry);
    event WipeBlocklistedAccount(address indexed account, uint256 balance);

    /**
     * @dev Sets {name} as "USD Stable Token", {symbol} as "USDST" and {decimals} with 18.
     *      Setup roles {DEFAULT_ADMIN_ROLE}, {MINTER_ROLE}, {WIPER_ROLE} and {REGISTRY_MANAGER_ROLE}.
     *      Mints `initialSupply` tokens and assigns them to the caller.
     */
    constructor(
        uint256 _initialSupply,
        IUserRegistry _userRegistry,
        address _minter,
        address _wiper,
        address _registryManager
    ) public ERC20("USD Stable Token", "USDST") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        require(_minter != address(0), "_minter cannot be zero address");
        _setupRole(MINTER_ROLE, _minter);

        require(_wiper != address(0), "_wiper cannot be zero address");
        _setupRole(WIPER_ROLE, _wiper);

        require(
            _registryManager != address(0),
            "_registryManager cannot be zero address"
        );
        _setupRole(REGISTRY_MANAGER_ROLE, _registryManager);

        _mint(msg.sender, _initialSupply);

        userRegistry = _userRegistry;

        emit SetUserRegistry(_userRegistry);
    }

    /**
     * @dev Moves tokens `_amount` from the caller to `_recipient`.
     * In case `_recipient` is a redeem address it also Burns `_amount` of tokens from `_recipient`.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - {userRegistry.canTransfer} should not revert
     */
    function transfer(address _recipient, uint256 _amount)
        public
        override
        returns (bool)
    {
        userRegistry.canTransfer(_msgSender(), _recipient);

        super.transfer(_recipient, _amount);

        if (userRegistry.isRedeem(_msgSender(), _recipient)) {
            _redeem(_recipient, _amount);
        }

        return true;
    }

    /**
     * @dev Moves tokens `_amount` from `_sender` to `_recipient`.
     * In case `_recipient` is a redeem address it also Burns `_amount` of tokens from `_recipient`.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - {userRegistry.canTransferFrom} should not revert
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        userRegistry.canTransferFrom(_msgSender(), _sender, _recipient);

        super.transferFrom(_sender, _recipient, _amount);

        if (userRegistry.isRedeemFrom(_msgSender(), _sender, _recipient)) {
            _redeem(_recipient, _amount);
        }

        return true;
    }

    /**
     * @dev Destroys `_amount` tokens from `_to`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     * Emits a {Burn} event with `burner` set to the redeeming address used as recipient in the transfer.
     *
     * Requirements
     *
     * - {userRegistry.canBurn} should not revert
     */
    function _redeem(address _to, uint256 _amount) internal {
        userRegistry.canBurn(_to, _amount);

        _burn(_to, _amount);

        emit Burn(_to, _amount);
    }

    /** @dev Creates `_amount` tokens and assigns them to `_to`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     * Emits a {Mint} event with `to` set to the `_to` address.
     *
     * Requirements
     *
     * - the caller should have {MINTER_ROLE} role.
     * - {userRegistry.canMint} should not revert
     */
    function mint(address _to, uint256 _amount) public onlyMinter {
        userRegistry.canMint(_to);

        _mint(_to, _amount);

        emit Mint(_to, _amount);
    }

    /**
     * @dev Destroys the tokens owned by a blocklisted `_account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     * Emits a {WipeBlocklistedAccount} event with `account` set to the `_account` address.
     *
     * Requirements
     *
     * - the caller should have {WIPER_ROLE} role.
     * - {userRegistry.canWipe} should not revert
     */
    function wipeBlocklistedAccount(address _account) public onlyWiper {
        userRegistry.canWipe(_account);

        uint256 accountBlance = balanceOf(_account);

        _burn(_account, accountBlance);

        emit WipeBlocklistedAccount(_account, accountBlance);
    }

    /**
     * @dev Sets the {userRegistry} address
     *
     * Emits a {SetUserRegistry}.
     *
     * Requirements
     *
     * - the caller should have {REGISTRY_MANAGER_ROLE} role.
     */
    function setUserRegistry(IUserRegistry _userRegistry)
        public
        onlyRegistryManager
    {
        userRegistry = _userRegistry;
        emit SetUserRegistry(userRegistry);
    }

    /**
     * @dev Throws if called by any account which does not have MINTER_ROLE.
     */
    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");

        _;
    }

    /**
     * @dev Throws if called by any account which does not have WIPER_ROLE.
     */
    modifier onlyWiper() {
        require(hasRole(WIPER_ROLE, msg.sender), "Caller is not a wiper");

        _;
    }

    /**
     * @dev Throws if called by any account which does not have REGISTRY_MANAGER_ROLE.
     */
    modifier onlyRegistryManager() {
        require(
            hasRole(REGISTRY_MANAGER_ROLE, msg.sender),
            "Caller is not a registry manager"
        );

        _;
    }
}
