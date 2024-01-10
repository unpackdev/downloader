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

import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./MerkleProof.sol";

contract TroubledTigers is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint;
    enum SaleStatus{ PAUSED, PRESALE, PUBLIC
    }

    Counters.Counter private _tokenIds;

    uint public constant COLLECTION_SIZE = 8888;
    uint public constant TOKENS_PER_TRAN_LIMIT = 8888;
    uint public constant TOKENS_PER_PERSON_PUB_LIMIT = 8888;
    uint public constant TOKENS_PER_PERSON_WL_LIMIT = 1;
    uint public constant PRESALE_MINT_PRICE = 0.39 ether;
    uint public MINT_PRICE = 0.59 ether;
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    
    bytes32 public merkleRoot;
    string private _baseURL = "ipfs://QmW3CwQdKhJAAYysPMgep3JDb2ndg3vz9hGCGNSbHg73DA/";
    
    mapping(address => uint) private _mintedCount;
    mapping(address => uint) private _whitelistMintedCount;

    constructor() ERC721("TroubledTigers",
    "TGR"){}
    
    
    function contractURI() public pure returns (string memory) {
        return "https://zerocodenft.azurewebsites.net/api/marketplacecollections/600e06ab-6acd-4698-c492-08da0f1cb18d";
    }
    /// @notice Update the merkle tree root
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }
    /// @notice Set base metadata URL
    function setBaseURL(string memory url) external onlyOwner {
        _baseURL = url;
    }


    function totalSupply() external view returns (uint) {
        return _tokenIds.current();
    }
    /// @dev override base uri. It will be combined with token ID
    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
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
        require(_tokenIds.current() + count <= COLLECTION_SIZE,
        "Request exceeds collection size");
        _mintTokens(to, count);
    }
    /// @notice Get token's URI. In case of delayed reveal we give user the json of the placeholer metadata.
    /// @param tokenId token ID
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token");
        
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),
        ".json")) : "";
    }
    
    function redeem(bytes32[] calldata merkleProof, uint count) external payable {
        require(saleStatus != SaleStatus.PAUSED,
        "Sales are off");
        require(_tokenIds.current() + count <= COLLECTION_SIZE,
        "Number of requested tokens will exceed collection size");
        require(count <= TOKENS_PER_TRAN_LIMIT,
        "Requested token count exceeds allowance (8888)");
        if(saleStatus == SaleStatus.PRESALE) {
            require(msg.value >= count * PRESALE_MINT_PRICE,
            "Ether value sent is not sufficient");
            require(_whitelistMintedCount[msg.sender
            ] + count <= TOKENS_PER_PERSON_WL_LIMIT,
            "Requested token count exceeds allowance (1)");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "You are not whitelisted");
            _whitelistMintedCount[msg.sender
            ] += count;
        }
        else {
            require(msg.value >= count * MINT_PRICE,
            "Ether value sent is not sufficient");
            require(_mintedCount[msg.sender
            ] + count <= TOKENS_PER_PERSON_PUB_LIMIT,
            "Requested token count exceeds allowance (8888)");
            _mintedCount[msg.sender
            ] += count;
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