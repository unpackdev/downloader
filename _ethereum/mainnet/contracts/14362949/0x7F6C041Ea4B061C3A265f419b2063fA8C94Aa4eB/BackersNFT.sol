import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
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
}

// File: contracts/BackersNFT.sol


pragma solidity ^0.8.0;

pragma experimental ABIEncoderV2;



/**
 * @title BackersNFT contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract BackersNFT is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    string public BACKERS_PROVENANCE = "";

    string public BASE_URI;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    uint256 public constant price = 1000000000000000; // 0.001 ETH

    uint public maxNftPurchase = 5;

    uint public royalty = 100000000000000;

    uint256 public MAX_NFTS;

    bool public saleIsActive = false;

    uint256 public REVEAL_TIMESTAMP;

    address public beneficiary;

    bool public whitelistActive = true;

    bytes32 public merkleRoot;

    // mapping (address => uint256) public pricing;
    mapping (address => uint256) public purchased;

    mapping(bytes4 => bool) private _supportedInterfaces;

    

    // ERC721 = 0x80ac58cd;
    //ERC721 METADATA = 0x5b5e139f
    // ERC721 ENUMERABLE = 0x780e9d63
    // royaltyInfo = 0x2a55205a
    // ERC165 = 0x01ffc9a7
    constructor(string memory name, string memory symbol, uint256 maxNftSupply, uint256 saleStart) ERC721(name, symbol) {
        MAX_NFTS = maxNftSupply;
        REVEAL_TIMESTAMP = saleStart + (86400 * 9);
        _registerInterface(0x2a55205a);
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override returns(bool) {
        return super.supportsInterface(interfaceId)  || _supportedInterfaces[interfaceId];
    }
    
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        royaltyAmount = royalty.mul(_salePrice).div(1000000000000000);
        receiver = owner();
        return (receiver, royaltyAmount);

    }

    function setRoyaltyInfo(uint256 _royaltyPercent) public onlyOwner {
        royalty = _royaltyPercent;
    }

    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        address payable reciever = payable(beneficiary);
        reciever.transfer(balance);
    }

    /**
     * Set some NFTs aside
     */
    function reserveNFTs() public onlyOwner {        
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < 30; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function setMaxNftPurchase(uint256 _max) public onlyOwner {
        maxNftPurchase = _max;
    }

    // function whitelist(address _whitelistedAddress, uint256 nft_price) public onlyOwner {
    //     pricing[_whitelistedAddress] = nft_price;
    // }

    // function batchWhitelist(address[9] memory whitelisters, uint[9] memory prices) public onlyOwner {
    //     uint i = 0;
    //     while(i<9) {
    //         pricing[whitelisters[i]] = prices[i];
    //         i++;
    //     }
    // }

    function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner {
        REVEAL_TIMESTAMP = revealTimeStamp;
    } 

    /*     
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        BACKERS_PROVENANCE = provenanceHash;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        BASE_URI = baseURI;
        //_setBaseURI(baseURI);
    }

    function flipWhitelist() public onlyOwner {
        whitelistActive = !whitelistActive;
    }
    /*
    * Pause sale if active, make active if paused
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }
    /**
    * Mints NFTs
    */
    function mintNFT(uint numberOfTokens, uint256 index, uint256 _price, bytes32[] calldata merkleProof) public payable {
        require(saleIsActive, "Sale must be active to mint NFT");
        require(purchased[msg.sender].add(numberOfTokens) <= maxNftPurchase, "NFT Purchase Over Limit");
        require(totalSupply().add(numberOfTokens) <= MAX_NFTS, "Purchase would exceed max supply of NFTs");
        if (whitelistActive) {
            
            bytes32 node = keccak256(abi.encodePacked(index, msg.sender, _price));
            require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');


            // require(pricing[msg.sender] != 0, "Address is not whitelisted");
            // require(pricing[msg.sender].mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
            require(_price.mul(numberOfTokens) <= msg.value, "Ether Value sent is not correct");
        } else {
            require(price.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        }
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_NFTS) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        purchased[msg.sender] = purchased[msg.sender].add(numberOfTokens);

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (totalSupply() == MAX_NFTS || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        } 
    }

    /**
     * Set the starting index for the collection
     */
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_NFTS;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_NFTS;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }
}
