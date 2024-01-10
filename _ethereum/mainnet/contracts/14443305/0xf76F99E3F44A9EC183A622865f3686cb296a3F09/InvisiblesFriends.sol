// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./Ownable.sol";
import "./ERC721A.sol";

contract InvisiblesFriends is Ownable, ERC721A {
    using Strings for uint256;

    string public _uri = "https://invisiblefriends.io/api/";
    address immutable wallet1;
    address immutable wallet2;
    uint256 public maxSupply = 20000;
    uint256 public minted;

    bool mintOpen = true;
    uint256 public minPrice = 0.1 ether;

    constructor() ERC721A("INVISIBLES FRIENDS", "IF") Ownable() {
        wallet1 = 0xC0106Fc59336D532222977625F2D85f1cb74A1D7;
        wallet2 = 0x9d3aa0Bb006A8b0cF93cdf025c84caC0470e20a4;
        _safeMint(wallet2, 1);
    }

    function mint(uint256 amount) external payable {
        require(mintOpen);
        require(minted + amount <= maxSupply);
        require(msg.value >= minPrice * amount);

        minted += amount;
        _safeMint(msg.sender, amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        uint256 id = tokenId % 5001;
        return super.tokenURI(id == 0 ? 5000 : id);
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        _uri = _newBaseURI;
    }

    function setMintOpen(bool open) external onlyOwner {
        mintOpen = open;
    }

    function setMinPrice(uint256 newPrice) external onlyOwner {
        minPrice = newPrice;
    }

    function withdraw() external onlyOwner {    
        uint256 balance = address(this).balance;
        uint256 toWallet1 = balance * 5 / 100;
        uint256 toWallet2 = balance - toWallet1;
        payable(wallet1).transfer(toWallet1);
        payable(wallet2).transfer(toWallet2);
    }
}