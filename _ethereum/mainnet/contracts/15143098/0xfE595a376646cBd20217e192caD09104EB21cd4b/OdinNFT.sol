/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-21
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract ODINNFT is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable {
    using SafeMath for uint256;

    string baseTokenURI;
    uint256 private _tokenIds = 0;

    uint256 public constant MINT_PRICE = 5000000000000000; //0.05 eth
    
    mapping(uint256 => uint256) private _tokenLevels;
    mapping(uint256 => string) private _tokenURIs;
    
    constructor() ERC721("OdinNFT", "ODINNT") {}

    function getTokenLevel(uint256 _id) public view returns (uint256) {
        require(_id < _tokenIds, "Non exist token!");
        return _tokenLevels[_id];
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Returns the base URI set via {_setBaseURI}. This will be
     * automatically added as a prefix in {tokenURI} to each token's URI, or
     * to the token ID if no specific URI is set for that token ID.
     */

    function mint(uint256 _level, address _to) public returns (uint256) {
        // require(msg.value >= MINT_PRICE, "Not sufficient price");
        uint256 curId = _tokenIds;
        _tokenIds ++;
        _tokenLevels[curId] = _level;
        _safeMint(_to, curId);
        return curId;
    }

    function setTokenURI(uint256 _tokenId,  string memory _tokenURI) public {
        require(_msgSender() == ownerOf(_tokenId), "Unable to set token URI");
        _tokenURIs[_tokenId] = _tokenURI;
    }

    function balanceOf(address _owner) 
    public 
    view 
    override(ERC721) 
    returns (uint256) {
        return super.balanceOf(_owner);
    }

    function getTokensOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 amount = balanceOf(_owner);
        uint256[] memory _tokens = new uint256[](amount);
        for(uint256 i = 0; i < amount; i++) {
            _tokens[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return _tokens;
    }

    function checkAccountLevel(address _account) external view returns (uint256) {
        uint256 level = 0;
        uint256[] memory ownIds = getTokensOfOwner(_account);
        bool level1 = false;
        bool level2 = false;
        bool level3 = false;
        bool level4 = false;
        bool level5 = false;
        for (uint256 i = 0; i < ownIds.length; i++) {
            if (_tokenLevels[ownIds[i]] > level) {
                level = _tokenLevels[ownIds[i]];
            }
            if (_tokenLevels[ownIds[i]] == 1) level1 = true;
            if (_tokenLevels[ownIds[i]] == 2) level2 = true;
            if (_tokenLevels[ownIds[i]] == 3) level3 = true;
            if (_tokenLevels[ownIds[i]] == 4) level4 = true;
            if (_tokenLevels[ownIds[i]] == 5) level5 = true;
        }
        if (level1 && level2 && level3 && level4 && level5) level = 6;
        return level;
    }

    function checkAccountLevels(address _account) external view returns (uint256[] memory) {
        require(balanceOf(_account) > 0, "No balance");
        uint256 tokenCount = balanceOf(_account);
        uint256[] memory levels = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            levels[i] = _tokenLevels[tokenOfOwnerByIndex(_account, i)];
        }

        return levels;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function ownerOf(uint256 _id)
    public
    view 
    override(ERC721) 
    returns (address) {
        return super.ownerOf(_id);
    }

    function totalSupply() 
    public 
    view 
    virtual 
    override (ERC721Enumerable)
    returns (uint256) {
        return super.totalSupply();
    }
}