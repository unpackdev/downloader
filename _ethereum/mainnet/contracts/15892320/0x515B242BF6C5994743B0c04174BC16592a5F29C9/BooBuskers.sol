
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


contract BooBuskers is ERC721, Ownable {
    using Strings for uint;
    using Counters for Counters.Counter;
    enum SaleStatus{ PAUSED, PRESALE, PUBLIC }

    Counters.Counter private _tokenIds;

    uint public constant COLLECTION_SIZE = 10000;
    
    uint public constant TOKENS_PER_TRAN_LIMIT = 10;
    uint public constant TOKENS_PER_PERSON_PUB_LIMIT = 10;
    
    
    uint public MINT_PRICE = 0.05 ether;
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    
    string private _baseURL = "ipfs://bafybeihbxq5ls5sip37m6cfexwod7t3ijdbdicnhtm6qgi4dns7734g2mm";
    
    mapping(address => uint) private _mintedCount;
    

    constructor() ERC721("BooBuskers", "BBs"){}
    
    
    function contractURI() public pure returns (string memory) {
        return "data:application/json;base64,eyJuYW1lIjoiQm9vIEJ1c2tlcnMiLCJkZXNjcmlwdGlvbiI6IkZyaWVuZGx5ICYgRW50ZXJ0YWluaW5nIEJ1c2tpbmcgR2hvc3RzIEZyb20gQm9vIFBsYW5ldCIsImV4dGVybmFsX3VybCI6Imh0dHBzOi8vd3d3LmJvb2J1c2tlcnMuaW8iLCJmZWVfcmVjaXBpZW50IjoiMHgyZDcyMTU3MjA1OTQxMGUzQ2VEMzQwMDBkQUIxQjc5Mzk2NTExOTkyIiwic2VsbGVyX2ZlZV9iYXNpc19wb2ludHMiOjc1MH0=";
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
        payable(owner()).transfer(balance);
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
        require(saleStatus != SaleStatus.PAUSED, "BooBuskers: Sales are off");

        

        
        uint price = MINT_PRICE;

        return count * price;
    }
    
    
    
    /// @notice Mints specified amount of tokens
    /// @param count How many tokens to mint
    function mint(uint count) external payable {
        require(saleStatus != SaleStatus.PAUSED, "BooBuskers: Sales are off");
        require(_tokenIds.current() + count <= COLLECTION_SIZE, "BooBuskers: Number of requested tokens will exceed collection size");
        require(count <= TOKENS_PER_TRAN_LIMIT, "BooBuskers: Number of requested tokens exceeds allowance (10)");
        require(_mintedCount[msg.sender] + count <= TOKENS_PER_PERSON_PUB_LIMIT, "BooBuskers: Number of requested tokens exceeds allowance (10)");
        require(msg.value >= calcTotal(count), "BooBuskers: Ether value sent is not sufficient");
        _mintedCount[msg.sender] += count;
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
