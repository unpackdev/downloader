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


contract Goblinbokitown is ERC721, Ownable {
    using Strings for uint;
    using Counters for Counters.Counter;
    enum SaleStatus{ PAUSED, PRESALE, PUBLIC
    }

    Counters.Counter private _tokenIds;

    uint public constant COLLECTION_SIZE = 4000;
    uint public constant FIRSTXFREE = 2;
    uint public constant TOKENS_PER_TRAN_LIMIT = 12;
    uint public constant TOKENS_PER_PERSON_PUB_LIMIT = 25;
    
    
    uint public MINT_PRICE = 0.005 ether;
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    
    string private _baseURL = "ipfs://QmNzmfY85WGj8PAniuo7zEnsHVTP4eVsTe1XzsaHCrni3u";
    
    mapping(address => uint) private _mintedCount;
    

    constructor() ERC721("Goblinbokitown",
    "GBT"){}
    
    
    function contractURI() public pure returns (string memory) {
        return "https://zerocodenft.azurewebsites.net/api/marketplacecollections/beb81001-ea32-4452-3d45-08da4822632f";
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
    /// @notice Withdraw contract balance
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
    /// @notice Get token URI. In case of delayed reveal we give user the json of the placeholer metadata.
    /// @param tokenId token ID
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0 
            ? string(abi.encodePacked(baseURI,
        "/", tokenId.toString(),
        ".json")) 
            : "";
    }
    
    function calcTotal(uint count, uint price) public view returns(uint) {
        
        if(FIRSTXFREE > _mintedCount[msg.sender
        ]) {
            uint freeLeft = FIRSTXFREE - _mintedCount[msg.sender
            ];
            if(count > freeLeft) {
                // just pay the difference
                count -= freeLeft;
            }
            else {
                count = 0;
            }
        }

        return count * price;
    }
    /// @notice Mints specified amount of tokens
    /// @param count How many tokens to mint
    function mint(uint count) external payable {
        require(saleStatus != SaleStatus.PAUSED,
        "ZeroCodeNFT: Sales are off");
        require(_tokenIds.current() + count <= COLLECTION_SIZE,
        "ZeroCodeNFT: Number of requested tokens will exceed collection size");
        require(count <= TOKENS_PER_TRAN_LIMIT,
        "ZeroCodeNFT: Number of requested tokens exceeds allowance (12)");
        require(_mintedCount[msg.sender
        ] + count <= TOKENS_PER_PERSON_PUB_LIMIT,
        "ZeroCodeNFT: Number of requested tokens exceeds allowance (25)");
        require(msg.value >= calcTotal(count, MINT_PRICE),
        "ZeroCodeNFT: Ether value sent is not sufficient");
        _mintedCount[msg.sender
        ] += count;
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