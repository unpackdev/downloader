// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./ECDSAUpgradeable.sol";

import "./IWallet.sol";
import "./IFactory.sol";
import "./ICryptoPunk.sol";

import "./ICyanConduit.sol";
import "./AddressProvider.sol";

error InvalidSender();
error InvalidSignature();
error InvalidPrice();
error InvalidAddress();
error InvalidItem();
error InvalidCurrency();

/// @title Cyan Private sales contract
/// @author Bulgantamir Gankhuyag - <bulgaa@usecyan.com>
/// @author Naranbayar Uuganbayar - <naba@usecyan.com>
contract CyanPrivateSales is AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    AddressProvider private constant addressProvider = AddressProvider(0xCF9A19D879769aDaE5e4f31503AAECDa82568E55);

    using ECDSAUpgradeable for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event Sold(address indexed seller, address indexed buyer, bytes signature);
    event CancelledSignature(bytes signature);

    event UpdatedWalletFactory(address indexed factory);
    event UpdatedCollectionSignatureVersion(uint256 indexed version);
    event UpdatedCyanSigner(address indexed signer);

    struct Item {
        address sellerAddress;
        address buyerAddress;
        uint256 signedDate;
        uint256 expiryDate;
        uint256 price;
        address currencyAddress;
        uint256 tokenAmount;
        uint256 tokenId;
        address contractAddress;
        // 1 -> ERC721
        // 2 -> ERC1155
        // 3 -> CryptoPunks
        uint8 tokenType;
        bytes collectionSignature;
    }

    mapping(address => bool) public supportedCurrency;
    mapping(bytes => bool) public signatureUsage;

    bytes32 public constant CYAN_ROLE = keccak256("CYAN_ROLE");
    address private walletFactory;
    address private cyanSigner;
    uint256 private collectionVersion;

    function initialize(
        address _cyanSuperAdmin,
        address _walletFactory,
        address _cyanSigner
    ) external initializer {
        if (_cyanSuperAdmin == address(0) || _walletFactory == address(0) || _cyanSigner == address(0))
            revert InvalidAddress();

        walletFactory = _walletFactory;
        cyanSigner = _cyanSigner;
        _setupRole(DEFAULT_ADMIN_ROLE, _cyanSuperAdmin);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        __AccessControl_init();
        __ReentrancyGuard_init();

        emit UpdatedWalletFactory(_walletFactory);
        emit UpdatedCyanSigner(_cyanSigner);
    }

    /**
     * @notice Creating a pawn plan
     * @param item Item detail to pawn
     * @param signature Signature from Lender
     */
    function buy(Item calldata item, bytes calldata signature) external payable nonReentrant {
        if (item.contractAddress == address(0)) revert InvalidAddress();
        if (item.tokenType < 1 || item.tokenType > 3) revert InvalidItem();
        if (item.tokenType == 1 && item.tokenAmount != 0) revert InvalidItem();
        if (item.tokenType == 2 && item.tokenAmount == 0) revert InvalidItem();
        if (item.tokenType == 3 && item.tokenAmount != 0) revert InvalidItem();

        if (item.sellerAddress == address(0)) revert InvalidAddress();
        if (item.price == 0) revert InvalidPrice();

        if (supportedCurrency[item.currencyAddress] != true) revert InvalidCurrency();

        if (item.signedDate >= block.timestamp) revert InvalidSignature();
        if (item.expiryDate < block.timestamp) revert InvalidSignature();
        if (signatureUsage[signature] == true) revert InvalidSignature();

        address mainAddress = msg.sender;
        address cyanWalletAddress = IFactory(walletFactory).getOrDeployWallet(msg.sender);
        if (cyanWalletAddress == msg.sender) {
            mainAddress = getMainWalletAddress(cyanWalletAddress);
        }

        if (
            mainAddress != item.buyerAddress &&
            cyanWalletAddress != item.buyerAddress &&
            !hasRole(CYAN_ROLE, msg.sender)
        ) {
            revert InvalidSender();
        }

        verifySellerSignature(item, signature);

        transferItem(item, item.sellerAddress, mainAddress);

        if (item.currencyAddress == address(0)) {
            // ETH
            if (item.price != msg.value) revert InvalidPrice();
            payable(item.sellerAddress).transfer(item.price);
        } else {
            // ERC20
            if (msg.value != 0) revert InvalidPrice();

            ICyanConduit(addressProvider.addresses("CYAN_CONDUIT")).transferERC20(
                mainAddress,
                item.sellerAddress,
                item.currencyAddress,
                item.price
            );
        }

        signatureUsage[signature] = true;
        emit Sold(item.sellerAddress, mainAddress, signature);
    }

    /**
     * @notice Transfers token to buyer's address from seller's address
     * @param item Transferring item
     * @param from Seller address
     * @param to Buyer address
     */
    function transferItem(
        Item memory item,
        address from,
        address to
    ) private {
        if (item.tokenType == 3) {
            ICryptoPunk cryptoPunkContract = ICryptoPunk(item.contractAddress);
            cryptoPunkContract.buyPunk{ value: 0 }(item.tokenId);
            cryptoPunkContract.transferPunk(to, item.tokenId);
            return;
        }

        ICyanConduit conduit = ICyanConduit(addressProvider.addresses("CYAN_CONDUIT"));
        if (item.tokenType == 1) {
            IERC721Upgradeable erc721Contract = IERC721Upgradeable(item.contractAddress);
            if (erc721Contract.ownerOf(item.tokenId) == from) {
                conduit.transferERC721(from, to, item.contractAddress, item.tokenId);
                return;
            }

            address cyanWalletAddress = getCyanWalletAddress(from);
            if (cyanWalletAddress == address(0)) revert InvalidItem();

            IWallet(cyanWalletAddress).executeModule(
                abi.encodeWithSelector(IWallet.transferNonLockedERC721.selector, item.contractAddress, item.tokenId, to)
            );
        } else if (item.tokenType == 2) {
            conduit.transferERC1155(from, to, item.contractAddress, item.tokenId, item.tokenAmount);
        } else {
            revert InvalidItem();
        }
    }

    /**
     * @notice Seller can cancel their signature
     * @param signature Signature from Seller
     */
    function cancelSignature(Item calldata item, bytes calldata signature) external nonReentrant {
        verifySellerSignature(item, signature);
        if (signatureUsage[signature] == true) revert InvalidSignature();
        if (
            msg.sender != item.sellerAddress &&
            getMainWalletAddress(msg.sender) != item.sellerAddress &&
            getCyanWalletAddress(msg.sender) != item.sellerAddress
        ) revert InvalidAddress();

        signatureUsage[signature] = true;
        emit CancelledSignature(signature);
    }

    /**
     * @notice Updating Cyan wallet factory address that used for deploying new wallets
     * @param factory New Cyan wallet factory address
     */
    function updateWalletFactoryAddress(address factory) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (factory == address(0) || walletFactory == factory) revert InvalidAddress();
        walletFactory = factory;
        emit UpdatedWalletFactory(factory);
    }

    /**
     * @notice Updating Cyan signer address that used for signing collection address
     * @param signer New Cyan signer address
     */
    function updateCyanSigner(address signer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (signer == address(0) || cyanSigner == signer) revert InvalidAddress();
        cyanSigner = signer;
        emit UpdatedCyanSigner(signer);
    }

    /**
     * @notice Updating collection signature version
     */
    function increaseCollectionSignatureVersion() external onlyRole(DEFAULT_ADMIN_ROLE) {
        ++collectionVersion;
        emit UpdatedCollectionSignatureVersion(collectionVersion);
    }

    /**
     * @notice Adding supported currencies
     * @param currency Array of supported currencies
     */
    function addSupportedCurrencies(address[] calldata currency) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 ind; ind < currency.length; ++ind) {
            supportedCurrency[currency[ind]] = true;
        }
    }

    /**
     * @notice Removing supported currencies
     * @param currency Array of unsupported currencies
     */
    function removeSupportedCurrencies(address[] calldata currency) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 ind; ind < currency.length; ++ind) {
            supportedCurrency[currency[ind]] = false;
        }
    }

    /**
     * @notice Getting Cyan wallet address by main wallet address
     * @param mainWalletAddress Main wallet address
     */
    function getCyanWalletAddress(address mainWalletAddress) private view returns (address) {
        return IFactory(walletFactory).getOwnerWallet(mainWalletAddress);
    }

    /**
     * @notice Getting main wallet address by Cyan wallet address
     * @param cyanWalletAddress Cyan wallet address
     */
    function getMainWalletAddress(address cyanWalletAddress) private view returns (address) {
        return IFactory(walletFactory).getWalletOwner(cyanWalletAddress);
    }

    function verifySellerSignature(Item calldata item, bytes calldata signature) private view {
        // Lenders signature can contain specific tokenId
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                item.buyerAddress,
                item.signedDate,
                item.expiryDate,
                item.price,
                item.currencyAddress,
                item.tokenAmount,
                item.tokenId,
                item.contractAddress,
                item.tokenType,
                item.collectionSignature
            )
        );

        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        if (signedHash.recover(signature) != item.sellerAddress) {
            revert InvalidSignature();
        }

        bytes32 collectionMsgHash = keccak256(abi.encodePacked(item.contractAddress, collectionVersion));
        bytes32 collectionSignedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", collectionMsgHash)
        );
        if (collectionSignedHash.recover(item.collectionSignature) != cyanSigner) {
            revert InvalidSignature();
        }
    }
}
