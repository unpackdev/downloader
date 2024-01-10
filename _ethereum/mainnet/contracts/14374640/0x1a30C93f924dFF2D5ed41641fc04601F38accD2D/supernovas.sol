// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
import "./ERC721.sol";
import "./Ownable.sol";


// Inspired/Copied from DystoPunks
contract SuperNovas is  Ownable, ERC721 {

    uint public constant MAX_GIRLS = 3333;
    uint constant TOKEN_PRICE = 0.04 ether;
    uint constant WL_TOKEN_PRICE = 0.03 ether;
    bool public hasSaleStarted = false;
    bool public hasPrivateSaleStarted = false;
    mapping(address => uint8) private _allowList;
    mapping(address => uint8) private _freeList;
    string private _baseTokenURI;
    uint public minted;

    constructor(string memory baseTokenURI) ERC721("SuperNovas","SN")  {
        setBaseURI(baseTokenURI);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }
    
    function setAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = 1;
        }
    }
    
    function numAllowMint(address addr) public view returns (uint8) {
        return _allowList[addr];
    }
    
    function mintAllowList(uint8 numSuperNovas) public payable {
        require(hasPrivateSaleStarted == true, "Private sale has not already started");
        require(minted+numSuperNovas <= MAX_GIRLS, "Exceeds MAX_GIRLS");
        require(msg.value >= WL_TOKEN_PRICE * numSuperNovas, "Ether value sent is below the price");
        require(_allowList[msg.sender] > 0, "Not whitelisted");
        require(numSuperNovas < 11, "You can mint minimum 1, maximum 10 SuperNovas");
        for (uint i = 0; i < numSuperNovas; i++) {
            uint mintIndex = minted;
            _safeMint(msg.sender, mintIndex);
            minted += 1;
        }
        
    }

     function setFreeList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _freeList[addresses[i]] = 1;
        }
    }
    
    function numFreeMint(address addr) public view returns (uint8) {
        return _freeList[addr];
    }
    
    function mintFreeList() public {
        require(hasPrivateSaleStarted == true, "Private sale has not already started");
        require(minted+1 <= MAX_GIRLS, "Exceeds MAX_GIRLS");
        require(_freeList[msg.sender] > 0, "Not whitelisted");
        uint mintIndex = minted;
        _safeMint(msg.sender, mintIndex);
        minted += 1;
        _freeList[msg.sender] -= 1;
        
    }

   function getSuperNovas(uint256 numSuperNovas) public payable {
        require(hasSaleStarted == true, "Sale has not already started");
        require(numSuperNovas < 11, "You can mint minimum 1, maximum 10 SuperNovas");
        require(minted+numSuperNovas <= MAX_GIRLS, "Exceeds MAX_GIRLS");
        require(msg.value >= TOKEN_PRICE * numSuperNovas, "Ether value sent is below the price");
        for (uint i = 0; i < numSuperNovas; i++) {
            uint mintIndex = minted;
            _safeMint(msg.sender, mintIndex);
            minted += 1;
        }
    }

    function reserveAirdrop(uint256 numSuperNovas) public onlyOwner {
        require(minted+numSuperNovas <= MAX_GIRLS, "Exceeds MAX_GIRLS");
        require(minted + numSuperNovas < 31, "Exceeded airdrop supply");
        for (uint i = 0; i < numSuperNovas; i++) {
            uint mintIndex = minted;
            _safeMint(msg.sender, mintIndex);
            minted += 1;
        }
        
    }
    
    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function startPrivateSale() public onlyOwner {
        hasPrivateSaleStarted = true;
    }

    function pausePrivateSale() public onlyOwner {
        hasPrivateSaleStarted = false;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}