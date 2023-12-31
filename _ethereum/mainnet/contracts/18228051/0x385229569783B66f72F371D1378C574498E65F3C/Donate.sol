// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Initializable.sol";

import "./Errors.sol";
import "./UniversalERC20.sol";
import "./ECDSA.sol";

import "./IDonate.sol";

/**
 * @title Donate contract
 * @author JusticeDAO
 * - Users can:
 *   # Donate ETH/ERC20 tokens
 * - Admin can:
 *   # Refund/withdraw ETH and ERC20 tokens
 *   # Change signer
 *   # Upgrade proxy
 */
contract Donate is Ownable, Initializable, IDonate {
    using UniversalERC20 for IERC20;

    /* ============ Immutables ============ */

    /* ============ Constants ============ */

    /* ============ State Variables ============ */

    // Address that must sign the message that the donation was successful
    address public override signer;

    mapping(bytes32 => address) public recipients;

    /* ============ Events ============ */

    /**
     * @dev Emitted when a successful donate of a contract.
     * @param token The address of the token to donate. (for ETH address(0))
     * @param from Address who create operation.
     * @param amount The amount of the token to donate.
     * @param recipient Address who will receive the tokens.
     */
    event Donation(address indexed token, address indexed from, uint256 amount, address recipient);

    /**
     * @dev Emitted when a successful withdrawal of a contract.
     * @param token The address of the token to withdrawal. (for ETH address(0))
     * @param to Address who will receive the tokens.
     * @param amount The amount of the token to withdrawal.
     */
    event Withdrawal(address indexed token, address indexed to, uint256 amount);

    /**
     * @dev Emitted when a successful refund of a contract.
     * @param token The address of the token to refund. (for ETH address(0))
     * @param to Address who will receive the tokens.
     * @param amount The amount of the token to refund.
     */
    event Refund(address indexed token, address indexed to, uint256 amount);

    /**
     * @dev Emitted when a successful refund of a contract.
     * @param recipient The address of the token to refund. (for ETH address(0))
     * @param name Address who will receive the tokens.
     */
    event AddRecipient(address indexed recipient, bytes32 indexed name);

    /**
     * @dev Emitted when a successful refund of a contract.
     * @param recipient The address of the token to refund. (for ETH address(0))
     * @param name Address who will receive the tokens.
     */
    event UpdateRecipient(address indexed recipient, bytes32 indexed name);

    /**
     * @dev Emitted when a successful refund of a contract.
     * @param recipient The address of the token to refund. (for ETH address(0))
     * @param name Address who will receive the tokens.
     */
    event RemoveRecipient(address indexed recipient, bytes32 indexed name);

    /* ============ Modifiers ============ */

    /* ============ Constructor ============ */

    /* ============ Initializer ============ */

    /**
     * @notice Initializes the Donate contract.
     * @dev The function is called by the proxy contract during initialization.
     * @param _signer Set the address of who will sign messages.
     * @param _newOwner Specify the owner of the contract.
     */
    function initialize(address _signer, address _newOwner) external initializer {
        signer = _signer;
        _transferOwnership(_newOwner);
    }

    /* ============ External Functions ============ */

    /**
     * @dev The donate function performs the top up of the contract by the amount sent, if the signature is valid.
     * @param _token The address of the token to donate. (for ETH address(0))
     * @param _amount The amount of the token to donate.
     * @param _signature Signature for verification, only the owner of the signature can make a donation.
     */
    function donate(
        IERC20 _token,
        uint256 _amount,
        bytes32 _name,
        bytes calldata _signature
    ) external payable override {
        address recipient = recipients[_name];
        require(recipient != address(0), Errors.INVALID_RECIPIENT);

        require(
            ECDSA.recover(_getMessageHash(_token, _amount, recipient), _signature) == signer,
            Errors.INVALID_SIGNER
        );

        _token.universalTransferFrom(msg.sender, recipient, _amount);
        emit Donation(msg.sender, address(_token), _amount, recipient);
    }

    /**
     * @dev The withdraw function for the withdrawal of funds, called only by the owner of the contract.
     * @param _token The address of the token to withdrawal. (for ETH address(0))
     * @param _to Address who will receive the tokens.
     * @param _amount The amount of the token to withdrawal.
     */
    function withdraw(IERC20 _token, address _to, uint _amount) external override {
        _transfer(_token, _to, _amount);
        emit Withdrawal(address(_token), _to, _amount);
    }

    /**
     * @dev The refund function for the return of funds to the sender, called only by the owner of the contract.
     * @param _token The address of the token to withdrawal. (for ETH address(0))
     * @param _to Address who will receive the tokens.
     * @param _amount The amount of the token to withdrawal.
     */
    function refund(IERC20 _token, address _to, uint256 _amount) external override {
        _transfer(_token, _to, _amount);
        emit Refund(address(_token), _to, _amount);
    }

    /**
     * @notice Update recipients to the donate contract.
     * @param _recipients The new recipients
     */
    function updateRecipients(address[] memory _recipients, bytes32[] memory _names) external override onlyOwner {
        require(_names.length == _recipients.length && _recipients.length > 0, '');

        for (uint256 i = 0; i < _recipients.length; i++) {
            _setRecipient(_recipients[i], _names[i]);
        }
    }

    /**
     * @notice Add a new recipient to the donate contract.
     * @param _recipient The new recipient
     * @param _name The index for a recipient
     */
    function setRecipient(address _recipient, bytes32 _name) external override onlyOwner {
        _setRecipient(_recipient, _name);
    }

    /**
     * @notice Update a recipient to the donate contract.
     * @param _recipient The new recipient
     * @param _name The index for a recipient
     */
    function updateRecipient(address _recipient, bytes32 _name) external override onlyOwner {
        _updateRecipient(_recipient, _name);
    }

    /**
     * @notice Remove a recipient to the donate contract.
     * @param _name The index a recipient
     */
    function removeRecipient(bytes32 _name) external override onlyOwner {
        require(recipients[_name] != address(0), Errors.RECIPIENT_NOT_FOUND);
        emit RemoveRecipient(recipients[_name], _name);
        delete recipients[_name];
    }

    /**
     * @notice Set a new signer to the donate contract.
     * @param _signer The new signer
     */
    function setSigner(address _signer) external override onlyOwner {
        signer = _signer;
    }

    /**
     * @dev Fallback function that returns an error that it is blocked. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable {
        _fallback();
    }

    /**
     * @dev Receive function that returns an error that it is blocked. Will run if call data
     * is empty.
     */
    receive() external payable {
        _fallback();
    }

    /* ============ Public Functions ============ */

    /* ============ Private Functions ============ */

    /**
     * @dev The transfer function the transfers tokens to the specified address.
     * If you specify 0, it will withdraw the entire balance.
     * @param _token The address of the token to transfer. (for ETH address(0))
     * @param _to Address who will receive the tokens.
     * @param _amount The amount of the token to transfer.
     */
    function _transfer(IERC20 _token, address _to, uint256 _amount) private onlyOwner {
        _amount = _amount == 0 ? _token.universalBalanceOf(address(this)) : _amount;
        _token.universalTransfer(_to, _amount);
    }

    /**
     * @notice Update a recipient to the donate contract.
     * @param _recipient The new recipient
     * @param _name The index for a recipient
     */
    function _updateRecipient(address _recipient, bytes32 _name) internal {
        require(_recipient != address(0), Errors.INVALID_RECIPIENT);
        require(recipients[_name] != address(0), Errors.RECIPIENT_NOT_FOUND);

        recipients[_name] = _recipient;
        emit UpdateRecipient(_recipient, _name);
    }

    /**
     * @notice Add a new recipient to the donate contract.
     * @param _recipient The new recipient
     * @param _name The index for a recipient
     */
    function _setRecipient(address _recipient, bytes32 _name) internal {
        require(_recipient != address(0), Errors.INVALID_RECIPIENT);
        require(recipients[_name] == address(0), Errors.RECIPIENT_ALREADY_EXIST);

        recipients[_name] = _recipient;
        emit AddRecipient(_recipient, _name);
    }

    /**
     * @dev Returns an error if called. Necessary to block receive and fallback functions.
     */
    function _fallback() internal pure {
        revert(Errors.RECEIVE_FALLBACK_PROHIBITED);
    }

    /**
     * @dev The getMessageHash function the returns the hash of the message from the sender with the specified data.
     * @param _token The address of the token that is used for donation. (for ETH address(0))
     * @param _amount The amount of the token that is used for donation.
     * @param _recipient The address who will receive the tokens.
     */
    function _getMessageHash(IERC20 _token, uint256 _amount, address _recipient) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    '\x19Ethereum Signed Message:\n128',
                    abi.encode(msg.sender, address(_token), _amount, _recipient)
                )
            );
    }
}
