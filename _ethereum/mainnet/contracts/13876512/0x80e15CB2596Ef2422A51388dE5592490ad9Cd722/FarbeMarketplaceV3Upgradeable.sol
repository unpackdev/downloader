// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./FarbeArtV3Upgradeable.sol";
import "./FixedPriceV3Upgradeable.sol";
import "./OpenOffersV3Upgradeable.sol";
import "./AuctionV3Upgradeable.sol";


contract FarbeMarketplaceV3Upgradeable is FixedPriceSaleV3Upgradeable, AuctionSaleV3Upgradeable, OpenOffersSaleV3Upgradeable, PausableUpgradeable {
    bool public isFarbeMarketplace;

    // Add the library methods
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    
    mapping(address => EnumerableMap.UintToAddressMap) institutionToTokenCollection;
    
    struct tokenDetails {
        address tokenCreator;
        uint16 creatorCut;
        bool isInstitution;
    }

    event AssignedToInstitution(address institutionAddress, uint256 tokenId, address owner);
    event TakeBackFromInstitution(uint256 tokenId, address institution,address owner);

    // platform cut on primary sales in %age * 10
    uint16 public platformCutOnPrimarySales;
    
    function initialize(address _nftAddress, address _platformAddress, uint16 _platformCut) public initializer {
        // check NFT contract supports ERC721 interface
        FarbeArtSaleV3Upgradeable candidateContract = FarbeArtSaleV3Upgradeable(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __PullPayment_init();
        __Pausable_init();
        NFTContract = candidateContract;
        platformCutOnPrimarySales = _platformCut;
        platformWalletAddress = _platformAddress;
    }

    /**
     * @dev Puclic function(only admin authorized) to pause the contract
     */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Puclic function(only admin authorized) to unpause the contract
     */
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev This function is reponsible to set platformCut
     * @param _platformCut cut to set
     */
    function setPlatformCut(uint16 _platformCut) external onlyRole(DEFAULT_ADMIN_ROLE) {
        platformCutOnPrimarySales = _platformCut;
    }

    /**
     * @dev This function is responsible for changing platform wallet address. Can only be called by the admin
     * @param _platformAddress new address to set
     */
    function setPlatformAddress(address _platformAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        platformWalletAddress = _platformAddress;
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
    
    modifier onlyFarbeContract() {
        // check the caller is the FarbeNFT contract
        require(msg.sender == address(NFTContract), "Caller is not the Farbe contract");
        _;
    }

    /**
     * @dev External function to be called to transfer token to Institution for sale
     * @param _institutionAddress address of institution
     * @param _tokenId ID of token to be transfered 
     */
    function assignToInstitution(address _institutionAddress, uint256 _tokenId) external {
        require(NFTContract.ownerOf(_tokenId) == msg.sender, "Sender is not the owner");
        NFTContract.safeTransferFrom(msg.sender, address(this), _tokenId);
        institutionToTokenCollection[_institutionAddress].set(_tokenId, msg.sender);
        
        emit AssignedToInstitution(_institutionAddress, _tokenId, msg.sender);
    }

    /**
     * @dev External function (but only called by Farbe Contract while minting) to be called to transfer token to Institution for sale
     * @param _institutionAddress address of institution
     * @param _tokenId ID of token to be transfered
     * @param _owner Owner of the token
     */
    function assignToInstitution(address _institutionAddress, uint256 _tokenId, address _owner) external onlyFarbeContract {
        NFTContract.safeTransferFrom(NFTContract.ownerOf(_tokenId), address(this), _tokenId);
        institutionToTokenCollection[_institutionAddress].set(_tokenId, _owner);
        
        emit AssignedToInstitution(_institutionAddress, _tokenId, _owner);
    }

    /**
     * @dev External function to take back token from institution
     * @param _tokenId ID of token
     * @param _institution address of institution
     */
    function takeBackFromInstitution(uint256 _tokenId, address _institution) external {
        address tokenOwner;
        tokenOwner = institutionToTokenCollection[_institution].get(_tokenId);
        require(tokenOwner == msg.sender, "Not original owner");
        
        institutionToTokenCollection[_institution].remove(_tokenId);
        NFTContract.safeTransferFrom(address(this), msg.sender, _tokenId);

        emit TakeBackFromInstitution(_tokenId, _institution, tokenOwner);
    }

    function preSaleChecks(uint256 _tokenId, uint16 _galleryCut) internal returns (address, address, address, uint16) {
        address owner = NFTContract.ownerOf(_tokenId);

        if(owner == address(this)){
            require(institutionToTokenCollection[msg.sender].contains(_tokenId), "Not approved institution");
        }
        else {
            require(owner == msg.sender, "Not owner or institution");
        }

        // using struct to avoid 'stack too deep' error
        tokenDetails memory _details = tokenDetails(
            NFTContract.getTokenCreatorAddress(_tokenId),
            NFTContract.getTokenCreatorCut(_tokenId),
            owner != msg.sender // true if sale is from an institution
        );

        if(getSecondarySale(_tokenId)){
            require(_details.creatorCut + _galleryCut + 25 < 1000, "Cuts greater than 100%");
        } else {
            require(_details.creatorCut + _galleryCut + platformCutOnPrimarySales < 1000, "Cuts greater than 100%");
        }

        // get reference to owner before transfer
        address _seller = _details.isInstitution ? institutionToTokenCollection[msg.sender].get(_tokenId) : msg.sender;

        if(_details.isInstitution){
            institutionToTokenCollection[msg.sender].remove(_tokenId);
        }

        // determine gallery address (0 if called by owner)
        address _galleryAddress = _details.isInstitution ? msg.sender : address(0);

        // escrow the token into the auction smart contract
        if(!_details.isInstitution) {
            NFTContract.safeTransferFrom(owner, address(this), _tokenId);
        }
        
        return (_details.tokenCreator, _seller, _galleryAddress, _details.creatorCut);

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
    public
    onlyValidStartingTime(_startingTime)
    whenNotPaused()
    {
        address _creatorAddress;
        address _seller;
        address _galleryAddress;
        uint16 _creatorCut;
        
        (_creatorAddress, _seller, _galleryAddress, _creatorCut) = preSaleChecks(_tokenId, _galleryCut);

        // call the external contract function to create the auction
        createAuctionSale(
            _tokenId,
            _startingPrice,
            _startingTime,
            _duration,
            _creatorAddress,
            _seller,
            _galleryAddress,
            _creatorCut,
            _galleryCut,
            platformCutOnPrimarySales
        );
    }

    /**
     * @dev Creates the sale auction for a bulk of tokens by calling the internal createSaleAuction for each one. Can only be called by owner,
     * individual external contract calls are expensive so a single function is used to pass all parameters
     * @param _tokenId IDs of the tokens to put on auction
     * @param _startingPrice Starting prices of the auction
     * @param _startingTime Starting times of the auction in UNIX timestamp
     * @param _duration The durations in seconds for the auction
     * @param _galleryCut The cuts for the gallery, will be 0 if gallery is not involved
     */
    function createBulkSaleAuction(
        uint256[] memory _tokenId,
        uint128[] memory _startingPrice,
        uint64[] memory _startingTime,
        uint64[] memory _duration,
        uint16 _galleryCut
    )
    external
    whenNotPaused()
    {
        uint _numberOfTokens = _tokenId.length;

        require(_startingPrice.length == _numberOfTokens, "starting prices incorrect");
        require(_startingTime.length == _numberOfTokens, "starting times incorrect");
        require(_duration.length == _numberOfTokens, "durations incorrect");

        for(uint i = 0; i < _numberOfTokens; i++){
            createSaleAuction(_tokenId[i], _startingPrice[i], _startingTime[i], _duration[i], _galleryCut);
        }
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
    public
    onlyValidStartingTime(_startingTime)
    whenNotPaused()
    {
        address _creatorAddress;
        address _seller;
        address _galleryAddress;
        uint16 _creatorCut;
        
        (_creatorAddress, _seller, _galleryAddress, _creatorCut) = preSaleChecks(_tokenId, _galleryCut);

        // call the external contract function to create the FixedPrice
        createFixedPriceSale(
            _tokenId,
            _fixedPrice,
            _startingTime,
            _creatorAddress,
            _seller,
            _galleryAddress,
            _creatorCut,
            _galleryCut,
            platformCutOnPrimarySales
        );
    }

    /**
     * @dev Creates the fixed price sale for a bulk of tokens by calling the internal createSaleFixedPrice funtion. Can only be called by owner.
     * Individual external contract calls are expensive so a single function is used to pass all parameters
     * @param _tokenId IDs of the tokens to put on auction
     * @param _fixedPrice Fixed prices of the auction
     * @param _startingTime Starting times of the auction in UNIX timestamp
     * @param _galleryCut The cut for the gallery, will be 0 if gallery is not involved
     */
    
    function createBulkSaleFixedPrice(
        uint256[] memory _tokenId,
        uint128[] memory _fixedPrice,
        uint64[] memory _startingTime,
        uint16 _galleryCut
    )
    external
    whenNotPaused()
    {
        uint _numberOfTokens = _tokenId.length;

        require(_fixedPrice.length == _numberOfTokens, "fixed prices incorrect");
        require(_startingTime.length == _numberOfTokens, "starting times incorrect");

        for(uint i = 0; i < _numberOfTokens; i++){
            createSaleFixedPrice(_tokenId[i], _fixedPrice[i], _startingTime[i], _galleryCut);
        }
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
    public
    onlyValidStartingTime(_startingTime)
    whenNotPaused()
    {
        address _creatorAddress;
        address _seller;
        address _galleryAddress;
        uint16 _creatorCut;
        
        (_creatorAddress, _seller, _galleryAddress, _creatorCut) = preSaleChecks(_tokenId, _galleryCut);

        // call the external contract function to create the openOffer
        createOppenOfferSale(
            _tokenId,
            _startingTime,
            _creatorAddress,
            _seller,
            _galleryAddress,
            _creatorCut,
            _galleryCut,
            platformCutOnPrimarySales
        );
    }

    /**
     * @dev Creates the open offer sale for a bulk of tokens by calling the internal createSaleOpenOffer function. Can only be called by owner,
     * individual external contract calls are expensive so a single function is used to pass all parameters
     * @param _tokenId IDs of the tokens to put on auction
     * @param _startingTime Starting times of the auction in UNIX timestamp
     * @param _galleryCut The cut for the gallery, will be 0 if gallery is not involved
     */
    function createBulkSaleOpenOffer(
        uint256[] memory _tokenId,
        uint64[] memory _startingTime,
        uint16 _galleryCut
    )
    external
    whenNotPaused()
    {
        uint _numberOfTokens = _tokenId.length;

        require(_startingTime.length == _numberOfTokens, "starting times incorrect");

        for(uint i = 0; i < _numberOfTokens; i++){
            createSaleOpenOffer(_tokenId[i], _startingTime[i], _galleryCut);
        }
    }
}