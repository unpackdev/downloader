// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

import "./ERC721AOwnersExplicit.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

contract MoneyShark is ERC721AOwnersExplicit, Ownable { 
    using Strings for uint256;

    uint256 public constant MAX_SHARKS = 2022;
    uint256 public constant RESERVED_SHARKS = 122;
    bool public reservedSharksMinted = false;

    bool public OGSaleActive = false;
    bool public WLSaleActive = false;
    bool public publicSaleActive = false;

    bytes32 public OGMerkleRoot = 0x95a54e2702655bca55b5208f06fbd93042014a8afa622fe6dd53ab60aafb5013;
    bytes32 public WLMerkleRoot = 0x7f6b8eeeac427da5e10b24729e512016ccdf3a119313c5a1bd9e2db9d8421318;

    mapping(address => uint256) public OGAlreadyMinted;
    mapping(address => uint256) public WLAlreadyMinted;

    uint256 public OGPrice = 0.1 ether; 
    uint256 public WLPrice = 0.125 ether; 
    uint256 public publicPrice = 0.175 ether; 

    string public _baseTokenUri = "https://gateway.pinata.cloud/ipfs/QmP69DscPRKUkYY88zHAYo33wbFkdXZBGHpv6ESFQXt5jF/";
    bytes32 public provenanceHash;

    event newSharksMinted(address sender);
    event flippedOGSale(bool saleState);
    event flippedWLSale(bool saleState);
    event flippedPublicSale(bool saleState);

    modifier checkAmount(uint256 amount) {
        require(amount > 0, "Invalid amount");
        require(
            totalSupply() + amount <= MAX_SHARKS,
            "Money Sharks are sold out"
        );
        _;
    }

    constructor() ERC721A("MoneyShark", "MSNFT") {}

    function reservedSharksMint() external onlyOwner {
        require(!reservedSharksMinted, "Reserved Sharks minted");
        reservedSharksMinted = true;
        _safeMint(owner(), RESERVED_SHARKS);
    }

    function OGSaleMint(uint256 amount, bytes32[] calldata merkleProof)
        external
        payable
        checkAmount(amount)
    {
        require(OGSaleActive, "OG sale not active");
        require(msg.value >= amount * OGPrice, "Insufficient funds");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, OGMerkleRoot, leaf),
            "invalid proof"
        );

        require(
            OGAlreadyMinted[_msgSender()] + amount <= 50,
            "max allocation reached"
        );
        OGAlreadyMinted[_msgSender()] += amount;

        _safeMint(_msgSender(), amount);
        emit newSharksMinted(msg.sender);
    }

    function WLSaleMint(uint256 amount, bytes32[] calldata merkleProof)
        external
        payable
        checkAmount(amount)
    {
        require(WLSaleActive, "WL sale not active");
        require(msg.value >= amount * WLPrice, "Insufficient funds");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, WLMerkleRoot, leaf),
            "Merkle proof invalid"
        );

        require(
            WLAlreadyMinted[_msgSender()] + amount <= 50,
            "max allocation reached"
        );
        WLAlreadyMinted[_msgSender()] += amount;

        _safeMint(_msgSender(), amount);
        emit newSharksMinted(msg.sender);
    }

    function publicSaleMint(uint256 amount)
        external
        payable
        checkAmount(amount)
    {
        require(publicSaleActive, "Public sale not active");
        require(msg.value >= amount * publicPrice, "Insufficient funds");

        _safeMint(_msgSender(), amount);
        emit newSharksMinted(msg.sender);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(_baseTokenUri, _tokenId.toString()));
    }

    function flipOGSale() external onlyOwner {
        OGSaleActive = !OGSaleActive;
        emit flippedOGSale(OGSaleActive);
    }

    function flipWLSale() external onlyOwner {
        WLSaleActive = !WLSaleActive;
        emit flippedWLSale(WLSaleActive);
    }

    function flipPublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
        emit flippedPublicSale(publicSaleActive);
    }

    function setBaseTokenUri(string memory _uri) external onlyOwner {
        _baseTokenUri = _uri;
    }

    function setOGRoot(bytes32 _OGroot) external onlyOwner {
        OGMerkleRoot = _OGroot;
    }

    function setWLRoot(bytes32 _WLroot) external onlyOwner {
        WLMerkleRoot = _WLroot;
    }

    function setProvenanceHash(bytes32 _hash) external onlyOwner {
        provenanceHash = _hash;
    }

    function getEther() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success);
    }
}
