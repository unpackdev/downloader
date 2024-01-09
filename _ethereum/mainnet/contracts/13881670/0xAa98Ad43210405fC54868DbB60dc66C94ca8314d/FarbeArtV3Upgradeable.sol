// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./Auction.sol";
import "./FixedPrice.sol";
import "./OpenOffers.sol";

interface IFarbeMarketplace {
    function assignToInstitution(address _institutionAddress, uint256 _tokenId, address _owner) external;
    function getIsFarbeMarketplace() external view returns (bool);
}


/**
 * @title ERC721 contract implementation
 * @dev Implements the ERC721 interface for the Farbe artworks
 */
contract FarbeArtV3Upgradeable is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, AccessControlUpgradeable {
    // counter for tracking token IDs
    CountersUpgradeable.Counter internal _tokenIdCounter;

    // details of the artwork
    struct artworkDetails {
        address tokenCreator;
        uint16 creatorCut;
        bool isSecondarySale;
    }

    // mapping of token id to original creator
    mapping(uint256 => artworkDetails) public tokenIdToDetails;

    // not using this here anymore, it has been moved to the farbe marketplace contract
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
     * @dev Initializer for the ERC721 contract
     */
    function initialize() public initializer {
        __ERC721_init("FarbeArt", "FBA");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    /**
     * @dev Implementation of ERC721Enumerable
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Destroy (burn) the NFT
     * @param tokenId The ID of the token to burn
     */
    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for the token
     * @param tokenId ID of the token to return URI of
     * @return URI for the token
     */
    function tokenURI(uint256 tokenId) public view
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Implementation of the ERC165 interface
     * @param interfaceId The Id of the interface to check support for
     */
    function supportsInterface(bytes4 interfaceId) public view
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    uint256[1000] private __gap;

}


/**
 * @title Farbe NFT sale contract
 * @dev Extension of the FarbeArt contract to add sale functionality
 */
contract FarbeArtSaleV3Upgradeable is FarbeArtV3Upgradeable {
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

    using CountersUpgradeable for CountersUpgradeable.Counter;

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
            setApprovalForAll(farbeMarketplace, true);
            // set the token URI
            _setTokenURI(_tokenIdCounter.current(), _tokenURI[i]);
            // track token creator
            tokenIdToDetails[_tokenIdCounter.current()].tokenCreator = _to;
            // track creator's cut
            tokenIdToDetails[_tokenIdCounter.current()].creatorCut = _creatorCut;

            if(_galleryAddress != address(0)){
                IFarbeMarketplace(farbeMarketplace).assignToInstitution(_galleryAddress, _tokenIdCounter.current(), msg.sender);
            }
            // increment tokenId
            _tokenIdCounter.increment();
        }
    }

    
    /**
     * @dev Initializer for the FarbeArtSale contract
     * name for initializer changed from "initialize" to "farbeInitialze" as it was causing override error with the initializer of NFT contract 
     */
    function farbeInitialize() public initializer {
        FarbeArtV3Upgradeable.initialize();
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
    
    function setFarbeMarketplaceAddress(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        farbeMarketplace = _address;
    }
    
    function getTokenCreatorAddress(uint256 _tokenId) public view returns(address) {
        return tokenIdToDetails[_tokenId].tokenCreator;
    }
    
    function getTokenCreatorCut(uint256 _tokenId) public view returns(uint16) {
        return tokenIdToDetails[_tokenId].creatorCut;
    }

    uint256[1000] private __gap;
    // #sbt upgrades-plugin does not support __gaps for now
    // so including the new variable here
    address public farbeMarketplace;
}