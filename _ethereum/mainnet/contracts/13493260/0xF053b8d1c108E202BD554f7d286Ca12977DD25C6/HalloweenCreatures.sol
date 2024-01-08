pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./Strings.sol";
import "./Pausable.sol";
import "./Counters.sol";

interface IStaking {
    function depositsOf(address account) external view returns (uint256[] memory);
}

contract HalloweenCreatures is ERC721URIStorage, Ownable, Pausable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    event AddToWhitelist(uint256 numberAdded);
    event RemoveFromWhitelist(uint256 numberRemoved);
    event TeamMint(address ownerAddress, uint256 amountMinted);

    uint256 public constant TOTAL_SUPPLY = 9696;
    uint256 public constant MAX_PRESALE_SUPPLY = 6969;
    uint256 public constant MAX_TEAM_SUPPLY = 50;
    uint256 public constant MAX_BATCH = 10;
    uint256 public constant PRICE_PER_MINT = 0.0666 ether;
    Counters.Counter private _tokenIdCounter;
    uint256 public _maxMintsPerWallet = 5;
    bool public _startPresale;
    bool public _startPublic;
    string public baseURI;
    
    mapping(address => bool) private _whitelistAddresses;
    mapping(address => uint256) private _mintCount;
    IERC721 public _creatureNFT;
    IERC721 public _fudFarmsNFT;
    IStaking public _stakingContract;

    //constructor args 
    constructor() ERC721("HalloweenCreatures", "HCreatures") {
        // make it 1-based instead of 0-based
        _tokenIdCounter.increment();
        _pause();
    }

    modifier isSetUp() {
        require(address(_creatureNFT) != address(0), "creaturesNFT not set");
        require(address(_fudFarmsNFT) != address(0), "fudFarmsNFT not set");
        require(address(_stakingContract) != address(0), "stakingContract not set");
        _;
    }
    modifier canMint(uint256 times) {
        require(times > 0 && times <= MAX_BATCH, "incorrect number of mints");
        require(currentSupply() + times <= TOTAL_SUPPLY, "This mint would pass max supply");
        require(msg.value == times * PRICE_PER_MINT, "Incorrect price given");
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
    function setSales(bool presale, bool publicSale) external onlyOwner {
        _startPresale = presale;
        _startPublic = publicSale;
    }
    function setContracts(address creature, address fudFarm, address stakingContract) external onlyOwner {
        _creatureNFT = IERC721(creature);
        _fudFarmsNFT = IERC721(fudFarm);
        _stakingContract = IStaking(stakingContract);
    }
    function pause() external onlyOwner {
        _pause();
    }
    function unpause() external onlyOwner isSetUp {
        _unpause();
    }
    function addToWhitelist(address[] calldata addressesToAdd) public onlyOwner {
        for (uint256 i = 0; i < addressesToAdd.length; i++) {
            _whitelistAddresses[addressesToAdd[i]] = true;
        }
        emit AddToWhitelist(addressesToAdd.length);
    }
    function removeFromWhitelist(address[] calldata addressesToRemove) public onlyOwner {
        for (uint256 i = 0; i < addressesToRemove.length; i++) {
            _whitelistAddresses[addressesToRemove[i]] = false;
        }
        emit RemoveFromWhitelist(addressesToRemove.length);
    }

    function mint(uint256 times) internal {
        for(uint256 i = 0; i < times; i++){
            _mint(_msgSender(), _tokenIdCounter.current());
            _tokenIdCounter.increment();
            _mintCount[msg.sender] += 1;
        }
    }

    function teamMint() public onlyOwner {
        require(!_startPresale && !_startPublic, "Can't mint after sales start");
        mint(MAX_TEAM_SUPPLY);
        emit TeamMint(msg.sender, MAX_TEAM_SUPPLY);
    }

    function mintHolderPresale(uint256 times) public payable canMint(times) whenNotPaused {
        require(_startPresale, "Presale is not live");
        require(currentSupply() + times <= MAX_PRESALE_SUPPLY + MAX_TEAM_SUPPLY, "No more presale mints available");
        require(_creatureNFT.balanceOf(msg.sender) > 0 
            || _fudFarmsNFT.balanceOf(msg.sender) > 0
            || _stakingContract.depositsOf(msg.sender).length > 0,
            "Must hold a creature or fudFarm");
        payable(owner()).transfer(msg.value);
        mint(times);
    }

    function mintWhitelistPresale(uint256 times) public payable canMint(times) whenNotPaused {
        require(_startPresale, "Presale is not live");
        require(currentSupply() + times <= MAX_PRESALE_SUPPLY + MAX_TEAM_SUPPLY, "No more presale mints available");
        require(_whitelistAddresses[msg.sender], "Not on whitelist");
        payable(owner()).transfer(msg.value);
        mint(times);
    }

    function mintPublic(uint256 times) public payable canMint(times) whenNotPaused {
        require(_startPublic, "Public sale is not live");
        payable(owner()).transfer(msg.value);
        mint(times);
    }
    
}