// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Strings.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract ArmedCryptoSquad is
ERC721,
Ownable
{
    uint256 private  _maxTotal;
    uint256 private  _batchSize;
    string private constant _uriExtension = "json";

    uint256 private _maxAmountPerMint = 10;
    uint256 private _maxAmountPerMintPresale = 4;
    uint256 private _reservedMints = 100;
    uint256 private _currentBatchID = 0;

    uint256 private _cost = 0.07 ether;
    uint256 private _presaleCost = 0.05 ether;

    bool private _isPaused = true;

    mapping(uint256 => string) private _batchCIDs;

    mapping(address => bool) private _whitelist;

    mapping(uint256 => mapping(address => bool)) private _presaleMinted;

    bool private _isPresale = true;
    address[] private _whitelistArray;
    string private _baseTokenURI;

    uint256 _tokenCounter = 0;

    event Mint(address indexed sender, uint totalSupply);

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        string memory CIDPath,
        uint256 maxTotal,
        uint256 batchSize,
        uint256 reservedMints
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _maxTotal = maxTotal;
        _batchSize = batchSize;
        _reservedMints = reservedMints;
        _batchCIDs[_currentBatchID] = CIDPath;
    }

    // Metadata

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_baseURI(), _tokenURIforBatch(tokenId), "/", Strings.toString(tokenId), ".", _uriExtension));
    }

    function _tokenURIforBatch(uint256 tokenId) internal view returns (string memory) {
        require(tokenId <= _maxTotal, "Invalid tokenId");
        require(tokenId > 0, "tokenId can't be 0");
        require(tokenId <= _tokenCounter, "token is not minted yet"); // issues to test
        uint256 batchNumber = tokenId / _batchSize;
        require(bytes(_batchCIDs[batchNumber]).length != 0, "Invalid tokenId");
        return _batchCIDs[batchNumber];
    }

    //Transactions

    function mint(uint256 amount) public payable {
        require(!_isPaused, "mint is currently paused");
        require(!_isPresale, "its currently only for Whitelisted users");
        require(msg.value >= (_cost * amount), "insufficient funds");
        require(amount <= _maxAmountPerMint, "max amount per mint is exceeded");
        require((_tokenCounter + amount) <= ((_currentBatchID + 1) * _batchSize - _reservedMints), "current batch supply is exceeded");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, _tokenCounter + 1);
            emit Mint(msg.sender, _tokenCounter + 1);
            _tokenCounter++;
        }
    }

    function mintPresale(uint256 amount) public payable {
        require(!_isPaused, "mint is currently paused");
        require(_isPresale, "currently only for Whitelisted users");
        require(msg.value >= (_presaleCost * amount), "insufficient funds");
        require(amount <= _maxAmountPerMintPresale, "max amount per mint is exceeded");
        require(isWhitelisted(msg.sender), "mint is currently on Presale, but address is not whitelisted");
        require(!(_presaleMinted[_currentBatchID][msg.sender]), "User already minted in Presale");
        require((_tokenCounter + amount) <= ((_currentBatchID + 1) * _batchSize - _reservedMints), "current batch supply is exceeded");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, _tokenCounter + 1);
            emit Mint(msg.sender, _tokenCounter + 1);
            _tokenCounter++;
        }
        _presaleMinted[_currentBatchID][msg.sender] = true;
    }

    function mintReserved(address to, uint256 amount) public onlyOwner {
        require((_tokenCounter + amount) <= ((_currentBatchID + 1) * _batchSize), "current batch supply is exceeded");
        require(_reservedMints > 0, "no reserved mints available");
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, _tokenCounter + 1);
            emit Mint(msg.sender, _tokenCounter + 1);
            _tokenCounter++;
        }
        _reservedMints--;
    }

    function airDrop(address[] memory addresses) public onlyOwner {
        require(_reservedMints > 0, "no reserved mints available");
        require(_tokenCounter + addresses.length <= ((_currentBatchID+1)*_batchSize), "current batch supply is exceeded");

    for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], _tokenCounter + 1);
            emit Mint(msg.sender, _tokenCounter + 1);
            _tokenCounter++;
            _reservedMints--;
        }
    }

    function withdraw(address payable to, uint256 amount) public onlyOwner {
        to.transfer(amount);
    }

    // Getters 

    function totalSupply() public view returns (uint256) {
        return _tokenCounter;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelist[account];
    }

    function didMintInCurrentPresale(address account) public view returns (bool) {
        return _presaleMinted[_currentBatchID][account];
    }

    function getPresaleCost() public view returns (uint256) {
        return _presaleCost;
    }

    function getCost() public view returns (uint256) {
        if (_isPresale) {
            return _presaleCost;
        } else {
            return _cost;
        }

    }

    function getMaxAmountPerMint() public view returns (uint256) {
        if (_isPresale) {
            return _maxAmountPerMintPresale;
        } else {
            return _maxAmountPerMint;
        }
    }

    function getReservedMints() public view returns (uint256) {
        return _reservedMints;
    }

    function isPresale() public view returns (bool) {
        return _isPresale;
    }

    function isPaused() public view returns (bool) {
        return _isPaused;
    }

    // Setters (onlyOwner)

    function registerNewBatch(string memory CIDPath, uint256 reservedMints) public onlyOwner {
        _currentBatchID++;
        _batchCIDs[_currentBatchID] = CIDPath;
        _reservedMints = reservedMints;
    }

    function revealBatch(uint256 barchNr, string memory CIDPath) public onlyOwner {
        _batchCIDs[barchNr] = CIDPath;
    }

    //  Add addressed to whitelist in current batch
    function addAddressesToWhitelist(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < _whitelistArray.length; i++) {
            _whitelist[_whitelistArray[i]] = false;
            _presaleMinted[_currentBatchID][_whitelistArray[i]] = false;
        }
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelist[addresses[i]] = true;
        }
        _whitelistArray = addresses;
    }

    function setBaseTokeURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
    }

    function setPresale(bool enable) public onlyOwner {
        _isPresale = enable;
    }

    function setCost(uint256 newCost) public onlyOwner {
        _cost = newCost;
    }

    function setPresaleCost(uint256 newCost) public onlyOwner {
        _presaleCost = newCost;
    }

    function setMaxAmountPerMint(uint256 amount) public onlyOwner {
        _maxAmountPerMint = amount;
    }

    function maxAmountPerMintPresale(uint256 amount) public onlyOwner {
        _maxAmountPerMintPresale = amount;
    }

    function setPaused(bool value) public onlyOwner {
        _isPaused = value;
    }

    function setReservedMints(uint256 count) public onlyOwner {
        _reservedMints = count;
    }
}

