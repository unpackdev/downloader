// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

contract SMOKINGALIENZ is ERC721A, Ownable {

    using Strings for uint256;

    uint256 public constant maxTokens = 1420;
    uint256 public maxPerTxn = 2;
    uint256 public maxPerWallet = 2;
    string private baseURI;
    bool public paused = true;
    mapping(address => uint256) private walletMinted;

    constructor(
        string memory _initBaseURI
    ) ERC721A("SMOKING ALIENZ", "ALIENZ") {
        setBaseURI(_initBaseURI);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 _amount) external {
        uint256 ts = totalSupply();

        require(paused == false, "Mint not active!");
        require(msg.sender == tx.origin, "No smartcontracts allowed!");
        require(_amount > 0, "Mint amount can't be zero!");
        require(ts + _amount <= maxTokens, "Over collection size!");
        require(_amount <= maxPerTxn, "Over transaction limit!");
        require(walletMinted[msg.sender] + _amount <= maxPerWallet, "Over wallet limit!");

        walletMinted[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token doesn't exist!");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";

    }

    function isPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

}