// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
import "./Ownable.sol";
import "./ERC721A.sol";

contract InvisiblesFriends is Ownable, ERC721A {
    using Strings for uint256;

    string public _uri = "https://invisiblefriends.io/api/";
    address immutable wallet1;
    address immutable wallet2;
    uint256 public maxSupply = 20000;
    uint256 public minted;

    bool mint1Open = true;
    bool mint2Open = true;
    bool mint25Open = true;
    bool mint3Open = true;
    bool mint4Open = true;
    bool mint5Open = true;

    constructor() ERC721A("TIFSO", "ISF") Ownable() {
        wallet1 = 0xac950385bA97427d508773906612B8c91AaEc6f4;
        wallet2 = 0xaa7217a665cdE7E18aCbfF3625495264434324CC;
        _safeMint(wallet2, 1);
    }

    function mint1(uint256 amount) external payable {
        require(mint1Open);
        require(minted + amount <= maxSupply);
        require(msg.value >= 0.1 ether * amount);

        minted += amount;
        _safeMint(msg.sender, amount);
    }

    function mint2(uint256 amount) external payable {
        require(mint2Open);
        require(minted + amount <= maxSupply);
        require(msg.value >= 0.2 ether * amount);

        minted += amount;
        _safeMint(msg.sender, amount);
    }

    function mint25(uint256 amount) external payable {
        require(mint25Open);
        require(minted + amount <= maxSupply);
        require(msg.value >= 0.25 ether * amount);

        minted += amount;
        _safeMint(msg.sender, amount);
    }

    function mint3(uint256 amount) external payable {
        require(mint3Open);
        require(minted + amount <= maxSupply);
        require(msg.value >= 0.3 ether * amount);

        minted += amount;
        _safeMint(msg.sender, amount);
    }

    function mint4(uint256 amount) external payable {
        require(mint4Open);
        require(minted + amount <= maxSupply);
        require(msg.value >= 0.4 ether * amount);

        minted += amount;
        _safeMint(msg.sender, amount);
    }

    function mint5(uint256 amount) external payable {
        require(mint5Open);
        require(minted + amount <= maxSupply);
        require(msg.value >= 0.5 ether * amount);

        minted += amount;
        _safeMint(msg.sender, amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return super.tokenURI((tokenId % 5000) + 1);
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        _uri = _newBaseURI;
    }

    function setMint1Open(bool open) external onlyOwner {
        mint1Open = open;
    }

    function setMint2Open(bool open) external onlyOwner {
        mint2Open = open;
    }

    function setMint25Open(bool open) external onlyOwner {
        mint25Open = open;
    }

    function setMint3Open(bool open) external onlyOwner {
        mint3Open = open;
    }

    function setMint4Open(bool open) external onlyOwner {
        mint4Open = open;
    }

    function setMint5Open(bool open) external onlyOwner {
        mint5Open = open;
    }

    function withdraw() external onlyOwner {    
        uint256 balance = address(this).balance;
        uint256 toWallet1 = balance * 5 / 100;
        uint256 toWallet2 = balance - toWallet1;
        payable(wallet1).transfer(toWallet1);
        payable(wallet2).transfer(toWallet2);
    }
}