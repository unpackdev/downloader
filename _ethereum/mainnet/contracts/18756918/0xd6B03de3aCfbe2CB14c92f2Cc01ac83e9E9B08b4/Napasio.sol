// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract Napasio is ERC721A, Ownable {

    /// ============ STORAGE ============

    string private baseURI;

    uint256 constant public MAX_SUPPLY = 777;
    uint256 constant public MAX_MINT_PER_WALLET = 2;

    uint256 public PRICEwl = 0.01 ether;
    uint256 public PRICEpubic = 0.01 ether;
    uint256 public saleStage;
    bytes32 public merkleRoot;

    mapping(address => uint256) public mintedCount;

    /// ============ CONSTRUCTOR ============

    constructor(
        string memory _baseURI,
        bytes32 _merkleRoot
    ) ERC721A("Napasio", "NAP") {
        baseURI = _baseURI;
        merkleRoot = _merkleRoot;
        _mint(msg.sender, 1);
    }

    /// ============ MAIN ============

    function mintWl(
        bytes32[] memory _merkleproof,
        uint256 quantity
    ) public payable {

        require(msg.sender == tx.origin, "No contracts");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleproof, merkleRoot, leaf), "Merkle proof verification failed");

        require(saleStage >= 1, "Sale has not started");
        require(quantity > 0, "Quantity must be greater than 0");
        require(quantity + mintedCount[msg.sender] <= MAX_MINT_PER_WALLET, "Quantity must be less than max mint per wallet");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Quantity must be less than max supply");
        require(msg.value >= PRICEwl * quantity, "Ether value sent is not correct");

        mintedCount[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    function mintPublic(
        uint256 quantity
    ) public payable {

        require(msg.sender == tx.origin, "No contracts");
        require(saleStage == 2, "Sale has not started");
        require(quantity > 0, "Quantity must be greater than 0");
        require(quantity + mintedCount[msg.sender] <= MAX_MINT_PER_WALLET, "Quantity must be less than max mint per wallet");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Quantity must be less than max supply");
        require(msg.value >= PRICEpubic * quantity, "Ether value sent is not correct");

        mintedCount[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    /// ============ ONLY OWNER ============

    function startWl() external onlyOwner {
        require(saleStage == 0, "NS");
        saleStage = 1;
    }

    function startPublic() external onlyOwner {
        require(saleStage == 1, "NWL");
        saleStage = 2;
    }

    function setPriceWl(uint256 _price) external onlyOwner {
        PRICEwl = _price;
    }

    function setPricePublic(uint256 _price) external onlyOwner {
        PRICEpubic = _price;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setbaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /// ============ METADATA ============

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

        return string(abi.encodePacked(baseURI, _toString(tokenId), ".json"));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

}
