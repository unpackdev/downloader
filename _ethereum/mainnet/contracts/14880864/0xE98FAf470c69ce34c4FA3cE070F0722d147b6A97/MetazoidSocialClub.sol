
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./MerkleProof.sol";

contract MetazoidSocialClub is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint;
    enum SaleStatus{ PAUSED, PRESALE, PUBLIC }

    Counters.Counter private _tokenIds;

    uint public constant COLLECTION_SIZE = 10000;
    uint public constant TOKENS_PER_TRAN_LIMIT = 20;
    uint public constant TOKENS_PER_PERSON_PUB_LIMIT = 20;
    uint public constant TOKENS_PER_PERSON_WL_LIMIT = 1;
    uint public constant PRESALE_MINT_PRICE = 0.065 ether;
    uint public MINT_PRICE = 0.065 ether;
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    string private _baseURL;
    bytes32 public merkleRoot;
    string public constant provenanceHash = "25e6c6b79152ef9578bcb7dd79ffd14a2b589718e00ee466557655d694690255";
    mapping(address => uint) private _mintedCount;
    mapping(address => uint) private _whitelistMintedCount;

    constructor(string memory baseURL, uint count) 
    ERC721("MetazoidSocialClub", "MSC"){
        _baseURL = baseURL;
        _mintTokens(msg.sender, count);
    }
    
    /// @notice Update the merkle tree root
    function setMerkleRoot(bytes32 root) onlyOwner external {
        merkleRoot = root;
    }

    function contractURI() public pure returns (string memory) {
		return "ipfs://QmUtk4bC2Gq2Wpzfhzp1rTrZigPdHDmcGditQ65fWQDje2";
	}

    function totalSupply() external view returns (uint) {
        return _tokenIds.current();
    }

    /// @dev override base uri. It will be combined with token ID
    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    /// @notice Update current sale status
    function setSaleStatus(SaleStatus status) external onlyOwner {
        saleStatus = status;
    }

    /// @notice Update public mint price
    function setPublicMintPrice(uint price) external onlyOwner {
        MINT_PRICE = price;
    }

    /// @notice Withdraw contract's balance
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "MSC: No balance");
        
        payable(owner()).transfer(balance);
    }

    /// @notice Allows owner to mint tokens to a specified address
    function airdrop(address to, uint count) external onlyOwner {
        require(_tokenIds.current() + count <= COLLECTION_SIZE, "MSC: Request exceeds collection size");
        _mintTokens(to, count);
    }

    /// @notice Get token's URI.
    /// @param tokenId token ID
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }
    
    function redeem(bytes32[] calldata merkleProof, uint count) external payable {
        require(saleStatus != SaleStatus.PAUSED, "MSC: Sales are off");
        require(_tokenIds.current() + count <= COLLECTION_SIZE, "MSC: Number of requested tokens will exceed collection size");
        require(count <= TOKENS_PER_TRAN_LIMIT, "MSC: Requested token count exceeds allowance (20)");
        if(saleStatus == SaleStatus.PRESALE) {
            require(msg.value >= count * PRESALE_MINT_PRICE, "MSC: Ether value sent is not sufficient");
            require(_whitelistMintedCount[msg.sender] + count <= TOKENS_PER_PERSON_WL_LIMIT, "MSC: Requested token count exceeds allowance (1)");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "MSC: You are not whitelisted");

            if(_whitelistMintedCount[msg.sender] == 0) {
                count += 1; // mint 1 free
            }
            _whitelistMintedCount[msg.sender] += count;
        }
        else {
            require(msg.value >= count * MINT_PRICE, "MSC: Ether value sent is not sufficient");
            require(_mintedCount[msg.sender] + count <= TOKENS_PER_PERSON_PUB_LIMIT, "MSC: Requested token count exceeds allowance (20)");
            _mintedCount[msg.sender] += count;
        }
        _mintTokens(msg.sender, count);
    }

    /// @dev Perform actual minting of the tokens
    function _mintTokens(address to, uint count) internal {
        for(uint index = 0; index < count; index++) {

            _tokenIds.increment();
            uint newItemId = _tokenIds.current();

            _safeMint(to, newItemId);
        }
    }

}