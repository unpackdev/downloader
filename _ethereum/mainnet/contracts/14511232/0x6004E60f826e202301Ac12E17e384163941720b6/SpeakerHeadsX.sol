//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./EnumerableSet.sol";
import "./Counters.sol";

/*
 * MultiToken SpeakerHeadsX contract for managing token drops
 *
 * by @prabhu
 */
contract SpeakerHeadsX is ERC1155, Ownable, ReentrancyGuard {
    using Strings for string;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    event TokenAdded(uint256 tokenId, string name, string metadataUrl, uint256 maxSupply);

    struct MultiToken {
        bool active;
        uint256 maxSupply;
        uint256 mintedSupply;
        string internalName;
        string metadataUrl;
        bool restrictSale;
        uint256 mintWeiPrice;
        uint256 maxPerWallet;
    }


    string public name;
    mapping(uint256 => MultiToken) public tokens;
    mapping(uint256 => EnumerableSet.AddressSet) internal  tokenAllowList;
    Counters.Counter private tokenCounter;

    constructor(
        string memory _name,
        string memory _uri
        )ERC1155(_uri)
        {
            name = _name;
    }
    function tokenCount() public view returns (uint) {
        return tokenCounter.current();
    }
    function addToken(bool _active, bool _restrictSale,string memory _name, string memory _metadataUrl, uint256 _maxSupply, uint256 _maxPerWallet, uint256 _mintWeiPrice) 
    public
    onlyOwner
    {
        require(_maxSupply > 0, "Invalid maxSupply");
        MultiToken storage token = tokens[tokenCounter.current()];
        token.active = _active;
        token.restrictSale = _restrictSale;
        token.internalName = _name;
        token.maxSupply = _maxSupply;
        token.maxPerWallet = _maxPerWallet;
        token.metadataUrl = _metadataUrl;
        token.mintWeiPrice = _mintWeiPrice;
        EnumerableSet.AddressSet storage tokenWL = tokenAllowList[tokenCounter.current()];
        tokenWL.add(msg.sender);
        emit TokenAdded(tokenCounter.current(), _name, _metadataUrl, _maxSupply);
        tokenCounter.increment();
    }
    function toggleTokenSaleStatus(uint256 tokenId) 
    public
    onlyOwner
    {
        MultiToken storage token = tokens[tokenId];
        token.active = !token.active;
    }
    function toggleRestrictSaleStatus(uint256 tokenId) 
    public
    onlyOwner
    {
        MultiToken storage token = tokens[tokenId];
        token.restrictSale = !token.restrictSale;
    }

    function uri(uint256 _tokenId) public view override returns (string memory output) {
        //require(exists(_tokenId), "Token doesn't exists");
        MultiToken storage token = tokens[_tokenId];
        output = token.metadataUrl;

    }

    modifier isTokenTransactionValid(uint256 tokenId, uint256 amount, bool isOwner) {
        MultiToken storage token = tokens[tokenId];
        require( token.mintedSupply+amount <= token.maxSupply, "Tokens Sold out");
        uint256 alreadyOwn = balanceOf(msg.sender, tokenId);
        if (!isOwner) {
            if (token.maxPerWallet != 0 && token.restrictSale) {
                require(alreadyOwn+amount <= token.maxPerWallet, " Owns more than allowed tokens");
            }
            require(token.active,"This token is not active for sale");
        }
        _;
    }

    function airdrop(uint256 _tokenId, address[] calldata _list)
        public
    {
        batchAirdrop(_tokenId,1,_list);
    }
    function batchAirdrop(uint256 _tokenId, uint256 _tokenCount, address[] calldata _list)
        public
        isTokenTransactionValid(_tokenId, _tokenCount*_list.length, true)
        onlyOwner
    {
        MultiToken storage token = tokens[_tokenId];
        for (uint256 i = 0; i < _list.length; i++) {
            token.mintedSupply = token.mintedSupply+_tokenCount;
            _mint(_list[i], _tokenId, _tokenCount, "");
        }
    }

    function ownerMint(
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public 
    virtual 
    isTokenTransactionValid(id, amount, true)
    onlyOwner
    {
        MultiToken storage token = tokens[id];
        token.mintedSupply = token.mintedSupply+amount;
        _mint(msg.sender, id, amount, data);
    }

    function publicMint(
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public 
    payable 
    nonReentrant
    isNotContract
    isTokenTransactionValid(tokenId, amount, false)
    {
        MultiToken storage token = tokens[tokenId];
        if (token.restrictSale) {
            require( verifyAllowlist(msg.sender, tokenId) , "Not Whitelisted");
        }
        uint256 totalPrice = amount * token.mintWeiPrice;
        require(msg.value >= totalPrice, "Insufficient funds");
        token.mintedSupply = token.mintedSupply+amount;
        _mint(msg.sender, tokenId, amount, data);
    }

    function withdraw(uint256 amount) public virtual onlyOwner {
         if (amount == 0) {
            amount = address(this).balance;
        }
        require(payable(owner()).send(amount), "Address cannot receive payment");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    modifier isNotContract() {
        require(msg.sender == tx.origin, "Proxies cannot mint");
        _;
    }

    function verifyAllowlist(address sender, uint256 tokenIndex) internal view returns (bool) {
        EnumerableSet.AddressSet storage tokenWL = tokenAllowList[tokenIndex];
        return tokenWL.contains(sender);
    }
    function revokeFromAllowList(uint256 tokenId, address[] memory revokeList) public onlyOwner {
        EnumerableSet.AddressSet storage tokenWL = tokenAllowList[tokenId];
        for (uint i = 0; i < revokeList.length; i++) {
            tokenWL.remove(revokeList[i]);
        }
    }
    function appendToAllowList(uint256 tokenId, address[] memory appendList) public onlyOwner {
        EnumerableSet.AddressSet storage tokenWL = tokenAllowList[tokenId];
        for (uint i = 0; i < appendList.length; i++) {
            tokenWL.add(appendList[i]);
        }
    }

    function getTokenAllowList (uint256 tokenId) external view returns (address[] memory) {
        return tokenAllowList[tokenId].values();
    }
}