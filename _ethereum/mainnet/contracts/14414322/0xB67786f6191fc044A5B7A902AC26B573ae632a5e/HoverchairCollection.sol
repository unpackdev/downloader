//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;
import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./AccessControl.sol";
import "./PaymentSplitter.sol";

/*
 * HoverchairCollection contract for managing token drops
 *
 * by @prabhu
 */
contract HoverchairCollection is ERC1155, Ownable, ReentrancyGuard, AccessControl, PaymentSplitter {
    using Strings for string;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    event TokenAdded(uint256 tokenId, string name, string metadataUrl, uint256 maxSupply);
    struct HoverToken {
        bool active;
        uint256 maxSupply;
        uint256 mintedSupply;
        string internalName;
        string metadataUrl;
        address[] allowListArray;
        uint256 mintWeiPrice;
    }
    string public name;
    mapping(uint256 => HoverToken) public tokens;
    Counters.Counter private tokenCounter;
    address[] _payees=[0x59381487124657694f8E1101DD62FA55aa038721, 0x82B40dC9113f7B90eba2a30477694b0C8a7a1070, 0x33A442b5f80531e5B722d2c4adaCF52febbC3BeA];
    uint[] _shares=[70,20,10];
    constructor(
        string memory _name,
        address[] memory _admins
        ) ERC1155("https://www.hoverchairstudios.com/") PaymentSplitter(_payees, _shares)
        {
            _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
            for (uint i=0; i< _admins.length; i++) {
                _setupRole(DEFAULT_ADMIN_ROLE, _admins[i]);
            }
            name = _name;
    }
    function tokenCount() public view returns (uint) {
        return tokenCounter.current();
    }
    function addNewToken(bool _active, string memory _name, string memory _metadataUrl, uint256 _maxSupply, uint256 _mintWeiPrice) 
    public
    onlyOwnerOrAdmin
    {
        require(_maxSupply > 0, "Invalid maxSupply");

        HoverToken storage token = tokens[tokenCounter.current()];
        token.active = _active;
        token.internalName = _name;
        token.maxSupply = _maxSupply;
        token.metadataUrl = _metadataUrl;
        token.mintWeiPrice = _mintWeiPrice;
        emit TokenAdded(tokenCounter.current(), _name, _metadataUrl, _maxSupply);
        tokenCounter.increment();
    }
    function toggleTokenSaleStatus(uint256 tokenId) 
    public
    onlyOwnerOrAdmin
    {
        HoverToken storage token = tokens[tokenId];
        token.active = !token.active;
    }
    function uri(uint256 _tokenId) public view override returns (string memory output) {
        //require(exists(_tokenId), "Token doesn't exists");
        HoverToken storage token = tokens[_tokenId];
        output = token.metadataUrl;

    }
    modifier isTokenTransactionValid(uint256 tokenId, uint256 amount, bool shouldBeActive) {
        HoverToken storage token = tokens[tokenId];
        require( token.mintedSupply+amount <= token.maxSupply, "Tokens Sold out");
        if (shouldBeActive) {
            require(token.active,"This token is not active for sale");
        }
        _;
    }
    modifier onlyOwnerOrAdmin() {
        require(owner() == _msgSender() || hasRole(DEFAULT_ADMIN_ROLE,_msgSender()),"This action can be performed by Owner or Admin only");
        _;
    }
    function batchAirdrop(uint256 _tokenId, uint256 _tokenCount, address[] calldata _list)
        public
        isTokenTransactionValid(_tokenId, _tokenCount*_list.length, false)
        onlyOwnerOrAdmin
    {
        HoverToken storage token = tokens[_tokenId];
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
    isTokenTransactionValid(id, amount, false)
    onlyOwnerOrAdmin
    {
        HoverToken storage token = tokens[id];
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
    isTokenTransactionValid(tokenId, amount, true)
    {
        HoverToken storage token = tokens[tokenId];
        uint256 totalPrice = amount * token.mintWeiPrice;
        require(msg.value >= totalPrice, " Insufficient funds");
        token.mintedSupply = token.mintedSupply+amount;
        _mint(msg.sender, tokenId, amount, data);
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    modifier isNotContract() {
        require(msg.sender == tx.origin, "Proxies cannot mint");
        _;
    }
}