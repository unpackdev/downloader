// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ERC165StorageUpgradeable.sol";
import "./IERC165Upgradeable.sol";
import "./IERC2981Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AccessRole.sol";
import "./IBasketball.sol";
import "./ISerum.sol";

/**
 * @title NonFiggybles  NFT
 * @dev Issues ERC-721 tokens 
 */
contract BasketballHead is IERC2981Upgradeable, ERC165StorageUpgradeable, ERC721Upgradeable, OwnableUpgradeable, AccessRole{
    using SafeMathUpgradeable for uint256;
    // @notice event emitted upon construction of this contract, used to bootstrap external indexers
    event NFTContractDeployed();

    // @notice event emitted when token URI is updated
    event TokenUriUpdate(
        uint256 indexed _tokenId,
        string _tokenUri
    );

    // @notice event emitted when a tokens primary sale occurs
    event TokenPrimarySalePriceSet(
        uint256 indexed _tokenId,
        uint256 _salePrice
    );

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /// @dev Basketball Contract
    IBasketball public basketballContract;

    /// @dev Serum Contract
    ISerum public serumContract;
    
    /// @dev royalty address
    address public royalty;

    /// @dev royalty percent of 2nd sale. ex: 1 = 1%.
    uint256 public constant royaltyPercent = 5;

    /// @dev base uri of NFT
    string private baseUri;

    /// @dev TokenID -> Primary Ether Sale Price in Wei
    mapping(uint256 => uint256) public primarySalePrice;

    /**
     @notice Constructor
     */
    function initialize(string memory _name, string memory _symbol, string memory _baseUri, address _royalty,
        address _basketballContractAddress, address _serumContractAddress) public initializer {
        ERC165StorageUpgradeable.__ERC165Storage_init();
        OwnableUpgradeable.__Ownable_init();
        __ERC721_init(_name, _symbol);
        AccessRole.initialize();

        baseUri = _baseUri;
        royalty = _royalty;
        basketballContract = IBasketball(_basketballContractAddress);
        serumContract = ISerum(_serumContractAddress);
        _registerInterface(_INTERFACE_ID_ERC2981);
        emit NFTContractDeployed();
    }

    
    /**
     @notice Mints a NFT AND when minting to a contract checks if the beneficiary is a 721 compatible
     @dev Only senders with either the admin or mintor role can invoke this method
     */
    function mint(
        uint256 _basketballheadTokenId, 
        uint256 _basketballTokenId, 
        uint256[] memory _serumTokenIds, 
        uint256 _serumCount
    ) external {
        require(_basketballTokenId == 1, "invalid basketball id");
        require(basketballContract.balanceOf(msg.sender, _basketballTokenId) >= 1, "not this basketball's owner");
        require(_serumCount <= 3, "serum count should be less than 3");
        for(uint i = 0; i < _serumCount; i++) {
            require(_serumTokenIds[i] >= 1 && _serumTokenIds[i] <= 11, "invalid serum id");
            require(serumContract.balanceOf(msg.sender, _serumTokenIds[i]) >= 1, "not these serums' owner");
        }
        require(basketballContract.isApprovedForAll(msg.sender, address(this)), "not approved for basketball");
        require(serumContract.isApprovedForAll(msg.sender, address(this)), "not approved for basketball");

        basketballContract.burn(msg.sender, _basketballTokenId, 1);
        for(uint i = 0; i < _serumCount; i++) {
            serumContract.burn(msg.sender, _serumTokenIds[i], 1);
        }

        // Mint token and set token URI
        _safeMint(msg.sender, _basketballheadTokenId);
    }

    /**
     @notice Burns a NFT
     @dev Only the owner or an approved sender can call this method
     @param _tokenId the token ID to burn
     */
    function burn(uint256 _tokenId) external {
        address operator = _msgSender();
        require(
            ownerOf(_tokenId) == operator || isApproved(_tokenId, operator),
            "NFT.burn: Only garment owner or approved"
        );
        // Destroy token mappings
        _burn(_tokenId);
    }

    function setBasketballContract(address _basketballContractAddress) external onlyOwner {
        require(_basketballContractAddress != address(0), "basketball contract addres is invalid");
        basketballContract = IBasketball(_basketballContractAddress);
    }

    function setSerumContract(address _serumContractAddress) external onlyOwner {
        require(_serumContractAddress != address(0), "serum contract addres is invalid");
        serumContract = ISerum(_serumContractAddress);
    }

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    /////////////////
    // View Methods /
    /////////////////

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */

    function royaltyInfo(uint256, uint256 salePrice) external view override(IERC2981Upgradeable) returns (address receiver, uint256 royaltyAmount) {
        receiver = royalty;
        royaltyAmount = salePrice.mul(royaltyPercent).div(100);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view 
        override(IERC165Upgradeable, ERC165StorageUpgradeable, ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override(ERC721Upgradeable) returns (string memory) {
        return baseUri;
    }

    /**
     @notice View method for checking whether a token has been minted
     @param _tokenId ID of the token being checked
     */
    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * @dev checks the given token ID is approved either for all or the single token ID
     */
    function isApproved(uint256 _tokenId, address _operator) public view returns (bool) {
        return isApprovedForAll(ownerOf(_tokenId), _operator) || getApproved(_tokenId) == _operator;
    }
}