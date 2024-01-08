// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* INHERITANCE IMPORTS */

import "./IXenoERC20.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ManagerRole.sol";
import "./Freezable.sol";
import "./Pausable.sol";
import "./Recoverable.sol";
import "./ERC20.sol";

contract XenoERC20 is IXenoERC20, Initializable, UUPSUpgradeable, ManagerRole, Freezable, Pausable, Recoverable, ERC20 {

    /* INITIALIZE METHOD */

    /**
     * @dev initalize() replaces the contract constructor in the UUPS proxy upgrade pattern.
     * It is gated by the initializer modifier to ensure that it can only be run once.
     * All inherited contracts must also replace constructors with initialize methods to be called here.
     */
    function initialize(string calldata setName, string calldata setSymbol, uint256 initialSupply ) external initializer {
        // set initializer as manager
        _initializeManagerRole(msg.sender);
        
        // set ERC20 name, symbol, decimals, and initial supply
        _initalizeERC20(setName, setSymbol, 18, initialSupply);

        // set pause state to false by default
        _initializePausable();
    }

    /* ManagerRoleInterface METHODS */

    /**
     * @dev Returns true if `account` holds a manager role, returns false otherwise.
     */
    function isManager(address account) external view override returns (bool) {
        return _isManager(account);
    }

    /**
     * @dev Give the manager role to `account`.
     *
     * Requirements;
     *
     * - caller must be a manager
     * - `account` is not already a manager
     *
     * Emits an {ManagerAdded} event.
     */
    function addManager(address account) external override {
       _addManager(account);
    }

    /**
     * @dev Renounce the manager role for the caller.
     *
     * Requirements;
     *
     * - caller must be a manager
     * - caller must NOT be the ONLY manager
     *
     * Emits an {ManagerRemoved} event.
     */
    function renounceManager() external override {
        _renounceManager();
    }

    /* IERC20Metadata METHODS */

    /**
     * @dev Returns the name of the token.
     */
    function name() external view override returns (string memory) {
        return _name();
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view override returns (string memory) {
        return _symbol();
    }

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view override returns (uint8) {
        return _decimals();
    }

    /* IERC20 METHODS */

   /**
     * @dev Returns the the total amount of tokens that exist.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply();
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view override returns (uint256) {
        return _balanceOf(account);
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowance(owner, spender);
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     *
     * Requirements:
     * - contract is upaused
     * - caller is not frozen
     * - `recipient` is not frozen
     * - transfer rules apply (i.e. adequate balance, non-zero addresses)
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        /* check if paused */
        require(
            !_paused(),
            "XenoERC20.transfer: PAUSED"
        );
        /* check if caller frozen */
        require(
            !_frozen(_msgSender()),
            "XenoERC20.transfer: CALLER_FROZEN"
        );
        /* check if recipient frozen */
        require(
            !_frozen(recipient),
            "XenoERC20.transfer: RECIPIENT_FROZEN"
        );
        return _transfer(_msgSender(), recipient, amount);
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Requirements:
     * - contract is upaused
     * - caller is not frozen
     * - `sender` is not forzen
     * - `recipient` is not frozen
     * - transferFrom rules apply (i.e. adequate allowance and balance, non-zero addresses)
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        /* check if paused */
        require(
            !_paused(),
            "XenoERC20.transferFrom: PAUSED"
        );
        /* check if caller frozen */
        require(
            !_frozen(_msgSender()),
            "XenoERC20.transferFrom: CALLER_FROZEN"
        );
        /* check if sender frozen */
        require(
            !_frozen(sender),
            "XenoERC20.transferFrom: SENDER_FROZEN"
        );
        /* check if recipient frozen */
        require(
            !_frozen(recipient),
            "XenoERC20.transferFrom: RECIPIENT_FROZEN"
        );
        return _transferFrom(sender, recipient, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Requirements:
     * - contract is upaused
     * - caller is not frozen
     * - `spender` is not frozen
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        /* check if paused */
        require(
            !_paused(),
            "XenoERC20.approve: PAUSED"
        );
        /* check if caller frozen */
        require(
            !_frozen(_msgSender()),
            "XenoERC20.approve: CALLER_FROZEN"
        );
        /* check if spender frozen */
        require(
            !_frozen(spender),
            "XenoERC20.approve: SPENDER_FROZEN"
        );
        return _approve(spender, amount);
    }

    /* ERC20AllowanceInterface METHODS */

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - contract is upaused
     * - caller is not frozen
     * - `spender` is not frozen
     *
     * Emits an {Approval} event
     */
    function increaseAllowance(address spender, uint256 addedValue) external override returns (bool) {
        /* check if paused */
        require(
            !_paused(),
            "XenoERC20.increaseAllowance: PAUSED"
        );
        /* check if caller frozen */
        require(
            !_frozen(_msgSender()),
            "XenoERC20.increaseAllowance: CALLER_FROZEN"
        );
        /* check if spender frozen */
        require(
            !_frozen(spender),
            "XenoERC20.increaseAllowance: SPENDER_FROZEN"
        );
        return _increaseAllowance(spender, addedValue);
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     * - contract is upaused
     * - caller is not frozen
     * - `spender` is not frozen
     *
     * Emits an {Approval} event
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external override returns (bool) {
        /* check if paused */
        require(
            !_paused(),
            "XenoERC20.decreaseAllowance: PAUSED"
        );
        /* check if caller frozen */
        require(
            !_frozen(_msgSender()),
            "XenoERC20.decreaseAllowance: CALLER_FROZEN"
        );
        /* check if spender frozen */
        require(
            !_frozen(spender),
            "XenoERC20.decreaseAllowance: SPENDER_FROZEN"
        );
        return _decreaseAllowance(spender, subtractedValue);
    }

    /* IERC20Burnable METHODS */

    /**
     * @dev Burns `amount` tokens from the caller account
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Requirements:
     * - contract is upaused
     * - caller is not frozen
     * - transfer rules apply (i.e. adequate balance, non-zero addresses)
     *
     * Emits a {Transfer} event with the ZERO address as recipient
     */
    function burn(uint256 amount) external override returns (bool) {
        /* check if paused */
        require(
            !_paused(),
            "XenoERC20.burn: PAUSED"
        );
        /* check if caller frozen */
        require(
            !_frozen(_msgSender()),
            "XenoERC20.burn: CALLER_FROZEN"
        );
        return _burn(amount);
    }

    /**
     * @dev Burns `amount` tokens from caller using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Requirements:
     * - contract is upaused
     * - caller is not frozen
     * - `account` is not frozen
     * - transfer rules apply (i.e. adequate balance)
     *
     * Emits a {Transfer} event with the ZERO address as recipient
     */
    function burnFrom(address account, uint256 amount) external override returns (bool) {
        /* check if paused */
        require(
            !_paused(),
            "XenoERC20.burnFrom: PAUSED"
        );
        /* check if caller frozen */
        require(
            !_frozen(_msgSender()),
            "XenoERC20.burnFrom: CALLER_FROZEN"
        );
        /* check if account frozen */
        require(
            !_frozen(account),
            "XenoERC20.burnFrom: ACCOUNT_FROZEN"
        );
        return _burnFrom(account, amount);
    }

    /* FreezableInterface METHODS */

    /**
     * @dev Returns the frozen state of `account`.
     */
    function frozen(address account) external view override returns (bool) {
        return _frozen(account);
    }

    /**
     * @dev Freezes activity of `account` until unfrozen
     *
     * Frozen activities include: 
     * - transfer (as sender and recipient)
     * - transferFrom (as caller, owner and recipient)
     * - approve (as caller and spender)
     * - increaseAllowance (as caller and spender)
     * - decreaseAllowance (as caller and spender)
     * - burn (as caller)
     * - burnFrom (as caller and spender)
     *
     * Requirements:
     * - caller must hold the ManagerRole
     * - `account` is unfrozen
     *
     * * Emits a {Frozen} event
     */
    function freeze(address account) external override {
        require(
            _isManager(_msgSender()),
            "XenoERC20.freeze: INVALID_CALLER"
        );
        _freeze(account);
    }

    /**
     * @dev Restores `account` activity
     *
     * Requirements:
     * - caller must hold the ManagerRole
     * - `account` is frozen
     *
     * * Emits an {Unfrozen} event
     *
     */
    function unfreeze(address account) external override {
        require(
            _isManager(_msgSender()),
            "XenoERC20.unfreeze: INVALID_CALLER"
        );
        _unfreeze(account);
    }

    /* PausableInterface  METHODS */

    /**
     * @dev Returns the paused state of the contract.
     */
    function paused() external view override returns (bool) {
        return _paused();
    }

    /**
     * @dev Pauses state changing activity of the entire contract
     *
     * Paused activities include: 
     * - transfer
     * - transferFrom
     * - approve
     * - increaseAllowance
     * - decreaseAllowance
     * - burn
     * - burnFrom
     *
     * Requirements:
     * - caller must hold the ManagerRole
     * - contract is unpaused
     *
     * * Emits a {Paused} event
     */
    function pause() external override {
        require(
            _isManager(_msgSender()),
            "XenoERC20.pause: INVALID_CALLER"
        );
        _pause();
    }

    /**
     * @dev Restores state changing activity to the entire contract
     *
     * Requirements:
     * - caller must hold the MangaerRole
     * - contract is paused
     *
     * * Emits a {Unpaused} event
     */
    function unpause() external override {
        require(
            _isManager(_msgSender()),
            "XenoERC20.unpause: INVALID_CALLER"
        );
        _unpause();
    }

    /* RecoverableInterface METHODS */

    /**
     * @dev Recovers `amount` of ERC20 `token` sent to the contract.
     *
     * Requirements:
     * - caller must hold the ManagerRole
     * - `token`.balanceOf(contract) must be greater than or equal to `amount`
     *
     * * Emits a {Recovered} event
     */
    function recover(IERC20 token, uint256 amount) override external {
        require(
            _isManager(_msgSender()),
            "XenoERC20.recover: INVALID_CALLER"
        );
        _recover(token, amount);
    }

    /* UUPSUpgradable METHODS */

    /**
     * @dev Returns the contract address of the currently deployed logic.
     */
    function getImplementation() external view returns (address) {
        return _getImplementation();
    }


    /**
     * @dev Ensures only manager role accounts can upgrade contract logic.
     */
    function _authorizeUpgrade(address) internal view override {
        require(
            _isManager(_msgSender()),
            "XenoERC20._authorizeUpgrade: INVALID_CALLER"
        );
    }
}
