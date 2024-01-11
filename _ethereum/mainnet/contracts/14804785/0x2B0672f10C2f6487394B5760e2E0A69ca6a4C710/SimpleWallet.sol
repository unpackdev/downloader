// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

// Inheritance
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";

// References
import "./ECDSA.sol";
import "./Address.sol";

/// @title Rentable account abstraction
/// @author Rentable Team <hello@rentable.world>
/// @notice Account Abstraction
contract SimpleWallet is
    Initializable,
    OwnableUpgradeable,
    ERC721HolderUpgradeable,
    ERC1155HolderUpgradeable
{
    /* ========== LIBRARIES ========== */

    using ECDSA for bytes32;
    using Address for address;

    /* ========== CONSTANTS ========== */

    bytes4 private constant ERC1271_IS_VALID_SIGNATURE =
        bytes4(keccak256("isValidSignature(bytes32,bytes)"));

    /* ========== STATE VARIABLES ========== */

    // current owner for the content
    address private _user;

    /* ========== CONSTRUCTOR ========== */

    /// @dev Instatiate SimpleWallet
    /// @param owner address for owner role
    /// @param user address for user role
    constructor(address owner, address user) {
        _initialize(owner, user);
    }

    /* ---------- INITIALIZER ---------- */

    /// @notice Initializer for the wallet
    /// @param owner address for owner role
    /// @param user address for user role
    function initialize(address owner, address user) external {
        _initialize(owner, user);
    }

    /// @dev Internal intializer for the wallet
    /// @param owner address for owner role
    /// @param user address for user role
    function _initialize(address owner, address user) internal initializer {
        require(owner != address(0), "Owner cannot be null");

        __Ownable_init();
        _transferOwnership(owner);
        __ERC721Holder_init();
        __ERC1155Holder_init();

        _setUser(user);
    }

    /* ========== SETTERS ========== */

    /* ---------- Internal ---------- */

    /// @dev Set current user for the wallet
    /// @param user user address
    function _setUser(address user) internal {
        // it's ok to se to 0x0, disabling signatures
        // slither-disable-next-line missing-zero-check
        _user = user;
    }

    /* ---------- Public ---------- */

    /// @notice Set current user for the wallet
    /// @param user user address
    function setUser(address user) external onlyOwner {
        _setUser(user);
    }

    /* ========== VIEWS ========== */

    /// @notice Set current user for the wallet
    /// @return user address
    function getUser() external view returns (address user) {
        return _user;
    }

    /// @notice Implementation of EIP 1271.
    /// Should return whether the signature provided is valid for the provided data.
    /// @param msgHash Hash of a message signed on the behalf of address(this)
    /// @param signature Signature byte array associated with _msgHash
    function isValidSignature(bytes32 msgHash, bytes memory signature)
        external
        view
        returns (bytes4)
    {
        // For the first implementation
        // we won't recursively check if user is smart wallet too
        // we assume user is an EOA
        address signer = msgHash.recover(signature);
        require(_user == signer, "Invalid signer");
        return ERC1271_IS_VALID_SIGNATURE;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Execute any tx
    /// @param to target
    /// @param value ether value
    /// @param data function+data
    /// @param isDelegateCall true will execute a delegate call, false a call
    function execute(
        address to,
        uint256 value,
        bytes memory data,
        bool isDelegateCall
    ) external payable onlyOwner returns (bytes memory returnData) {
        if (isDelegateCall) {
            returnData = to.functionDelegateCall(data, "");
        } else {
            returnData = to.functionCallWithValue(data, value, "");
        }
    }

    /// @notice Withdraw ETH
    /// @param amount amount to withdraw
    function withdrawETH(uint256 amount) external onlyOwner {
        Address.sendValue(payable(msg.sender), amount);
    }

    /// @notice Can receive ETH
    receive() external payable {}
}
