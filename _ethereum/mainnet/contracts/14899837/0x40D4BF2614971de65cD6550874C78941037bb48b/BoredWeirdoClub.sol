// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";
import "./Ownable.sol";

contract BoredWeirdoClub is Ownable, ERC721A, ReentrancyGuard {  
    using Strings for uint256;

    string private _baseURIextended = "";

    bool public pauseMint = true;
    uint256 public presaleSupply = 666;

    uint256 public constant MAX_NFT_SUPPLY = 6666;
    
    enum SaleState{PreSale, PublicSale }
    
    struct SaleConfig {
        uint256 preSalePrice;
        uint256 publicSalePrice;
        uint256 preSaleLimit;
        uint256 publicSaleLimit;
    }

    SaleConfig public saleConfig;

    constructor() ERC721A("BoredWeirdoClub", "$BWC") {
        saleConfig = SaleConfig(
            0,
            9 * 10 ** 15,
            5,
            5
        );
    }

    function setConfig( uint256 _preSalePrice,
                        uint256 _publicSalePrice,
                        uint256 _preSaleLimit,
                        uint256 _publicSaleLimit ) public onlyOwner {
        saleConfig = SaleConfig(
            _preSalePrice,
            _publicSalePrice,
            _preSaleLimit,
            _publicSaleLimit
        );
    }

    function getSaleState() public view returns (SaleState) {
        SaleState _saleState;

        if (totalSupply() < presaleSupply)
            _saleState = SaleState.PreSale;
        else
            _saleState = SaleState.PublicSale;
        return _saleState;
    }

    function mintNFTForOwner(uint256 amount) public onlyOwner {
        require(!pauseMint, "Paused!");
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");

        _safeMint(msg.sender, amount);
    }

    function mintNFT(uint256 _quantity) public payable {
        require(_quantity > 0);
        require(!pauseMint, "Paused!");
        require(totalSupply() + _quantity < MAX_NFT_SUPPLY, "Sale has already ended");

        SaleState _saleState = getSaleState();

        if(_saleState == SaleState.PreSale) {
            require(saleConfig.preSalePrice * _quantity == msg.value, "ETH value is not correct");
            require(_quantity <= saleConfig.preSaleLimit, "Exceeded mint number.");
        }

        if(_saleState == SaleState.PublicSale) {
            require(saleConfig.publicSalePrice * _quantity == msg.value, "ETH value is not correct");
            require(_quantity <= saleConfig.publicSaleLimit, "Exceeded mint number.");
        }

        _safeMint(msg.sender, _quantity);
    }

    function withdraw() public onlyOwner() {
        require(pauseMint, "ongoing mint");
        uint balance = address(this).balance;
        address payable ownerAddress = payable(msg.sender);
        ownerAddress.transfer(balance);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(_baseURIextended).length > 0 ? string(abi.encodePacked(_baseURIextended, tokenId.toString(), ".json")) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function setPresaleAmount(uint256 amount) external onlyOwner() {
        require(amount <= MAX_NFT_SUPPLY);
        presaleSupply = amount;
    }

    function _price() public view returns (uint256) {
        return saleConfig.publicSalePrice;
    }

    function tokenMinted() public view returns (uint256) {
        return totalSupply();
    }

    function getNFTPrice() public view returns (uint256) {
        if (totalSupply() < presaleSupply)
            return 0;
        else
            return saleConfig.publicSalePrice;
    }

    function pause() public onlyOwner {
        pauseMint = true;
    }

    function unPause() public onlyOwner {
        pauseMint = false;
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}