// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./OpenOffers.sol";
import "./Auction.sol";
import "./FixedPrice.sol";


/**
 * @title ERC721 contract implementation
 * @dev Implements the ERC721 interface for the Farbe artworks
 */
contract FarbeArt is ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl {
    // counter for tracking token IDs
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // details of the artwork
    struct artworkDetails {
        address tokenCreator;
        uint16 creatorCut;
        bool isSecondarySale;
    }

    // mapping of token id to original creator
    mapping(uint256 => artworkDetails) tokenIdToDetails;

    // platform cut on primary sales in %age * 10
    uint16 public platformCutOnPrimarySales;

    // constant for defining the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // reference to auction contract
    AuctionSale public auctionSale;
    // reference to fixed price contract
    FixedPriceSale public fixedPriceSale;
    // reference to open offer contract
    OpenOffersSale public openOffersSale;

    event TokenUriChanged(uint256 tokenId, string uri);

    /**
     * @dev Constructor for the ERC721 contract
     */
    constructor() ERC721("FarbeArt", "FBA") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    /**
     * @dev Function to mint an artwork as NFT. If no gallery is approved, the parameter is zero
     * @param _to The address to send the minted NFT
     * @param _creatorCut The cut that the original creator will take on secondary sales
     */
    function safeMint(
        address _to,
        address _galleryAddress,
        uint8 _numberOfCopies,
        uint16 _creatorCut,
        string[] memory _tokenURI
    ) public {
        require(hasRole(MINTER_ROLE, msg.sender), "does not have minter role");

        require(_tokenURI.length == _numberOfCopies, "Metadata URIs not equal to editions");

        for(uint i = 0; i < _numberOfCopies; i++){
            // mint the token
            _safeMint(_to, _tokenIdCounter.current());
            // approve the gallery (0 if no gallery authorized)
            approve(_galleryAddress, _tokenIdCounter.current());
            // set the token URI
            _setTokenURI(_tokenIdCounter.current(), _tokenURI[i]);
            // track token creator
            tokenIdToDetails[_tokenIdCounter.current()].tokenCreator = _to;
            // track creator's cut
            tokenIdToDetails[_tokenIdCounter.current()].creatorCut = _creatorCut;
            // increment tokenId
            _tokenIdCounter.increment();
        }
    }

    /**
     * @dev Implementation of ERC721Enumerable
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal
    override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Destroy (burn) the NFT
     * @param tokenId The ID of the token to burn
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for the token
     * @param tokenId ID of the token to return URI of
     * @return URI for the token
     */
    function tokenURI(uint256 tokenId) public view
    override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Implementation of the ERC165 interface
     * @param interfaceId The Id of the interface to check support for
     */
    function supportsInterface(bytes4 interfaceId) public view
    override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}


/**
 * @title Farbe NFT sale contract
 * @dev Extension of the FarbeArt contract to add sale functionality
 */
