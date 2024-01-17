
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

pragma solidity ^0.8.14;

import "./Counters.sol";
import "./Ownable.sol";
import "./Base64.sol";
import "./ERC721.sol";
import "./MerkleProof.sol";

contract Kill3rKritt3rs is ERC721, Ownable {
    using Strings for uint;
    using Counters for Counters.Counter;
    enum SaleStatus{ PAUSED, PRESALE, PUBLIC }

    Counters.Counter private _tokenIds;

    uint public constant COLLECTION_SIZE = 9990;
    
    uint public constant TOKENS_PER_TRAN_LIMIT = 2;
    uint public constant TOKENS_PER_PERSON_PUB_LIMIT = 5;
    uint public constant TOKENS_PER_PERSON_WL_LIMIT = 5;
    uint public constant PRESALE_MINT_PRICE = 0.093 ether;
    uint public MINT_PRICE = 0.13 ether;
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    bytes32 public merkleRoot;
    string private _baseURL = "ipfs://Qmcu89CVUrz1dEZ8o32qnQnN4myurbAFr162w1qKLCKAA8";
    
    mapping(address => uint) private _mintedCount;
    mapping(address => uint) private _whitelistMintedCount;

    constructor() ERC721("Kill3rKritt3rs", "KK"){}
    
    
    function contractURI() public pure returns (string memory) {
        return "data:application/json;base64,eyJuYW1lIjoiS2lsbDNyIEtyaXR0M3JzIiwiZGVzY3JpcHRpb24iOiJHcmVldGluZ3MgZmVsbG93IGR1ZWxpc3QsIHdlbGNvbWUgdG8gdGhlIEtpbGwzciBLcml0dDNycywgYSBwbGFjZSB3aGVyZSB5b3VyIHRva2VuIGFjdHMgYXMgYSBkdWVsaW5nIGNhcmQgYW5kIGdhdGV3YXkgdG8gdGhlIGltbWVyc2l2ZSB3b3JsZCBvZiB0aGUgZXhxdWlzaXRlIE5GVCBjb2xsZWN0aW9uLCBhIHdvcmxkIHdoZXJlIHlvdSdsbCBiZWdpbiB5b3VyIGpvdXJuZXkgdG8gdGFtZSBhbmQgdHJhaW4gcG93ZXJmdWwgS3JpdHQzcnMhIiwiZXh0ZXJuYWxfdXJsIjoiaHR0cHM6Ly93d3cua2lsbDNya3JpdHQzcnMuY29tLyIsImZlZV9yZWNpcGllbnQiOiIweGQ3OWZiNzIxYjRhOGYxZDJiMzU5NTI0NzA4ZjBjNDdmNmYxNzhhOGEiLCJzZWxsZXJfZmVlX2Jhc2lzX3BvaW50cyI6MTAwMH0=";
    }
    
    /// @notice Update the merkle tree root
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }
    
    
    
    /// @notice Set base metadata URL
    function setBaseURL(string calldata url) external onlyOwner {
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

    /// @notice Withdraw contract balance
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No balance");
        
        payable(0xD79fB721B4a8F1d2B359524708F0c47F6F178a8A).transfer((balance * 8500)/10000);
        payable(0x0c2aE7294209fCE2cb92Ef469fF881Da0C625274).transfer((balance * 1500)/10000);
    }

    /// @notice Allows owner to mint tokens to a specified address
    function airdrop(address to, uint count) external onlyOwner {
        require(_tokenIds.current() + count <= COLLECTION_SIZE, "Request exceeds collection size");
        _mintTokens(to, count);
    }

    /// @notice Get token URI. In case of delayed reveal we give user the json of the placeholer metadata.
    /// @param tokenId token ID
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0 
            ? string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json")) 
            : "";
    }
    
    function calcTotal(uint count) public view returns(uint) {
        require(saleStatus != SaleStatus.PAUSED, "Kill3rKritt3rs: Sales are off");

        

        
        uint price = saleStatus == SaleStatus.PRESALE 
            ? PRESALE_MINT_PRICE 
            : MINT_PRICE;

        return count * price;
    }
    
    
    function redeem(bytes32[] calldata merkleProof, uint count) external payable {
        require(saleStatus != SaleStatus.PAUSED, "Kill3rKritt3rs: Sales are off");
        require(_tokenIds.current() + count <= COLLECTION_SIZE, "Kill3rKritt3rs: Number of requested tokens will exceed collection size");
        require(count <= TOKENS_PER_TRAN_LIMIT, "Kill3rKritt3rs: Number of requested tokens exceeds allowance (2)");
        require(msg.value >= calcTotal(count), "Kill3rKritt3rs: Ether value sent is not sufficient");
        if(saleStatus == SaleStatus.PRESALE) {
            require(_whitelistMintedCount[msg.sender] + count <= TOKENS_PER_PERSON_WL_LIMIT, "Kill3rKritt3rs: Number of requested tokens exceeds allowance (5)");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Kill3rKritt3rs: You are not whitelisted");
            _whitelistMintedCount[msg.sender] += count;
        }
        else {
            require(_mintedCount[msg.sender] + count <= TOKENS_PER_PERSON_PUB_LIMIT, "Kill3rKritt3rs: Number of requested tokens exceeds allowance (5)");
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
