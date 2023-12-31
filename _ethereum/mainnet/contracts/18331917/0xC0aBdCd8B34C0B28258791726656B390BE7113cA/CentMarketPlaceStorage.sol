// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Context.sol";
import "./AccessControlEnumerable.sol";

contract CentMarketPlaceStorage is Context, AccessControlEnumerable {
    /// @notice The account that will receive the service fee.
    /// @return serviceWallet The serivce wallet address.
    address payable public serviceWallet;

    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant BUYER_SERVICE_ROLE =
        keccak256("BUYER_SERVICE_ROLE");

    string private constant SIGNING_DOMAIN = "Centaurify-Marketplace";
    string private constant SIGNATURE_VERSION = "1";

    /// MAPPINGS

    /// @notice Mapping of ERC20 tokens accepted for listings
    mapping(address => bool) public acceptedTokensMapping;

    /// STRUCTS

    // @dev contains the data the market order.
    struct CentOrderVoucher {
        uint orderId;
        uint chainId;
        address collectionAddress;
        uint tokenId;
        address payable sellerAddress;
        address priceToken;
        uint totalAmount;
        uint priceAmount;
        uint royaltyAmount;
        address payable royaltyReceiver;
        uint totalServiceFees;
        uint sellerAmount;
        uint expires;
        bytes sellerSignature;
    }

    /// MODIFIERS

    /// CUSTOM ERRORS

    /// @notice Thrown with a string message.
    /// @param message Error message string.
    error ErrorMessage(string message);

    /// @notice thrown if the voucher has expired
    error ExpiredOrder(uint expires);

    /// @notice thrown when a transfer transaction fails
    error FailedTransfer(string reason);

    /// @notice thrown if the NFT transfer has not been approved
    error NotApprovedOrNotOwner(address collectionAddress, uint tokenId);

    /// @notice thrown if the accepted token is already accepted
    error TokenDuplicate(address tokenAddress);

    /// @notice thrown if the accepted token does not exist
    error TokenNotFound(address tokenAddress);

    /// @notice thrown if the wrong amount of tokens are sent
    /// @param amount the expected amount
    error WrongAmount(uint amount);

    /// @notice thrown if the voucher signer does not match the voucher seller address
    error WrongSigner(address signer);

    /// EVENTS

    /// @notice Emitted when a new Centaurify signer for order vouchers is set.
    event CentSignerUpdated(address signer);

    /// @notice Emitted when a marketOrder is sold.
    /// @param orderId indexed - The Id of this marketOrder.
    /// @param nftContract Indexed - The smartcontact of this nft.
    /// @param tokenId indexed - The tokenId of this marketOrder.
    /// @param priceTokenAddress The address of the ERC20 token used for the sales price.
    /// @param priceInWei The salesprice nominated in wei.
    /// @param buyer The buyer of this marketOrder.
    event MarketOrderSold(
        uint256 indexed orderId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address priceTokenAddress,
        uint256 priceInWei,
        address buyer
    );

    /// @notice Emitted when a new token is added to the accepted tokens.
    event AcceptedTokenAdded(address tokenAddress);

    /// @notice Emitted when a token is removed from the accepted tokens.
    event AcceptedTokenRemoved(address tokenAddress);

    /// @notice Emitted when the serviceWallet is updated.
    /// @param serviceWallet Indexed - The new account to serve as service wallet.
    event ServiceWalletUpdated(address indexed serviceWallet);

    /// @notice Emitted on withdrawals from the marketplace contract.
    event Withdraw();

    /// ADMIN METHODS

    /// @notice Restricted method used to add a new token order prices can be listed in.
    /// @param _tokenAddress The address of the ERC20 token
    /// @dev Restricted to Admin Role.
    /// @dev Throws: DoubleEntry if the token is already in the mapping.
    function addAcceptedToken(
        address _tokenAddress
    ) external onlyRole(ADMIN_ROLE) {
        if (acceptedTokensMapping[_tokenAddress]) {
            revert TokenDuplicate(_tokenAddress);
        }
        acceptedTokensMapping[_tokenAddress] = true;
    }

    /// @notice Restricted method used to remove a token from the accepted tokens.
    /// @param _tokenAddress The address of the ERC20 token to remove
    /// @dev Restricted to Admin Role.
    /// @dev throws: TokenNotFound if the token is not in the mapping
    function removeAcceptedToken(
        address _tokenAddress
    ) external onlyRole(ADMIN_ROLE) {
        if (!acceptedTokensMapping[_tokenAddress]) {
            revert TokenNotFound(_tokenAddress);
        }
        delete acceptedTokensMapping[_tokenAddress];
    }
}
