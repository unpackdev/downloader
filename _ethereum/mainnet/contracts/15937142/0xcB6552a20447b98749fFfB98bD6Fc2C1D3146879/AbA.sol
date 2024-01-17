// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract AnonymousByAnonymous is ERC721A, Ownable, ReentrancyGuard  {

    enum MintPhase {
        NOT_START,
        KOUN_PASS_MINT,
        ALLOW_LIST
    }

    MintPhase public currentMintPhase = MintPhase.NOT_START;

    function setMintPhase(MintPhase _mintPhase) external onlyOwner {
        currentMintPhase = _mintPhase;
    }

    modifier inMintPhase(MintPhase requireMintPhase) {
        require(requireMintPhase == currentMintPhase, "Not in correct mint phase.");
        _;
    }

    uint256 collectionSize = 1111;

    constructor() ERC721A("Anonymous by Anonymous", "AbA") {}

    string public baseURI;

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    uint256 public priceOfAllowList = 0.02 ether;

    function setPrice(uint256 _priceOfAllowList) external onlyOwner {
        priceOfAllowList = _priceOfAllowList;
    }

    bytes32 public kounPassRoot;

    mapping(address => bool) addressAppeared;

    function isKounPassHolder(address from, uint256 amount, bytes32[] memory proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(from, _toString(amount)));
        return MerkleProof.verify(proof, kounPassRoot, leaf);
    }

    function setKounPassRoot(bytes32 _kounPassRoot) external onlyOwner {
        kounPassRoot = _kounPassRoot;
    }

    function kounPassClaim(uint256 amount, bytes32[] memory proof) external inMintPhase(MintPhase.KOUN_PASS_MINT) {
        require(amount > 0, "Mint amount not valid.");
        require(totalSupply() + amount <= collectionSize, "Exceed Collection Size.");
        require(isKounPassHolder(msg.sender, amount, proof), "Invalid Merkle Proof.");
        require(!addressAppeared[msg.sender], "You have minted.");
        addressAppeared[msg.sender] = true;
        _safeMint(msg.sender, amount);
    }

    bytes32 public allowListRoot;

    function isInAllowList(address from, bytes32[] memory proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(from));
        return MerkleProof.verify(proof, allowListRoot, leaf);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        allowListRoot = _merkleRoot;
    }

    function allowListMint(uint256 amount, bytes32[] memory proof) external payable nonReentrant inMintPhase(MintPhase.ALLOW_LIST) {
        require(amount > 0, "Mint amount not valid.");
        require(totalSupply() + amount <= collectionSize, "Exceed Collection Size.");
        require(isInAllowList(msg.sender, proof), "Invalid Merkle Proof Or You Have Minted");
        require(_numberMinted(msg.sender) + amount * 2 <= 600, "Reached max.");
        require(msg.value == amount * priceOfAllowList, "Not Enough Value.");
        _safeMint(msg.sender, amount * 2);
    }

    function airdrop(address[] calldata toList, uint256[] calldata quantities) external onlyOwner {
        for (uint256 i = 0; i < toList.length; i++) {
            require(totalSupply() + quantities[i] <= collectionSize, "Exceed Collection Size.");
            _safeMint(toList[i], quantities[i]);
        }
    }

    function withdraw() external onlyOwner {
        address vault = 0x68C77dC5A305579Ec17f2488B1Fac826bE0D6FC7;
        (bool success, ) = vault.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}
