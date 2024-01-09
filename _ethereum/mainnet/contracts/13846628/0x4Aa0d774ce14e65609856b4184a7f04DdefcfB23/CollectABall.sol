pragma solidity ^0.8.0;
                                                                                                                                                                                                                                              
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";

contract CollectABall is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    // Constants
    uint256 public constant MAX_COLLECTION_SIZE = 10000;
    uint256 public constant MINT_PRICE = 0.08 ether;
    uint256 public constant MAX_MINT_QUANTITY = 5;
    address private constant ARTIST_WALLET = 0x113Aed406B5f22190726F9C8B51d50e74569A98D;
    address private constant DEV_WALLET = 0x291f158F42794Db959867528403cdb382DbECfA3;
    address private constant FOUNDER_WALLET = 0xd04a78A2cF122e7bC7F96Bf90FB984000436CFCd;
    
    // string public baseURI;
    bool public publicSaleStarted = false;
    bool public presaleStarted = false;
    uint256 public reservedBalls = 100;
    
    // Private
    mapping(address => bool) private _presaleWhiteList;
    mapping(address => uint) private _presaleMintedCount;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _reservedBallsClaimed;
    string private baseURI;
    
    event BaseURIChanged(string baseURI);

    constructor() ERC721("Collect-A-Ball NFT", "CAB") { }

    // Modifiers

    modifier publicSaleIsLive() {
        require(publicSaleStarted, "Public sale has not started");
        _;
    }

    modifier presaleIsLive() {
        require(presaleStarted, "Presale has not started or Presale is over");
        _;
    }

    function isOwner() public view returns(bool) {
        return owner() == msg.sender;
    }

    // Mint

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(address _to, uint256 _quantity) public payable publicSaleIsLive {
        uint256 supply = totalSupply();
        require(_to != address(0), "Invalid addresss");
        require(supply < MAX_COLLECTION_SIZE, "Sold Out");
        require(_quantity > 0, "Need to mint at least one!");
        require(_quantity <= MAX_MINT_QUANTITY, "More than the max allowed in one transaction");
        require(supply + _quantity <= MAX_COLLECTION_SIZE, "Minting would exceed max supply");
        require(msg.value == MINT_PRICE * _quantity, "Incorrect amount of ETH sent");

        for (uint256 i = 0; i < _quantity; i++) {
            _tokenIdCounter.increment();
            _safeMint(_to, _tokenIdCounter.current());
        }
    }

    // MARK: Presale

    function mintPreSale(uint256 _quantity) public payable presaleIsLive {
        require(_presaleWhiteList[msg.sender], "You're are not eligible for Presale");
        require(_presaleMintedCount[msg.sender] <= MAX_MINT_QUANTITY, "Exceeded max mint limit for presale");
        require(_presaleMintedCount[msg.sender]+_quantity <= MAX_MINT_QUANTITY, "Minting would exceed presale mint limit. Please decrease quantity");
        require(totalSupply() <= MAX_COLLECTION_SIZE, "Collection Sold Out");
        require(_quantity > 0, "Need to mint at least one!");
        require(_quantity <= MAX_MINT_QUANTITY, "Cannot mint more than max");
        require(totalSupply() + _quantity <= MAX_COLLECTION_SIZE, "Minting would exceed max supply, please decrease quantity");
        require(_quantity*MINT_PRICE == msg.value, "Incorrect amount of ETH sent");
        
        uint count = _presaleMintedCount[msg.sender];
        _presaleMintedCount[msg.sender] = _quantity + count;
        for (uint256 i = 0; i < _quantity; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    function checkPresaleEligibility(address addr) public view returns (bool) {
        return _presaleWhiteList[addr];
    }
   
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, "/", tokenId.toString(), ".json"))
            : "";
    }

    // MARK: onlyOwner

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function addToPresaleWhitelist(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0));
            _presaleWhiteList[addresses[i]] = true;
        }
    }

    function removeFromWhitelist(address[] memory addresses) public onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            _presaleWhiteList[addresses[i]] = false;
        }
    }

    function claimReserved(address addr, uint256 _quantity) public onlyOwner {
        require(_tokenIdCounter.current() < MAX_COLLECTION_SIZE, "Collection has sold out");
        require(_quantity + _tokenIdCounter.current() < MAX_COLLECTION_SIZE, "Minting would exceed 10,000, please decrease your quantity");
        require(_reservedBallsClaimed.current() < reservedBalls, "Already minted all of the reserved balls");
        require(_quantity + _reservedBallsClaimed.current() <= reservedBalls, "Minting would exceed the limit of reserved balls. Please decrease quantity.");

        for(uint256 i = 0; i < _quantity; i++) {
            _tokenIdCounter.increment();
            _mint(addr, _tokenIdCounter.current());
            _reservedBallsClaimed.increment();
        }
    }

    function togglePresaleStarted() public onlyOwner {
        presaleStarted = !presaleStarted;
    }

    function togglePublicSaleStarted() public onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function contractBalance() public view onlyOwner returns(uint256) {
        return address(this).balance;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = contractBalance();
        require(balance > 0, "The balance is 0");
        _withdraw(DEV_WALLET, (balance * 15)/100);
        _withdraw(ARTIST_WALLET, (balance * 10)/100);
        _withdraw(FOUNDER_WALLET, contractBalance());
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call { value: _amount}("");
        require(success, "failed with withdraw");
    }
    
 // The following functions are overrides required by Solidity.

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
}