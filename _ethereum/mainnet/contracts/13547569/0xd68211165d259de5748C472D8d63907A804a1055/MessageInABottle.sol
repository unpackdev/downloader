// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IERC20.sol";


/* 
 * Copy/pasted from @openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol, 
 * except modified to append "/metadata.json" to the URI returned by tokenURI() .  
 * We do this to save some gas 
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI, "/metadata.json"));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}
    


contract MessageInABottle is Ownable, ERC721URIStorage {

    address private _utilityTokenAddress;       // address of ERC20 contract for paying to send messages
    
    uint32 private _currentTokenId;             // increments with each new message

    string private _uriPrefix;                  // uri prefix

    address public DAO;                         // where the payments go

    uint256 public publicPrice;                 // price in utility token 1e18 units


    constructor(address _beginUilityTokenAddress, address _daoAddress, uint256 _initialPrice, string memory _initURIPrefix)
    ERC721("Message In a Bottle", "MIAB")
    Ownable() 
    {
        _utilityTokenAddress = _beginUilityTokenAddress;
        _uriPrefix = _initURIPrefix;
        DAO = _daoAddress;
        publicPrice = _initialPrice;
    }

    function sendMessage(address to, string calldata uri) external {
        if (publicPrice > 0) {
            IERC20 utilityTokenInterface = IERC20(_utilityTokenAddress);
            utilityTokenInterface.transferFrom(_msgSender(), DAO, publicPrice);
        }
        uint256 nextTokenId = _getNextTokenId();
        _mint(to, nextTokenId);
        _setTokenURI(nextTokenId, uri);
        _incrementTokenId();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _uriPrefix;
    }

    function destroyMessage(uint256 tokenId) external {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "DONT_OWN_MESSAGE");
        _burn(tokenId);
    }

    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId + 1;
    }

    function _incrementTokenId() private {
        _currentTokenId++;
    }

    // need to specify in units of 1e18 
    function setPrice(uint256 _newPrice) external onlyOwner {
        publicPrice = _newPrice;
    }    

    function setDAOaddress(address _newDAO) external onlyOwner {
        DAO = _newDAO;
    }    

    function setUtilityToken(address _newUtilityTokenAddress) external onlyOwner {
        _utilityTokenAddress = _newUtilityTokenAddress;
    }    

    function setURIPrefix(string calldata _newURIPrefix) external onlyOwner {
        _uriPrefix = _newURIPrefix;
    }
}