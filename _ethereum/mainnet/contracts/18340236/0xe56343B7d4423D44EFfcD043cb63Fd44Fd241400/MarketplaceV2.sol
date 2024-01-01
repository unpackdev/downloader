// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC2981.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./Math.sol";
import "./ECDSA.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

// Safety guard
import "./ReentrancyGuardUpgradeable.sol";

import "./IGateway.sol";

contract MarketplaceV2 is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /********************************************************************
     *                      Convenience structs                         *
     ********************************************************************/

    struct OrderMetadata {
        bool sellOrBuy; // true for sell, false for buy
        address recipient; // the actual recipient of the deal
        // For buy orders, this is the recipient of the NFT
        // For sell orders, this is the recipient of the payment tokens
        uint256 listingTime; // When the order becomes effective
        uint256 expirationTime; // When the order expires
        uint256 maximumFill; // Number of **NFTs** the trader wants to transact
        bool forceFilled; // Force filled in one transaction
        uint256 salt; // Random salt
    }

    struct Order {
        address marketplaceAddress; // Address of this contract
        address targetTokenAddress; // NFT token address
        uint256 targetTokenId; // The tokenId of the NFT to be transacted
        address paymentTokenAddress; // The address of the payment token
        uint256 price; // The price of the NFT, in payment tokens
        uint256 serviceFee; // Fee to platform
        uint256 royaltyFee; // Fee to NFT providers
        address royaltyFeeRecipient; // Address of the NFT provider
        bool allowMint; // Allow the NFT to be minted at sale
    }

    /********************************************************************
     *                            Constants                             *
     ********************************************************************/

    // Transaction modes
    bytes32 public constant TRANSACT_ERC721 = keccak256("TRANSACT_ERC721");
    bytes32 public constant TRANSACT_ERC1155 = keccak256("TRANSACT_ERC1155");

    // Fee related magic numbers
    uint256 public constant BASE = 10000;

    /********************************************************************
     *                         State variables                          *
     ********************************************************************/

    // Supported payment ERC20 tokens
    mapping(address => bool) public paymentTokens;

    // Platform address
    address public serviceFeeRecipient;

    // Gateway address
    address public gateway;

    /**
     * cancelled records if an order (indexed by the result of getMessageHash)
     * has been cancelled by its initializer (by calling ignoreMessagehash)
     */
    mapping(address => mapping(bytes32 => bool)) cancelled;

    /**
     * fills records how many NFTs has been transacted for a certain order
     *
     * Note During a transaction, there are two items in fills to be changed, for
     * buyer and seller, respectively. For example, if the seller wants to sell
     * 10 ERC1155 tokens, but the buyer only wants to buy 8 of them, then their
     * fills will both increase 8 if the transaction succeeds.
     */
    mapping(address => mapping(bytes32 => uint256)) fills;

    /********************************************************************
     *                             Events                               *
     ********************************************************************/

    event MatchOrder(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed paymentToken,
        uint256 price,
        uint256 fill,
        address seller,
        address buyer,
        address sellerRecipient,
        address buyerRecipient,
        bytes32 sellerMessageHash,
        bytes32 buyerMessageHash
    );

    event IgnoreMessageHash(
        address indexed operator,
        bytes32 indexed messageHash
    );

    event SetServiceFeeRecipient(address indexed serviceFeeRecipient);

    event AddPaymentToken(address indexed paymentToken);

    event RemovePaymentToken(address indexed paymentToken);

    event SetGateway(address indexed gateway);

    function initialize(
        address _gateway,
        address _serviceFeeRecipient
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        // Let native token be payment token
        paymentTokens[address(0)] = true;
        gateway = _gateway;
        serviceFeeRecipient = _serviceFeeRecipient;
    }

    /********************************************************************
     *                      Owner-only functions                        *
     ********************************************************************/

    function setGateway(address _gateway) public onlyOwner {
        gateway = _gateway;

        emit SetGateway(gateway);
    }

    function setServiceFeeRecipient(
        address _serviceFeeRecipient
    ) public onlyOwner {
        serviceFeeRecipient = _serviceFeeRecipient;

        emit SetServiceFeeRecipient(serviceFeeRecipient);
    }

    function addPaymentTokens(
        address[] calldata _paymentTokens
    ) public onlyOwner {
        for (uint256 i = 0; i < _paymentTokens.length; i++) {
            if (paymentTokens[_paymentTokens[i]] == true) {
                continue;
            }

            paymentTokens[_paymentTokens[i]] = true;

            emit AddPaymentToken(_paymentTokens[i]);
        }
    }

    function removePaymentTokens(
        address[] calldata _removedPaymentTokens
    ) public onlyOwner {
        for (uint256 i = 0; i < _removedPaymentTokens.length; i++) {
            if (paymentTokens[_removedPaymentTokens[i]] == false) {
                continue;
            }

            paymentTokens[_removedPaymentTokens[i]] = false;

            emit RemovePaymentToken(_removedPaymentTokens[i]);
        }
    }

    /********************************************************************
     *                         Core functions                           *
     ********************************************************************/

    /**
     * This is the function exposed to external users. When a buyer wants to match a sell
     * order, or a seller wants to match a buy order, they call this function. If they
     * provide their signature, everyone can help match the order on their behalf.
     *
     * Note The atomicMatch function is splitted into two functions, atomicMatch and _atomicMatch,
     * to circumvent solidity's restriction on stack size.
     *
     * @param transactionType should either be TRANSACT_ERC721 or TRANSACT_ERC1155
     * @param _order information encoded by an Order object, represent the order to be matched
     * @param seller address of the seller
     * @param _sellerMetadata information encoded by the seller's OrderMetadata object
     * @param sellerSig seller's signature of the intention to sell, this parameter is not needed
     * in case seller is msg.sender
     * @param buyer address of the buyer
     * @param _buyerMetadata information encoded by the buyer's OrderMetadata object
     * @param buyerSig buyer's signature of the intention to buy, this parameter is not needed
     * in case buyer is msg.sender
     */
    function atomicMatch(
        bytes32 transactionType,
        bytes memory _order,
        address seller,
        bytes memory _sellerMetadata,
        bytes memory sellerSig,
        address buyer,
        bytes memory _buyerMetadata,
        bytes memory buyerSig
    ) public payable nonReentrant {
        // Check signature validity
        (bool sellerSigValid, bytes32 sellerMessageHash) = checkSigValidity(
            seller,
            transactionType,
            _order,
            _sellerMetadata,
            sellerSig
        );
        require(sellerSigValid, "MarketplaceV2: invalid seller signature");

        (bool buyerSigValid, bytes32 buyerMessageHash) = checkSigValidity(
            buyer,
            transactionType,
            _order,
            _buyerMetadata,
            buyerSig
        );
        require(buyerSigValid, "MarketplaceV2: invalid buyer signature");

        // Decode bytes into structs
        Order memory order = decodeOrder(_order);
        OrderMetadata memory sellerMetadata = decodeOrderMetadata(
            _sellerMetadata
        );
        OrderMetadata memory buyerMetadata = decodeOrderMetadata(
            _buyerMetadata
        );

        return
            _atomicMatch(
                transactionType,
                order,
                seller,
                sellerMetadata,
                sellerMessageHash,
                buyer,
                buyerMetadata,
                buyerMessageHash
            );
    }

    function atomicMatchAndDeposit(
        bytes32 _transactionType,
        bytes memory _order,
        address seller,
        bytes memory _sellerMetadata,
        bytes memory sellerSig,
        address buyer,
        bytes memory _buyerMetadata,
        bytes memory buyerSig
    ) public payable {
        // 1. Get manager's(CP) address and filled amount
        (address buyerRecipient, uint256 fill) = _getBuyerRecipientAndFill(
            _transactionType,
            _order,
            seller,
            _sellerMetadata,
            buyer,
            _buyerMetadata
        );

        // 2. Conduct the atomic match
        atomicMatch(
            _transactionType,
            _order,
            seller,
            _sellerMetadata,
            sellerSig,
            buyer,
            _buyerMetadata,
            buyerSig
        );

        // 3. Get target token address
        Order memory order = decodeOrder(_order);
        address managerAddress = IGateway(gateway).nftManager(
            order.targetTokenAddress
        );

        // 4. Transfer & Deposit to the corresponding manager's address
        _transferNFT(
            _transactionType,
            order,
            fill,
            buyerRecipient,
            managerAddress
        );
    }

    function _atomicMatch(
        bytes32 transactionType,
        Order memory order,
        address seller,
        OrderMetadata memory sellerMetadata,
        bytes32 sellerMessageHash,
        address buyer,
        OrderMetadata memory buyerMetadata,
        bytes32 buyerMessageHash
    ) internal {
        /*  CHECKS  */
        checkMetaInfo(
            transactionType,
            order,
            seller,
            buyer,
            sellerMetadata,
            buyerMetadata,
            sellerMessageHash,
            buyerMessageHash
        );

        /*  EFFECTS  */
        uint256 fill = Math.min(
            sellerMetadata.maximumFill - fills[seller][sellerMessageHash],
            buyerMetadata.maximumFill - fills[buyer][buyerMessageHash]
        );
        if (sellerMetadata.forceFilled) {
            require(
                fill == sellerMetadata.maximumFill,
                "MarketplaceV2: sell order not filled"
            );
        }
        if (buyerMetadata.forceFilled) {
            require(
                fill == buyerMetadata.maximumFill,
                "MarketplaceV2: buy order not filled"
            );
        }
        executeTransfers(
            transactionType,
            order,
            fill,
            seller,
            buyer,
            sellerMetadata.recipient,
            buyerMetadata.recipient
        );
        fills[seller][sellerMessageHash] += fill;
        fills[buyer][buyerMessageHash] += fill;

        /*  LOGS  */
        emit MatchOrder(
            order.targetTokenAddress,
            order.targetTokenId,
            order.paymentTokenAddress,
            order.price,
            fill,
            seller,
            buyer,
            sellerMetadata.recipient,
            buyerMetadata.recipient,
            sellerMessageHash,
            buyerMessageHash
        );
    }

    /********************************************************************
     *                      User-called functions                       *
     ********************************************************************/

    /**
     * Revoke a single order.
     */
    function ignoreMessageHash(bytes32 messageHash) public {
        require(
            cancelled[msg.sender][messageHash] == false,
            "MarketplaceV2: order has been revoked"
        );

        cancelled[msg.sender][messageHash] = true;

        emit IgnoreMessageHash(msg.sender, messageHash);
    }

    /**
     * Revoke a bunch of orders. Parameters similar to the single version.
     */
    function ignoreMessageHashs(bytes32[] calldata messageHashs) external {
        for (uint256 i = 0; i < messageHashs.length; i++) {
            ignoreMessageHash(messageHashs[i]);
        }
    }

    /********************************************************************
     *                        Helper functions                          *
     ********************************************************************/

    /**
     * Check the validity of order metadata.
     */
    function checkMetaInfo(
        bytes32 transactionType,
        Order memory order,
        address seller,
        address buyer,
        OrderMetadata memory sellerMetadata,
        OrderMetadata memory buyerMetadata,
        bytes32 sellerMessageHash,
        bytes32 buyerMessageHash
    ) internal view {
        require(
            order.marketplaceAddress == address(this),
            "MarketplaceV2: wrong market address"
        );
        require(
            paymentTokens[order.paymentTokenAddress] == true,
            "MarketplaceV2: invalid payment method"
        );

        require(
            sellerMetadata.sellOrBuy == true,
            "MarketplaceV2: seller should sell"
        );
        require(
            buyerMetadata.sellOrBuy == false,
            "MarketplaceV2: buyer should buy"
        );

        require(
            !cancelled[seller][sellerMessageHash],
            "MarketplaceV2: sell order has been revoked"
        );
        require(
            !cancelled[buyer][buyerMessageHash],
            "MarketplaceV2: buy order has been revoked"
        );
        require(
            fills[seller][sellerMessageHash] < sellerMetadata.maximumFill,
            "MarketplaceV2: sell order has been filled"
        );
        require(
            fills[buyer][buyerMessageHash] < buyerMetadata.maximumFill,
            "MarketplaceV2: buy order has been filled"
        );
        require(
            sellerMetadata.listingTime < block.timestamp,
            "MarketplaceV2: sell order not in effect"
        );
        require(
            sellerMetadata.expirationTime == 0 ||
                sellerMetadata.expirationTime > block.timestamp,
            "MarketplaceV2: sell order expired"
        );
        require(
            buyerMetadata.listingTime < block.timestamp,
            "MarketplaceV2: buy order not in effect"
        );
        require(
            buyerMetadata.expirationTime == 0 ||
                buyerMetadata.expirationTime > block.timestamp,
            "MarketplaceV2: buy order expired"
        );

        // Check mode-specific parameters
        if (transactionType == TRANSACT_ERC721) {
            require(
                sellerMetadata.maximumFill == 1 &&
                    sellerMetadata.maximumFill == 1,
                "MarketplaceV2: invalid maximumFill"
            );
        }
    }

    /**
     * Authority check
     * The signature of an address `x` is valid if
     * 1. `msg.sender` is `x`, or
     * 2. the signature is signed with `x`'s private key
     */
    function checkSigValidity(
        address x,
        bytes32 transactionType,
        bytes memory order,
        bytes memory metadata,
        bytes memory sig
    ) internal view returns (bool valid, bytes32 messageHash) {
        messageHash = getMessageHash(transactionType, order, metadata);
        valid =
            x == msg.sender ||
            x == ECDSA.recover(getEthSignedMessageHash(messageHash), sig);
    }

    function getEthSignedMessageHash(
        bytes32 criteriaMessageHash
    ) internal pure returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(criteriaMessageHash);
    }

    /**
     * @dev Calculate order digest.
     * @notice messageHash is used as index in `cancelled` and `fills`.
     */
    function getMessageHash(
        bytes32 transactionType,
        bytes memory order,
        bytes memory metadata
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(transactionType, order, metadata));
    }

    /**
     * Execute the transfers of ERC721 and ERC1155 tokens.
     *
     * @param transactionType either TRANSACT_ERC721 or TRANSACT_ERC1155
     * @param order the order to be executed
     * @param fill the number of NFTs to be transferred
     * @param from the source address of the transfer
     * @param to the destination address of the transfer
     */
    function _transferNFT(
        bytes32 transactionType,
        Order memory order,
        uint256 fill,
        address from,
        address to
    ) internal {
        if (transactionType == TRANSACT_ERC721) {
            require(fill == 1, "MarketplaceV2: invalid fill");
            // Check balance requirement
            IERC721 nft = IERC721(order.targetTokenAddress);

            // Transfer ERC721
            nft.safeTransferFrom(from, to, order.targetTokenId);
        } else if (transactionType == TRANSACT_ERC1155) {
            IERC1155 nft = IERC1155(order.targetTokenAddress);

            // Transfer ERC1155
            nft.safeTransferFrom(from, to, order.targetTokenId, fill, "");
        }
    }

    /**
     * Execute the transfers of payment tokens.
     *
     * @param order the order to be executed
     * @param fill the number of NFTs to be transacted, hence, the number of fungible tokens
     * to be transferred is `order.price * fill`
     * @param from the source address of the transfer
     * @param to the destination address of the transfer
     */
    function _transferFT(
        Order memory order,
        uint256 fill,
        address from,
        address to
    ) internal {
        uint256 totalCost = order.price * fill;

        // Calculate ERC20 fees
        uint256 fee2service = (totalCost * order.serviceFee) / BASE;
        uint256 royaltyFee = (totalCost * order.royaltyFee) / BASE;

        (bool success, bytes memory result) = order
            .targetTokenAddress
            .staticcall(
                abi.encodeWithSelector(
                    IERC2981.royaltyInfo.selector,
                    order.targetTokenId,
                    order.price
                )
            );

        if (success && result.length == 64) {
            (order.royaltyFeeRecipient, royaltyFee) = abi.decode(
                result,
                (address, uint256)
            );
            require(
                totalCost > fee2service + royaltyFee,
                "MarketplaceV2: wrong royalty fee"
            );
        }

        address paymentTokenAddress = order.paymentTokenAddress;

        if (paymentTokenAddress == address(0)) {
            require(
                msg.value == totalCost,
                "MarketplaceV2: wrong native token amount"
            );

            if (fee2service > 0) {
                (bool sent2service, ) = serviceFeeRecipient.call{
                    value: fee2service
                }("");
                require(
                    sent2service,
                    "MarketplaceV2: failed to send native tokens to service"
                );
            }
            if (royaltyFee > 0) {
                (bool sent2cp, ) = order.royaltyFeeRecipient.call{
                    value: royaltyFee
                }("");
                require(
                    sent2cp,
                    "MarketplaceV2: failed to send native tokens to cp"
                );
            }
            (bool sent2seller, ) = to.call{
                value: totalCost - fee2service - royaltyFee
            }("");
            require(
                sent2seller,
                "MarketplaceV2: failed to send native tokens to seller"
            );
        } else {
            // Check balance requirement
            IERC20Upgradeable paymentContract = IERC20Upgradeable(
                order.paymentTokenAddress
            );
            require(
                paymentContract.balanceOf(from) >= totalCost,
                "MarketplaceV2: buyer doesn't have enough token to buy this item"
            );
            require(
                paymentContract.allowance(from, address(this)) >= totalCost,
                "MarketplaceV2: buyer doesn't approve marketplace to spend payment amount"
            );

            // Transfer ERC20 to multiple addresses
            if (fee2service > 0) {
                paymentContract.safeTransferFrom(
                    from,
                    serviceFeeRecipient,
                    fee2service
                );
            }
            if (royaltyFee > 0) {
                paymentContract.safeTransferFrom(
                    from,
                    order.royaltyFeeRecipient,
                    royaltyFee
                );
            }
            paymentContract.safeTransferFrom(
                from,
                to,
                totalCost - fee2service - royaltyFee
            );
        }
    }

    function _checkMinted(
        bytes32 transactionType,
        address tokenAddress,
        uint256 tokenId,
        address seller
    ) internal view returns (uint256 mintedAmount) {
        if (transactionType == TRANSACT_ERC721) {
            mintedAmount = 0;
            try IERC721(tokenAddress).ownerOf(tokenId) returns (address owner) {
                // If the NFT has a non-zero owner, it's minted.
                // Otherwise, it's unminted.
                if (owner != address(0)) mintedAmount = 1;
            } catch Error(string memory) {
                // In most cases, querying the owner of an unminted NFT
                // will result in a revert.
            }
        } else if (transactionType == TRANSACT_ERC1155) {
            mintedAmount = IERC1155(tokenAddress).balanceOf(seller, tokenId);
        } else {
            revert("MarketplaceV2: transaction type is not supported");
        }
    }

    /**
     * Mint NFTs directly to the buyer's address
     *
     * @param transactionType either TRANSACT_ERC721 or TRANSACT_ERC1155
     * @param order the order to be executed
     * @param toBeMinted the number of NFTs to be minted to the buyer address
     * @param from the seller address
     * @param to the buyer address
     */
    function _mintNFT(
        bytes32 transactionType,
        Order memory order,
        uint256 toBeMinted,
        address from,
        address to
    ) internal {
        require(
            IGateway(gateway).nftManager(order.targetTokenAddress) == from,
            "MarketplaceV2: only manager can mint at sale"
        );
        if (transactionType == TRANSACT_ERC721) {
            require(toBeMinted == 1, "MarketplaceV2: invalid fill");
            IGateway(gateway).ERC721_mint(
                order.targetTokenAddress,
                to,
                order.targetTokenId
            );
        } else if (transactionType == TRANSACT_ERC1155) {
            IGateway(gateway).ERC1155_mint(
                order.targetTokenAddress,
                to,
                order.targetTokenId,
                toBeMinted,
                ""
            );
        }
    }

    /**
     * Execute the actual token transfers
     *
     * @param transactionType either TRANSACT_ERC721 or TRANSACT_ERC1155
     * @param order the order to be executed
     * @param fill the number of NFTs to be transferred
     * @param seller the source address of the transfer
     * @param buyer the destination address of the transfer
     * @param sellRecipient the address that receives the payment tokens
     * @param buyRecipient the address that receives the nft tokens
     */
    function executeTransfers(
        bytes32 transactionType,
        Order memory order,
        uint256 fill,
        address seller,
        address buyer,
        address sellRecipient,
        address buyRecipient
    ) internal {
        // 1. Transfer FTs from buyer to sellRecipient
        _transferFT(order, fill, buyer, sellRecipient);

        // 2. Transfer NFTs from seller to buyRecipient
        if (!order.allowMint) {
            _transferNFT(transactionType, order, fill, seller, buyRecipient);
        } else {
            // Check if the NFTs have been minted
            uint256 mintedAmount = _checkMinted(
                transactionType,
                order.targetTokenAddress,
                order.targetTokenId,
                seller
            );

            if (mintedAmount >= fill) {
                _transferNFT(
                    transactionType,
                    order,
                    fill,
                    seller,
                    buyRecipient
                );
            } else {
                // 1. Transfer existing tokens to the recipient
                if (mintedAmount > 0) {
                    _transferNFT(
                        transactionType,
                        order,
                        mintedAmount,
                        seller,
                        buyRecipient
                    );
                }
                // 2. Mint the remaining tokens directly to the recipient
                _mintNFT(
                    transactionType,
                    order,
                    fill - mintedAmount,
                    seller,
                    buyRecipient
                );
            }
        }
    }

    function decodeOrder(
        bytes memory _order
    ) internal pure returns (Order memory) {
        (
            address marketplaceAddress,
            address targetTokenAddress,
            uint256 targetTokenId,
            address paymentTokenAddress,
            uint256 price,
            uint256 serviceFee,
            uint256 royaltyFee,
            address royaltyFeeRecipient,
            bool allowMint
        ) = abi.decode(
                _order,
                (
                    address,
                    address,
                    uint256,
                    address,
                    uint256,
                    uint256,
                    uint256,
                    address,
                    bool
                )
            );
        return
            Order(
                marketplaceAddress,
                targetTokenAddress,
                targetTokenId,
                paymentTokenAddress,
                price,
                serviceFee,
                royaltyFee,
                royaltyFeeRecipient,
                allowMint
            );
    }

    function decodeOrderMetadata(
        bytes memory _metadata
    ) internal pure returns (OrderMetadata memory) {
        (
            bool sellOrBuy,
            address recipient,
            uint256 listingTime,
            uint256 expirationTime,
            uint256 maximumFill,
            bool forceFilled,
            uint256 salt
        ) = abi.decode(
                _metadata,
                (bool, address, uint256, uint256, uint256, bool, uint256)
            );
        return
            OrderMetadata(
                sellOrBuy,
                recipient,
                listingTime,
                expirationTime,
                maximumFill,
                forceFilled,
                salt
            );
    }

    function _getBuyerRecipientAndFill(
        bytes32 _transactionType,
        bytes memory _order,
        address seller,
        bytes memory _sellerMetadata,
        address buyer,
        bytes memory _buyerMetadata
    ) internal view returns (address, uint256) {
        OrderMetadata memory sellerMetadata = decodeOrderMetadata(
            _sellerMetadata
        );
        OrderMetadata memory buyerMetadata = decodeOrderMetadata(
            _buyerMetadata
        );

        bytes32 sellerMessageHash = getMessageHash(
            _transactionType,
            _order,
            _sellerMetadata
        );
        bytes32 buyerMessageHash = getMessageHash(
            _transactionType,
            _order,
            _buyerMetadata
        );

        /*  EFFECTS  */
        uint256 fill = Math.min(
            sellerMetadata.maximumFill - fills[seller][sellerMessageHash],
            buyerMetadata.maximumFill - fills[buyer][buyerMessageHash]
        );
        return (buyerMetadata.recipient, fill);
    }
}
