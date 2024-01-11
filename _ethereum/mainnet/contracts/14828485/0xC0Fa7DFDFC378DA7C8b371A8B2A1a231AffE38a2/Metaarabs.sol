// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract Metaarabs is Ownable, ERC721A, ReentrancyGuard {  
    using Strings for uint256;
    
    string private _baseURIextended = "";
    string public unrevealURI = "ipfs://QmXosHGnJPyDVWzLQ7uTyowmrkPzb3VvretTVGhNVYKtvn/unreveal.json";
    bool public reveal = false;

    bool public pauseMint = true;

    uint256 public constant MAX_NFT_SUPPLY = 9999;
    
    enum SaleState{ Preparing, PreSale, TeamSale, PublicSale }
    
    bytes32 public preSaleMerkleRoot;
    bytes32 public teamSaleMerkleRoot;

    struct SaleConfig {
        uint256 preSaleStartTime;
        uint256 teamSaleStartTime;
        uint256 publicSaleStartTime;
        uint256 preSalePrice;
        uint256 teamSalePrice;
        uint256 publicSalePrice;
        uint256 preSaleLimit;
        uint256 teamSaleLimit;
        uint256 publicSaleLimit;
    }

    SaleConfig public saleConfig;

    constructor() ERC721A("TEST", "$TEST") {
        uint256 _preSaleStartTime = 1654095600;
        saleConfig = SaleConfig(
            _preSaleStartTime,
            _preSaleStartTime + 3600 * 22,
            _preSaleStartTime + 3600 * 24,
            10 * 10 ** 16,
            0,
            18 * 10 ** 16,
            3,
            1,
            10
        );
    }

    function setConfig( uint256 _preSaleStartTime,
                        uint256 _teamSaleStartTime,
                        uint256 _publicSaleStartTime,
                        uint256 _preSalePrice,
                        uint256 _teamSalePrice,
                        uint256 _publicSalePrice,
                        uint256 _preSaleLimit,
                        uint256 _teamSaleLimit,
                        uint256 _publicSaleLimit ) public onlyOwner {
        saleConfig = SaleConfig(
            _preSaleStartTime,
            _teamSaleStartTime,
            _publicSaleStartTime,
            _preSalePrice,
            _teamSalePrice,
            _publicSalePrice,
            _preSaleLimit,
            _teamSaleLimit,
            _publicSaleLimit
        );
    }

    function getSaleState() public view returns (SaleState) {
        uint256 nowTime = block.timestamp;
        SaleState _saleState = SaleState.Preparing;
        if(nowTime >= saleConfig.preSaleStartTime && nowTime < saleConfig.teamSaleStartTime) {
            _saleState = SaleState.PreSale;
        } else if(nowTime >= saleConfig.teamSaleStartTime && nowTime < saleConfig.publicSaleStartTime) {
            _saleState = SaleState.TeamSale;
        } else if(nowTime >= saleConfig.publicSaleStartTime) {
            _saleState = SaleState.PublicSale;
        }
        return _saleState;
    }

    function setMerkleRoot(bytes32 _preSaleMerkleRoot, bytes32 _teamSaleMerkleRoot) external onlyOwner {
        preSaleMerkleRoot = _preSaleMerkleRoot;
        teamSaleMerkleRoot = _teamSaleMerkleRoot;
    }

    function mintNFTForOwner() public onlyOwner {
        require(!pauseMint, "Paused!");
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");

        _safeMint(msg.sender, 1);
    }

    function mintNFT(bytes32[] calldata _proof, uint256 _quantity) public payable {
        require(_quantity > 0);
        require(!pauseMint, "Paused!");
        require(totalSupply() + _quantity < MAX_NFT_SUPPLY, "Sale has already ended");

        SaleState _saleState = getSaleState();
        require(_saleState != SaleState.Preparing, "Not ready to mint.");

        if(_saleState == SaleState.PreSale) {
            require(saleConfig.preSalePrice * _quantity == msg.value, "ETH value is not correct");
            require(MerkleProof.verify(_proof, preSaleMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Address does not exist in whitelist.");
            require(_quantity <= saleConfig.preSaleLimit, "Exceeded mint number.");
        }

        if(_saleState == SaleState.TeamSale) {
            require(saleConfig.teamSalePrice * _quantity == msg.value, "ETH value is not correct");
            require(MerkleProof.verify(_proof, teamSaleMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Address does not exist in whitelist.");
            require(_quantity <= saleConfig.teamSaleLimit, "Exceeded mint number.");
        }

        if(_saleState == SaleState.PublicSale) {
            require(saleConfig.publicSalePrice * _quantity == msg.value, "ETH value is not correct");
            require(_quantity <= saleConfig.publicSaleLimit, "Exceeded mint number.");
        }

        _safeMint(msg.sender, _quantity);
    }

    function withdraw() public onlyOwner() {
        uint balance = address(this).balance;
        address payable ownerAddress = payable(msg.sender);
        ownerAddress.transfer(balance);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(!reveal) return unrevealURI;
        return bytes(_baseURIextended).length > 0 ? string(abi.encodePacked(_baseURIextended, tokenId.toString(), ".json")) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function setUnrevealURI(string memory _uri) external onlyOwner() {
        unrevealURI = _uri;
    }

    function Reveal() public onlyOwner() {
        reveal = true;
    }

    function UnReveal() public onlyOwner() {
        reveal = false;
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