//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

// import "./ERC1155URIStorageUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
// import "./ERC2981Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./OwnableUpgradeable.sol";
import "./IFanvToken.sol";
import "./ITemplate1155.sol";
import "./ITemplate721.sol";
import "./FNVvoucher.sol";


contract Secondbuy is EIP712Upgradeable,OwnableUpgradeable {
    // string private constant SIGNING_DOMAIN = "Secondary";
    // string private constant SIGNATURE_VERSION = "2";
    address public Admin;
    address fanverseContract;
    bytes4 public constant id721Upgradeable =
        type(IERC721Upgradeable).interfaceId;
    bytes4 public constant id721 = type(IERC721).interfaceId;
    bytes4 public constant id1155Upgradeable =
        type(IERC1155Upgradeable).interfaceId;
    bytes4 public constant id1155 = type(IERC1155).interfaceId;
    bytes4 private constant FUNC_SELECTOR =
        bytes4(keccak256("royaltyInfo(uint256,uint256)"));
    mapping(uint256 => bool) public batchAmountStatus; // mapping to keep track of validity of voucher
    mapping(uint256 => uint256) public nftBatchamountleft; // mapping to keep track of nfts left in the voucher
    mapping(uint256 => bool) public usedVoucher;    //mapping to keep a check on reusability of same voucher
    uint256 public platformFees;
    IFanvToken public fanvToken;
    event secondaryFixBuy(
        address indexed seller,
        address indexed buyer,
        uint256 tokenId,
        uint256 nftBatchAmount,
        uint256 nftPrice
    );
    event secondaryAuc(
        address indexed seller,
        address indexed buyer,
        uint256 tokenId,
        uint256 nftPrice
    );

/**
 * Constructor function for disabling the initialization of the implementation.
 */
    constructor() {
        // _disableInitializers();
    }
    /**
 * @notice Initializes the contract with the provided parameters.
 * @param _platformFees The platform fees value.
 * @param _adminAddress The address of the admin.
 * @param _fanvContract The address of the Fanverse contract.
 * @dev This function is external and initializer.
 * @dev It sets the admin address, initializes the FanvToken contract, and sets the platform fees and Fanverse contract addresses.
 * @dev Throws an error with the message "ACZ" if the provided admin address is the zero address.

 */
    function initialize(
        uint256 _platformFees,
        address _adminAddress,
        address _fanvContract
    ) external initializer {
        //ACZ--> Admin address can't be zero
        require(_adminAddress != address(0), "ACZ");
        __EIP712_init("Secondary", "2");
        __Ownable_init();
        platformFees = _platformFees;
        fanverseContract = _fanvContract;
        Admin = _adminAddress;
    }

/**
 * @dev this is an internal function that generates a 32 byte hash of a struct like object 
 * @param voucher struct like voucher that indicates all the required information of ERC1155 tokens of which the hash is to be generate
 */
    function _hashpriMarketItem(
        FNVvoucher.marketItem memory voucher
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "marketItem(uint256 tokenId,uint256 unitPrice,uint256 nftBatchAmount,uint256 counterValue,address nftAddress,address owner,string tokenURI,bool listed,bool isEth)"
                        ),
                        voucher.tokenId,
                        voucher.unitPrice,
                        voucher.nftBatchAmount,
                        voucher.counterValue,
                        voucher.nftAddress,
                        voucher.owner,
                        keccak256(bytes(voucher.tokenURI)),
                        voucher.listed,
                        voucher.isEth
                    )
                )
            );
    }

    /**
     * @notice Verifies the signature of a market item using the provided voucher and recovers the signer's address.
     * @param voucher The market item struct containing the item details and signature.
     * @return The address of the signer if the signature is valid, otherwise returns address(0).
     * @dev This function is internal and view.
     * @dev It calculates the digest by calling the _hashpriMarketItem function with the voucher.
     * @dev The ECDSAUpgradeable.recover function is then called with the digest and the voucher's signature to recover the signer's address.
     * @dev If the signature is valid, the signer's address is returned. Otherwise, address(0) is returned.
     */
    function _verifypriListing(
        FNVvoucher.marketItem memory voucher
    ) internal view returns (address) {
        bytes32 digest = _hashpriMarketItem(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

/**
 * @dev this is an internal function that generates a 32 byte hash of a struct like object 
 * @param auctionSeller struct like voucher that indicates all the required information of ERC1155 tokens of which the hash is to be generate
 */
    function _hashSecAuctionItemSeller(
        FNVvoucher.secAuctionItemSeller memory auctionSeller
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "secAuctionItemSeller(uint256 minimumBid,uint256 tokenId,uint256 nftBatchAmount,address nftAddress,address owner,string tokenURI,bool isEth)"
                        ),
                        auctionSeller.minimumBid,
                        auctionSeller.tokenId,
                        auctionSeller.nftBatchAmount,
                        auctionSeller.nftAddress,
                        auctionSeller.owner,
                        keccak256(bytes(auctionSeller.tokenURI)),
                        auctionSeller.isEth
                    )
                )
            );
    }

    /**
     * @notice Verifies the signature of a secondary auction item seller using the provided auctionSeller struct and recovers the signer's address.
     * @param auctionSeller The secondary auction item seller struct containing the item details and signature.
     * @return The address of the signer if the signature is valid, otherwise returns address(0).
     * @dev This function is internal and view.
     * @dev It calculates the digest by calling the _hashSecAuctionItemSeller function with the auctionSeller.
     * @dev The ECDSAUpgradeable.recover function is then called with the digest and the auctionSeller's signature to recover the signer's address.
     * @dev If the signature is valid, the signer's address is returned. Otherwise, address(0) is returned.
     */

    function _verifySecAuctionItemSeller(
        FNVvoucher.secAuctionItemSeller memory auctionSeller
    ) internal view returns (address) {
        bytes32 digest = _hashSecAuctionItemSeller(auctionSeller);
        return ECDSAUpgradeable.recover(digest, auctionSeller.signature);
    }

    function _hashAuctionItemBuyer(
        FNVvoucher.auctionItemBuyer memory auctionBuyer
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "auctionItemBuyer(uint256 tokenId,uint256 nftBatchAmount,uint256 pricePaid,address nftAddress,address buyer,string tokenURI)"
                        ),
                        auctionBuyer.tokenId,
                        auctionBuyer.nftBatchAmount,
                        auctionBuyer.pricePaid,
                        auctionBuyer.nftAddress,
                        auctionBuyer.buyer,
                        keccak256(bytes(auctionBuyer.tokenURI))
                    )
                )
            );
    }

    /**
     * @notice Verifies the signature of an auction item buyer using the provided auctionBuyer struct and recovers the signer's address.
     * @param auctionBuyer The auction item buyer struct containing the item details and signature.
     * @return The address of the signer if the signature is valid, otherwise returns address(0).
     * @dev This function is internal and view.
     * @dev It calculates the digest by calling the _hashAuctionItemBuyer function with the auctionBuyer.
     * @dev The ECDSAUpgradeable.recover function is then called with the digest and the auctionBuyer's signature to recover the signer's address.
     * @dev If the signature is valid, the signer's address is returned. Otherwise, address(0) is returned.
     */

    function _verifyAuctionItemBuyer(
        FNVvoucher.auctionItemBuyer memory auctionBuyer
    ) internal view returns (address) {
        bytes32 digest = _hashAuctionItemBuyer(auctionBuyer);
        return ECDSAUpgradeable.recover(digest, auctionBuyer.signature);
    }

    /**
     * @notice Processes the winning of a secondary auction by the buyer.
     * @param auctionSeller The struct containing information about the seller and the auction item.
     * @param auctionBuyer The struct containing information about the buyer and the auction transaction.
     * @dev This function is public and payable.
     * @dev It calls the auctionWinnerFlow function to handle the necessary steps for finalizing the auction.
     * @dev After the auction is finalized, it emits a secondaryAuc event with the relevant information.
     * @dev This function allows the buyer to complete the secondary auction and emit an event to notify interested parties.
     */
    function secondaryAuctionWinner(
        FNVvoucher.secAuctionItemSeller memory auctionSeller,
        FNVvoucher.auctionItemBuyer memory auctionBuyer
    ) public payable {
        auctionWinnerFlow(auctionSeller, auctionBuyer);
        emit secondaryAuc(
            auctionSeller.owner,
            auctionBuyer.buyer,
            auctionSeller.tokenId,
            auctionBuyer.pricePaid
        );
    }

    function auctionWinnerFlow(
        FNVvoucher.secAuctionItemSeller memory auctionSeller,
        FNVvoucher.auctionItemBuyer memory auctionBuyer
    ) internal {
        //SA:CNB--> Secondary Auction: Caller is not buyer
        require(auctionBuyer.buyer == msg.sender, "SA:CNB");
        //SA:TBNS--> Seconday Auction: Seller and buyer tokenId are not same
        require(auctionSeller.tokenId == auctionBuyer.tokenId, "SA:TBNS");
        //SA:ASBNS--> Secondary Auction: NFT address of seller and buyer tokenId not same
        require(
            auctionSeller.nftAddress == auctionBuyer.nftAddress,
            "SA:ASBNS"
        );
        //SA:IA--> Secondary Auction: Invalid Amount
        require(
            auctionSeller.nftBatchAmount >= auctionBuyer.nftBatchAmount,
            "SA:IA"
        );
        //SA:EST--> Secondary Auction: Enter the same Token Uri
        require(
            keccak256(abi.encode(auctionSeller.tokenURI)) ==
                keccak256(abi.encode(auctionBuyer.tokenURI)),
            "SA:EST"
        );
        address seller = _verifySecAuctionItemSeller(auctionSeller);
        //SA:IS--> Secondary Auction: Invalid Seller
        require(seller == auctionSeller.owner, "SA:IS");
        address buyer = _verifyAuctionItemBuyer(auctionBuyer);
        //SA:IB--> Secondary Auction: Invalid Buyer
        require(buyer == auctionBuyer.buyer, "SA:IB");
        //SA:SBE--> Secondary Auction: Seller and Buyer signature are equal
        require(seller != buyer, "SA:SBE");
        if (
            IERC721Upgradeable(auctionSeller.nftAddress).supportsInterface(
                id721Upgradeable
            ) || IERC721(auctionSeller.nftAddress).supportsInterface(id721)
        ) {
            //SA:NO--> Secondary Auction: Not the owner
            require(
                ITemplate721(auctionSeller.nftAddress).ownerOf(
                    auctionSeller.tokenId
                ) == auctionSeller.owner,
                "SA:NO"
            );

            if (auctionSeller.isEth) {
                //SA:ALMB--> Secondary Auction: Amount paid is less than minimum bid
                require(auctionSeller.minimumBid <= msg.value, "SA:ALMB");
                //SA:APPNE--> Secondary Auction: Amount paid and promised not equal
                require(auctionBuyer.pricePaid == msg.value, "SA:APPNE");
                if (
                    checkFunc(
                        auctionSeller.nftAddress,
                        auctionSeller.tokenId,
                        auctionBuyer.pricePaid
                    )
                ) {
                    uint256 serviceFees = ((msg.value * platformFees) / 10000);
                    (address receiver, uint256 royalty) = ITemplate721(
                        auctionSeller.nftAddress
                    ).royaltyInfo(auctionSeller.tokenId, msg.value);
                    uint256 nftPrice = (msg.value - serviceFees) - royalty;
                    (bool success, ) = payable(auctionSeller.owner).call{
                        value: nftPrice
                    }("");
                    //FTF--> Failed to transfer funds
                    require(success, "FTF");
                    (bool success1, ) = payable(Admin).call{value: serviceFees}(
                        ""
                    );
                    require(success1, "FTF");
                    (bool success2, ) = payable(receiver).call{value: royalty}(
                        ""
                    );
                    require(success2, "FTF");
                } else {
                    uint256 serviceFees = ((msg.value * platformFees) / 10000);
                    uint256 nftPrice = (msg.value - serviceFees);
                    (bool success, ) = payable(auctionSeller.owner).call{
                        value: nftPrice
                    }("");
                    require(success, "FTF1");
                    (bool success1, ) = payable(Admin).call{value: serviceFees}(
                        ""
                    );
                    require(success1, "FTF1");
                }
            } else {
                //SA:ALMB--> Secondary Auction: Amount paid is less than minimum bid
                require(
                    auctionSeller.minimumBid <= auctionBuyer.pricePaid,
                    "SA:ALMB"
                );
                if (
                    checkFunc(
                        auctionSeller.nftAddress,
                        auctionSeller.tokenId,
                        auctionBuyer.pricePaid
                    )
                ) {
                    uint256 serviceFees = ((auctionBuyer.pricePaid *
                        platformFees) / 10000);
                    (address receiver, uint256 royalty) = ITemplate721(
                        auctionSeller.nftAddress
                    ).royaltyInfo(
                            auctionSeller.tokenId,
                            auctionBuyer.pricePaid
                        );
                    uint256 nftPrice = (auctionBuyer.pricePaid - serviceFees) -
                        royalty;
                    fanvToken.transferFrom(msg.sender, Admin, serviceFees);
                    fanvToken.transferFrom(msg.sender, receiver, royalty);
                    fanvToken.transferFrom(
                        msg.sender,
                        auctionSeller.owner,
                        nftPrice
                    );
                } else {
                    uint256 serviceFees = ((auctionBuyer.pricePaid *
                        platformFees) / 10000);
                    uint256 nftPrice = (auctionBuyer.pricePaid - serviceFees);
                    fanvToken.transferFrom(msg.sender, Admin, serviceFees);
                    fanvToken.transferFrom(
                        msg.sender,
                        auctionSeller.owner,
                        nftPrice
                    );
                }
            }
            ITemplate721(auctionSeller.nftAddress).safeTransferFrom(
                seller,
                buyer,
                auctionSeller.tokenId,
                ""
            );
        } else {
            //SA" Secondary Auction: Non Fanverse 1155 NFT can't be auctioned
            require(auctionSeller.nftAddress == fanverseContract, "SA:NFCA");
            //SA:IB--> Secondary Auction: Insufficient Balance
            require(
                ITemplate1155(auctionSeller.nftAddress).balanceOf(
                    auctionSeller.owner,
                    auctionSeller.tokenId
                ) >= auctionBuyer.nftBatchAmount,
                "SA:ISB"
            );
            if (auctionSeller.isEth) {
                //SA:ALMB--> Secondary Auction: Amount paid is less than minimum bid
                require(auctionSeller.minimumBid <= msg.value, "SA:ALMB");
                //SA:APPNE--> Secondary Auction: Amount paid and promised not equal
                require(auctionBuyer.pricePaid == msg.value, "SA:APPNE");

                uint256 serviceFees = ((msg.value * platformFees) / 10000);
                (address receiver, uint256 royalty) = ITemplate1155(
                    auctionSeller.nftAddress
                ).royaltyInfo(auctionSeller.tokenId, msg.value);
                uint256 nftPrice = (msg.value - serviceFees) - royalty;
                (bool success, ) = payable(auctionSeller.owner).call{
                    value: nftPrice
                }("");
                //FTF--> Failed to transfer funds
                require(success, "FTF");
                (bool success1, ) = payable(Admin).call{value: serviceFees}("");
                require(success1, "FTF");
                (bool success2, ) = payable(receiver).call{value: royalty}("");
                require(success2, "FTF");
            } else {
                //SA:ALMB--> Secondary Auction: Amount paid is less than minimum bid
                require(
                    auctionSeller.minimumBid <= auctionBuyer.pricePaid,
                    "SA:ALMB"
                );

                uint256 serviceFees = ((auctionBuyer.pricePaid * platformFees) /
                    10000);
                (address receiver, uint256 royalty) = ITemplate1155(
                    auctionSeller.nftAddress
                ).royaltyInfo(auctionSeller.tokenId, auctionBuyer.pricePaid);
                uint256 nftPrice = (auctionBuyer.pricePaid - serviceFees) -
                    royalty;
                fanvToken.transferFrom(msg.sender, Admin, serviceFees);
                fanvToken.transferFrom(msg.sender, receiver, royalty);
                fanvToken.transferFrom(
                    msg.sender,
                    auctionSeller.owner,
                    nftPrice
                );
            }
            ITemplate1155(auctionSeller.nftAddress).safeTransferFrom(
                seller,
                buyer,
                auctionSeller.tokenId,
                auctionBuyer.nftBatchAmount,
                ""
            );
        }
    }

    /**
     * @notice Performs a secondary buy transaction by purchasing NFTs from the seller.
     * @param seller The market item struct representing the seller and the item being purchased.
     * @param redeemer The address of the redeemer or buyer.
     * @param nftAmount The amount of NFTs to be purchased.
     * @param fanvAmount The amount of Fanv tokens to be used for the purchase.
     * @dev This function is public and payable.
     * @dev It calls the secondaryBuyFlow function to handle the buy transaction.
     * @dev Emits a secondaryFixBuy event with the relevant details of the transaction.
     * @dev The event includes the seller's address, redeemer's address, tokenId, nftBatchAmount, and the total purchase price.
     */
    function secondarybuy(
        FNVvoucher.marketItem memory seller,
        address redeemer,
        uint256 nftAmount,
        uint256 fanvAmount
    ) public payable {
        secondaryBuyFlow(seller, redeemer, nftAmount, fanvAmount);
        emit secondaryFixBuy(
            seller.owner,
            redeemer,
            seller.tokenId,
            seller.nftBatchAmount,
            seller.unitPrice * (nftAmount)
        );
    }

    function secondaryBuyFlow(
        FNVvoucher.marketItem memory seller,
        address redeemer,
        uint256 nftAmount,
        uint256 fanvAmount
    ) internal {
        //IA--> Invalid Address
        require(address(seller.owner) != address(0), "IA");
        //MVE--> Mint Voucher has expired
        require(!batchAmountStatus[seller.counterValue], "MVE");
        //NL--> Not listed
        require(seller.listed, "NL");
        address signer = _verifypriListing(seller);
        //IS--> Invalid Seller
        require(signer == seller.owner, "IS");
        if (
            IERC1155Upgradeable(seller.nftAddress).supportsInterface(
                id1155Upgradeable
            ) || IERC1155(seller.nftAddress).supportsInterface(id1155)
        ) {
            //IA--> Invalid Amount

            require(
                ITemplate1155(seller.nftAddress).balanceOf(
                    seller.owner,
                    seller.tokenId
                ) >= nftBatchamountleft[seller.counterValue],
                "IA"
            );
            if (nftBatchamountleft[seller.counterValue] == 0) {
                nftBatchamountleft[seller.counterValue] = seller.nftBatchAmount;
            }
            //IA--> Invalid Amount
            require(nftBatchamountleft[seller.counterValue] >= nftAmount, "IA");
            nftBatchamountleft[seller.counterValue] -= nftAmount;
            if (nftBatchamountleft[seller.counterValue] == 0) {
                batchAmountStatus[seller.counterValue] = true;
            }
            if (seller.isEth) {
                //PME--> Pay more eth
                require((seller.unitPrice * (nftAmount)) <= msg.value, "PME");
                distributeAmountInEth(seller, signer, msg.value);
            } else {
                //PMF--> Pay more fanverse token
                require((seller.unitPrice * (nftAmount)) <= fanvAmount, "PMF");
                distributeAmountInFanv(seller, signer, fanvAmount);
            }
            ITemplate1155(seller.nftAddress).safeTransferFrom(
                signer,
                redeemer,
                seller.tokenId,
                nftAmount,
                ""
            );
        } else if (
            IERC721(seller.nftAddress).supportsInterface(id721) ||
            IERC721Upgradeable(seller.nftAddress).supportsInterface(
                id721Upgradeable
            )
        ) {
            //IO--> Invalid Owner

            require(
                ITemplate721(seller.nftAddress).ownerOf(seller.tokenId) ==
                    seller.owner,
                "IO"
            );
            //VU--> Voucher Used
            require(!usedVoucher[seller.counterValue], "VU");
            if (seller.isEth) {
                //PME--> Pay more eth
                require((seller.unitPrice) <= msg.value, "PME");
                distributeAmountInEth(seller, signer, msg.value);
            } else {
                //PMF--> Pay more fanverse token
                require((seller.unitPrice) <= fanvAmount, "PMF");
                distributeAmountInFanv(seller, signer, fanvAmount);
            }
            usedVoucher[seller.counterValue] = true;
            ITemplate721(seller.nftAddress).safeTransferFrom(
                seller.owner,
                redeemer,
                seller.tokenId,
                ""
            );
        }
    }

    /**
     * @notice Distributes the Fanv token amount according to the specified distribution rules.
     * @param seller The market item struct representing the seller and the item being purchased.
     * @param _receiver The address of the receiver or buyer.
     * @param FanvAmount The amount of Fanv tokens to be distributed.
     * @dev This function is internal.
     * @dev It first checks if the seller's NFT address and tokenId are eligible for the specified distribution rules by calling the checkFunc function.
     * @dev If the checkFunc returns true, the function calculates the service fees and royalty amounts based on the platform fees and the royaltyInfo function of the ITemplate1155 contract.
     * @dev The nftPrice is calculated by subtracting the service fees and royalty from the FanvAmount.
     * @dev The Fanv tokens are transferred from the message sender to the specified addresses (receiver, Admin, and receiver of the royalty) using the transferFrom function of the fanvToken contract.
     * @dev If the checkFunc returns false, only the service fees are calculated and transferred to the Admin address, and the remaining FanvAmount is transferred to the _receiver address.
     */

    function distributeAmountInFanv(
        FNVvoucher.marketItem memory seller,
        address _receiver,
        uint256 FanvAmount
    ) internal {
        if (
            checkFunc(seller.nftAddress, seller.tokenId, seller.nftBatchAmount)
        ) {
            uint256 serviceFees = ((FanvAmount * platformFees) / 10000);
            (address receiver, uint256 royalty) = ITemplate1155(
                seller.nftAddress
            ).royaltyInfo(seller.tokenId, FanvAmount);

            uint256 nftPrice = (FanvAmount - serviceFees) - royalty;
            fanvToken.transferFrom(msg.sender, _receiver, nftPrice);
            fanvToken.transferFrom(msg.sender, Admin, serviceFees);
            fanvToken.transferFrom(msg.sender, receiver, royalty);
        } else {
            uint256 serviceFees = ((FanvAmount * platformFees) / 10000);
            uint256 nftPrice = (FanvAmount - serviceFees);
            fanvToken.transferFrom(msg.sender, Admin, serviceFees);
            fanvToken.transferFrom(msg.sender, _receiver, nftPrice);
        }
    }

    /**
 * @notice Distributes the ETH amount according to the specified distribution rules.
 * @param seller The market item struct representing the seller and the item being purchased.
 * @param _receiver The address of the receiver or buyer.
 * @param ethAmount The amount of ETH to be distributed.
 * @dev This function is internal.
 * @dev It first checks if the seller's NFT address and tokenId are eligible for the specified distribution rules by calling the checkFunc function.
 * @dev If the checkFunc returns true, the function calculates the service fees and royalty amounts based on the platform fees and the royaltyInfo function of the ITemplate1155 contract.
 * @dev The nftPrice is calculated by subtracting the service fees and royalty from the ethAmount.
 * @dev The nftPrice is transferred to the _receiver address using the call function with the payable modifier.
 * @dev If the transfer is successful, the service fees and royalty amounts are transferred to the Admin and receiver addresses respectively.

 */

    function distributeAmountInEth(
        FNVvoucher.marketItem memory seller,
        address _receiver,
        uint256 ethAmount
    ) internal {
        if (
            checkFunc(seller.nftAddress, seller.tokenId, seller.nftBatchAmount)
        ) {
            uint256 serviceFees = ((ethAmount * platformFees) / 10000);
            (address receiver, uint256 royalty) = ITemplate1155(
                seller.nftAddress
            ).royaltyInfo(seller.tokenId, ethAmount);

            uint256 nftPrice = (ethAmount - serviceFees) - royalty;
            (bool success, ) = payable(_receiver).call{value: nftPrice}("");
            //FTF--> Failed to transfer funds
            require(success, "FTF");

            (bool success1, ) = payable(Admin).call{value: serviceFees}("");
            require(success1, "FTF");

            (bool success2, ) = payable(receiver).call{value: royalty}("");
            require(success2, "FTF");
        } else {
            uint256 serviceFees = ((ethAmount * platformFees) / 10000);
            uint256 nftPrice = (ethAmount - serviceFees);
            (bool success, ) = payable(_receiver).call{value: nftPrice}("");
            require(success, "FTF");

            (bool success1, ) = payable(Admin).call{value: serviceFees}("");
            require(success1, "FTF");
        }
    }

    /**
     * @notice Checks if a specified function is available in an NFT contract.
     * @param nftAddress The address of the NFT contract to check.
     * @param tokenId The ID of the token to be used as a parameter in the function call.
     * @param amount The amount to be used as a parameter in the function call.
     * @return A boolean value indicating whether the function call was successful or not.
     * @dev This function is internal and returns a boolean value.
     * @dev It encodes the function call with the FUNC_SELECTOR, tokenId, and amount parameters.
     * @dev The nftAddress is called with the encoded data, and the success status of the call is stored in the _success variable.
     * @dev The success status is assigned to the success variable and returned.
     */

    function checkFunc(
        address nftAddress,
        uint256 tokenId,
        uint256 amount
    ) internal returns (bool) {
        bool success;
        bytes memory data = abi.encodeWithSelector(
            FUNC_SELECTOR,
            tokenId,
            amount
        );

        (bool _success, ) = nftAddress.call(data);

        success = _success;
        return (success);
    }

    /**
     * @notice Retrieves the owner of a specific token in an NFT contract.
     * @param _tokenId The ID of the token for which to retrieve the owner.
     * @param nftAddress The address of the NFT contract.
     * @return The address of the owner of the specified token.
     * @dev This function is public and view.
     * @dev It calls the ownerOf function of the ITemplate721 contract, passing the _tokenId as a parameter, and returns the result.
     */
    function ownerOf(
        uint256 _tokenId,
        address nftAddress
    ) public view returns (address) {
        return ITemplate721(nftAddress).ownerOf(_tokenId);
    }

    /**
     * @notice Sets the approval status for a user on an NFT contract to enable or disable operator control over the user's tokens.
     * @param _userAddress The address of the user for whom to set the approval status.
     * @param _nftAddress The address of the NFT contract.
     * @dev This function is external.
     * @dev It calls the setApprovalForAll function of the ITemplate1155 contract, passing the _userAddress and true as parameters, to enable operator control over the user's tokens.
     * @dev This function allows the specified user to give approval for an operator to manage their tokens on the specified NFT contract.
     */
    function safeApproveForAllUser(
        address _userAddress,
        address _nftAddress
    ) external {
        ITemplate1155(_nftAddress).setApprovalForAll(_userAddress, true);
    }

    /**
     * @notice Resets the counter status for a specific counter value in the batchAmountStatus mapping.
     * @param _voucher The market item struct containing the counter value for which to reset the status.
     * @dev This function is external and can only be called by the owner.
     * @dev It updates the batchAmountStatus mapping by setting the status for the specified counter value to true.
     * @dev This function allows the owner to reset the counter status, potentially enabling the use of the counter value for future operations.
     */
    function resetCounter(
        FNVvoucher.marketItem memory _voucher
    ) external onlyOwner {
        batchAmountStatus[_voucher.counterValue] = true;
    }

    /**
     * @notice Sets the market fee percentage to be applied to transactions.
     * @param _marketfees The percentage value of the market fees to be set.
     * @dev This function is external and can only be called by the owner.
     * @dev It requires the _marketfees parameter to be non-zero.
     * @dev It updates the platformFees variable with the specified _marketfees value.
     * @dev This function allows the owner to adjust the market fee percentage for transactions.
     */
    function setMarketFee(uint256 _marketfees) external onlyOwner {
        require(_marketfees != 0, "Market fees cannot be zero");
        platformFees = _marketfees;
    }

    /**
     * @notice Sets the address of the Fanv Token contract.
     * @param _fanvToken The address of the Fanv Token contract to be set.
     * @dev This function is external and can only be called by the owner.
     * @dev It requires the _fanvToken parameter to be non-zero.
     * @dev It updates the fanvToken variable with an instance of the IFanvToken interface pointing to the specified _fanvToken address.
     * @dev This function ensures that the Fanv Token address is valid and sets it for further operations within the contract.
     */
    function setFanvToken(address _fanvToken) external onlyOwner {
        //FCZ--> Fanverse Token address can't be zero
        require(_fanvToken != address(0), "FCZ");
        fanvToken = IFanvToken(_fanvToken);
    }

    /**
     * @notice Sets the address of the admin.
     * @param _adminAddress The address of the admin to be set.
     * @dev This function is external and can only be called by the owner.
     * @dev It requires the _adminAddress parameter to be non-zero.
     * @dev It updates the Admin variable with the specified _adminAddress.
     * @dev This function ensures that the admin address is valid and sets it for further operations within the contract.
     */
    function setAdminAddress(address _adminAddress) external onlyOwner {
        //ACZ--> Admin address can't be zero address
        require(_adminAddress != address(0), "ACZ");
        Admin = _adminAddress;
    }

    /**
     * @notice Retrieves the current chain ID.
     * @return The chain ID as a uint256 value.
     * @dev This function is external and view.
     * @dev It uses assembly code to directly retrieve the chain ID using the chainid opcode.
     * @dev The retrieved chain ID is stored in the 'id' variable and returned.
     * @dev This function allows users to obtain the chain ID on which the contract is deployed.
     */

    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}
