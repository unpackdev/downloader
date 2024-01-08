// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./MarketTradingAccessControls.sol";
import "./ERC721.sol";
import "./EnumerableSet.sol";

/**
 * @title MarketTrading  NFT
 * @dev Issues ERC-721 tokens 
 */
contract MarketTradingNFT is ERC721("Market Trading NFT", "MTN") {

    // @notice event emitted upon construction of this contract, used to bootstrap external indexers
    event MarketTradingNFTContractDeployed();

    // @notice event emitted when base UIR is updated
    event MarketTradingBaseUriUpdate(
        string _tokenUri
    );

    // @notice event emitted when token URI is updated
    event MarketTradingTokenUriUpdate(
        uint256 indexed _tokenId,
        string _tokenUri
    );

    // @notice event emitted when a tokens primary sale occurs
    event TokenPrimarySalePriceSet(
        uint256 indexed _tokenId,
        uint256 _salePrice
    );

    // @notice event emitted when token is minted
    event MarketTradingNFTMinted(
        uint256 _tokenId,
        address _creator,
        address _owner,
        string _tokenUri,
        string _edition
    );

    /// @dev Required to govern who can call certain functions
    MarketTradingAccessControls public accessControls;

    /// @dev current max tokenId
    uint256 public tokenIdPointer = 1000;

    /// @dev TokenID -> Post Creator address
    mapping(uint256 => address) public postCreators;

    /// @dev TokenID -> Primary Ether Sale Price in Wei
    mapping(uint256 => uint256) public primarySalePrice;

    /**
     @notice Constructor
     @param _accessControls Address of the MarketTradingNFT access control contract
     */
    constructor(MarketTradingAccessControls _accessControls) public {
        accessControls = _accessControls;
        emit MarketTradingNFTContractDeployed();
    }

    /**
     @notice Mints a MarketTradingNFT AND when minting to a contract checks if the beneficiary is a 721 compatible
     @dev Only senders with either the admin or mintor role can invoke this method
     @param _beneficiary Recipient of the NFT
     @param _tokenUri URI for the token being minted
     @param _postCreator Instagram Post Creator - will be required for issuing royalties from secondary sales
     @return uint256 The token ID of the token that was minted
     */
    function mint(address _beneficiary, string calldata _tokenUri, address _postCreator) external returns (uint256) {
        require(
            accessControls.hasAdminRole(_msgSender()) || accessControls.hasSmartContractRole(_msgSender()),
            "MarketTradingNFT.mint: Sender must have the admin or smart contract role"
        );
        // Valid args
        _assertMintingParamsValid(_tokenUri, _postCreator);

        tokenIdPointer = tokenIdPointer.add(1);
        uint256 tokenId = tokenIdPointer;

        // Mint token and set token URI
        _safeMint(_beneficiary, tokenId);
        _setTokenURI(tokenId, _tokenUri);

        postCreators[tokenId] = _postCreator;

        emit MarketTradingNFTMinted(tokenId, _postCreator, _beneficiary, _tokenUri, "1 of 1");

        return tokenId;
    }

    /**
     @notice Burns a MarketTradingNFT
     @dev Only the owner or an approved sender can call this method
     @param _tokenId the token ID to burn
     */
    function burn(uint256 _tokenId) external {
        address operator = _msgSender();
        require(
            ownerOf(_tokenId) == operator || isApproved(_tokenId, operator),
            "MarketTradingNFT.burn: Only garment owner or approved"
        );
        // Destroy token mappings
        _burn(_tokenId);

        delete postCreators[_tokenId];
        delete primarySalePrice[_tokenId];
    }



    //////////
    // Admin /
    //////////
    /**
     @notice Updates the Base URI of NFT
     @dev Only admin or smart contract
     @param baseURI_ The new URI
     */
    function setBaseURI(string memory baseURI_) external {
        require(
            accessControls.hasAdminRole(_msgSender()) || accessControls.hasSmartContractRole(_msgSender()),
            "MarketTradingNFT.mint: Sender must have the admin or contract role"
        );
        _setBaseURI(baseURI_);
        emit MarketTradingBaseUriUpdate(baseURI_);
    }

    /**
     @notice Updates the token URI of a given token
     @dev Only admin or smart contract
     @param _tokenId The ID of the token being updated
     @param _tokenUri The new URI
     */
    function setTokenURI(uint256 _tokenId, string calldata _tokenUri) external {
        require(
            accessControls.hasAdminRole(_msgSender()) || accessControls.hasSmartContractRole(_msgSender()),
            "MarketTradingNFT.mint: Sender must have the admin or contract role"
        );
        _setTokenURI(_tokenId, _tokenUri);
        emit MarketTradingTokenUriUpdate(_tokenId, _tokenUri);
    }

    /**
     @notice Records the Ether price that a given token was sold for (in WEI)
     @dev Only admin or a smart contract can call this method
     @param _tokenId The ID of the token being updated
     @param _salePrice The primary Ether sale price in WEI
     */
    function setPrimarySalePrice(uint256 _tokenId, uint256 _salePrice) external {
        require(
            accessControls.hasAdminRole(_msgSender()) || accessControls.hasSmartContractRole(_msgSender()),
            "MarketTradingNFT.mint: Sender must have the admin or contract role"
        );
        require(_exists(_tokenId), "MarketTradingNFT.setPrimarySalePrice: Token does not exist");
        require(_salePrice > 0, "MarketTradingNFT.setPrimarySalePrice: Invalid sale price");

        // Only set it once
        if (primarySalePrice[_tokenId] == 0) {
            primarySalePrice[_tokenId] = _salePrice;
            emit TokenPrimarySalePriceSet(_tokenId, _salePrice);
        }
    }

    /**
     @notice Method for updating the access controls contract used by the NFT
     @dev Only admin
     @param _accessControls Address of the new access controls contract
     */
    function updateAccessControls(MarketTradingAccessControls _accessControls) external {
        require(accessControls.hasAdminRole(_msgSender()), "MarketTradingNFT.updateAccessControls: Sender must be admin");
        accessControls = _accessControls;
    }
    /////////////////
    // View Methods /
    /////////////////

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

    /**
     * @dev get all information of token Id
     */
    function getNFTDetailByTokenId(uint256 tokenId) external view returns (
        uint256 _tokenId, 
        address _creator, 
        address _owner, 
        uint256 _tokenPrice, 
        string memory _tokenUri
    ) {
        return (tokenId, postCreators[tokenId], ownerOf(tokenId), primarySalePrice[tokenId], tokenURI(tokenId));
    }

    /////////////////////////
    // Internal and Private /
    /////////////////////////

    /**
     @notice Checks that the URI is not empty and the post creator is a real address
     @param _tokenUri URI supplied on minting
     @param _postCreator Address supplied on minting
     */
    function _assertMintingParamsValid(string calldata _tokenUri, address _postCreator) pure internal {
        require(bytes(_tokenUri).length > 0, "MarketTradingNFT._assertMintingParamsValid: Token URI is empty");
        require(_postCreator != address(0), "MarketTradingNFT._assertMintingParamsValid: Post createErrors is zero address");
    }
}
