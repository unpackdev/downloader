// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./Ownable.sol";
import "./ERC721A.sol";

contract MutantApesPlanet is Ownable, ERC721A {
    using Strings for uint256;

    string public _uri = "ipfs://QmfCf5QWU1n6ECDkUmBjuSdhypU7xUnqBU2b3fTNuN9tag/";
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

    constructor() ERC721A("Mutant Apes Planet", "MAP") Ownable() {
        wallet1 = 0xDFb11c091BeD62cfaa133B0AA2c004D67891FBc7;
        wallet2 = 0x3a29794FE68cC80d1af57a7e72442F1FA72f1A21;
        _safeMint(wallet2, 1);
    }

    function mintOwner(uint256 amount) external onlyOwner {
        require(mint1Open);
        require(minted + amount <= maxSupply);

        minted += amount;
        _safeMint(msg.sender, amount);
    }
    
    function mintForOne(uint256 amount) external payable {
        require(mint1Open);
        require(minted + amount <= maxSupply);
        require(msg.value >= 0.1 ether * amount);

        minted += amount;
        _safeMint(msg.sender, amount);
    }

    function mintForTwo(uint256 amount) external payable {
        require(mint2Open);
        require(minted + amount <= maxSupply);
        require(msg.value >= 0.2 ether * amount);

        minted += amount;
        _safeMint(msg.sender, amount);
    }

    function mintForTwoAndAHalf(uint256 amount) external payable {
        require(mint25Open);
        require(minted + amount <= maxSupply);
        require(msg.value >= 0.25 ether * amount);

        minted += amount;
        _safeMint(msg.sender, amount);
    }

    function mintForThree(uint256 amount) external payable {
        require(mint3Open);
        require(minted + amount <= maxSupply);
        require(msg.value >= 0.3 ether * amount);

        minted += amount;
        _safeMint(msg.sender, amount);
    }

    function mintForFour(uint256 amount) external payable {
        require(mint4Open);
        require(minted + amount <= maxSupply);
        require(msg.value >= 0.4 ether * amount);

        minted += amount;
        _safeMint(msg.sender, amount);
    }

    function mintForFive(uint256 amount) external payable {
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
        uint256 id = tokenId % 6806;
        if (id == 0) {
            id = 6805;
        }
        return super.tokenURI(id);
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

    function withdraw() public onlyOwner {    
        uint256 balance = address(this).balance;
        uint256 toWallet1 = balance * 5 / 100;
        uint256 toWallet2 = balance - toWallet1;
        payable(wallet1).transfer(toWallet1);
        payable(wallet2).transfer(toWallet2);
    }

    function destroy() external onlyOwner {
        withdraw();
        selfdestruct(payable(msg.sender));
    }
}