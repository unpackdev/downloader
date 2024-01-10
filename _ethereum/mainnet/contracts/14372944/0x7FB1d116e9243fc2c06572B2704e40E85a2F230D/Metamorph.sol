// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IERC2981.sol";

contract Metamorph is ERC721A, IERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public mintPrice = 0.03 ether;
    uint256 public balanceLimit = 10;
    uint256 public mintLimit = 3300;
    uint256 public freeBalanceLimit = 3;
    uint256 public freeMintLimit = 300;
    uint256 public collabMintLimit = 30;

    string private baseURI = "ipfs://QmcjB4JTWRFwpJmJZ3bA6CF5GmLmEbGLM6SiEHUSixxwgh/";
    string private contractMetadataURI = "https://metamorph.ink/contract-meta/contract-metadata.json";

    constructor() ERC721A("Metamorph", "Metamorph") {}

    receive() external payable {}

    function mint(uint256 quantity) external payable {
        if (_totalMinted() + quantity <= freeMintLimit) {
            require(balanceOf(msg.sender) + quantity <= freeBalanceLimit, "error: free balance limit reached");
        } else {
            require(msg.value >= mintPrice * quantity, "error: invalid tx value");
            require(balanceOf(msg.sender) + quantity <= balanceLimit, "error: balance limit reached");
            require(_totalMinted() + quantity <= mintLimit, "error: mint limit reached");
        }

        _safeMint(msg.sender, quantity);
    }

    function collabMint(address receiver, uint256 quantity) public onlyOwner {
        require(_totalMinted() + quantity <= mintLimit + collabMintLimit);
        _safeMint(receiver, quantity);
    }

    function withdraw() public onlyOwner nonReentrant {
        // 0x165CD37b4C644C2921454429E7F9358d18A45e14 === Ukraine
        (bool donation, ) = payable(0x165CD37b4C644C2921454429E7F9358d18A45e14).call{value: SafeMath.div(SafeMath.mul(address(this).balance, 25), 100)}("");
        require(donation);

        (bool withdrawal, ) = payable(owner()).call{value: address(this).balance}("");
        require(withdrawal);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "error: nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setContractURI(string memory _uri) external onlyOwner {
        contractMetadataURI = _uri;
    }

    function contractURI() public view returns (string memory) {
        return contractMetadataURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "Nonexistent token");

        return (address(this), SafeMath.div(SafeMath.mul(salePrice, 5), 100));
    }
}