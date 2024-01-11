//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Pausable.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract THE is ERC721Enumerable, ReentrancyGuard, Pausable, Ownable {

    using Strings for uint256;

    bool public isRevealed = false;

    uint256 public presaleItemPrice = 0.03 ether;
    uint256 public itemPrice = 0.05 ether;
    uint256 public constant _TOTAL_SUPPLY = 9_100;
    uint256 public constant WALLET_LIMIT = 5;

    mapping(address => bool) private whitelist;
    mapping(address => uint256) private addressIndices;

    address[] private stakeHolders = [
        0x510997dfB2C52C92542fEBB9425e0Dbf03B3FF78,
        0xF011DC11Cf157cD302853101Ccc83Db52CE57d3c,
        0x531c2f396114112effCc2A5CDf574358B8183526,
        0xfCD6Ce5bAe312e1a4E2e04E1669f88E4D37A7912,
        0x690977AcDB63E9786f7A58D025b021b2783a4B3D
    ];

    uint256[] private teamShares = [
        27,
        27, 
        10,
        11,
        25
    ];

    string public baseURI;
    string public notRevealedURI;

    using Counters for Counters.Counter;
    Counters.Counter public currentTokenId;
    
    enum Steps {
        Presale,
        Sale
    }
    Steps public sellingStep;

    constructor(string memory _name, string memory _notRevealedURI)
        ERC721(_name, "THE")
    {
        // baseURI = _baseUri;
        notRevealedURI = _notRevealedURI;
        sellingStep = Steps.Presale;
    }

    // MODIFIERS

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // FUNCTIONS

    function setUpSale() external onlyOwner callerIsUser {
        sellingStep = Steps.Sale;
    }

    function reveal() external onlyOwner{
        isRevealed = true;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function baseUri() public view returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint _currentTokenId) public view override(ERC721) returns (string memory) {
        require(_exists(_currentTokenId), "This NFT doesn't exist.");
        if(isRevealed == false) {
            return notRevealedURI;
        }   
        return 
        string(abi.encodePacked(baseURI,_currentTokenId.toString()));
    }

    function setNotRevealURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unPause() external onlyOwner whenPaused {
        _unpause();
    }

    function whitelistMint() external payable whenNotPaused nonReentrant callerIsUser
    {
        address minter = msg.sender;
        require(whitelist[minter], "Not allowed to whitelist mint");
        require(addressIndices[minter] < 1, "Only 1 NFT par user for presales");
        require(msg.value >= presaleItemPrice, "Incorrect payable amount");
        currentTokenId.increment();
        ++addressIndices[minter];
        uint256 newItemId = currentTokenId.current();
        _safeMint(minter, newItemId);    
    }

    function publicMint(uint256 _amount) external payable whenNotPaused nonReentrant callerIsUser 
        returns (uint256)
    {
        address minter = msg.sender;
        require(addressIndices[minter] + _amount <= WALLET_LIMIT, "Max wallet mint limit reached");
        require(_TOTAL_SUPPLY - currentTokenId.current() != 0, "Sorry, no NFTs left.");
        require(msg.value >= _amount * itemPrice, "Incorrect payable amount");
        require(sellingStep == Steps.Sale, "Sorry, sale has not started yet.");
        require(_amount <= (_TOTAL_SUPPLY - currentTokenId.current()), "Try minting less tokens");

        for (uint256 i = 0; i < _amount; i++) {
            currentTokenId.increment();
            ++addressIndices[minter];
            uint256 newItemId = currentTokenId.current();
            _safeMint(minter, newItemId);
        }

        return currentTokenId.current();
    }

    function gift(address _minter) external whenNotPaused onlyOwner callerIsUser {
        require(currentTokenId.current() + 1 <= _TOTAL_SUPPLY, "Sold out");
        currentTokenId.increment();
        ++addressIndices[_minter];
       uint256 newItemId = currentTokenId.current();
        _safeMint(_minter, newItemId);
    }

    function addToWhitelistSaleList(address[] memory _whitelistMinters) public onlyOwner
    {
        for (uint256 i = 0; i < _whitelistMinters.length; i++)
            whitelist[_whitelistMinters[i]] = true;
    }

    function updatePreSalePrice(uint256 _presaleItemPrice) external onlyOwner {
        presaleItemPrice = _presaleItemPrice;
    }

    function updateSalePrice(uint256 _price) external onlyOwner {
        itemPrice = _price;
    }

    function withdrawAll() external {
        uint256 balance = address(this).balance;
        for (uint256 i = 0; i < stakeHolders.length; i++) {
            payable(stakeHolders[i]).transfer((balance/100) * teamShares[i]);
        }
    }
}
