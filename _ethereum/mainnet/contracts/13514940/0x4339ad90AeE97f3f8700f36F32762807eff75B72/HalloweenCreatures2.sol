pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./Strings.sol";
import "./Pausable.sol";
import "./Counters.sol";

interface IStaking {
    function depositsOf(address account) external view returns (uint256[] memory);
}

contract HalloweenCreatures2 is ERC721URIStorage, Ownable, Pausable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    event AddToWhitelist(uint256 numberAdded);
    event RemoveFromWhitelist(uint256 numberRemoved);
    event TeamMint(address ownerAddress, uint256 amountMinted);

    uint256 public constant TOTAL_SUPPLY = 9696;
    uint256 public constant MAX_PRESALE_SUPPLY = 3333;
    uint256 public constant MAX_TEAM_SUPPLY = 516;
    uint256 public _maxBatch = 5;
    uint256 public _pricePerMint = 0.0333 ether;
    Counters.Counter private _tokenIdCounter;
    uint256 public _maxMintsPerWallet = 15;
    bool public _startFreeSale;
    bool public _startPublic;
    string public baseURI;
    
    mapping(address => uint256) private _mintCount;

    //constructor args 
    constructor() ERC721("HalloweenCreatures", "HCreatures") {
        // make it 1-based instead of 0-based
        _tokenIdCounter.increment();
        _pause();
    }
    modifier canMintFree(uint256 times) {
        require(times > 0 && times <= _maxBatch, "incorrect number of mints");
        require(currentSupply() + times <= TOTAL_SUPPLY, "This mint would pass max supply");
        require(_mintCount[msg.sender] + times <= _maxMintsPerWallet, "Too many mints for this wallet");
        _;
    }
    modifier canMint(uint256 times) {
        require(times > 0 && times <= _maxBatch, "incorrect number of mints");
        require(currentSupply() + times <= TOTAL_SUPPLY, "This mint would pass max supply");
        require(msg.value == times * _pricePerMint, "Incorrect price given");
        require(_mintCount[msg.sender] + times <= _maxMintsPerWallet, "Too many mints for this wallet");
        _;
    }
    function currentSupply() public view returns(uint256) {
        // Subtract 1 because we start at 1 for tokens but supply is 0-based
        return _tokenIdCounter.current() - 1;
    }
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }
    function setPrice(uint256 price) external onlyOwner {
        _pricePerMint = price;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "tokenId does not exist.");
        
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : ".json";
    }
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }
    function setMaxMintsPerWallet(uint256 maxMints) external onlyOwner {
        _maxMintsPerWallet = maxMints;
    }
    function setMaxBatch(uint256 maxBatch) external onlyOwner {
        _maxBatch = maxBatch;
    }
    function setSales(bool freeSale, bool publicSale) external onlyOwner {
        _startFreeSale = freeSale;
        _startPublic = publicSale;
    }
    function pause() external onlyOwner {
        _pause();
    }
    function unpause() external onlyOwner {
        _unpause();
    }

    function mint(uint256 times) internal {
        for(uint256 i = 0; i < times; i++){
            _mint(_msgSender(), _tokenIdCounter.current());
            _tokenIdCounter.increment();
            _mintCount[msg.sender] += 1;
        }
    }

    function teamMint() public onlyOwner {
        require(!_startFreeSale && !_startPublic, "Can't mint after sales start");
        mint(MAX_TEAM_SUPPLY);
        emit TeamMint(msg.sender, MAX_TEAM_SUPPLY);
    }

    function mintFree(uint256 times) public canMintFree(times) whenNotPaused {
        require(_startFreeSale, "Free sale is not live");
        require(currentSupply() + times <= MAX_PRESALE_SUPPLY + MAX_TEAM_SUPPLY, "No more free mints available");
        mint(times);
    }

    function mintPublic(uint256 times) public payable canMint(times) whenNotPaused {
        require(_startPublic, "Public sale is not live");
        payable(owner()).transfer(msg.value);
        mint(times);
    }
    
}