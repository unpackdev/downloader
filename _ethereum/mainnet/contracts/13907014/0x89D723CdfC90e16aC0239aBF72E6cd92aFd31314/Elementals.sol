//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721PEnum.sol";
import "./PaymentSplitter.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Elementals is ERC721PEnum, Ownable, PaymentSplitter {
    using Strings for uint256;
    // public urls
    string public baseURI;
    string public provenance;
    // sale info
    uint256 public ogPrice = 0.03 ether;
    uint256 public price = 0.05 ether;
    uint256 public mintLimit = 11;
    uint256 public maxSupply;
    bool public saleOn = false;

    // early adopters get rewarded
    mapping(address => bool) public ogElementals;
    // team
    address[] team = [
        0x1AF8c7140cD8AfCD6e756bf9c68320905C355658,
        0x55953d49052050a4300Cb94207c4695Fdb865915,
        0x23a1b5EA9e7DB3172B5AdC54fCDea187f5C2AFF3
    ];
    uint256[] teamShares = [62, 33, 5];

    constructor(uint256 supply, string memory baseUrl, address systemAccount)
        ERC721P("Elementals", "ELEMENT", systemAccount) 
        PaymentSplitter(team, teamShares) {
        maxSupply = supply;
        baseURI = baseUrl;
    }

    function mint(uint256 total) public payable {
        uint256 supply = totalSupply();
        uint256 mintPrice = ogElementals[msg.sender] ? ogPrice : price;
        require(saleOn, "Sale Off");
        require(total < mintLimit, "10 Max");
        require(msg.value >= mintPrice * total, "Incorrect ETH");
        require(supply + total <= maxSupply, "Exceeds Max Supply");
        for (uint256 i = 0; i < total; ++i) {
            _safeMint(msg.sender, supply + i, "");
        }
        delete supply;
        delete mintPrice;
    }

    function giveaway(address to, uint256 total) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + total <= maxSupply, "Exceeds Max Supply");
        for (uint256 i; i < total; i++) {
            _safeMint(to, supply + i, "");
        }
        delete supply;
    }

    function flipSale() public onlyOwner {
        saleOn = !saleOn;
    }

    function deposit() external payable {}

    function withdraw() external payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    function setBaseUrl(string memory baseUri) public onlyOwner {
        baseURI = baseUri;
    }

    function setProvenance(string memory prov) public onlyOwner {
        provenance = prov;
    }

    function setPrices(uint256 newOgPrice, uint256 newPrice) public onlyOwner {
        ogPrice = newOgPrice;
        price = newPrice;
    }

    function crownOGs(address[] calldata addresses) external onlyOwner {
        for (uint256 i; i < addresses.length; i++) {
            ogElementals[addresses[i]] = true;
        }
    }

    function tokenURIsOfOwner(address owner) public view returns (string[] memory) {
        uint256[] memory tokenIds = tokensOfOwner(owner);
        string[] memory tokenURIs = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenURIs[i] = tokenURI(tokenIds[i]);
        }
        return tokenURIs;
    }
}
