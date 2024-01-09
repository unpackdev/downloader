// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Counters.sol";

/*===== Opensea related definitions =====*/
contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract SlimeProducer is
    ERC721,
    ERC721Burnable,
    Ownable
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    /* ===== Opensea related variables ===== */    
    address public proxyRegistryAddress=0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    bool public openseaActive = true;
    Counters.Counter private _tokenIdCounter;

    /*===== Minting related variables=====*/
    mapping(address => bool) public proxyMinters;

    mapping(uint256 => uint256) public mintTimes;

    /*===== URI related variables=====*/

    /* since we will be uploading to ipfs and revealing in batches, 
    we need different baseURI for different token id ranges */
    struct RangedURI {
        uint256 lastId;
        string uri;
    }

    RangedURI[] public _rangedURIs;

    /* before we reveal, we will be storing the metadata on a temporary server, which will be defined here */
    string public defaultBaseURI ="https://www.goopyslimes.online/metadata/";

    /* track the last revealed tokenId so everything after it will use default Base URI */
    uint256 public lastRevealedId;

    constructor(
        string memory name,
        string memory symbol        
    ) ERC721(name, symbol) {        
         _tokenIdCounter.increment();
    }

    /*====== Owner only functions ====== */
    function setOpenseaActive(bool active) external onlyOwner {
        openseaActive=active;
    }

    function setProxyMinter(address contractAddr, bool enabled)
        external
        onlyOwner
    {
        proxyMinters[contractAddr] = enabled;
    }

    function addRangeURI(uint256 lastId, string memory uri) external onlyOwner {
        require(lastId <= totalSupply(),"Id Range exceeded");
        require(lastId > lastRevealedId, "Range URI already Set");
        lastRevealedId = lastId;
        _rangedURIs.push(RangedURI(lastId, uri));
    }

    function removeLastRangeURI() external onlyOwner {
        require( _rangedURIs.length >0, "No Range URI Set");        
        _rangedURIs.pop();
        if (_rangedURIs.length>0){
          lastRevealedId=_rangedURIs[_rangedURIs.length].lastId;
        } else {
          lastRevealedId=0;
        }
    }

    function setDefaultBaseURI(string memory baseURI) external onlyOwner {
        defaultBaseURI = baseURI;
    }

    /*===== URI generation ====== */
    function _baseURI(uint256 tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        require(_exists(tokenId), "Non Existing TokenId");
        if (tokenId > lastRevealedId) return defaultBaseURI;
        for (uint256 i = 0; i < _rangedURIs.length; i++) {
            if (tokenId <= _rangedURIs[i].lastId) {
                return _rangedURIs[i].uri;
            }
        }
        /* impossible case, added for completeness */
        return "";
    }

    function totalSupply() public view returns (uint256) {
        return  _tokenIdCounter.current()-1;
    }

    function tokensOwned(address owner) public view returns (uint256[] memory tokenIds){
       uint256 bal = balanceOf(owner);
       uint256[] memory ids = new uint256[](bal);
       uint256 idx=0;
       for (uint256 i=1;i<=totalSupply();i++){
         if (ownerOf(i)==owner){
             ids[idx++]=i;             
         }
       }
       return ids;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(_baseURI(tokenId), tokenId.toString()));
    }
    /*===== Minting related functions =====*/
    
    /* only allow proxy minters to mint and ensure the max supply is not exceeded if defined */
    function proxyMint(address to) external returns (uint256) {
        require(proxyMinters[msg.sender] == true, "Unauthorized Minting");        
        require(
            this.maxSupply() == 0 || totalSupply() < this.maxSupply(),
            "Max supply exceeded"
        );        
        uint256 tokenId=_tokenIdCounter.current();
        _safeMint(to,tokenId );
        _tokenIdCounter.increment();
        mintTimes[tokenId] = block.timestamp;        
        return tokenId;
    }

    /* tracking of minting time for reward computation purposes */
    function getCreationTime(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Non Existing Token");
        return mintTimes[tokenId];
    }

     /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (openseaActive && address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }


    /*===== virtual function =====*/
    function maxSupply() external pure virtual returns (uint256);
}
