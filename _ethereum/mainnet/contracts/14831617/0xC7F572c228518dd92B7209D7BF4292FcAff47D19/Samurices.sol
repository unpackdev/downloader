// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract Samurices is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI = "";
    string public baseURIExtension = "";
    string public hiddenMetadataURI = "";

    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant VAULT_SUPPLY = 77;
    uint256 public constant MINT_PRICE_PRESALE = 0.033 ether;
    uint256 public constant MINT_PRICE_PUBLIC = 0.05 ether;
    uint256 public constant MAX_MINT_PRESALE = 3;
    uint256 public MAX_MINT_PUBLIC = 3;

    bytes32 public merkleRoot;

    bool public isPresaleActive = false;
    bool public isPublicSaleActive = false;
    bool public revealed = false;

    mapping(address => uint256) public reservationList;

    constructor(
        string memory _hiddenMetadataURI,
        string memory _initBaseURI,
        string memory _initBaseURIExtension
    ) ERC721A("Samurices", "SAMURICES") {
        setHiddenMetadataURI(_hiddenMetadataURI);
        setBaseURI(_initBaseURI);
        setBaseExtension(_initBaseURIExtension);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function publicMint(uint256 _quantity) external payable nonReentrant callerIsUser {
        uint256 price = MINT_PRICE_PUBLIC;
        require(isPublicSaleActive, "Public sale is not active");
        require(_quantity > 0, "Invalid quantity");
        require(
            _numberMinted(msg.sender) - reservationList[msg.sender] + _quantity <= MAX_MINT_PUBLIC,
            "Max mint reached"
        );
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply reached");
        require(msg.value == price * _quantity, "Wrong ETH amount");
        _safeMint(msg.sender, _quantity);
    }

    // Reservation list

    function reservedMint(uint256 _quantity, bytes32[] calldata _proof) external payable nonReentrant callerIsUser {
        uint256 price = MINT_PRICE_PRESALE;
        require(isPresaleActive, "Presale is not active");
        require(hasReservedSpot(msg.sender, _proof), "Not in the reservation list");
        require(_quantity > 0, "Invalid quantity");
        require(reservationList[msg.sender] + _quantity <= MAX_MINT_PRESALE, "Max mint reached");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply reached");
        require(msg.value == price * _quantity, "Wrong ETH amount");
        reservationList[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function hasReservedSpot(address _account, bytes32[] calldata _proof) internal view returns (bool) {
        return _verify(leaf(_account), _proof);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    // Metadata

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if (!revealed) {
            return hiddenMetadataURI;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), baseURIExtension))
                : "";
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setHiddenMetadataURI(string memory _newURI) public onlyOwner {
        hiddenMetadataURI = _newURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseExtension(string memory _newBaseURIExtension) public onlyOwner {
        baseURIExtension = _newBaseURIExtension;
    }

    // Admin

    function togglePresale() external onlyOwner {
        isPresaleActive = !isPresaleActive;
    }

    function togglePublicSale() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function toggleReveal() external onlyOwner {
        revealed = !revealed;
    }

    function setMaxMintPublic(uint256 _newMaxMints) external onlyOwner {
        MAX_MINT_PUBLIC = _newMaxMints;
    }

    function adminMint() external onlyOwner {
        require(totalSupply() + VAULT_SUPPLY <= MAX_SUPPLY, "Max supply reached");
        _safeMint(owner(), VAULT_SUPPLY);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
