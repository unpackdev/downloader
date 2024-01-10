/*
 /$$$$$$$$                                /$$$$$$                  /$$           /$$   /$$ /$$$$$$$$ /$$$$$$$$
|_____ $$                                /$$__  $$                | $$          | $$$ | $$| $$_____/|__  $$__/
     /$$/   /$$$$$$   /$$$$$$   /$$$$$$ | $$  \__/  /$$$$$$   /$$$$$$$  /$$$$$$ | $$$$| $$| $$         | $$
    /$$/   /$$__  $$ /$$__  $$ /$$__  $$| $$       /$$__  $$ /$$__  $$ /$$__  $$| $$ $$ $$| $$$$$      | $$
   /$$/   | $$$$$$$$| $$  \__/| $$  \ $$| $$      | $$  \ $$| $$  | $$| $$$$$$$$| $$  $$$$| $$__/      | $$
  /$$/    | $$_____/| $$      | $$  | $$| $$    $$| $$  | $$| $$  | $$| $$_____/| $$\  $$$| $$         | $$
 /$$$$$$$$|  $$$$$$$| $$      |  $$$$$$/|  $$$$$$/|  $$$$$$/|  $$$$$$$|  $$$$$$$| $$ \  $$| $$         | $$
|________/ \_______/|__/       \______/  \______/  \______/  \_______/ \_______/|__/  \__/|__/         |__/

Drop Your NFT Collection With ZERO Coding Skills at https://zerocodenft.com
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";

contract BagBoysxHappyBoysArcade is ERC721A, Ownable {
    using Strings for uint;
    enum SaleStatus{ PAUSED, PRESALE, PUBLIC
    }

    uint public constant COLLECTION_SIZE = 2222;
    uint public constant TOKENS_PER_TRAN_LIMIT = 5;
    uint public constant TOKENS_PER_PERSON_PUB_LIMIT = 20;
    uint public constant TOKENS_PER_PERSON_WL_LIMIT = 5;
    uint public constant PRESALE_MINT_PRICE = 0.03 ether;
    uint public MINT_PRICE = 0.05 ether;
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    bool public canReveal = false;
    bytes32 public merkleRoot;
    string private _baseURL;
    string private _hiddenURI = "ipfs://QmaT3mRmRQ3UzQT8GkYKaRRA4EsndNdmsM6YVjaK5CxTby";
    mapping(address => uint) private _mintedCount;
    mapping(address => uint) private _whitelistMintedCount;

    constructor() ERC721A("BagBoysxHappyBoysArcade",
    "bagboysHBA"){}
    
    
    function contractURI() public pure returns (string memory) {
        return "https://zerocodenft.azurewebsites.net/api/marketplacecollections/c36bb08b-3f32-4c92-546f-08da1380b949";
    }
    /// @notice Update the merkle tree root
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }
    /// @notice Reveal metadata for all the tokens
    function reveal(string memory uri) external onlyOwner {
        canReveal = true;
        _baseURL = uri;
    }
    /// @notice Set placeholder URI
    function setPlaceholderUri(string memory uri) external onlyOwner {
        _hiddenURI = uri;
    }
    /// @dev override base uri. It will be combined with token ID
    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
    /// @notice Update current sale stage
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
        require(balance > 0,
        "No balance");
        
        payable(owner()).transfer(balance);
    }
    /// @notice Allows owner to mint tokens to a specified address
    function airdrop(address to, uint count) external onlyOwner {
        require(_currentIndex + count <= COLLECTION_SIZE,
        "Request exceeds collection size");
        _safeMint(to, count);
    }
    /// @notice Get token's URI. In case of delayed reveal we give user the json of the placeholer metadata.
    /// @param tokenId token ID
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token");
        
        if(!canReveal) {
            return _hiddenURI;
        }
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),
        ".json")) : "";
    }
    
    function redeem(bytes32[] calldata merkleProof, uint count) external payable {
        require(saleStatus != SaleStatus.PAUSED,
        "Sales are off");
        require(_totalMinted() + count <= COLLECTION_SIZE,
        "Number of requested tokens will exceed collection size");
        require(count <= TOKENS_PER_TRAN_LIMIT,
        "Requested token count exceeds allowance (5)");
        uint totalCount;
        if(saleStatus == SaleStatus.PRESALE) {
            require(msg.value >= count * PRESALE_MINT_PRICE,
            "Ether value sent is not sufficient");
            require(_whitelistMintedCount[msg.sender
            ] + count <= TOKENS_PER_PERSON_WL_LIMIT,
            "Requested token count exceeds allowance (5)");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "You are not whitelisted");
            totalCount = count + count * 3; // 3 free as gift for rach
            uint grandTotal = _totalMinted() + totalCount;
            if(grandTotal > COLLECTION_SIZE) {
                uint overflow = grandTotal - COLLECTION_SIZE;
                totalCount -= overflow;
            }
            _whitelistMintedCount[msg.sender
            ] += count;
        }
        else {
            require(msg.value >= count * MINT_PRICE,
            "Ether value sent is not sufficient");
            require(_mintedCount[msg.sender
            ] + count <= TOKENS_PER_PERSON_PUB_LIMIT,
            "Requested token count exceeds allowance (20)");
            totalCount = count + count; // 1 free as gift for rach
            uint grandTotal = _totalMinted() + totalCount;
            if(grandTotal > COLLECTION_SIZE) {
                uint overflow = grandTotal - COLLECTION_SIZE;
                totalCount -= overflow;
            }
            _mintedCount[msg.sender
            ] += count;
        }
        _safeMint(msg.sender, totalCount);
    }
}