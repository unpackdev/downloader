//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "./console.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol"; // OZ: MerkleProof
import "./console.sol";

contract Main is ERC721Enumerable, Ownable {
    string private _baseURIPrefix;
    uint256 public TOTAL_SUPPLY = 3000;
    uint256 public PRESALE_LIMIT = 1350;
    uint256 public PRESALE_MVHQ_PRICE = 0.6 ether;
    uint256 public PRESALE_PRICE = 0.65 ether;
    uint256 public PUBLIC_SALE_PRICE = 0.85 ether;
    uint256 public MAX_MINT_PER_PRESALE = 1;
    address public FEE_RECIPIENT;
    bool public PRESALE_ACTIVE = false;
    bool public SALE_ACTIVE = false;
    uint256 public presaleMinted;
    uint256 public saleMinted;
    uint256 public devMinted;
    mapping(address => uint) public mintPerAddress;
    bytes32 public merkleRoot;
    bytes32 public merkleRoot_mvhq;
    constructor(bytes32 _merkleRoot, bytes32 _merkleRoot_mvhq) ERC721("Crypcentra.com", "CRYP") {
        FEE_RECIPIENT = msg.sender;
        merkleRoot = _merkleRoot;
        merkleRoot_mvhq = _merkleRoot_mvhq;
        _baseURIPrefix = "https://gateway.pinata.cloud/ipfs/QmTVwzADH71JrkWKQSUhi9yuAmy4yHeZsA5JMiDi5PiUrJ/";
    }
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }
    function setMVHQMerkleRoot(bytes32 _merkleRoot_mvhq) public onlyOwner {
        merkleRoot_mvhq = _merkleRoot_mvhq;
    }

    function setFeeRecipient(address to) public onlyOwner {
        FEE_RECIPIENT = to;
    }

    function setPresaleStatus(bool status) public onlyOwner {
        PRESALE_ACTIVE = status;
    }

    function setSaleStatus(bool status) public onlyOwner {
        SALE_ACTIVE = status;
    }

    function setPresaleMintLimit(uint limit) public onlyOwner {
        MAX_MINT_PER_PRESALE = limit;
    }

    function mintToDev(address mintAddress, uint amount) public onlyOwner {
        require(totalSupply() + amount <= TOTAL_SUPPLY, "Mint would exceed max supply of tokens");
        for (uint i = 0; i < amount; i++) {
            uint mintIndex = totalSupply();
            _safeMint(mintAddress, mintIndex);
            devMinted++;
        }
    }

    function mintPresaleMvhq(uint numberOfTokens, bytes32[] calldata proof) public payable {
        require(PRESALE_ACTIVE, "Pre-sale must be active to mint");
        require(presaleMinted + numberOfTokens <= PRESALE_LIMIT, "Purchase would exceed max supply of tokens");
        require(mintPerAddress[msg.sender] + numberOfTokens <= MAX_MINT_PER_PRESALE, "Requested amount over max presale mint limit");
        merkleProof_mvhq(msg.sender, proof);
        require(PRESALE_MVHQ_PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");
        for (uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (mintIndex < TOTAL_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
                presaleMinted++;
                mintPerAddress[msg.sender]++;
            }
        }
        internalSendFeeTo();
    }

    function mintPresale(uint numberOfTokens, bytes32[] calldata proof) public payable {
        require(PRESALE_ACTIVE, "Pre-sale must be active to mint");
        require(presaleMinted + numberOfTokens <= PRESALE_LIMIT, "Purchase would exceed max supply of tokens");
        require(mintPerAddress[msg.sender] + numberOfTokens <= MAX_MINT_PER_PRESALE, "Max presale mint limit reached");
        merkleProof(msg.sender, proof);
        require(PRESALE_PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");
        for (uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (mintIndex < TOTAL_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
                presaleMinted++;
                mintPerAddress[msg.sender]++;
            }
        }
        internalSendFeeTo();
    }

    function merkleProof_mvhq(address to, bytes32[] calldata proof) internal {
        bytes32 leaf = keccak256(abi.encodePacked(to));
        bool isValidLeaf = verify(merkleRoot_mvhq, leaf, proof);
        require(isValidLeaf, "not authorized");
    }
    function merkleProof(address to, bytes32[] calldata proof) internal {
        bytes32 leaf = keccak256(abi.encodePacked(to));
        bool isValidLeaf = verify(merkleRoot, leaf, proof);
        require(isValidLeaf, "not authorized");
    }

    function verify(bytes32 root, bytes32 leaf, bytes32[] memory proof) public pure returns (bool) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    function mintPublic(uint numberOfTokens) public payable {
        require(SALE_ACTIVE, "Sale must be active to mint");
        require(totalSupply() + numberOfTokens <= TOTAL_SUPPLY, "Purchase would exceed max supply of tokens");
        require(PUBLIC_SALE_PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");
        for (uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
            saleMinted++;
        }
        internalSendFeeTo();
    }

    function internalSendFeeTo() internal {
        (bool transferStatus,) = FEE_RECIPIENT.call{value : msg.value}("");
        require(transferStatus, "Failed to send to FEE_RECIPIENT");
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseURIPrefix = baseURI;
    }
}
