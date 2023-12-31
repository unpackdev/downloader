// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";
import "./IERC1155.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AdminControl.sol";
import "./MerkleProof.sol";
import "./ECDSA.sol";
import "./IERC721CreatorCore.sol";
import "./IERC1155CreatorCore.sol";

interface IPriceFeed {
    function getLatestPrice(
        uint256 amount,
        address fiat
    ) external view returns (uint256);
}

interface IRoyaltyEngine {
    function getRoyalty(
        address collectionAddress,
        uint256 tokenId
    ) external view returns (address payable[] memory, uint256[] memory);
}

contract OffchainAuction is ReentrancyGuard, AdminControl {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    /// @notice The metadata for a given Order
    /// @param nftContractAddress the nft contract address
    /// @param tokenId the Nft token Id
    /// @param quantityOf1155 the quantity of 1155 for auction
    /// @param tokenOwnerAddress the address of the nft owner of the auction
    /// @param highestBidder the address of the highest bidder
    /// @param highestBid the amount to be paid by the highest bid
    /// @param paymentCurrency the payment currency for seller requirement
    /// @param paymentStatus the status flat to be paid by fiat or crypto
    /// @param settlementList the settlement address and payment percentage provided in basis points
    struct createAuctionList {
        address nftContractAddress;
        uint256 tokenId;
        uint256 quantityOf1155;
        address tokenOwnerAddress;
        address highestBidder;
        uint256 highestBid;
        address paymentCurrency; // cant support multiple currency here
        PaymentStatus paymentStatus;
        settlementList settlement;
    }

    enum PaymentStatus {
        fiat,
        crypto
    }

    /// @notice The metadata for a given Order
    /// @param paymentSettlementAddress the settlement address for the listed tokens
    /// @param taxSettlementAddress the taxsettlement address for settlement of tax fee
    /// @param commissionAddress the commission address for settlement of commission fee
    /// @param platformSettlementAddress the platform address for settlement of platform fee
    /// @param commissionFeePercentage the commission fee given in basis points
    /// @param platformFeePercentage the platform fee given in basis points
    struct settlementList {
        address paymentSettlementAddress;
        address taxSettlementAddress;
        address commissionAddress;
        address platformSettlementAddress;
        uint16 commissionFeePercentage; // in basis points
        uint16 platformFeePercentage; // in basis points
    }

    /// @notice Emitted when an auction is ended
    /// @param auctionId the id of the created auction
    /// @param createdDetails the details of the auction
    /// @param tax the tax amount highestbidder pays
    event AuctionEnded(
        string indexed auctionId,
        createAuctionList createdDetails,
        uint256 tax
    );

    /// @notice Emitted when an Royalty Payout is executed
    /// @param tokenId The NFT tokenId
    /// @param tokenContract The NFT Contract address
    /// @param recipient Address of the Royalty Recipient
    /// @param amount Amount sent to the royalty recipient address
    event RoyaltyPayout(
        address tokenContract,
        uint256 tokenId,
        address recipient,
        uint256 amount
    );

    // @notice emits an event when platformAddress is updated
    /// @param platformAddress The existing platformAddress
    /// @param updatedPlatformAddress The updated platformAddress
    event PlatformAddressUpdated(address platformAddress,address updatedPlatformAddress);

    /// @notice emits an event when platformFeePercentage is updated
    /// @param platformFeePercentage The existing platformFeePercentage
    /// @param updatedPlatformFeePercentage The updated platformFeePercentage
    event PlatformFeePercentageUpdated(uint16 platformFeePercentage,uint16 updatedPlatformFeePercentage);

    /// @notice emits an event when a royalty address is updated.
    /// @param royaltySupport The royaltySupport address
    /// @param updatedRoyaltySupport The new royaltySupport address
    event RoyaltySupportUpdated(
        IRoyaltyEngine royaltySupport,
        address updatedRoyaltySupport
    );

    // Interface ID constants
    bytes4 private constant ERC721_INTERFACE_ID = 0x80ac58cd;
    bytes4 private constant ERC1155_INTERFACE_ID = 0xd9b67a26;

    // Platform Address
    address payable public platformAddress;

    // Fee percentage to the Platform
    uint16 public platformFeePercentage;

    // The address of the royaltySupport to use via this contract
    IRoyaltyEngine public royaltySupport;

    // The address of the pricefeed
    IPriceFeed public pricefeedAddress;

    // validating saleId
    mapping(string => bool) usedAuctionId;

    /// @param _platformAddress The Platform Address
    /// @param _platformFeePercentage The Platform fee percentage
    /// @param _royaltyAddress the royalty contract address
    /// @param _pricefeedAddress PriceFeed Contract Address
    constructor(
        address _platformAddress,
        uint16 _platformFeePercentage,
        IRoyaltyEngine _royaltyAddress,
        IPriceFeed _pricefeedAddress
    ) {
        require(_platformAddress != address(0), "Invalid Platform Address");
        require(
            _platformFeePercentage < 10000,
            "platformFee should not be more than 100 %"
        );

        platformAddress = payable(_platformAddress);
        platformFeePercentage = _platformFeePercentage;
        royaltySupport = _royaltyAddress;
        pricefeedAddress = _pricefeedAddress;
    }

    /// @notice Ending an Auction based on the signature verification with highest bidder
    function executeAuction(
        createAuctionList calldata order,
        string calldata auctionId,
        bytes memory signature,
        address signer,
        uint32 expirationTime,
        uint256 tax
    ) external payable nonReentrant {
        require(!usedAuctionId[auctionId], "auction Id is already used");
        // Validating the InterfaceID
        require(
            (IERC165(order.nftContractAddress).supportsInterface(
                ERC721_INTERFACE_ID
            ) ||
                IERC165(order.nftContractAddress).supportsInterface(
                    ERC1155_INTERFACE_ID
                )),
            "tokenContract does not support ERC721 or ERC1155 interface"
        );
        require(isAdmin(signer), "signer should be admin");
        bytes32 paymenthash = getHashData(order, auctionId, expirationTime);
        require(
            _verifySignature(paymenthash, signature, signer),
            "signature invalid"
        );

        // Transferring  the NFT tokens to the highest Bidder
        _tokenTransaction(
            order.tokenOwnerAddress,
            order.nftContractAddress,
            order.highestBidder, //nftSettlementAddress,
            order.tokenId,
            order.quantityOf1155
        );
        paymentTransaction(order, tax);

        usedAuctionId[auctionId] = true;

        emit AuctionEnded(auctionId, order, tax);
    }

    function paymentTransaction(
        createAuctionList memory order,
        uint256 tax
    ) internal {
        settlementList memory paymentSettlement = order.settlement;

        uint256 paymentAmount;
        // getting the price using saleId
        if (order.paymentStatus == PaymentStatus.fiat) {
            paymentAmount = pricefeedAddress.getLatestPrice(
                order.highestBid,
                order.paymentCurrency
            );
        } else {
            paymentAmount = order.highestBid;
        }
        require(
            paymentAmount != 0,
            "Please provide valid supported ERC20/ETH address"
        );
        address paymentSettler = isAdmin(msg.sender)
            ? order.highestBidder
            : msg.sender;
        if (order.paymentCurrency == address(0)) {
            require(
                (msg.value - tax) >= paymentAmount,
                "Insufficient funds or invalid amount. You need to pass a valid amount to complete this transaction"
            );
            paymentAmount = msg.value - tax;
        } else {
            // checks the buyer has sufficient amount to buy the nft
            require(
                IERC20(order.paymentCurrency).balanceOf(paymentSettler) >=
                    paymentAmount,
                "Insufficient funds. You should have sufficient balance to complete this transaction"
            );
            // checks the buyer has provided approval for the contract to transfer the amount
            require(
                IERC20(order.paymentCurrency).allowance(
                    paymentSettler,
                    address(this)
                ) >= paymentAmount,
                "Insufficient approval from an ERC20 Token. Please provide approval to this contract and try again"
            );
        }

        // Tax Settlement
        if (tax > 0) {
            _handlePayment(
                paymentSettler,
                payable(paymentSettlement.taxSettlementAddress),
                order.paymentCurrency,
                tax
            );
        }

        // PlatformFee Settlement
        uint256 commessionAmount;

        // transferring the platformFee amount  to the platformSettlementAddress
        if (
            paymentSettlement.platformSettlementAddress != address(0) &&
            paymentSettlement.platformFeePercentage > 0
        ) {
            _handlePayment(
                paymentSettler,
                payable(paymentSettlement.platformSettlementAddress),
                order.paymentCurrency,
                commessionAmount += ((paymentAmount *
                    paymentSettlement.platformFeePercentage) / 10000)
            );
        } else if (platformAddress != address(0) && platformFeePercentage > 0) {
            _handlePayment(
                paymentSettler,
                platformAddress,
                order.paymentCurrency,
                commessionAmount += ((paymentAmount * platformFeePercentage) /
                    10000)
            );
        }

        // transferring the commissionfee amount  to the commissionAddress
        if (
            paymentSettlement.commissionAddress != address(0) &&
            paymentSettlement.commissionFeePercentage > 0
        ) {
            commessionAmount += ((paymentAmount *
                paymentSettlement.commissionFeePercentage) / 10000);
            _handlePayment(
                paymentSettler,
                payable(paymentSettlement.commissionAddress),
                order.paymentCurrency,
                ((paymentAmount * paymentSettlement.commissionFeePercentage) /
                    10000)
            );
        }

        paymentAmount = paymentAmount - commessionAmount;

        // royalty fee payout settlement
        if (royaltySupport != IRoyaltyEngine(address(0))) {
            // Royalty Fee Payout Settlement
            paymentAmount = _handleRoyaltyEnginePayout(
                paymentSettler,
                order.nftContractAddress,
                order.tokenId,
                paymentAmount,
                order.paymentCurrency
            );
        }

        // Transfer the balance to the tokenOwner
        _handlePayment(
            paymentSettler,
            payable(paymentSettlement.paymentSettlementAddress),
            order.paymentCurrency,
            paymentAmount
        );
    }

    /// @notice The details to be provided to buy the token
    /// @param _tokenOwner the owner of the nft token
    /// @param _tokenContract the address of the nft contract
    /// @param _buyer the address of the buyer
    /// @param _tokenId the token Id of the owner owns
    /// @param _quantity the quantity of tokens for 1155 only
    function _tokenTransaction(
        address _tokenOwner,
        address _tokenContract,
        address _buyer,
        uint256 _tokenId,
        uint256 _quantity
    ) private {
        if (IERC165(_tokenContract).supportsInterface(ERC721_INTERFACE_ID)) {
            // minting the token
            if (_tokenId == 0) {
                IERC721CreatorCore(_tokenContract).mintExtension(_buyer);
            } else {
                require(
                    IERC721(_tokenContract).ownerOf(_tokenId) == _tokenOwner,
                    "maker is not the owner"
                );
                // Transferring the ERC721
                IERC721(_tokenContract).safeTransferFrom(
                    _tokenOwner,
                    _buyer,
                    _tokenId
                );
            }
        } else if (
            IERC165(_tokenContract).supportsInterface(ERC1155_INTERFACE_ID)
        ) {
            uint256 ownerBalance = IERC1155(_tokenContract).balanceOf(
                _tokenOwner,
                _tokenId
            );
            require(
                _quantity <= ownerBalance && _quantity > 0,
                "Insufficeint token balance"
            );
            if (_tokenId == 0) {
                address[] memory to = new address[](1);
                uint256[] memory amounts = new uint256[](1);
                string[] memory uris;
                to[0] = _buyer;
                amounts[0] = _quantity;
                IERC1155CreatorCore(_tokenContract).mintExtensionNew(
                    to,
                    amounts,
                    uris
                );
            } else {
                // Transferring the ERC1155
                IERC1155(_tokenContract).safeTransferFrom(
                    _tokenOwner,
                    _buyer,
                    _tokenId,
                    _quantity,
                    "0x"
                );
            }
        }
    }

    /// @notice Settle the Payment based on the given parameters
    /// @param _from Address from whom the amount to be transferred
    /// @param _to Address to whom need to settle the payment
    /// @param _paymentToken Address of the ERC20 Payment Token
    /// @param _amount Amount to be transferred
    function _handlePayment(
        address _from,
        address payable _to,
        address _paymentToken,
        uint256 _amount
    ) private {
        bool success;
        if (_paymentToken == address(0)) {
            // transferreng the native currency
            (success, ) = _to.call{value: _amount}(new bytes(0));
            require(success, "transaction failed");
        } else {
            // transferring ERC20 currency
            IERC20(_paymentToken).safeTransferFrom(_from, _to, _amount);
        }
    }

    /// @notice Settle the Royalty Payment based on the given parameters
    /// @param _buyer the address of the buyer
    /// @param _tokenContract The NFT Contract address
    /// @param _tokenId The NFT tokenId
    /// @param _amount Amount to be transferred
    /// @param _payoutCurrency Address of the ERC20 Payout
    function _handleRoyaltyEnginePayout(
        address _buyer,
        address _tokenContract,
        uint256 _tokenId,
        uint256 _amount,
        address _payoutCurrency
    ) private returns (uint256) {
        // Store the initial amount
        uint256 amountRemaining = _amount;
        uint256 feeAmount;

        // Verifying whether the token contract supports Royalties of supported interfaces
        (
            address payable[] memory recipients,
            uint256[] memory bps // Royalty amount denominated in basis points
        ) = royaltySupport.getRoyalty(_tokenContract, _tokenId);

        // Store the number of recipients
        uint256 totalRecipients = recipients.length;

        // If there are no royalties, return the initial amount
        if (totalRecipients == 0) return _amount;

        // Payout each royalty
        for (uint256 i = 0; i < totalRecipients; ) {
            // Cache the recipient and amount
            address payable recipient = recipients[i];

            feeAmount = (bps[i] * _amount) / 10000;

            // Ensure that we aren't somehow paying out more than we have
            require(amountRemaining >= feeAmount, "insolvent");

            _handlePayment(_buyer, recipient, _payoutCurrency, feeAmount);
            emit RoyaltyPayout(_tokenContract, _tokenId, recipient, feeAmount);

            // Cannot underflow as remaining amount is ensured to be greater than or equal to royalty amount
            unchecked {
                amountRemaining -= feeAmount;
                ++i;
            }
        }

        return amountRemaining;
    }

    function getHashData(
        createAuctionList memory order,
        string memory auctionId,
        uint32 expirationTime
    ) public view returns (bytes32 paymenthash) {
        require(
            expirationTime >= block.timestamp,
            "discount signature is already expired"
        );
        settlementList memory paymentSettlement = order.settlement;
        bytes32 value = keccak256(
            abi.encodePacked(
                order.highestBid,
                order.highestBidder, 
                order.nftContractAddress,
                order.tokenId, 
                order.quantityOf1155, 
                order.paymentCurrency, 
                block.chainid,
                expirationTime
            )
        );

        paymenthash = keccak256(
            abi.encodePacked(
                value,
                auctionId, 
                order.tokenOwnerAddress, 
                paymentSettlement.paymentSettlementAddress,
                paymentSettlement.taxSettlementAddress,
                paymentSettlement.platformSettlementAddress,
                paymentSettlement.platformFeePercentage,
                paymentSettlement.commissionAddress,
                paymentSettlement.commissionFeePercentage
            )
        );
    }

    /// @notice Withdraw the funds to owner
    function withdraw(address paymentCurrency) external adminRequired {
        bool success;
        address payable to = payable(msg.sender);
        if (paymentCurrency == address(0)) {
            (success, ) = to.call{value: address(this).balance}(new bytes(0));
            require(success, "withdraw to withdraw funds. Please try again");
        } else if (paymentCurrency != address(0)) {
            // transferring ERC20 currency
            uint256 amount = IERC20(paymentCurrency).balanceOf(address(this));
            IERC20(paymentCurrency).safeTransfer(to, amount);
        }
    }

    /// @notice Update the Platform Fee Percentage
    /// @param _platformFeePercentage The Platform fee percentage
    function updatePlatformFeePercentage(
        uint16 _platformFeePercentage
    ) external adminRequired {
        require(
            _platformFeePercentage < 10000,
            "platformFee should not be more than 100 %"
        );
        emit PlatformFeePercentageUpdated(platformFeePercentage,_platformFeePercentage);
        platformFeePercentage = _platformFeePercentage;
    }

    /// @notice Update the platform Address
    /// @param _platformAddress The Platform Address
    function updatePlatformAddress(
        address _platformAddress
    ) external adminRequired {
        require(_platformAddress != address(0), "Invalid Platform Address");
        emit PlatformAddressUpdated(platformAddress,_platformAddress);
        platformAddress = payable(_platformAddress);
    }

    /// @notice Update the _royaltySupport Address
    /// @param _royaltySupport The royaltyEngine Address
    function updateRoyaltySupport(
        address _royaltySupport
    ) external adminRequired {
       emit RoyaltySupportUpdated(royaltySupport,_royaltySupport);
       royaltySupport = IRoyaltyEngine(_royaltySupport);
    }

    /// @notice Verifies the Signature with the required Signer
    /// @param value the hash of the order details
    /// @param _signature Signature generated when signing the hash(order details) by the signer
    /// @param _signer Address of the Signer
    function _verifySignature(
        bytes32 value,
        bytes memory _signature,
        address _signer
    ) internal pure returns (bool) {
        return value.toEthSignedMessageHash().recover(_signature) == _signer;
    }

    receive() external payable {}

    fallback() external payable {}
}