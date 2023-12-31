// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./CentMarketPlaceStorage.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./draft-EIP712.sol";

/// @title Centaurify Marketplace
/// @author @mayjer, @Dadogg80 (Viken Blockchain Solutions)
/// @notice This is the Centaurify Marketplace smart contract.
contract CentMarketPlace is CentMarketPlaceStorage, EIP712, ReentrancyGuard {
    string private constant SIGNING_DOMAIN = "Centaurify-Marketplace";
    string private constant SIGNATURE_VERSION = "1";

    /// @notice The constructor will set the serviceWallet and Centaurify signer address.
    /// @param _serviceWallet The account that will receive the service fee.
    constructor(
        address payable _serviceWallet,
        address _buyerService
    ) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        require(_serviceWallet != address(0));

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(BUYER_SERVICE_ROLE, _buyerService);

        serviceWallet = _serviceWallet;
    }

    /// @notice Method used to purchase a market Order.
    /// @param voucher The signed voucher from the seller containing the order data.
    /// @dev emits: MarketOrderSold
    /// @dev throws: WrongSigner, ExpiredOrder, WrongAmount, FailedTransfer, TokenNotFound
    /// @dev before calling this method check the buyer approval for ERC20 token transfer, the seller marketplace approval, and seller token ownership as it may have been sold somewhere else.
    function executeOrder(
        CentOrderVoucher calldata voucher
    ) external payable nonReentrant {
        _executeOrder(voucher, _msgSender());
    }

    /// @notice extract the signer addresses from the voucher signatures
    /// @param voucher The signed voucher from the seller containing the order data.
    /// @return sellerSigner The address of the seller signer.
    function recoverSigner(
        CentOrderVoucher calldata voucher
    ) public view returns (address sellerSigner) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "CentOrderVoucher(uint256 orderId,uint256 chainId,address collectionAddress,uint256 tokenId,address sellerAddress,address priceToken,uint256 totalAmount,uint256 priceAmount,uint256 royaltyAmount,address royaltyReceiver,uint256 totalServiceFees,uint256 sellerAmount,uint256 expires)"
                    ),
                    voucher.orderId,
                    voucher.chainId,
                    voucher.collectionAddress,
                    voucher.tokenId,
                    voucher.sellerAddress,
                    voucher.priceToken,
                    voucher.totalAmount,
                    voucher.priceAmount,
                    voucher.royaltyAmount,
                    voucher.royaltyReceiver,
                    voucher.totalServiceFees,
                    voucher.sellerAmount,
                    voucher.expires
                )
            )
        );
        return ECDSA.recover(digest, voucher.sellerSignature);
    }

    /// PRIVATE METHODS

    /// @notice Private helper method used to purchase a marketOrder.
    /// @param voucher The signed voucher from the seller containing the order data.
    /// @param buyer The address of the buyer
    function _executeOrder(
        CentOrderVoucher calldata voucher,
        address buyer
    ) private {
        if (voucher.chainId != block.chainid)
            revert ErrorMessage("Wrong ChainId");
        if (
            voucher.priceToken != address(0) &&
            !acceptedTokensMapping[voucher.priceToken]
        ) revert TokenNotFound(voucher.priceToken);

        address sellerSigner = recoverSigner(voucher);
        if (sellerSigner != voucher.sellerAddress)
            revert WrongSigner(sellerSigner);
        if (block.timestamp > voucher.expires)
            revert ExpiredOrder(voucher.expires);

        if (voucher.priceToken == address(0)) {
            _sendFeesEth(voucher);
        } else {
            _sendFeesErc20(voucher);
        }

        IERC721(voucher.collectionAddress).safeTransferFrom(
            voucher.sellerAddress,
            buyer,
            voucher.tokenId
        );

        emit MarketOrderSold(
            voucher.orderId,
            voucher.collectionAddress,
            voucher.tokenId,
            voucher.priceToken,
            voucher.priceAmount,
            buyer
        );
    }

    function _sendFeesEth(CentOrderVoucher calldata voucher) private {
        if (msg.value != voucher.totalAmount)
            revert WrongAmount(voucher.totalAmount);

        (bool _feeSuccess, ) = serviceWallet.call{
            value: voucher.totalServiceFees
        }("");
        if (!_feeSuccess) revert FailedTransfer("Fees");

        (bool _royaltySuccess, ) = voucher.royaltyReceiver.call{
            value: voucher.royaltyAmount
        }("");
        if (!_royaltySuccess) revert FailedTransfer("Royalties");

        (bool _sellerSuccess, ) = voucher.sellerAddress.call{
            value: voucher.sellerAmount
        }("");
        if (!_sellerSuccess) revert FailedTransfer("Seller");
    }

    function _sendFeesErc20(CentOrderVoucher calldata voucher) private {
        bool _feeSuccess = IERC20(voucher.priceToken).transferFrom(
            _msgSender(),
            serviceWallet,
            voucher.totalServiceFees
        );
        if (!_feeSuccess) revert FailedTransfer("Fees");

        bool _royaltySuccess = IERC20(voucher.priceToken).transferFrom(
            _msgSender(),
            voucher.royaltyReceiver,
            voucher.royaltyAmount
        );
        if (!_royaltySuccess) revert FailedTransfer("Royalties");

        bool _sellerSuccess = IERC20(voucher.priceToken).transferFrom(
            _msgSender(),
            voucher.sellerAddress,
            voucher.sellerAmount
        );
        if (!_sellerSuccess) revert FailedTransfer("Seller");
    }

    /// ADMIN METHODS

    /// @notice Restricted method used to withdraw the funds from the marketplace.
    /// @dev Restricted to Admin Role.
    /// @dev Emits the event { Withdraw }.
    function withdraw() external onlyRole(ADMIN_ROLE) {
        (bool success, ) = payable(_msgSender()).call{
            value: address(this).balance
        }("");
        if (!success) revert ErrorMessage("Withdraw Failed");
        emit Withdraw();
    }

    function withdrawErc20(address tokenAddress) external onlyRole(ADMIN_ROLE) {
        bool success = IERC20(tokenAddress).transfer(
            _msgSender(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
        if (!success) revert ErrorMessage("Withdraw Failed");
        emit Withdraw();
    }

    /// @notice Restricted method used to set the serviceWallet.
    /// @dev Restricted to Admin Role.
    /// @param _serviceWallet The new account to receive the service fee.
    /// @dev Emits the event { ServiceWalletUpdated }.
    function updateServiceWallet(
        address payable _serviceWallet
    ) external onlyRole(ADMIN_ROLE) {
        serviceWallet = _serviceWallet;
        emit ServiceWalletUpdated(serviceWallet);
    }

    /// @notice Method used to purchase a marketOrder on behalf of a buyer.
    /// @param voucher The signed voucher from the seller containing the order data.
    /// @param buyer The address of the buyer
    function executeOrderForBuyer(
        CentOrderVoucher calldata voucher,
        address buyer
    ) external payable onlyRole(BUYER_SERVICE_ROLE) nonReentrant {
        _executeOrder(voucher, buyer);
    }

    /// OVERRIDES

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControlEnumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
