// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./MerkleProof.sol";

/// @custom:security-contact xmichael446@gmail.com
contract InvisibleWomen is ERC721A {
    address public immutable owner;
    bytes32 MERKLE_ROOT;

    uint64 constant public price = 0.03 ether;
    uint64 public count = 2500;
    uint64 constant maxPerWallet = 5;

    bool publicMint = false;
    bool revealed = false;

    mapping(address => uint8) balances;

    string baseURI = "";

    constructor(address _owner, string memory __baseURI, bytes32 _merkleRoot) ERC721A("InvisibleWomen", "IWM") {
        owner = _owner;
        baseURI = __baseURI;
        MERKLE_ROOT = _merkleRoot;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Permission denied");
        _;
    }

    function reveal(string memory __baseURI) external onlyOwner {
        require(!revealed, "Already set the base URI!");

        revealed = true;
        baseURI = __baseURI;
    }

    function startPublicMint() external onlyOwner {
        require(!publicMint, "Already started");

        publicMint = true;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        MERKLE_ROOT = _merkleRoot;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 quantity, bytes32[] calldata proof) external payable {
        require(isInWhitelist(msg.sender, proof) || publicMint, "Must be wl or public mint should be on");
        require(balances[msg.sender] + quantity <= 5, "Limit of 5 tokens per wallet");
        require(quantity <= count, "Trying to mint more than available");
        require(msg.value >= price * quantity, "Paying less");

        payable(owner).transfer(msg.value);

        count -= uint64(quantity);
        balances[msg.sender] += uint8(quantity);
        _safeMint(msg.sender, quantity);
    }

    function isInWhitelist(address claimer, bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, MERKLE_ROOT, keccak256(abi.encodePacked(claimer)));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (revealed) {
            return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
        }
        return baseURI;
    }
}