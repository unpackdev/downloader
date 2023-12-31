// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./ERC721.sol";
import "./Ownable.sol";

contract NFT is ERC721, Ownable {
    using Strings for uint256;
    uint public constant MAX_TOKENS = 520;                   // 520 NFT
    uint private constant TOKENS_RESERVED = 52;  
    uint public price = 10000000000000000;                  // Default 0.01 ETH
    uint256 public constant MAX_MINT_PER_TX = 1;

    bool public isSaleActive;         
    uint256 public totalSupply;
    mapping(address => uint256) private mintedPerWallet;    // Map buyer to NFT amt

    string public baseUri;
    string public baseExtension = ".json";

    constructor() ERC721("APA POKER", "Asia Poker Academy") {
        /* * Need Json File ipfs : TACKLED* */
        baseUri = "ipfs://QmTjAWZyHRSFE8odjHf9i4ic8jgy4w9eavzfDRa6bA1zcR/";
        for(uint256 i = 1; i <= TOKENS_RESERVED; ++i) {
            _safeMint(msg.sender, i);
        }
        totalSupply = TOKENS_RESERVED;
    }
    // Public Functions ( Only 1 NFT is minted every transaction )
    function mint() external payable {
        require(isSaleActive, "The sale is paused.");
        uint256 curTotalSupply = totalSupply;
        require(curTotalSupply < MAX_TOKENS, "Exceeds total supply.");
        require( msg.value >= price, "Insufficient funds.");
        _safeMint(msg.sender, curTotalSupply + 1);
        mintedPerWallet[msg.sender]++;
        totalSupply++;
    }

    // Owner-only functions
    function flipSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }
    function withdrawAll() external payable onlyOwner {
        uint256 balance = address(this).balance;
        /* * Need Ethernet Metamask Address : TACKLED * */
        ( bool transfer, ) = payable(0x9872B939Ec2B2CD846FF104b7f8310f8E08468f4).call{value: balance}("");
        require(transfer, "Transfer failed.");
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();

        uint files_in_set = 52;
        uint set_no = ((tokenId - 1) / files_in_set)+1; // Subtract 1 to adjust for 0-based indexing
        uint token_in_set = ((tokenId - 1) % files_in_set) + 1; // Subtract 1 to adjust for 0-based indexing

        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(set_no), "/", Strings.toString(token_in_set), baseExtension))
            : "";
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }
}


