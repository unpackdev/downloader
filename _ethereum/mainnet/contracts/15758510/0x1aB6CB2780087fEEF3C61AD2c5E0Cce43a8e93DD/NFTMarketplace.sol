// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";
error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error ItemNotForSale(address nftAddress, uint256 tokenId);
error NotListed(address nftAddress, uint256 tokenId);
error AlreadyListed(address nftAddress, uint256 tokenId);
error NotOwner();
error NotApprovedForMarketplace();
error PriceMustBeAboveZero();
contract NftMarketplace is ReentrancyGuard {
    struct Listing {
        uint256 price;
        address seller;
    }
    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );
    event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );
    event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );
    mapping(address => mapping(uint256 => Listing)) private s_listings;
    modifier notListed(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert AlreadyListed(nftAddress, tokenId);
        }
        _;
    }
    modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price <= 0) {
            revert NotListed(nftAddress, tokenId);
        }
        _;
    }
    modifier isOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) {
            revert NotOwner();
        }
        _;
    }
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /////////////////////
    // Main Functions //
    /////////////////////
    /*
     * @notice Method for checking if contract supports royalties
     * @param nftAddress Address of NFT contract
     */
    function checkRoyalty(address _contract) 
    internal
    view 
    returns(bool)
    {
        (bool success) = IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
        return success;
    }
    /*
     * @notice Method for listing NFT
     * @param nftAddress Address of NFT contract
     * @param tokenId Token ID of NFT
     * @param price sale price for each item
     */
    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        notListed(nftAddress, tokenId, msg.sender)
        isOwner(nftAddress, tokenId, msg.sender)
    {
        if (price <= 0) {
            revert PriceMustBeAboveZero();
        }
        IERC721 nft = IERC721(nftAddress);
        if (!nft.isApprovedForAll(msg.sender, address(this))) {
            revert NotApprovedForMarketplace();
        }
        s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }
    /*
     * @notice Method for cancelling listing
     * @param nftAddress Address of NFT contract
     * @param tokenId Token ID of NFT
     */
    function cancelListing(address nftAddress, uint256 tokenId)
        external
        isOwner(nftAddress, tokenId, msg.sender)
        isListed(nftAddress, tokenId)
    {
        delete (s_listings[nftAddress][tokenId]);
        emit ItemCanceled(msg.sender, nftAddress, tokenId);
    }
    /*
     * @notice Method for buying listing
     * @notice The owner of an NFT could unapprove the marketplace,
     * @param nftAddress Address of NFT contract
     * @param tokenId Token ID of NFT
     */
    function buyItem(address nftAddress, uint256 tokenId)
        external
        payable
        isListed(nftAddress, tokenId)
        nonReentrant
    {
        Listing memory listedItem = s_listings[nftAddress][tokenId];
        if (msg.value < listedItem.price) {
            revert PriceNotMet(nftAddress, tokenId, listedItem.price);
        }
        if(checkRoyalty(nftAddress)){
            (address receiver, uint256 amount) = IERC2981(nftAddress).royaltyInfo(tokenId, listedItem.price);
            if(receiver != nftAddress){
                (bool royaltyTransfer, ) = payable(receiver).call{value: amount}("");
                (bool transfer, ) = payable(listedItem.seller).call{value: listedItem.price - amount}("");
                require(royaltyTransfer, "Royalty transfer failed");
                require(transfer, "Transfer failed");
            } else {
                (bool transfer, ) = payable(listedItem.seller).call{value: listedItem.price}("");
                require(transfer, "Transfer failed");
            }
        } else {
                (bool transfer, ) = payable(listedItem.seller).call{value: listedItem.price}("");
                require(transfer, "Transfer failed");
        }
        delete (s_listings[nftAddress][tokenId]);
        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
        emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
    }
    /*
     * @notice Method for buying listing item giving fashionchain the royalties
     * @notice The owner of an NFT could unapprove the marketplace,
     * @param nftAddress Address of NFT contract
     * @param tokenId Token ID of NFT
     */
    function buyFashionchainItem(address nftAddress, uint256 tokenId)
        external
        payable
        isListed(nftAddress, tokenId)
        nonReentrant
    {
        Listing memory listedItem = s_listings[nftAddress][tokenId];
        if (msg.value < listedItem.price) {
            revert PriceNotMet(nftAddress, tokenId, listedItem.price);
        }
        if(checkRoyalty(nftAddress)){
            (address receiver, uint256 amount) = IERC2981(nftAddress).royaltyInfo(tokenId, listedItem.price);
            if(receiver != nftAddress){
                (bool royaltyTransfer, ) = payable(receiver).call{value: amount}("");
                (bool transfer, ) = payable(listedItem.seller).call{value: listedItem.price - amount}("");
                require(royaltyTransfer, "Royalty transfer failed");
                require(transfer, "Transfer failed");
            } else{
                (bool royaltyTransfer, ) = payable(address(0xfA4dCb5813c1530461FFC16CFA89fE91d653055C)).call{value: amount}("");
                (bool transfer, ) = payable(listedItem.seller).call{value: listedItem.price - amount}("");
                require(royaltyTransfer, "Royalty transfer failed");
                require(transfer, "Transfer failed");
            }
        } else {
                (bool transfer, ) = payable(listedItem.seller).call{value: listedItem.price}("");
                require(transfer, "Transfer failed");
        }
        delete (s_listings[nftAddress][tokenId]);
        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
        emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
    }
    /*
     * @notice Method for updating listing
     * @param nftAddress Address of NFT contract
     * @param tokenId Token ID of NFT
     * @param newPrice Price in Wei of the item
     */
    function updateListing(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isListed(nftAddress, tokenId)
        nonReentrant
        isOwner(nftAddress, tokenId, msg.sender)
    {
        //We should check the value of `newPrice` and revert if it's below zero (like we also check in `listItem()`)
        if (newPrice <= 0) {
            revert PriceMustBeAboveZero();
        }
        s_listings[nftAddress][tokenId].price = newPrice;
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
    }
    /////////////////////
    // Getter Functions //
    /////////////////////
    function getListing(address nftAddress, uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        return s_listings[nftAddress][tokenId];
    }
}