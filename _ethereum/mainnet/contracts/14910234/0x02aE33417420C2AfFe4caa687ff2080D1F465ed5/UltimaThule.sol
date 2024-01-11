// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ERC721R.sol";

contract Ultimathule is Ownable, ERC721r, ReentrancyGuard {
    uint256 MaxSupply = 5555;
    uint256 public presaleSupply;

    bytes32 private wlMerkleRoot;

    mapping(address => uint256) public presaleMinted;
    mapping(address => uint256) public publicMinted;

    uint8 public presaleMaxWL = 10;
    uint8 public publicSaleMax = 50;

    struct SaleConfig {
        uint256 presalePrice;
        uint256 presaleStartTime;
        uint256 presaleEndTime;
        uint256 publicSalePrice;
        uint256 publicSaleStartTime;
    }

    SaleConfig public saleConfig;

    constructor(uint256 presaleSupply_) ERC721r("UltimaThule: Keys", "ULTM", 5555) {
        presaleSupply = presaleSupply_;

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function presaleWLMint(uint256 quantity, bytes32[] calldata proof) external payable callerIsUser {
        uint256 _salePrice = saleConfig.presalePrice;
        uint256 _totalCost = _salePrice * quantity;
        bytes32 senderKeccak = keccak256(abi.encodePacked(msg.sender));

        require(isPrivateSaleOn(), "Presale is not active");
        require(MerkleProof.verify(proof, wlMerkleRoot, senderKeccak), "Not eligible for presale");
        require(msg.value == _totalCost, "Value cannot be lower than total cost");
        require(totalSupply() < presaleSupply, "Presale supply reached, wait for public sale");
        require(totalSupply() + quantity <= presaleSupply, "Cannot mint this many");
        require(presaleMinted[msg.sender] + quantity <= presaleMaxWL, "Reached maximum mint amount");

        presaleMinted[msg.sender] += quantity;
        _mintRandom(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable callerIsUser {
        uint256 _salePrice = saleConfig.publicSalePrice;
        uint256 _totalCost = _salePrice * quantity;

        require(isPublicSaleOn(), "Public sale is not active");
        require(msg.value == _totalCost, "Value cannot be lower than total cost");
        require(totalSupply() < MaxSupply, "Max supply reached, collection sold out");
        require(totalSupply() + quantity <= MaxSupply, "Cannot mint this many");
        require(publicMinted[msg.sender] + quantity <= publicSaleMax, "Reached maximum mint amount");

        publicMinted[msg.sender] += quantity;
        _mintRandom(msg.sender, quantity);
    }


    function updateConfig(uint256 presalePrice, uint256 presaleStartTime, uint presaleEndTime, uint publicSalePrice, uint publicSaleStartTime) external onlyOwner{
        saleConfig = SaleConfig(presalePrice, presaleStartTime, presaleEndTime, publicSalePrice, publicSaleStartTime);
    }

    function devMint(uint amountForDevs_, address _to) external onlyOwner{
        _mintRandom(_to, amountForDevs_);
    }

    function isPrivateSaleOn() public view returns (bool) {
        uint256 _salePrice = saleConfig.presalePrice;
        uint256 _saleStartTime = saleConfig.presaleStartTime;
        uint256 _saleEndTime = saleConfig.presaleEndTime;
        return _salePrice != 0 && _saleStartTime != 0 && _saleEndTime != 0 && block.timestamp >= _saleStartTime && block.timestamp <= _saleEndTime;
    }

    function isPublicSaleOn() public view returns (bool) {
        uint256 _salePrice = saleConfig.publicSalePrice;
        uint256 _saleStartTime = saleConfig.publicSaleStartTime;
        return _salePrice != 0 && _saleStartTime != 0 && block.timestamp >= _saleStartTime;
    }

    function setMaxSupply(uint256 _newSupply) external onlyOwner {
        require(totalSupply() <= _newSupply, "Cannot set maxSupply less than totalSupply");
        MaxSupply = _newSupply;
    }

    function setMerkleRoot(bytes32 wlMerkleRoot_) external onlyOwner {
        wlMerkleRoot = wlMerkleRoot_;
    }

    function setPresaleMax(uint8 presaleMaxWL_) external onlyOwner {
        presaleMaxWL = presaleMaxWL_;
    }

    function setPublicSaleMax(uint8 publicSaleMax_) external onlyOwner {
        publicSaleMax = publicSaleMax_;
    }

    function isCollectionSoldOut() public view returns (bool) {
        if(totalSupply() == MaxSupply) return true;
        return false;
    }

    function endPublicSale() external onlyOwner {
        require(isPublicSaleOn(), "Public sale is not active");
        saleConfig = SaleConfig(0, 0, 0, 0, 0);
        MaxSupply = totalSupply();
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }


    function withdrawFunds() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to withdraw payment");

    }


}