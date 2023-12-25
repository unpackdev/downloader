// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";
import "./Counters.sol";

contract ZKLegendGenesisNFT is ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    address private _owner;
    uint256 private _claimCase = 0;

    bool public publicMintingActive = false;
    uint256 public mintingFee = 1 ether;

    string private _baseURIValue = "ipfs://bafybeidm6xt6yrqggce4gocuz4ghopyuyfi3vdmsvtocfez6fj5n3qxu7m/";
    string private _contractURIValue = "ipfs://bafkreiasti6a2obuhe4qmavdfi5fsyloehfwmv2uqpfab445wrlqwppaem";

    
    bytes32 public merkleRoot; 

    mapping(address => bool) public claimedAddresses; 

    mapping(address => bool) public w1;
    mapping(address => bool) public w2;
    mapping(address => bool) public w3;

    constructor(bytes32 _merkleRoot) ERC721("zkLegend Genesis NFT", "ZKLG") {
        merkleRoot = _merkleRoot;
        _owner = msg.sender;
    }

    function ownerClaim() external onlyOwner {
        _mintNFT(msg.sender);
    }

    function ownerDistribute(address recipient) public onlyOwner {
        _mintNFT(recipient);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIValue;
    }

    // WL Users to claim
    function claim(bytes32[] calldata proof) external {

        require(_claimCase == 0, "Wrong case!"); 

        require(!claimedAddresses[msg.sender], "Already claimed");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");
        
        claimedAddresses[msg.sender] = true;

        _mintNFT(msg.sender);
    }
    
    function otherClaim(bytes32[] calldata proof) external {

        if (_claimCase == 1) {
            require(!w1[msg.sender], "Already claimed");

            bytes32 leaf = keccak256(abi.encodePacked(msg.sender)); 
            require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");
            w1[msg.sender] = true;
            _mintNFT(msg.sender);
        }
        
        if (_claimCase == 2) {
            require(!w2[msg.sender], "Already claimed");
            
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender)); 
            require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");
            w2[msg.sender] = true;
            _mintNFT(msg.sender);
        } 

        if (_claimCase == 3) {
            require(!w3[msg.sender], "Already claimed");
        
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender)); 
            require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");
            w3[msg.sender] = true;

            _mintNFT(msg.sender);
        }
    }

    function mint() external payable {
        require(publicMintingActive, "Minting is currently disabled!");

        require(msg.value >= mintingFee, "Insufficient ETH Sent");

        _mintNFT(msg.sender);
    }

    function _mintNFT(address recipient) private {

        require(_tokenIdCounter.current() < 20000, "The maximum limit for this series is set at 20,000.");
        
        uint256 newTokenId = _tokenIdCounter.current();
    
        _safeMint(recipient, newTokenId);

        _tokenIdCounter.increment();   
    }

    function viewCase() external view returns(uint256) {
        return _claimCase;
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    function setClaimCase(uint256 _newCase) external onlyOwner {
        _claimCase = _newCase;
    }

    function toggleMinting() external onlyOwner {
        publicMintingActive = !publicMintingActive;
    }

    function withdraw() external onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }

    function setMintingFee(uint256 _newFee) external onlyOwner {
        mintingFee = _newFee;
    }

    function contractURI() public view returns (string memory) {
        return _contractURIValue;
    }

    function setBaseURI(string memory _newBaseURIValue) public onlyOwner {
        _baseURIValue = _newBaseURIValue;
    }

    function setContractURI(string memory _newContractURIValue) public onlyOwner {
        _contractURIValue = _newContractURIValue;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "You are not the owner!");
        _;
    }
}