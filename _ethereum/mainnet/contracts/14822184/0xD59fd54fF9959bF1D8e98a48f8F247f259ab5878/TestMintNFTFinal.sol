// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract CryptoBullsGuild is ERC721, Ownable {
    
    event Mint(address indexed _to, uint256 _tokenId, uint _type);

    uint256 public maxSupply = 10000;
    uint256 public maxGiveawaySupply = 200;
    uint256 public maxPresaleSupply = 3000;
    uint256 public totalSupply = 0;
    uint256 public totalGiveawaySupply = 0;
    uint256 public presalePrice = 0.02 ether;
    uint256 public publicSalePrice = 0.025 ether;
    uint256 public maxPerPresaleTx = 10;
    uint256 public maxPerPublicSaleTx = 20;
    bool public isPresaleOpen = false;
    bool public isPublicSaleOpen = false;
    string public hiddenTokenURI = "";
    string public baseTokenURI = "";
    mapping(address => uint256) public presaleWallets;

    struct Data{
        bool isTokenURIRevealed;
        uint256 maxSupply;
        uint256 maxGiveawaySupply;
        uint256 maxPresaleSupply;
        uint256 totalSupply;
        uint256 totalGiveawaySupply;
        uint256 presalePrice;
        uint256 publicSalePrice;
        uint256 maxPerPresaleTx;
        uint256 maxPerPublicSaleTx;
        bool isPresaleOpen;
        bool isPublicSaleOpen;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _hiddenTokenURI
    ) ERC721 (_name, _symbol) {
        hiddenTokenURI = _hiddenTokenURI;
    }

    /* ****************** */
    /* EXTERNAL FUNCTIONS */
    /* ****************** */

    function presaleMint(uint256 quantity) external payable {
        require(isPresaleOpen, "Presale is not open");
        require(quantity > 0 && quantity <= maxPresaleSupply + totalGiveawaySupply - totalSupply, "Quantity invalid");
        require(quantity <= maxPerPresaleTx - presaleWallets[msg.sender], "Exceeded max per wallet");
        require(msg.value >= presalePrice * quantity, "Insufficient ether value");
        presaleWallets[msg.sender] += quantity;
        mintLoop(msg.sender, quantity, 1);
    }

    function publicSaleMint(uint256 quantity) external payable {
        require(isPublicSaleOpen, "Public Sale is not open");
        require(quantity > 0 && quantity <= maxSupply - maxGiveawaySupply + totalGiveawaySupply - totalSupply, "Quantity invalid");
        require(quantity <= maxPerPublicSaleTx, "Exceeded max per transaction");
        require(msg.value >= publicSalePrice * quantity, "Insufficient funds");
        mintLoop(msg.sender, quantity, 2);
    }

    function data() external view returns (Data memory){
        return Data({
            isTokenURIRevealed: bytes(_baseURI()).length>0,
            maxSupply: maxSupply,
            maxGiveawaySupply: maxGiveawaySupply,
            maxPresaleSupply: maxPresaleSupply,
            totalSupply: totalSupply,
            totalGiveawaySupply: totalGiveawaySupply,
            presalePrice: presalePrice,
            publicSalePrice: publicSalePrice,
            maxPerPresaleTx: maxPerPresaleTx,
            maxPerPublicSaleTx: maxPerPublicSaleTx,
            isPresaleOpen: isPresaleOpen,
            isPublicSaleOpen: isPublicSaleOpen
        });
    }

    /* ****************** */
    /* INTERNAL FUNCTIONS */
    /* ****************** */
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function mintLoop(address _to, uint256 _mintAmount, uint _type) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            totalSupply++;
            _safeMint(_to, totalSupply);
            emit Mint(_to, totalSupply, _type);
        }
    }

    /* **************** */
    /* MINTER FUNCTIONS */
    /* **************** */

    function giveawayMint(address to) external onlyOwner {
        require(totalGiveawaySupply < maxGiveawaySupply, "Exceeded max giveaway supply");
        totalGiveawaySupply++;
        mintLoop(to, 1, 0);
    }

    function togglePresale() external onlyOwner {
        isPresaleOpen=!isPresaleOpen;
    }

    function togglePublicSale() external onlyOwner {
        isPublicSaleOpen=!isPublicSaleOpen;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxGiveawaySupply(uint256 _maxGiveawaySupply) external onlyOwner {
        maxGiveawaySupply = _maxGiveawaySupply;
    }

    function setMaxPresaleSupply(uint256 _maxPresaleSupply) external onlyOwner {
        maxPresaleSupply = _maxPresaleSupply>0?_maxPresaleSupply:totalSupply-totalGiveawaySupply;
    }

    function setPresalePrice(uint256 _presalePrice) external onlyOwner {
        presalePrice = _presalePrice;
    }

    function setPublicSalePrice(uint256 _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }

    function setMaxPerPresaleTx(uint256 _maxPerPresaleTx) external onlyOwner {
        maxPerPresaleTx = _maxPerPresaleTx;
    }

    function setMaxPerPublicSaleTx(uint256 _maxPerPublicSaleTx) external onlyOwner {
        maxPerPublicSaleTx = _maxPerPublicSaleTx;
    }


    function setHiddenTokenURI(string memory _hiddenTokenURI) external onlyOwner {
        hiddenTokenURI = _hiddenTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /* ***************** */
    /* OVERRIDE FUNCTION */
    /* ***************** */

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length>0?string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json")):hiddenTokenURI;
    }
}