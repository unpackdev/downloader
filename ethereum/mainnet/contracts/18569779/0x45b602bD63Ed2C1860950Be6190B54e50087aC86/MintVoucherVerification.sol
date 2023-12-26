// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import "./AccessControl.sol";
import "./ECDSA.sol";
import "./MintVoucherCapability.sol";
import "./Helper.sol";
import "./MintVoucherErrors.sol";
import "./Initializable.sol";

/**
 * @title MintVoucherVerification
 * @notice MintVoucherVerification is intended to be used to
 *         restrict minting via an off chain mint limiting server that issues vouchers.
 *         This contract handles the validation of the voucher and signature.
 * @dev Non-voucher related validation logic such as checking availably supply and funds should
 *      be implemented in the caller functions.
 */
abstract contract MintVoucherVerification is Initializable, AccessControl, MintVoucherErrors, MintVoucherCapability {
    // The recovered signer must have this role
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    // Track nonce of each account to be able to mark vouchers as filled or canceled
    mapping(address => uint256) private lastNonce;

    /**
     * @dev The MintVoucher struct contains the specific mint details. This data
     *      along with the contract address and the msg sender will be included in
     *      the signed message. Some of these fields may not be used depending on
     *      the situation. Currency should be zero address if payment is in native currency.
     *      tokenId is necessary for ERC1155 implementations but for ERC721 it is up to
     *      the implementation.
     */
    struct MintVoucher {
        address netRecipient;
        address initialRecipient;
        uint256 initialRecipientAmount;
        uint256 quantity;
        uint256 nonce;
        uint256 expiry;
        uint256 price;
        uint256 tokenId;
        address currency;
    }

    /**
     * @param signer An address that will sign the vouchers. The signing address
     *               will be recovered from the signature and verified to match
     *               this signer.
     */
    function initialize(address signer) public virtual onlyInitializing {
        _grantRole(SIGNER_ROLE, signer);
    }

    /**
     * @dev Recover signer from signature and mint voucher data. Validate the signer
     *      has the required role.
     * @param netRecipient The address to transfer the net funds minus initial payout, if any
     * @param initialRecipient The address to transfer an initial payout
     * @param initialRecipientAmount The amount to send to initial recipient
     * @param quantity The quantity to mint
     * @param nonce The mint voucher nonce used for replay protection
     * @param expiry The mint voucher expiration
     * @param price The price per unit
     * @param tokenId The tokenId to mint
     * @param currency The currency for payment
     * @param signature The signature to validate
     */
    function verifySignature(
        address netRecipient,
        address initialRecipient,
        uint256 initialRecipientAmount,
        uint256 quantity,
        uint256 nonce,
        uint256 expiry,
        uint256 price,
        uint256 tokenId,
        address currency,
        bytes calldata signature
    ) internal view {
        bytes32 digest = ECDSA.toEthSignedMessageHash(
            hash(
                netRecipient,
                initialRecipient,
                initialRecipientAmount,
                quantity,
                nonce,
                expiry,
                price,
                tokenId,
                currency
            )
        );
        address recoveredSigner = ECDSA.recover(digest, signature);

        if (!hasRole(SIGNER_ROLE, recoveredSigner)) {
            revert InvalidSignature();
        }
    }

    /**
     * @dev Hash the mint voucher data, msg sender, and contract address. The lastNonce
     *      needs to be updated with the voucher nonce prior to hashing.
     * @param netRecipient The address to transfer the net funds minus initial payout, if any
     * @param initialRecipient The address to transfer an initial payout
     * @param initialRecipientAmount The amount to send to initial recipient
     * @param quantity The quantity to mint
     * @param nonce The mint voucher nonce used for replay protection
     * @param expiry The mint voucher expiration
     * @param price The price per unit
     * @param tokenId The tokenId to mint
     * @param currency The currency for payment
     */
    function hash(
        address netRecipient,
        address initialRecipient,
        uint256 initialRecipientAmount,
        uint256 quantity,
        uint256 nonce,
        uint256 expiry,
        uint256 price,
        uint256 tokenId,
        address currency
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    netRecipient,
                    initialRecipient,
                    initialRecipientAmount,
                    quantity,
                    nonce,
                    expiry,
                    price,
                    tokenId,
                    currency,
                    _msgSender(),
                    address(this),
                    block.chainid
                )
            );
    }

    /**
     * @dev Set the last nonce used for an account. Any oucher with a nonce below or
     *      equal to this nonce is no invalid.
     * @param account The account to set the nonce for
     * @param nonce The new nonce
     */
    function updateLastNonce(address account, uint256 nonce) internal {
        // Cannot decrease the last used nonce
        if (nonce <= getLastNonce(account)) {
            revert VoucherNonceTooLow();
        }
        lastNonce[account] = nonce;
    }

    /**
     * @notice Get the last used nonce for an account.
     * @dev  A valid voucher must have a nonce higher than this
     * @param account The account to get the nonce for
     */
    function getLastNonce(address account) public view virtual returns (uint256) {
        return lastNonce[account];
    }
}
