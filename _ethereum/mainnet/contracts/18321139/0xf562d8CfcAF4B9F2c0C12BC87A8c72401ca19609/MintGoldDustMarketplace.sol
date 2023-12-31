// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./Counters.sol";
import "./IERC721Receiver.sol";
import "./IERC1155Receiver.sol";
import "./Initializable.sol";
import "./ERC165Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MintGoldDustCompany.sol";
import "./MintGoldDustERC721.sol";
import "./MintGoldDustNFT.sol";
import "./MintGoldDustERC1155.sol";

/// @title An abstract contract responsible to define some general responsibilites related with
/// a marketplace for its childrens.
/// @notice Contain a general function for purchases in primary and secondary sales
/// and also a virtual function that each children should have a specif implementation.
/// @author Mint Gold Dust LLC
/// @custom:contact klvh@mintgolddust.io
abstract contract MintGoldDustMarketplace is
    Initializable,
    PausableUpgradeable,
    IERC1155Receiver,
    IERC721Receiver,
    ReentrancyGuardUpgradeable
{
    using Counters for Counters.Counter;

    /// @notice that this struct has the necessary fields to manage the secondary sales.
    /// @dev it will be used by the isSecondarySale mapping.
    struct ManageSecondarySale {
        address owner;
        bool sold;
        uint256 amount;
    }

    /**
     * This struct consists of the following fields:
     *    - tokenId: The tokenId of the marketItem.
     *    - seller: The seller of the marketItem.
     *    - price: The price which the item should be sold.
     *    - sold: It says if an item was or not sold.
     *    - isAuction: true if the item was listed for marketplace auction and false if for set price market.
     *    - isERC721: true is an MintGoldDustERC721 token.
     *    - tokenAmount: The quantity of tokens to be listed for an MintGoldDustERC1155. For
     *              MintGoldDustERC721 the amout must be always one.
     *    - AuctionProps: The AuctionProps structure (See below).
     */
    struct MarketItem {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isERC721;
        uint256 tokenAmount;
        AuctionProps auctionProps;
    }

    /**
     * This struct consists of the following fields:
     *    - endTime: the time that the auction must be finished. Is the start time plus 24 hours.
     *    - highestBidder: the bidder that did bid the highest value.
     *    - highestBid: the value of the high bid.
     *    - ended: a boolean that indicates if the auction was already finished or not.
     */
    struct AuctionProps {
        uint256 auctionId;
        uint256 startTime;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool ended;
    }

    /**
     * @notice that is a Data Transfer Object to be transferred between functions for the sale flow.
     *              It consists of the following fields:
     *                  - tokenid: The tokenId of the marketItem.
     *                  - amount: The quantity of tokens to be listed for an MintGoldDustERC1155. For
     *                            MintGoldDustERC721 the amout must be always one.
     *                  - contractAddress: The MintGoldDustERC1155 or the MintGoldDustERC721 address.
     *                  - seller: The seller of the marketItem.
     */
    struct SaleDTO {
        uint256 tokenId;
        uint256 amount;
        address contractAddress;
        address seller;
    }

    /**
     * @notice that is a Data Transfer Object to be transferred between functions for the listing flow.
     *              It consists of the following fields:
     *                    - tokenid: The tokenId of the marketItem.
     *                    - amount: The quantity of tokens to be listed for an MintGoldDustERC1155. For
     *                              MintGoldDustERC721 the amout must be always one.
     *                    - contractAddress: The MintGoldDustERC1155 or the MintGoldDustERC721 address.
     *                    - price: the price to be paid for the item in the set price market and it correponds
     *                             to the reserve price for the marketplace auction.
     */
    struct ListDTO {
        uint256 tokenId;
        uint256 amount;
        address contractAddress;
        uint256 price;
    }

    /**
     * @notice that is a Data Transfer Object to be transferred between functions in the Collector (lazy) mint flow.
     *              It consists of the following fields:
     *                    - contractAddress: The MintGoldDustERC1155 or the MintGoldDustERC721 address.
     *                    - tokenURI the URI that contains the metadata for the NFT.
     *                    - royalty the royalty percentage to be applied for this NFT secondary sales.
     *                    - collaborators an array of address that can be a number of maximum 4 collaborators.
     *                    - ownersPercentage an array of uint256 that are the percetages for the artist and for each one of the collaborators.
     *                    - amount: The quantity of tokens to be listed for an MintGoldDustERC1155. For
     *                              MintGoldDustERC721 the amout must be always one.
     *                    - artistSigner: the address of the artist creator.
     *                    - price: the price to be paid for the item in the set price market.
     *                    - collectorMintId: the id of the collector mint generated off chain.
     */
    struct CollectorMintDTO {
        address contractAddress;
        string tokenURI;
        uint256 royalty;
        bytes memoir;
        address[] collaborators;
        uint256[] ownersPercentage;
        uint256 amount;
        address artistSigner;
        uint256 price;
        uint256 collectorMintId;
    }

    Counters.Counter public itemsSold;
    MintGoldDustMarketplace internal mintGoldDustMarketplace;
    MintGoldDustCompany internal mintGoldDustCompany;
    address payable internal mintGoldDustERC721Address;
    address payable internal mintGoldDustERC1155Address;
    uint256[48] __gap;

    /**
     * @notice that this mapping do the relationship between a contract address,
     *         the tokenId created in this contract (MintGoldDustERC721 or MintGoldDustERC1155)
     *         the owner address and the Market Item owned.
     * @dev this mapping is necessary mainly because of the ERC1155. I.e Some artist can mint the quantity
     *      of 10 for a tokenId. After it can list 8 items. So other address can buy 4 and another 4.
     *      Then this MarketItem can has 3 different owners for the same tokenId for the MintGoldDustERC1155 address.
     */
    mapping(address => mapping(uint256 => mapping(address => MarketItem)))
        public idMarketItemsByContractByOwner;

    /**
     *  @notice that this mapping will manage the state to track the secondary sales.
     *  @dev here we can handle when a secondarySale should start. A succinct example that you can
     *  understand easily is the following:
     *      - An artist mint 10 items for a MintGoldDustERC1155.
     *      - He list 5 items for sale.
     *      - A buyer buys 5 items.
     *      - This buyer list s5 items for sale.
     *      - The artist buys your 5 items back.
     *      - Now the artist has 10 items again.
     *      - But notice that it can sale only more five in the primary sale flow.
     *  With this mapping and the ManageSecondarySale struct we can manage it.
     */
    mapping(address => mapping(uint256 => ManageSecondarySale))
        public isSecondarySale;

    /**
     * @notice that this event show the info about primary sales.
     * @dev this event will be triggered if a primary sale is correctly completed.
     * @param saleId a uint value that indicates the sale number.
     * @param tokenId the sequence number for the item.
     * @param seller the address of the seller.
     * @param newOwner the address that is buying the item.
     * @param buyPrice the price that the buyer is paying for the item.
     * @param sellerAmount the final value that the seller should receive.
     * @param feeAmount the primary sale fee to be applied on top of the item price.
     * @param collectorFeeAmount the value paind by the collector to the marketplace.
     * @param tokenAmountSold the quantity of tokens bought.
     * @param hasCollaborators a parameter that indicate if the item has or not collaborators.
     * @param isERC721 a parameter that indicate if the item is an ERC721 or not.
     */
    event MintGoldDustNftPurchasedPrimaryMarket(
        uint256 indexed saleId,
        uint256 indexed tokenId,
        address seller,
        address newOwner,
        uint256 buyPrice,
        uint256 sellerAmount,
        uint256 feeAmount,
        uint256 collectorFeeAmount,
        uint256 tokenAmountSold,
        bool hasCollaborators,
        bool isERC721
    );

    /**
     * @notice that this event show the info about secondary sales.
     * @dev this event will be triggered if a secondary sale is correctly completed.
     * @param saleId a uint value that indicates the sale number.
     * @param tokenId the sequence number for the item.
     * @param seller the address of the seller.
     * @param newOwner the address that is buying the item.
     * @param sellerAmount the final value that the seller should receive.
     * @param royaltyPercent the royalty percent setted for this token.
     * @param royaltyAmount the value to be paid for the artist and the collaborators (when it has) for the royalties.
     * @param royaltyRecipient the main recipient for the royalty value (the artist).
     * @param feeAmount the fee final value that was paid to the marketplace.
     * @param tokenAmountSold the quantity of tokens bought.
     * @param hasCollaborators a parameter that indicate if the item has or not collaborators.
     * @param isERC721 a parameter that indicate if the item is an ERC721 or not.
     */
    event MintGoldDustNftPurchasedSecondaryMarket(
        uint256 indexed saleId,
        uint256 indexed tokenId,
        address seller,
        address newOwner,
        uint256 buyPrice,
        uint256 sellerAmount,
        uint256 royaltyPercent,
        uint256 royaltyAmount,
        address royaltyRecipient,
        uint256 feeAmount,
        uint256 tokenAmountSold,
        bool hasCollaborators,
        bool isERC721
    );

    /**
     * @notice that this event is used when a item has collaborators.
     * @dev this event shouldbe used if splitted market items. At the purchase moment it will
     *      be triggered for each one of the collaborators including the artist.
     * @param saleId a uint value that indicates the sale number.
     * @dev use this to vinculate this event with the MintGoldDustNftPurchasedSecondaryMarket that contains more
     *      general info about the sale.
     * @param collaborator the sequence number for the item.
     * @param amount the final value that the seller should receive.
     */
    event NftPurchasedCollaboratorAmount(
        uint256 indexed saleId,
        address collaborator,
        uint256 amount
    );

    error ItemIsNotListed(address _contractAddress);
    error ItemIsNotListedBySeller(
        uint256 tokenId,
        address market,
        address contractAddress,
        address seller,
        address msgSender
    );
    error ItemIsAlreadyListed(address _contractAddress);
    error AddressUnauthorized(string _reason);
    error MustBeERC721OrERC1155();
    error LessItemsListedThanTheRequiredAmount();
    error InvalidAmountForThisPurchase();
    error PurchaseOfERC1155InAuctionThatCoverAllListedItems();
    error InvalidAmount();

    modifier isowner() {
        if (msg.sender != mintGoldDustCompany.owner()) {
            revert AddressUnauthorized("Not Mint Gold Dust owner");
        }
        _;
    }

    /**
     *
     * @notice MintGoldDustMarketplace is composed by other two contracts.
     * @param _mintGoldDustCompany The contract responsible to Mint Gold Dust management features.
     * @param _mintGoldDustERC721Address The Mint Gold Dust ERC721 address.
     * @param _mintGoldDustERC1155Address The Mint Gold Dust ERC1155 address.
     */
    function initialize(
        address _mintGoldDustCompany,
        address payable _mintGoldDustERC721Address,
        address payable _mintGoldDustERC1155Address
    ) internal onlyInitializing {
        require(
            _mintGoldDustCompany != address(0) &&
                _mintGoldDustERC721Address != address(0) &&
                _mintGoldDustERC1155Address != address(0),
            "contract address cannot be zero"
        );
        __ReentrancyGuard_init();
        __Pausable_init();
        mintGoldDustCompany = MintGoldDustCompany(_mintGoldDustCompany);
        mintGoldDustERC721Address = _mintGoldDustERC721Address;
        mintGoldDustERC1155Address = _mintGoldDustERC1155Address;
    }

    /// @notice that this function set an instance of the MintGoldDustMarketplace to the sibling contract.
    /// @param _mintGoldDustMarketplace the address of the MintGoldDustMarketplace.
    /// @dev we create this lazy dependence because of the circular dependence between the
    /// MintGoldDustMarketplace. So this way we can share the state of the isSecondarySale mapping.
    function setMintGoldDustMarketplace(
        address _mintGoldDustMarketplace
    ) external {
        require(mintGoldDustCompany.owner() == msg.sender, "Unauthorized");
        mintGoldDustMarketplace = MintGoldDustMarketplace(
            _mintGoldDustMarketplace
        );
    }

    /// @notice that this function is used to populate the isSecondarySale mapping for the
    /// sibling contract. This way the mapping state will be shared.
    /// @param _contractAddress the address of the MintGoldDustERC1155 or MintGoldDustERC721.
    /// @param _tokenId the id of the token.
    /// @param _owner the owner of the token.
    /// @param _sold a boolean that indicates if the token was sold or not.
    /// @param _amount the amount of tokens minted for this token.
    function setSecondarySale(
        address _contractAddress,
        uint256 _tokenId,
        address _owner,
        bool _sold,
        uint256 _amount
    ) external {
        require(msg.sender == address(mintGoldDustMarketplace), "Unauthorized");
        isSecondarySale[_contractAddress][_tokenId] = ManageSecondarySale(
            _owner,
            _sold,
            _amount
        );
    }

    /// @notice that this function should be used to update the amount attribute for the isSecondarySale mapping
    /// in the sibling contract.
    /// @param _contractAddress the address of the MintGoldDustERC1155 or MintGoldDustERC721.
    /// @param _tokenId the id of the token.
    /// @param _amount the amount of tokens minted for this token.
    function updateSecondarySaleAmount(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _amount
    ) external {
        require(msg.sender == address(mintGoldDustMarketplace), "Unauthorized");
        ManageSecondarySale storage _manageSecondarySale = isSecondarySale[
            _contractAddress
        ][_tokenId];
        _manageSecondarySale.amount = _manageSecondarySale.amount - _amount;
    }

    /// @notice that this function should be used to update the sold attribute for the isSecondarySale mapping
    /// in the sibling contract.
    /// @param _contractAddress the address of the MintGoldDustERC1155 or MintGoldDustERC721.
    /// @param _tokenId the id of the token.
    /// @param _sold a boolean that indicates if the token was sold or not.
    function updateSecondarySaleSold(
        address _contractAddress,
        uint256 _tokenId,
        bool _sold
    ) external {
        require(msg.sender == address(mintGoldDustMarketplace), "Unauthorized");
        ManageSecondarySale storage _manageSecondarySale = isSecondarySale[
            _contractAddress
        ][_tokenId];
        _manageSecondarySale.sold = _sold;
    }

    /// @notice Pause the contract
    function pauseContract() external isowner {
        _pause();
    }

    /// @notice Unpause the contract
    function unpauseContract() external isowner {
        _unpause();
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     *
     * @notice that is a general function that must be implemented by the more specif makets.
     * @dev it is a internal function and should be implemented by the childrens
     * if these are not abstract also.
     * @param _tokenId: The tokenId of the marketItem.
     * @param _amount: The quantity of tokens to be listed for an MintGoldDustERC1155.
     *    @dev For MintGoldDustERC721 the amout must be always one.
     * @param _contractAddress: The MintGoldDustERC1155 or the MintGoldDustERC721 address.
     * @param _price: The price or reserve price for the item.
     */
    function list(
        uint256 _tokenId,
        uint256 _amount,
        address _contractAddress,
        uint256 _price
    ) external virtual;

    /**
     * @notice that is a more generic list function than the above. This function can be used by both kind of markets
     *         marketplace auction and set price.
     * @dev Here we're listing a MintGoldDustERC721 or a MintGoldDustERC1155 to the MintGoldDustMarketplace.
     *      If the item is being listed to _isAuction and the price is zero it means that
     *      the auction doesn't has a reserve price. In other case it has. If the NFT is being listed to
     *      the set price market the price must be greater than zero.
     *      Is important to know that after list an item to auction is not possible to cancel it like
     *      the delist function in the Set Price market.
     *      After the MarketItem struct creation the NFT is transferred from the seller to the respective
     *      markeplace address (marketplace auction or set price).
     * @param _listDTO The ListDTO struct parameter to use.
     *                 It consists of the following fields:
     *                    - tokenid: The tokenId of the marketItem.
     *                    - amount: The quantity of tokens to be listed for an MintGoldDustERC1155. For
     *                              MintGoldDustERC721 the amout must be always one.
     *                    - contractAddress: The MintGoldDustERC1155 or the MintGoldDustERC721 address.
     *                    - seller: The seller of the marketItem.
     *                    - price: the price to list the item. For auction it corresponds to the reserve price.
     * @param _auctionId the auctionId for the auction. If the item is being listed to the set price market it is *                   zero.
     * @param _sender the address that is listing the item.
     *    @dev we need this parameter because in the collectorMint flow who calls this function is the buyer. How *    it function is internal we can have a good control on top of it.
     */
    function list(
        ListDTO memory _listDTO,
        uint256 _auctionId,
        address _sender
    ) internal {
        MintGoldDustNFT _mintGoldDustNFT;
        bool _isERC721 = false;
        uint256 _realAmount = 1;

        if (_listDTO.contractAddress == mintGoldDustERC721Address) {
            isNFTowner(_listDTO.tokenId, _sender);
            _mintGoldDustNFT = MintGoldDustNFT(mintGoldDustERC721Address);
            _isERC721 = true;
        } else {
            checkBalanceForERC1155(_listDTO.tokenId, _listDTO.amount, _sender);
            _mintGoldDustNFT = MintGoldDustNFT(mintGoldDustERC1155Address);
            _realAmount = _listDTO.amount;
        }

        if (
            isSecondarySale[address(_mintGoldDustNFT)][_listDTO.tokenId]
                .owner == address(0)
        ) {
            uint256 _amountMinted = 1;

            if (address(_mintGoldDustNFT) == mintGoldDustERC1155Address) {
                _amountMinted = (
                    MintGoldDustERC1155(mintGoldDustERC1155Address)
                ).balanceOf(_sender, _listDTO.tokenId);
            }

            isSecondarySale[address(_mintGoldDustNFT)][
                _listDTO.tokenId
            ] = ManageSecondarySale(_sender, false, _amountMinted);
            mintGoldDustMarketplace.setSecondarySale(
                _listDTO.contractAddress,
                _listDTO.tokenId,
                _sender,
                false,
                _amountMinted
            );
        }

        ManageSecondarySale memory manageSecondarySale = isSecondarySale[
            address(_mintGoldDustNFT)
        ][_listDTO.tokenId];

        /// @dev why we need this? We need to check if there are some amount listed for the other market.
        /// I mean, if the item was listed for the set price market and the seller is trying to list it for auction.
        /// It needs to be added to the sommary of the quantity restant for primary sales.
        (, , , , uint256 returnedTokenAmount, ) = mintGoldDustMarketplace
            .idMarketItemsByContractByOwner(
                address(_mintGoldDustNFT),
                _listDTO.tokenId,
                _sender
            );

        if (!manageSecondarySale.sold && _sender == manageSecondarySale.owner) {
            require(
                _listDTO.amount + returnedTokenAmount <=
                    manageSecondarySale.amount,
                "Invalid amount for primary sale"
            );
        }

        AuctionProps memory auctionProps = AuctionProps(
            _auctionId,
            0,
            0,
            payable(address(0)),
            0,
            false
        );

        idMarketItemsByContractByOwner[_listDTO.contractAddress][
            _listDTO.tokenId
        ][_sender] = MarketItem(
            _listDTO.tokenId,
            _sender,
            _listDTO.price,
            _isERC721,
            _realAmount,
            auctionProps
        );

        _mintGoldDustNFT.transfer(
            _sender,
            address(this),
            _listDTO.tokenId,
            _realAmount
        );
    }

    /// @notice that this function check a boolean and depending of the value return a MintGoldDustERC721 or a MintGoldDustERC1155.
    /// @dev If true is created an instance of a MintGoldDustERC721 using polymorphism with the parent contract. If not
    ///      it creates an isntance for MintGoldDustERC1155.
    /// @param _isERC721 a boolean that say if the address is an ERC721 or not.
    /// @return MintGoldDustNFT an instance of MintGoldDustERC721 or MintGoldDustERC1155.
    function getERC1155OrERC721(
        bool _isERC721
    ) internal view returns (MintGoldDustNFT) {
        if (_isERC721) {
            return MintGoldDustNFT(mintGoldDustERC721Address);
        } else {
            return MintGoldDustNFT(mintGoldDustERC1155Address);
        }
    }

    /**
     * @param _saleDTO The SaleDTO struct parameter to use.
     *                 It consists of the following fields:
     *                    - tokenid: The tokenId of the marketItem.
     *                    - amount: The quantity of tokens to be listed for an MintGoldDustERC1155. For
     *                              MintGoldDustERC721 the amout must be always one.
     *                    - contractAddress: The MintGoldDustERC1155 or the MintGoldDustERC721 address.
     *                    - seller: The seller of the marketItem.
     * @return MarketItem struct.
     *                 It consists of the following fields:
     *                    - tokenId: The tokenId of the marketItem.
     *                    - seller: The seller of the marketItem.
     *                    - price: The price which the item should be sold.
     *                    - sold: It says if an item was or not sold.
     *                    - isAuction: true if the item was listed for marketplace auction and false if for set price market.
     *                    - isERC721: true is an MintGoldDustERC721 token.
     *                    - tokenAmount: The quantity of tokens to be listed for an MintGoldDustERC1155. For
     *                              MintGoldDustERC721 the amout must be always one.
     *                    - auctionProps:
     *                        - endTime: the time that the auction must be finished. Is the start time plus 24 hours.
     *                        - highestBidder: the bidder that did bid the highest value.
     *                        - highestBid: the value of the high bid.
     *                        - ended: a boolean that indicates if the auction was already finished or not.
     */
    function getMarketItem(
        SaleDTO memory _saleDTO
    ) internal view returns (MarketItem memory) {
        return
            idMarketItemsByContractByOwner[_saleDTO.contractAddress][
                _saleDTO.tokenId
            ][_saleDTO.seller];
    }

    /**
     * @notice function will fail if the token was not listed to the set price market.
     * @notice function will fail if the contract address is not a MintGoldDustERC721 neither a MintGoldDustERC1155.
     * @notice function will fail if the amount paid by the buyer does not cover the purshace amount required.
     * @param _saleDTO The SaleDTO struct parameter to use.
     *                 It consists of the following fields:
     *                    - tokenid: The tokenId of the marketItem.
     *                    - amount: The quantity of tokens to be listed for an MintGoldDustERC1155. For
     *                              MintGoldDustERC721 the amout must be always one.
     *                    - contractAddress: The MintGoldDustERC1155 or the MintGoldDustERC721 address.
     *                    - seller: The seller of the marketItem.
     * @param _sender The address that started this flow.
     * @param _value The value to be paid for the purchase.
     */
    function executePurchaseNftFlow(
        SaleDTO memory _saleDTO,
        address _sender,
        uint256 _value
    ) internal {
        isTokenIdListed(
            _saleDTO.tokenId,
            _saleDTO.contractAddress,
            _saleDTO.seller
        );

        mustBeMintGoldDustERC721Or1155(_saleDTO.contractAddress);

        hasEnoughAmountListed(
            _saleDTO.tokenId,
            _saleDTO.contractAddress,
            address(this),
            _saleDTO.amount,
            _saleDTO.seller
        );

        MarketItem memory _marketItem = getMarketItem(_saleDTO);

        /// @dev if the flow goes for ERC721 the amount of tokens MUST be ONE.
        uint256 _realAmount = 1;

        if (!_marketItem.isERC721) {
            _realAmount = _saleDTO.amount;
        }

        checkIfIsPrimaryOrSecondarySaleAndCall(
            _marketItem,
            _saleDTO,
            _value,
            _sender,
            _realAmount
        );
    }

    /**
     * @dev this function check if the item was already sold some time and *      direct the flow to
     *     a primary or a secondary sale flow.
     * @param _marketItem The MarketItem struct parameter to use.
     * @param _saleDTO The SaleDTO struct parameter to use.
     * @param _value The value to be paid for the purchase.
     * @param _sender The address that started this flow.
     *    @dev we need to receive the sender this way, because in the auction flow the purchase starts from
     *         the endAuction function in the MintGoldDustMarketplaceAuction contract. So from there the address
     *         that we get is the highest bidder that is stored in the marketItem struct. So we need to manage this way.
     */
    function checkIfIsPrimaryOrSecondarySaleAndCall(
        MarketItem memory _marketItem,
        SaleDTO memory _saleDTO,
        uint256 _value,
        address _sender,
        uint256 _realAmount
    ) internal {
        ManageSecondarySale memory manageSecondarySale = isSecondarySale[
            _saleDTO.contractAddress
        ][_marketItem.tokenId];

        if (
            (manageSecondarySale.owner == _saleDTO.seller &&
                manageSecondarySale.sold) ||
            (manageSecondarySale.owner != _saleDTO.seller)
        ) {
            isMsgValueEnough(
                _marketItem.price,
                _realAmount,
                _value,
                _marketItem.auctionProps.auctionId
            );
            secondarySale(_marketItem, _saleDTO, _value, _sender);
        } else {
            isMsgValueEnoughPrimarySale(
                _marketItem.price,
                _realAmount,
                _value,
                _marketItem.auctionProps.auctionId
            );
            primarySale(_marketItem, _saleDTO, _value, _sender, _realAmount);
        }
    }

    /**
     * @dev for the auction market, when an artist or collector decides to put a MintGoldDustERC1155 for auction
     *      is necessary to inform the quantity of tokens to be listed.
     *    @notice that in this case, at the moment of the purchase, the buyer needs to buy all the tokens
     *            listed for auction.
     *    @notice that this function check if the _amount being purchased by the onwer is the same of the amount
     *            of listed MintGoldDustERC1155 tokenId.
     * @param _saleDTO a parameter just like in doxygen (must be followed by parameter name)
     */
    function isBuyingAllListedTokens(SaleDTO memory _saleDTO) internal view {
        if (
            _saleDTO.amount <
            idMarketItemsByContractByOwner[_saleDTO.contractAddress][
                _saleDTO.tokenId
            ][_saleDTO.seller].tokenAmount
        ) {
            revert PurchaseOfERC1155InAuctionThatCoverAllListedItems();
        }
    }

    /**
     * @dev this function check if the an address represents a MintGoldDustNFT contract.
     *      It MUST be a MintGoldDustERC721 address or a MintGoldDustERC1155 address.
     * @notice that the function REVERTS with a MustBeERC721OrERC1155() error if the conditon is not met.
     * @param _contractAddress is a MintGoldDustNFT address.
     */
    function mustBeMintGoldDustERC721Or1155(
        address _contractAddress
    ) internal view {
        //   // Get the interfaces that the contract supports
        bool _isERC721 = _contractAddress == mintGoldDustERC721Address;

        bool _isERC1155 = _contractAddress == mintGoldDustERC1155Address;

        // Ensure that the contract is either an ERC721 or ERC1155
        if (!_isERC1155 && !_isERC721) {
            revert MustBeERC721OrERC1155();
        }
    }

    /**
     * @dev the main goal of this function is check if the address calling the function is the
     *      owner of the tokenId.
     * @notice that it REVERTS with a AddressUnauthorized error if the condition is not met.
     * @param _tokenId is the id that represent the token.
     * @param _sender is the address that started this flow.
     */
    function isNFTowner(uint256 _tokenId, address _sender) internal view {
        if (
            (MintGoldDustERC721(mintGoldDustERC721Address)).ownerOf(_tokenId) !=
            _sender
        ) {
            revert AddressUnauthorized("Not owner!");
        }
    }

    /**
     * @dev the goal here is, depending of the contract address (MintGoldDustERC721 or MintGoldDustERC1155)
     *      verify if the tokenId is really listed.
     * @notice that if not it REVERTS with a ItemIsNotListed() error.
     * @param _tokenId is the id that represent the token.
     * @param _contractAddress is a MintGoldDustNFT address.
     */
    function isTokenIdListed(
        uint256 _tokenId,
        address _contractAddress,
        address _seller
    ) internal view {
        if (
            idMarketItemsByContractByOwner[_contractAddress][_tokenId][_seller]
                .tokenAmount == 0
        ) {
            revert ItemIsNotListedBySeller(
                _tokenId,
                address(this),
                _contractAddress,
                _seller,
                msg.sender
            );
        }
        if (
            _contractAddress == mintGoldDustERC721Address &&
            (MintGoldDustERC721(mintGoldDustERC721Address)).ownerOf(_tokenId) !=
            address(this)
        ) {
            revert ItemIsNotListed(_contractAddress);
        }

        if (
            _contractAddress == mintGoldDustERC1155Address &&
            (MintGoldDustERC1155(mintGoldDustERC1155Address)).balanceOf(
                address(this),
                _tokenId
            ) ==
            0
        ) {
            revert ItemIsNotListed(_contractAddress);
        }
    }

    /**
     * @dev the goal here is verify if the MintGoldDustMarketplace contract has the quantity of
     *      MintGoldDustERC1155 tokens that the collector is trying to buy.
     * @notice that if not it REVERTS with a LessItemsListedThanTheRequiredAmount() error.
     * @param _tokenId is the id that represent the token.
     * @param _contractAddress is a MintGoldDustNFT address.
     * @param _marketPlaceAddress it can be a MintGoldDustMarketplaceAuction or a MintGoldDustSetPrice address.
     * @param _tokenQuantity the quantity of tokens desired by the buyer.
     * @param _seller is the address of the seller of this tokenId.
     */
    function hasEnoughAmountListed(
        uint256 _tokenId,
        address _contractAddress,
        address _marketPlaceAddress,
        uint256 _tokenQuantity,
        address _seller
    ) internal view {
        if (
            _contractAddress == mintGoldDustERC1155Address &&
            (MintGoldDustERC1155(mintGoldDustERC1155Address)).balanceOf(
                _marketPlaceAddress,
                _tokenId
            ) <
            _tokenQuantity
        ) {
            revert LessItemsListedThanTheRequiredAmount();
        }
        if (
            idMarketItemsByContractByOwner[_contractAddress][_tokenId][_seller]
                .tokenAmount < _tokenQuantity
        ) {
            revert LessItemsListedThanTheRequiredAmount();
        }
    }

    /**
     * @dev the goal here is verify if the address is the seller of the respective tokenId for a contract address.
     * @notice that if not it REVERTS with a AddressUnauthorized() error.
     * @param _tokenId is the id that represent the token.
     * @param _contractAddress is a MintGoldDustNFT address.
     * @param _seller is the address of the seller of this tokenId.
     */
    function isSeller(
        uint256 _tokenId,
        address _contractAddress,
        address _seller
    ) internal view {
        if (
            msg.sender !=
            idMarketItemsByContractByOwner[_contractAddress][_tokenId][_seller]
                .seller
        ) {
            revert AddressUnauthorized("Not seller!");
        }
    }

    function isNotListed(
        uint256 _tokenId,
        address _contractAddress,
        address _seller
    ) internal view {
        if (
            idMarketItemsByContractByOwner[_contractAddress][_tokenId][_seller]
                .tokenAmount > 0
        ) {
            revert ItemIsAlreadyListed(_contractAddress);
        }
    }

    function checkAmount(uint256 _amount) internal pure {
        if (_amount <= 0) {
            revert InvalidAmount();
        }
    }

    /**
     * @dev the main goal of this function is check if the address calling the function is the
     *      owner of the tokenId. For ERC1155 it means if the address has some balance for this token.
     * @notice that it REVERTS with a AddressUnauthorized error if the condition is not met.
     * @param _tokenId is the id that represent the token.
     * @param _tokenAmount is the quantity of tokens desired by the buyer.
     * @param _sender is the address that started this flow.
     */
    function checkBalanceForERC1155(
        uint256 _tokenId,
        uint256 _tokenAmount,
        address _sender
    ) private view {
        if (
            (MintGoldDustERC1155(mintGoldDustERC1155Address)).balanceOf(
                _sender,
                _tokenId
            ) < _tokenAmount
        ) {
            revert AddressUnauthorized(
                "Not owner or not has enough token quantity!"
            );
        }
    }

    /**
     * @notice that this function is responsible to start the primary sale flow.
     * @dev here we apply the fees related with the primary market that are:
     *                 - the primarySaleFeePercent and the collectorFee.
     * @param _marketItem The MarketItem struct parameter to use.
     *                 It consists of the following fields:
     *                    - tokenId: The tokenId of the marketItem.
     *                    - seller: The seller of the marketItem.
     *                    - price: The price which the item should be sold.
     *                    - isERC721: true is an MintGoldDustERC721 token.
     *                    - tokenAmount: The quantity of tokens to be listed for an MintGoldDustERC1155. For
     *                              MintGoldDustERC721 the amout must be always one.
     *                    - auctionProps:
     *                        - auctionId: the auctionId for the auction.
     *                        - startTime: the time that the auction have started.
     *                        - endTime: the time that the auction must be finished. Is the start time plus 24 hours.
     *                        - highestBidder: the bidder that did bid the highest value.
     *                        - highestBid: the value of the high bid.
     *                        - ended: a boolean that indicates if the auction was already finished or not.
     * @param _saleDTO The SaleDTO struct parameter to use.
     *                 It consists of the following fields:
     *                    - tokenid: The tokenId of the marketItem.
     *                    - amount: The quantity of tokens to be listed for an MintGoldDustERC1155. For
     *                              MintGoldDustERC721 the amout must be always one.
     *                    - contractAddress: The MintGoldDustERC1155 or the MintGoldDustERC721 address.
     *                    - seller: The seller of the marketItem.
     * @param _value The value to be paid for the purchase.
     * @param _sender The address that started this flow.
     *    @dev we need to receive the sender this way, because in the auction flow the purchase starts from
     *         the endAuction function in the MintGoldDustMarketplaceAuction contract. So from there the address
     *         that we get is the highst bidder that is stored in the marketItem struct. So we need to manage this way.
     */
    function primarySale(
        MarketItem memory _marketItem,
        SaleDTO memory _saleDTO,
        uint256 _value,
        address _sender,
        uint256 _realAmount
    ) private {
        MintGoldDustNFT _mintGoldDustNFT = getERC1155OrERC721(
            _marketItem.isERC721
        );
        ManageSecondarySale storage _manageSecondarySale = isSecondarySale[
            _saleDTO.contractAddress
        ][_saleDTO.tokenId];

        _manageSecondarySale.amount = _manageSecondarySale.amount - _realAmount;
        mintGoldDustMarketplace.updateSecondarySaleAmount(
            _saleDTO.contractAddress,
            _saleDTO.tokenId,
            _realAmount
        );

        _mintGoldDustNFT.updatePrimarySaleQuantityToSold(
            _saleDTO.tokenId,
            _realAmount
        );

        if (_manageSecondarySale.amount == 0) {
            _manageSecondarySale.sold = true;
            mintGoldDustMarketplace.updateSecondarySaleSold(
                _saleDTO.contractAddress,
                _saleDTO.tokenId,
                true
            );
            _mintGoldDustNFT.setTokenWasSold(_saleDTO.tokenId);
        }

        itemsSold.increment();

        uint256 fee;
        uint256 collFee;
        uint256 balance;

        /// @dev it removes the fee from the value that the buyer sent.
        uint256 netValue = (_value * (100e18)) / (103e18);

        fee =
            (netValue * mintGoldDustCompany.primarySaleFeePercent()) /
            (100e18);
        collFee = (netValue * mintGoldDustCompany.collectorFee()) / (100e18);
        balance = netValue - fee;

        checkIfIsSplitPaymentAndCall(
            _mintGoldDustNFT,
            _marketItem,
            _saleDTO,
            balance,
            fee,
            collFee,
            true,
            netValue,
            _sender
        );

        (bool successOwner, ) = payable(mintGoldDustCompany.owner()).call{
            value: collFee + fee
        }("");
        require(successOwner, "Transfer to owner failed.");
    }

    /**
     * @notice that this function will check if the item has or not the collaborator and call the correct
     *         flow (unique sale or split sale)
     * @dev Explain to a developer any extra details
     * @param _mintGoldDustNFT MintGoldDustNFT is an instance of MintGoldDustERC721 or MintGoldDustERC1155.
     * @param _marketItem the struct MarketItem - check it in the primarySale or secondary sale functions.
     * @param _saleDTO the struct SaleDTO - check it in the primarySale or secondary sale functions.
     * @param _balance uint256 that represents the total amount to be received by the seller after fee calculations.
     * @param _fee uint256 the primary or the secondary fee to be paid by the buyer.
     * @param _collFeeOrRoyalty uint256 that represent the collector fee or the royalty depending of the flow.
     * @param isPrimarySale bool that helps the code to go for the correct flow (Primary or Secondary sale).
     * @param _value The value to be paid for the purchase.
     * @param _sender The address that started this flow.
     *    @dev we need to receive the sender this way, because in the auction flow the purchase starts from
     *         the endAuction function in the MintGoldDustMarketplaceAuction contract. So from there the address
     *         that we get is the highst bidder that is stored in the marketItem struct. So we need to manage this way.
     */
    function checkIfIsSplitPaymentAndCall(
        MintGoldDustNFT _mintGoldDustNFT,
        MarketItem memory _marketItem,
        SaleDTO memory _saleDTO,
        uint256 _balance,
        uint256 _fee,
        uint256 _collFeeOrRoyalty,
        bool isPrimarySale,
        uint256 _value,
        address _sender
    ) private {
        address _artistOrSeller = _mintGoldDustNFT.tokenIdArtist(
            _saleDTO.tokenId
        );

        if (isPrimarySale) {
            _artistOrSeller = _saleDTO.seller;
        }

        if (_mintGoldDustNFT.hasTokenCollaborators(_saleDTO.tokenId)) {
            handleSplitPaymentCall(
                _mintGoldDustNFT,
                _saleDTO,
                _balance,
                _fee,
                _collFeeOrRoyalty,
                _artistOrSeller,
                isPrimarySale,
                _value,
                _sender
            );
            return;
        }

        if (isPrimarySale) {
            uniqueOwnerPrimarySale(
                _mintGoldDustNFT,
                _marketItem,
                _saleDTO,
                _fee,
                _collFeeOrRoyalty,
                _balance,
                _value,
                _sender
            );
            return;
        }

        uniqueOwnerSecondarySale(
            _marketItem,
            _mintGoldDustNFT,
            _saleDTO,
            _artistOrSeller,
            _fee,
            _collFeeOrRoyalty,
            _balance,
            _value,
            _sender
        );
    }

    /**
     * @dev this function is called when in the checkIfIsSplitPaymentAndCall function the flow goes for
     *      a sale for an item that does not has collaborators and is its first sale in the MintGoldDustMarketplace.
     * @param _mintGoldDustNFT explained in checkIfIsSplitPaymentAndCall function.
     * @param _marketItem explained in checkIfIsSplitPaymentAndCall function.
     * @param _saleDTO explained in checkIfIsSplitPaymentAndCall function.
     * @param _fee the primary fee to be paid for the MintGoldDustMarketplace.
     * @param _collFee represent the collector fee.
     * @param _balance represents the total amount to be received by the seller after fee calculations.
     * @param _value The value to be paid for the purchase.
     * @param _sender The address that started this flow.
     *    @dev we need to receive the sender this way, because in the auction flow the purchase starts from
     *         the endAuction function in the MintGoldDustMarketplaceAuction contract. So from there the address
     *         that we get is the highst bidder that is stored in the marketItem struct. So we need to manage this way.
     */
    function uniqueOwnerPrimarySale(
        MintGoldDustNFT _mintGoldDustNFT,
        MarketItem memory _marketItem,
        SaleDTO memory _saleDTO,
        uint256 _fee,
        uint256 _collFee,
        uint256 _balance,
        uint256 _value,
        address _sender
    ) private {
        _mintGoldDustNFT.transfer(
            address(this),
            _sender,
            _saleDTO.tokenId,
            _saleDTO.amount
        );

        updateIdMarketItemsByContractByOwnerMapping(_saleDTO);
        emit MintGoldDustNftPurchasedPrimaryMarket(
            itemsSold.current(),
            _saleDTO.tokenId,
            _saleDTO.seller,
            _sender,
            _value,
            _balance,
            _fee,
            _collFee,
            _saleDTO.amount,
            false,
            _marketItem.isERC721
        );

        (bool successSeller, ) = payable(_marketItem.seller).call{
            value: _balance
        }("");
        require(successSeller, "Transfer to seller failed.");
    }

    function updateIdMarketItemsByContractByOwnerMapping(
        SaleDTO memory _saleDTO
    ) private {
        MarketItem storage item = idMarketItemsByContractByOwner[
            _saleDTO.contractAddress
        ][_saleDTO.tokenId][_saleDTO.seller];

        item.tokenAmount = item.tokenAmount - _saleDTO.amount;

        if (item.tokenAmount == 0) {
            delete idMarketItemsByContractByOwner[_saleDTO.contractAddress][
                _saleDTO.tokenId
            ][_saleDTO.seller];
        }
    }

    /**
     * @dev this function is called when in the checkIfIsSplitPaymentAndCall function the flow goes for
     *      a sale for an item that does not has collaborators and was already sold the first time.
     * @param _marketItem explained in checkIfIsSplitPaymentAndCall function.
     * @param _mintGoldDustNFT explained in checkIfIsSplitPaymentAndCall function.
     * @param _saleDTO explained in checkIfIsSplitPaymentAndCall function.
     * @param _artist the creator of the artwork to receive the royalties.
     * @param _fee the secondary fee to be paid for the MintGoldDustMarketplace.
     * @param _royalty represent the royalty to be paid for the artist.
     * @param _balance represents the total amount to be received by the seller after fee calculations.
     * @param _value The value to be paid for the purchase.
     * @param _sender The address that started this flow.
     *    @dev we need to receive the sender this way, because in the auction flow the purchase starts from
     *         the endAuction function in the MintGoldDustMarketplaceAuction contract. So from there the address
     *         that we get is the highst bidder that is stored in the marketItem struct. So we need to manage this way.
     */
    function uniqueOwnerSecondarySale(
        MarketItem memory _marketItem,
        MintGoldDustNFT _mintGoldDustNFT,
        SaleDTO memory _saleDTO,
        address _artist,
        uint256 _fee,
        uint256 _royalty,
        uint256 _balance,
        uint256 _value,
        address _sender
    ) private {
        _mintGoldDustNFT.transfer(
            address(this),
            _sender,
            _saleDTO.tokenId,
            _saleDTO.amount
        );

        updateIdMarketItemsByContractByOwnerMapping(_saleDTO);

        emit MintGoldDustNftPurchasedSecondaryMarket(
            itemsSold.current(),
            _saleDTO.tokenId,
            _saleDTO.seller,
            _sender,
            _value,
            _balance,
            _mintGoldDustNFT.tokenIdRoyaltyPercent(_saleDTO.tokenId),
            _royalty,
            _artist,
            _fee,
            _saleDTO.amount,
            false,
            _marketItem.isERC721
        );

        (bool successArtist, ) = payable(_artist).call{value: _royalty}("");
        require(successArtist, "Transfer to artist failed.");
    }

    /**
     * @notice that is the function responsible to manage the split sale flow.
     * @dev the _isPrimarySale is very important. It define if the value to be received is
     *      the balance for primary sale or the royalty for secondary sales.
     *    @notice that the emitEventForSplitPayment os called to trigger the correct event depending of the flow.
     * @param _balance uint256 that represents the total amount to be received by the seller after fee calculations.
     * @param _fee uint256 the primary or the secondary fee to be paid by the buyer.
     * @param _collFeeOrRoyalty uint256 that represent the collector fee or the royalty depending of the flow.
     * @param _artist the creator of the artwork to receive the royalties.
     * @param _saleDTO The SaleDTO struct parameter to use.
     *                 It consists of the following fields:
     *                    - tokenid: The tokenId of the marketItem.
     *                    - amount: The quantity of tokens to be listed for an MintGoldDustERC1155. For
     *                              MintGoldDustERC721 the amout must be always one.
     *                    - contractAddress: The MintGoldDustERC1155 or the MintGoldDustERC721 address.
     *                    - seller: The seller of the marketItem.
     * @param _isPrimarySale bool that helps the code to go for the correct flow (Primary or Secondary sale).
     * @param _value The value to be paid for the purchase.
     * @param _sender The address that started this flow.
     *    @dev we need to receive the sender this way, because in the auction flow the purchase starts from
     *         the endAuction function in the MintGoldDustMarketplaceAuction contract. So from there the address
     *         that we get is the highst bidder that is stored in the marketItem struct. So we need to manage this way.
     */
    function splittedSale(
        uint256 _balance,
        uint256 _fee,
        uint256 _collFeeOrRoyalty,
        address _artist,
        MintGoldDustNFT _mintGoldDustNFT,
        SaleDTO memory _saleDTO,
        bool _isPrimarySale,
        uint256 _value,
        address _sender
    ) private {
        MarketItem memory _marketItem = getMarketItem(_saleDTO);

        uint256 balanceOrRoyalty = _collFeeOrRoyalty;

        if (_isPrimarySale) {
            balanceOrRoyalty = _balance;
        }

        uint256 _tokenIdCollaboratorsQuantity = _mintGoldDustNFT
            .tokenIdCollaboratorsQuantity(_saleDTO.tokenId);

        uint256 balanceSplitPart = (balanceOrRoyalty *
            _mintGoldDustNFT.tokenIdCollaboratorsPercentage(
                _saleDTO.tokenId,
                0
            )) / (100e18);

        (bool successArtist, ) = payable(_artist).call{value: balanceSplitPart}(
            ""
        );
        require(successArtist, "Split tx to artist failed.");

        emit NftPurchasedCollaboratorAmount(
            itemsSold.current(),
            _artist,
            balanceSplitPart
        );

        for (uint256 i = 1; i < _tokenIdCollaboratorsQuantity; i++) {
            balanceSplitPart =
                (balanceOrRoyalty *
                    _mintGoldDustNFT.tokenIdCollaboratorsPercentage(
                        _saleDTO.tokenId,
                        i
                    )) /
                (100e18);
            address collaborator = _mintGoldDustNFT.tokenCollaborators(
                _saleDTO.tokenId,
                i - 1
            );

            (bool successCollaborator, ) = payable(collaborator).call{
                value: balanceSplitPart
            }("");
            require(successCollaborator, "Split tx to collab failed.");

            emit NftPurchasedCollaboratorAmount(
                itemsSold.current(),
                collaborator,
                balanceSplitPart
            );
        }

        updateIdMarketItemsByContractByOwnerMapping(_saleDTO);
        emitEventForSplitPayment(
            _saleDTO,
            _marketItem,
            _mintGoldDustNFT,
            _artist,
            _balance,
            _fee,
            _collFeeOrRoyalty,
            _isPrimarySale,
            _value,
            _sender
        );
    }

    /**
     * @notice that is the function responsible to trigger the correct event for splitted sales.
     * @dev the _isPrimarySale defines if the primary sale or the secondary sale should be triggered.
     * @param _mintGoldDustNFT MintGoldDustNFT is an instance of MintGoldDustERC721 or MintGoldDustERC1155.
     * @param _marketItem explained in splittedSale function.
     * @param _artist the creator of the artwork to receive the royalties.
     * @param _artist the creator of the artwork to receive the royalties.
     * @param _balance uint256 that represents the total amount to be received by the seller after fee calculations.
     * @param _fee uint256 the primary or the secondary fee to be paid by the buyer.
     * @param _collFeeOrRoyalty uint256 that represent the collector fee or the royalty depending of the flow.
     * @param _isPrimarySale bool that helps the code to go for the correct flow (Primary or Secondary sale).
     * @param _value The value to be paid for the purchase.
     * @param _sender The address that started this flow.
     *    @dev we need to receive the sender this way, because in the auction flow the purchase starts from
     *         the endAuction function in the MintGoldDustMarketplaceAuction contract. So from there the address
     *         that we get is the highst bidder that is stored in the marketItem struct. So we need to manage this way.
     */
    function emitEventForSplitPayment(
        SaleDTO memory _saleDTO,
        MarketItem memory _marketItem,
        MintGoldDustNFT _mintGoldDustNFT,
        address _artist,
        uint256 _balance,
        uint256 _fee,
        uint256 _collFeeOrRoyalty,
        bool _isPrimarySale,
        uint256 _value,
        address _sender
    ) private {
        if (_isPrimarySale) {
            emit MintGoldDustNftPurchasedPrimaryMarket(
                itemsSold.current(),
                _saleDTO.tokenId,
                _saleDTO.seller,
                _sender,
                _value,
                _balance,
                _fee,
                _collFeeOrRoyalty,
                _saleDTO.amount,
                true,
                _marketItem.isERC721
            );
            return;
        }

        emit MintGoldDustNftPurchasedSecondaryMarket(
            itemsSold.current(),
            _saleDTO.tokenId,
            _saleDTO.seller,
            _sender,
            _value,
            _balance,
            _mintGoldDustNFT.tokenIdRoyaltyPercent(_saleDTO.tokenId),
            _collFeeOrRoyalty,
            _artist,
            _fee,
            _saleDTO.amount,
            true,
            _marketItem.isERC721
        );
    }

    /**
     * @notice that this function do continuity to split payment flow.
     * @dev Explain to a developer any extra details
     * @param _mintGoldDustNFT MintGoldDustNFT is an instance of MintGoldDustERC721 or MintGoldDustERC1155.
     * @param _saleDTO The SaleDTO struct parameter to use.
     *                 It consists of the following fields:
     *                    - tokenid: The tokenId of the marketItem.
     *                    - amount: The quantity of tokens to be listed for an MintGoldDustERC1155. For
     *                              MintGoldDustERC721 the amout must be always one.
     *                    - contractAddress: The MintGoldDustERC1155 or the MintGoldDustERC721 address.
     *                    - seller: The seller of the marketItem.
     * @param _balance uint256 that represents the total amount to be received by the seller after fee calculations.
     * @param _fee uint256 the primary or the secondary fee to be paid by the buyer.
     * @param _collFeeOrRoyalty uint256 that represent the collerctor fee or the royalty depending of the flow.
     * @param _artistOrSeller address for the artist on secondary sales and for the seller on the primary sales.
     * @param _isPrimarySale bool that helps the code to go for the correct flow (Primary or Secondary sale).
     * @param _value The value to be paid for the purchase.
     * @param _sender The address that started this flow.
     *    @dev we need to receive the sender this way, because in the auction flow the purchase starts from
     *         the endAuction function in the MintGoldDustMarketplaceAuction contract. So from there the address
     *         that we get is the highst bidder that is stored in the marketItem struct. So we need to manage this way.
     */
    function handleSplitPaymentCall(
        MintGoldDustNFT _mintGoldDustNFT,
        SaleDTO memory _saleDTO,
        uint256 _balance,
        uint256 _fee,
        uint256 _collFeeOrRoyalty,
        address _artistOrSeller,
        bool _isPrimarySale,
        uint256 _value,
        address _sender
    ) private {
        _mintGoldDustNFT.transfer(
            address(this),
            _sender,
            _saleDTO.tokenId,
            _saleDTO.amount
        );
        splittedSale(
            _balance,
            _fee,
            _collFeeOrRoyalty,
            _artistOrSeller,
            _mintGoldDustNFT,
            _saleDTO,
            _isPrimarySale,
            _value,
            _sender
        );
    }

    /**
     * @notice that this function is responsible to start the secondary sale flow.
     * @dev here we apply the fees related with the secondary market that are:
     *                 - the secondarySaleFeePercent and the tokenIdRoyaltyPercent.
     * @param _marketItem The MarketItem struct parameter to use.
     *                 It consists of the following fields:
     *                    - tokenId: The tokenId of the marketItem.
     *                    - seller: The seller of the marketItem.
     *                    - price: The price which the item should be sold.
     *                    - sold: It says if an item was or not sold.
     *                    - isAuction: true if the item was listed for marketplace auction and false if for set price market.
     *                    - isERC721: true is an MintGoldDustERC721 token.
     *                    - tokenAmount: The quantity of tokens to be listed for an MintGoldDustERC1155. For
     *                              MintGoldDustERC721 the amout must be always one.
     *                    - auctionProps:
     *                        - endTime: the time that the auction must be finished. Is the start time plus 24 hours.
     *                        - highestBidder: the bidder that did bid the highest value.
     *                        - highestBid: the value of the high bid.
     *                        - ended: a boolean that indicates if the auction was already finished or not.
     * @param _saleDTO The SaleDTO struct parameter to use.
     *                 It consists of the following fields:
     *                    - tokenid: The tokenId of the marketItem.
     *                    - amount: The quantity of tokens to be listed for an MintGoldDustERC1155. For
     *                              MintGoldDustERC721 the amout must be always one.
     *                    - contractAddress: The MintGoldDustERC1155 or the MintGoldDustERC721 address.
     *                    - seller: The seller of the marketItem.
     * @param _value The value to be paid for the purchase.
     * @param _sender The address that started this flow.
     *    @dev we need to receive the sender this way, because in the auction flow the purchase starts from
     *         the endAuction function in the MintGoldDustMarketplaceAuction contract. So from there the address
     *         that we get is the highst bidder that is stored in the marketItem struct. So we need to manage this way.
     */
    function secondarySale(
        MarketItem memory _marketItem,
        SaleDTO memory _saleDTO,
        uint256 _value,
        address _sender
    ) private {
        MintGoldDustNFT _mintGoldDustNFT = getERC1155OrERC721(
            _marketItem.isERC721
        );

        itemsSold.increment();

        uint256 fee;
        uint256 royalty;
        uint256 balance;

        fee =
            (_value * mintGoldDustCompany.secondarySaleFeePercent()) /
            (100e18);
        royalty =
            (_value *
                _mintGoldDustNFT.tokenIdRoyaltyPercent(_saleDTO.tokenId)) /
            (100e18);

        balance = _value - (fee + royalty);

        checkIfIsSplitPaymentAndCall(
            _mintGoldDustNFT,
            _marketItem,
            _saleDTO,
            balance,
            fee,
            royalty,
            false,
            _value,
            _sender
        );

        (bool successOwner, ) = payable(mintGoldDustCompany.owner()).call{
            value: fee
        }("");
        require(successOwner, "Transaction to owner failed.");

        (bool successSeller, ) = payable(_marketItem.seller).call{
            value: balance
        }("");
        require(successSeller, "Transaction to seller failed.");
    }

    /// @dev it is a private function to verify if the msg.value is enough to pay the product between the
    ///      price of the token and the quantity desired.
    /// @param _price the price of one market item.
    /// @param _amount the quantity desired for this purchase.
    /// @param _value the value sent by the buyer.
    /// @notice that it REVERTS with a InvalidAmountForThisPurchase() error if the condition is not met.
    function isMsgValueEnough(
        uint256 _price,
        uint256 _amount,
        uint256 _value,
        uint256 _auctionId
    ) private pure {
        uint256 realAmount = _amount;
        if (_auctionId != 0) {
            realAmount = 1;
        }

        if (_value != _price * realAmount) {
            revert InvalidAmountForThisPurchase();
        }
    }

    /**
     * @dev Checks if the provided value is enough to cover the total price of the product, including a 3% fee.
     * @param _price The unit price of the item.
     * @param _amount The quantity of items desired for purchase.
     * @param _value The value sent with the transaction, expected to cover the totalPrice including the 3% fee.
     * @notice Reverts with the InvalidAmountForThisPurchase error if the provided _value doesn't match the expected amount.
     */
    function isMsgValueEnoughPrimarySale(
        uint256 _price,
        uint256 _amount,
        uint256 _value,
        uint256 _auctionId
    ) private pure {
        uint256 realAmount = _amount;
        if (_auctionId != 0) {
            realAmount = 1;
        }

        // Calculate total price for the _amount
        uint256 totalPrice = _price * realAmount;

        // Calculate the increase using higher precision
        uint256 increase = (totalPrice * 3) / 100;

        uint256 realPrice = totalPrice + increase;

        // Check if _value is equal to totalPrice + realPrice
        if (_value != realPrice && _auctionId == 0) {
            revert InvalidAmountForThisPurchase();
        }

        if (_value < realPrice && _auctionId > 0) {
            revert InvalidAmountForThisPurchase();
        }
    }
}