contract FarbeArtSale is FarbeArt {
    /**
     * @dev Only allow owner to execute if no one (gallery) has been approved
     * @param _tokenId Id of the token to check approval and ownership of
     */
    modifier onlyOwnerOrApproved(uint256 _tokenId) {
        if(getApproved(_tokenId) == address(0)){
            require(ownerOf(_tokenId) == msg.sender, "Not owner or approved");
        } else {
            require(getApproved(_tokenId) == msg.sender, "Only approved can list, revoke approval to list yourself");
        }
        _;
    }

    /**
     * @dev Make sure the starting time is not greater than 60 days
     * @param _startingTime starting time of the sale in UNIX timestamp
     */
    modifier onlyValidStartingTime(uint64 _startingTime) {
        if(_startingTime > block.timestamp) {
            require(_startingTime - block.timestamp <= 60 days, "Start time too far");
        }
        _;
    }

    /**
     * @dev Set the primary platform cut on deployment
     * @param _platformCut Cut that the platform will take on primary sales
     */
    constructor(uint16 _platformCut) {
        platformCutOnPrimarySales = _platformCut;
    }

    function burn(uint256 tokenId) external {
        // must be owner
        require(ownerOf(tokenId) == msg.sender);
        _burn(tokenId);
    }

    /**
     * @dev Change the tokenUri of the token. Can only be changed when the creator is the owner
     * @param _tokenURI New Uri of the token
     * @param _tokenId Id of the token to change Uri of
     */
    function changeTokenUri(string memory _tokenURI, uint256 _tokenId) external {
        // must be owner and creator
        require(ownerOf(_tokenId) == msg.sender, "Not owner");
        require(tokenIdToDetails[_tokenId].tokenCreator == msg.sender, "Not creator");

        _setTokenURI(_tokenId, _tokenURI);

        emit TokenUriChanged(
            uint256(_tokenId),
            string(_tokenURI)
        );
    }

    /**
     * @dev Set the address for the external auction contract. Can only be set by the admin
     * @param _address Address of the external contract
     */
    function setAuctionContractAddress(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        AuctionSale auction = AuctionSale(_address);

        require(auction.isFarbeSaleAuction());

        auctionSale = auction;
    }

    /**
     * @dev Set the address for the external auction contract. Can only be set by the admin
     * @param _address Address of the external contract
     */
    function setFixedSaleContractAddress(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        FixedPriceSale fixedSale = FixedPriceSale(_address);

        require(fixedSale.isFarbeFixedSale());

        fixedPriceSale = fixedSale;
    }

    /**
     * @dev Set the address for the external auction contract. Can only be set by the admin
     * @param _address Address of the external contract
     */
    function setOpenOffersContractAddress(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        OpenOffersSale openOffers = OpenOffersSale(_address);

        require(openOffers.isFarbeOpenOffersSale());

        openOffersSale = openOffers;
    }

    /**
     * @dev Set the percentage cut that the platform will take on all primary sales
     * @param _platformCut The cut that the platform will take on primary sales as %age * 10 for values < 1%
     */
    function setPlatformCut(uint16 _platformCut) external onlyRole(DEFAULT_ADMIN_ROLE) {
        platformCutOnPrimarySales = _platformCut;
    }

    /**
     * @dev Track artwork as sold before by updating the mapping. Can only be called by the sales contracts
     * @param _tokenId The id of the token which was sold
     */
    function setSecondarySale(uint256 _tokenId) external {
        require(msg.sender != address(0));
        require(msg.sender == address(auctionSale) || msg.sender == address(fixedPriceSale)
            || msg.sender == address(openOffersSale), "Caller is not a farbe sale contract");
        tokenIdToDetails[_tokenId].isSecondarySale = true;
    }

    /**
     * @dev Checks from the mapping if the token has been sold before
     * @param _tokenId ID of the token to check
     * @return bool Weather this is a secondary sale (token has been sold before)
     */
    function getSecondarySale(uint256 _tokenId) public view returns (bool) {
        return tokenIdToDetails[_tokenId].isSecondarySale;
    }

    /**
     * @dev Creates the sale auction for the token by calling the external auction contract. Can only be called by owner,
     * individual external contract calls are expensive so a single function is used to pass all parameters
     * @param _tokenId ID of the token to put on auction
     * @param _startingPrice Starting price of the auction
     * @param _startingTime Starting time of the auction in UNIX timestamp
     * @param _duration The duration in seconds for the auction
     * @param _galleryCut The cut for the gallery, will be 0 if gallery is not involved
     */
    function createSaleAuction(
        uint256 _tokenId,
        uint128 _startingPrice,
        uint64 _startingTime,
        uint64 _duration,
        uint16 _galleryCut
    )
    external
    onlyOwnerOrApproved(_tokenId)
    onlyValidStartingTime(_startingTime)
    {
        // using struct to avoid 'stack too deep' error
        artworkDetails memory _details = artworkDetails(
            tokenIdToDetails[_tokenId].tokenCreator,
            tokenIdToDetails[_tokenId].creatorCut,
            false
        );

        require(_details.creatorCut + _galleryCut + platformCutOnPrimarySales < 1000, "Cuts greater than 100%");

        // determine gallery address (0 if called by owner)
        address _galleryAddress = ownerOf(_tokenId) == msg.sender ? address(0) : msg.sender;

        // get reference to owner before transfer
        address _seller = ownerOf(_tokenId);

        // escrow the token into the auction smart contract
        safeTransferFrom(_seller, address(auctionSale), _tokenId);

        // call the external contract function to create the auction
        auctionSale.createSale(
            _tokenId,
            _startingPrice,
            _startingTime,
            _duration,
            _details.tokenCreator,
            _seller,
            _galleryAddress,
            _details.creatorCut,
            _galleryCut,
            platformCutOnPrimarySales
        );
    }

    /**
     * @dev Creates the fixed price sale for the token by calling the external fixed sale contract. Can only be called by owner.
     * Individual external contract calls are expensive so a single function is used to pass all parameters
     * @param _tokenId ID of the token to put on auction
     * @param _fixedPrice Fixed price of the auction
     * @param _startingTime Starting time of the auction in UNIX timestamp
     * @param _galleryCut The cut for the gallery, will be 0 if gallery is not involved
     */
    function createSaleFixedPrice(
        uint256 _tokenId,
        uint128 _fixedPrice,
        uint64 _startingTime,
        uint16 _galleryCut
    )
    external
    onlyOwnerOrApproved(_tokenId)
    onlyValidStartingTime(_startingTime)
    {
        // using struct to avoid 'stack too deep' error
        artworkDetails memory _details = artworkDetails(
            tokenIdToDetails[_tokenId].tokenCreator,
            tokenIdToDetails[_tokenId].creatorCut,
            false
        );

        require(_details.creatorCut + _galleryCut + platformCutOnPrimarySales < 1000, "Cuts greater than 100%");

        // determine gallery address (0 if called by owner)
        address _galleryAddress = ownerOf(_tokenId) == msg.sender ? address(0) : msg.sender;

        // get reference to owner before transfer
        address _seller = ownerOf(_tokenId);

        // escrow the token into the auction smart contract
        safeTransferFrom(ownerOf(_tokenId), address(fixedPriceSale), _tokenId);

        // call the external contract function to create the auction
        fixedPriceSale.createSale(
            _tokenId,
            _fixedPrice,
            _startingTime,
            _details.tokenCreator,
            _seller,
            _galleryAddress,
            _details.creatorCut,
            _galleryCut,
            platformCutOnPrimarySales
        );
    }

    /**
     * @dev Creates the open offer sale for the token by calling the external open offers contract. Can only be called by owner,
     * individual external contract calls are expensive so a single function is used to pass all parameters
     * @param _tokenId ID of the token to put on auction
     * @param _startingTime Starting time of the auction in UNIX timestamp
     * @param _galleryCut The cut for the gallery, will be 0 if gallery is not involved
     */
    function createSaleOpenOffer(
        uint256 _tokenId,
        uint64 _startingTime,
        uint16 _galleryCut
    )
    external
    onlyOwnerOrApproved(_tokenId)
    onlyValidStartingTime(_startingTime)
    {
        // using struct to avoid 'stack too deep' error
        artworkDetails memory _details = artworkDetails(
            tokenIdToDetails[_tokenId].tokenCreator,
            tokenIdToDetails[_tokenId].creatorCut,
            false
        );

        require(_details.creatorCut + _galleryCut + platformCutOnPrimarySales < 1000, "Cuts greater than 100%");

        // get reference to owner before transfer
        address _seller = ownerOf(_tokenId);

        // determine gallery address (0 if called by owner)
        address _galleryAddress = ownerOf(_tokenId) == msg.sender ? address(0) : msg.sender;

        // escrow the token into the auction smart contract
        safeTransferFrom(ownerOf(_tokenId), address(openOffersSale), _tokenId);

        // call the external contract function to create the auction
        openOffersSale.createSale(
            _tokenId,
            _startingTime,
            _details.tokenCreator,
            _seller,
            _galleryAddress,
            _details.creatorCut,
            _galleryCut,
            platformCutOnPrimarySales
        );
    }
}