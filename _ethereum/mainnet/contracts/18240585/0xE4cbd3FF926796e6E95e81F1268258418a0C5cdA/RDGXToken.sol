// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

// This is developed with OpenZeppelin contracts v4.9.3.
import "./AccessControlEnumerable.sol";
import "./ERC20Pausable.sol";

/**
 * @title Radiologex token (RDGX).
 * @notice This contract is the ERC20 token of R-DEE protocol.
 *
 * It includes the basic ERC20 functionality as well as the following:
 * - The total supply is preminted to the owner address specified for contract creation.
 * - A pauser role that allows to stop all token transfers.
 * - A denier role that allows to deny and allow token transfers for addresses.
 *
 * The owner address specified for contract creation is granted the default admin role, which lets it grant both
 * pauser and denier roles to other addresses.
 *
 * It is also used for R-DEE token sale and vesting.
 */
contract RDGXToken is AccessControlEnumerable, ERC20Pausable {
    // _______________ Constants _______________

    // The token name used for contract initialization.
    string private constant NAME = "R-DEE Protocol Token";

    // The token symbol used for contract initialization.
    string private constant SYMBOL = "RDGX";

    // The total supply without decimals, that is transferred to the owner address during contract initialization.
    uint256 private constant TOTAL_SUPPLY = 1E9;

    /// @notice The role of a pauser, who is responsible for pausing and unpausing all token transfers.
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice The role of a denier, who is responsible for denying and allowing addresses for token transfer.
    bytes32 public constant DENIER_ROLE = keccak256("DENIER_ROLE");

    // _______________ Storage _______________

    /**
     * @notice Stores `true` for addresses for which all token transfers are denied.
     *
     * An address => is denied for all token transfers?
     */
    mapping(address => bool) public denylist;

    // _______________ Errors _______________

    /// @notice Reverted if the owner address is zero address during contract initialization.
    error OwnerEqZeroAddr();

    /**
     * @notice Reverted when token transfer from or to a denied address.
     *
     * It provides the value:
     * @param _addr The denied address, from or to which a token transfer is attempted.
     */
    error DeniedAddress(address _addr);

    /**
     * @notice Reverted when re-denying a denied address.
     *
     * It provides the value:
     * @param _addr The denied address attempted to be denied again.
     */
    error AlreadyDenied(address _addr);

    /**
     * @notice Reverted when allowing an address that is not denied.
     *
     * It provides the value:
     * @param _addr The address that is not denied, but has been attempted to be allowed.
     */
    error NotDenied(address _addr);

    // _______________ Events _______________

    /**
     * @notice Emitted when all token transfers are denied for an address `_addr`.
     *
     * @param _addr The address for which all token transfers are denied.
     */
    event Denied(address indexed _addr);

    /**
     * @notice Emitted when token transfers are allowed for a denied address `_addr`.
     *
     * @param _addr The address for which token transfers are allowed.
     */
    event Allowed(address indexed _addr);

    // _______________ Constructor _______________

    /**
     * @notice Initializes this ERC20 contract by setting token name and symbol, transfer the total supply to
     * the `_owner` address and granting him the role `DEFAULT_ADMIN_ROLE`.
     *
     * Emits events `RoleGranted` and `Transfer`.
     *
     * Requirements:
     * - `_owner` should not be zero address.
     *
     * @param _owner The address to which the total supply is initially minted.
     */
    // prettier-ignore
    constructor(address _owner) ERC20(NAME, SYMBOL) {
        if (_owner == address(0))
            revert OwnerEqZeroAddr();

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);

        _mint(_owner, TOTAL_SUPPLY * 10 ** decimals());
    }

    // _______________ External functions _______________

    /**
     * @notice Pauses all token transfers.
     *
     * Emits a `Paused` event.
     *
     * Requirements:
     * - The caller should have the role `PAUSER_ROLE`.
     * - The contract should not be paused.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses all token transfers.
     *
     * Emits an `Unpaused` event.
     *
     * Requirements:
     * - The caller should have the role `PAUSER_ROLE`.
     * - The contract should be paused.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @notice Denies all token transfers for an address `_addr`.
     *
     * Emits a `Denied` event.
     *
     * Requirements:
     * - The caller should have the role `DENIER_ROLE`.
     * - The address `_addr` should not be denied.
     *
     * @param _addr An address to be denied.
     */
    // prettier-ignore
    function deny(address _addr) external onlyRole(DENIER_ROLE) {
        if (denylist[_addr])
            revert AlreadyDenied(_addr);

        denylist[_addr] = true;

        emit Denied(_addr);
    }

    /**
     * @notice Allows token transfers for a denied address `_addr`.
     *
     * Emits an `Allowed` event.
     *
     * Requirements:
     * - The caller should have the role `DENIER_ROLE`.
     * - The address `_addr` should be denied.
     *
     * @param _addr A denied address to be allowed.
     */
    // prettier-ignore
    function allow(address _addr) external onlyRole(DENIER_ROLE) {
        if (!denylist[_addr])
            revert NotDenied(_addr);

        denylist[_addr] = false;

        emit Allowed(_addr);
    }

    // _______________ Internal functions _______________

    /**
     * @notice Hook that is called before any transfer of tokens.
     *
     * It is overridden to be extended with the following requirements:
     * - `_from` should not be denied (`denylist`).
     * - `_to` should not be denied (`denylist`).
     *
     * It also includes the condition of `Pauseable`:
     * - The contract should not be paused.
     *
     * @param _from An address from which tokens are transferred. Only in the first transaction, it is zero address,
     * when the total supply is minted to the owner address during contract creation.
     * @param _to An address to which tokens are transferred.
     * @param _amount Amount of tokens to be transferred.
     *
     * @notice See `Pauseable` and `ERC20` for details.
     */
    // prettier-ignore
    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal virtual override {
        if (denylist[_from])
            revert DeniedAddress(_from);
        if (denylist[_to])
            revert DeniedAddress(_to);

        super._beforeTokenTransfer(_from, _to, _amount);
    }
}
