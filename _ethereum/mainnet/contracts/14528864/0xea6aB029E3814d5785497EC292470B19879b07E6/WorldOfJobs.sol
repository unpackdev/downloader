// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract WorldOfJobs is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public maxPublicMint = 25;
    uint256 public maxWhitelistMint = 3;
    uint256 public publicSalePrice = .08 ether;
    uint256 public whitelistSalePrice = .06 ether;
    uint256 public maxMintableTokenId = 1000;
    uint256 public saleNumber = 1;

    string private  baseTokenUri = "https://worldofjobs.io/files/metadata/";

    bool public isPublicSaleActive = false;
    bool public isWhiteListSaleActive = false;
    bool public hasTeamMinted;

    bytes32 private merkleRoot;

    mapping(uint256 => mapping(address => uint256)) public totalPublicMint;
    mapping(uint256 => mapping(address => uint256)) public totalWhitelistMint;

    constructor() ERC721A("World of Jobs", "WOJ"){}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "World of Jobs :: Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser {
        require(isPublicSaleActive, "World of Jobs :: Not Yet Active.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "World of Jobs :: Beyond Max Supply");
        require((totalSupply() + _quantity) <= maxMintableTokenId, "World of Jobs :: Beyond Max Supply for current sale");
        require((totalPublicMint[saleNumber][msg.sender] + _quantity) <= maxPublicMint, "World of Jobs :: Already minted 25 times!");
        require(msg.value >= (publicSalePrice * _quantity), "World of Jobs :: Below ");
        totalPublicMint[saleNumber][msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable callerIsUser {
        require(isWhiteListSaleActive, "World of Jobs :: Minting is on Pause");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "World of Jobs :: Cannot mint beyond max supply");
        require((totalSupply() + _quantity) <= maxMintableTokenId, "World of Jobs :: Beyond Max Supply for current sale");
        require((totalWhitelistMint[saleNumber][msg.sender] + _quantity) <= maxWhitelistMint, "World of Jobs :: Cannot mint beyond whitelist max mint!");
        require(msg.value >= (whitelistSalePrice * _quantity), "World of Jobs :: Payment is below the price");
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "World of Jobs :: You are not whitelisted");
        totalWhitelistMint[saleNumber][msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint() external onlyOwner {
        require(!hasTeamMinted, "World of Jobs :: Team already minted");
        hasTeamMinted = true;
        _safeMint(msg.sender, 50);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 trueId = tokenId + 1;

        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setMaxPublicMint(uint256 _newMax) public onlyOwner() {
        maxPublicMint = _newMax;
    }

    function setMaxWhitelistMint(uint256 _newMax) public onlyOwner() {
        maxWhitelistMint = _newMax;
    }

    function setPublicPrice(uint256 _newPrice) public onlyOwner() {
        publicSalePrice = _newPrice;
    }

    function setWhitelistPrice(uint256 _newPrice) public onlyOwner() {
        whitelistSalePrice = _newPrice;
    }

    function incrementSale(uint256 _saleNumber) public onlyOwner() {
        saleNumber = _saleNumber;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32){
        return merkleRoot;
    }

    function toggleWhiteListSale() external onlyOwner {
        isWhiteListSaleActive = !isWhiteListSaleActive;
    }

    function togglePublicSale() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
