// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ERC721, ContextMixin, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    /**
     * We rely on the OZ Counter util to keep track of the next available ID.
     * We track the nextTokenId instead of the currentTokenId to save users on gas costs. 
     * Read more about it here: https://shiny.mirror.xyz/OUampBbIz9ebEicfGnQf5At_ReMHlZy0tB4glb9xQ0E
     */ 
    Counters.Counter private _nextTokenId;
    address proxyRegistryAddress;
    uint256 private price = 0.06 * 1e18; //price for minting
    bool private paused = true; //switch for minting
    bool private mintPublic = false; //only while list can mint
    uint private totalLimit = 1000; //limit for total mint
    uint private singleAddrLimit = 2; //limit for single addr for mint
    mapping(address=>bool) private mintWhiteList;  //white list for mint
    // Mapping owner address to mint count
    mapping(address => uint256) private mintCount;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        _nextTokenId.increment();
        _initializeEIP712(_name);
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) public onlyOwner {
        uint256 currentTokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _safeMint(_to, currentTokenId);
        mintCount[_to] += 1;
    }

    /**
     @dev set the price for minting
     @param _price the price for minting;
     */
    function setPrice(uint256 _price) public onlyOwner returns (bool){
        require(_price>0,"price must be a positive number");
        price = _price;
        return true;
    }

    function getPrice() public view returns(uint256){
        return price;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function getPaused() public view returns(bool){
        return paused;
    }
// white list
    function addWhiteLists(address[] memory accounts) public onlyOwner{
        require(accounts.length > 0,"inputs must have value");
        for(uint i=0;i<accounts.length;i++){
            mintWhiteList[accounts[i]] = true;
        }
    }

    function addWhiteList(address _addr) public onlyOwner{
        mintWhiteList[_addr] = true;
    }

    function getWhiteList(address _addr) view public returns(bool){
        return mintWhiteList[_addr];
    }

    function setMintPublic(bool _status)public onlyOwner{
        mintPublic = _status;
    }

    function getMintPublic() public view returns(bool){
        return mintPublic;
    }

//limit
    function setTotalLimit(uint256 _limit)public onlyOwner returns(bool){
        require(_limit > 0," limit must be a positive numbe");
        totalLimit = _limit;
        return true;
    }

    function getTotalLimit() public view returns(uint256){
        return totalLimit;
    }

    function setSingleLimit(uint256 _limit)public onlyOwner returns(bool){
        require(_limit > 0," limit must be a positive numbe");
        singleAddrLimit = _limit;
        return true;
    }

    function getSingleLimit() public view returns(uint256){
        return singleAddrLimit;
    }

    function getMintCount() public view returns(uint256){
        return mintCount[msg.sender];
    }


// mint
    function mintNft() public payable {
        require(!getPaused(),"mint nft was paused");
        require(totalSupply() < totalLimit,"sell out");
        if(!mintPublic){
            require(mintWhiteList[msg.sender],"your address not in white list");
        }
        require(mintCount[msg.sender] < singleAddrLimit,"reach the minting limit");
        require(msg.value >= price,"ETH amount is not enough for minting");
        uint256 currentTokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _safeMint(msg.sender, currentTokenId);
        mintCount[msg.sender] += 1;
    }

    /**
        @dev Returns the total tokens minted so far.
        1 is always subtracted from the Counter since it tracks the next available tokenId.
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function baseTokenURI() virtual public pure returns (string memory);

    function tokenURI(uint256 _tokenId) override public pure returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
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
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}
