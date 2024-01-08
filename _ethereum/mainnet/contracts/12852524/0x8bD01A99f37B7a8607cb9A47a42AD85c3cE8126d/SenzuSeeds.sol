// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract SenzuSeeds is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;

    string private _baseTokenURI;
    uint256 private _reserved = 100;
    uint256 private _price = 0.06 *  10 ** 18;
    uint256 private _maxInitialTrees = 10001;
    bool public _paused = false;

    constructor() ERC721("Senzu Seeds", "SNZSEEDS") {}


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
    function mintTrees(uint256 _num) public payable {
        uint256 _supply = totalSupply();
        require(!_paused, "Sale paused");
        require(_num < 51, "You can plant a maximum of 50 Trees");
        require(
            _supply + _num < _maxInitialTrees,
            "Exceeds maximum Trees supply"
        );
        require(msg.value >= _price * _num, "Ether sent is not correct");

        for (uint256 i; i < _num; i++) {
            _safeMint(msg.sender, _supply + i);
        }
    }

    function mintSeedingSeason(uint256 _num) public payable {
        uint256 _supply = totalSupply();
        require(!_paused, "It is not Seed Season! Come back Later!");
        require(msg.value >= _price * _num, "Ether sent is not correct");
        for (uint256 i; i < _num; i++) {
            _safeMint(msg.sender, _supply + i);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function walletOfOwnerTokensURI(address _owner) public view returns (string[] memory){
        uint256 tokenCount = balanceOf(_owner);

        string[] memory tokensURI = new string[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_owner, i);
            tokensURI[i] = tokenURI(tokenId);
        }
        return tokensURI;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        uint256 supply = totalSupply();
        for (uint256 i; i < _amount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function setMaxInititalTrees(uint256 _newMax) public onlyOwner() {
        _maxInitialTrees = _newMax;
    }

    function withdraw() public onlyOwner {
        uint _balance = address(this).balance;
        payable(msg.sender).transfer(_balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}
