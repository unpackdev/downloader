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

contract AdoptMeImUglyOfficial is ERC721A, Ownable {
    enum SaleStatus{ PAUSED, PRESALE, PUBLIC
    }

    uint public constant COLLECTION_SIZE = 9999;
    
    uint public constant TOKENS_PER_TRAN_LIMIT = 3;
    uint public constant TOKENS_PER_PERSON_PUB_LIMIT = 3;
    uint public constant TOKENS_PER_PERSON_WL_LIMIT = 3;
    uint public constant PRESALE_MINT_PRICE = 0 ether;
    uint public MINT_PRICE = 0.0059 ether;
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    bytes32 public merkleRoot;
    string private _baseURL = "ipfs://QmY95SndHHJ7WmqdKbqmah1Z4RRfnga9EPSNqHxN14oqhM";
    
    mapping(address => uint) private _mintedCount;
    mapping(address => uint) private _whitelistMintedCount;

    constructor() ERC721A("AdoptMeImUglyOfficial",
    "ADIU"){}
    
    
    function contractURI() public pure returns (string memory) {
        return "https://zerocodenft.azurewebsites.net/api/marketplacecollections/ddd6541a-a57e-4362-2f48-08da48e9b325";
    }
    /// @notice Update the merkle tree root
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }
    /// @notice Set base metadata URL
    function setBaseURL(string memory url) external onlyOwner {
        _baseURL = url;
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
    /// @notice Withdraw contract balance
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0,
        "No balance");
        
        payable(0x2a9A4d68F2752c69C6e2360827b147E2210064AD).transfer((balance * 10000)/10000);
    }
    /// @notice Allows owner to mint tokens to a specified address
    function airdrop(address to, uint count) external onlyOwner {
        require(_totalMinted() + count <= COLLECTION_SIZE,
        "Request exceeds collection size");
        _safeMint(to, count);
    }
    /// @notice Get token URI. In case of delayed reveal we give user the json of the placeholer metadata.
    /// @param tokenId token ID
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0 
            ? string(abi.encodePacked(baseURI,
        "/", _toString(tokenId),
        ".json")) 
            : "";
    }
    
    function calcTotal(uint count) public view returns(uint) {
        require(saleStatus != SaleStatus.PAUSED,
        "ZeroCodeNFT: Sales are off");

        

        
        uint price = saleStatus == SaleStatus.PRESALE 
            ? PRESALE_MINT_PRICE 
            : MINT_PRICE;

        return count * price;
    }
    
    
    function redeem(bytes32[] calldata merkleProof, uint count) external payable {
        require(saleStatus != SaleStatus.PAUSED,
        "ZeroCodeNFT: Sales are off");
        require(_totalMinted() + count <= COLLECTION_SIZE,
        "ZeroCodeNFT: Number of requested tokens will exceed collection size");
        require(count <= TOKENS_PER_TRAN_LIMIT,
        "ZeroCodeNFT: Number of requested tokens exceeds allowance (3)");
        require(msg.value >= calcTotal(count),
        "ZeroCodeNFT: Ether value sent is not sufficient");
        if(saleStatus == SaleStatus.PRESALE) {
            require(_whitelistMintedCount[msg.sender
            ] + count <= TOKENS_PER_PERSON_WL_LIMIT,
            "ZeroCodeNFT: Number of requested tokens exceeds allowance (3)");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "ZeroCodeNFT: You are not whitelisted");
            _whitelistMintedCount[msg.sender
            ] += count;
        }
        else {
            require(_mintedCount[msg.sender
            ] + count <= TOKENS_PER_PERSON_PUB_LIMIT,
            "ZeroCodeNFT: Number of requested tokens exceeds allowance (3)");
            _mintedCount[msg.sender
            ] += count;
        }
        _safeMint(msg.sender, count);
    }
}