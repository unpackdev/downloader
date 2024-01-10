// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract ValentinesGame is ERC721A, Ownable {
    using SafeMath for uint256;

    uint256 public loveCost = 0.03 ether;
    uint256 public freeLovesAvailable = 4000;
    uint256 public freeLovesTaken = 0;
    uint256 public maxLovesAvailable = 8000;
    address private chestAddress = address(0);
    bool public isGameOpen = false;

    mapping(address => uint256) public lovesPerWallet;

    string public loveURI;
    string public hateURI;

    constructor(string memory name, string memory symbol) ERC721A(name, symbol) {}

    function love(uint256 _amount) external payable {
        require(isGameOpen, "Game not started");
        require(_amount <= 25, "Too much love in one go");
        require(totalSupply().add(_amount)<= maxLovesAvailable, "Love exceeds expectations");
        require(_amount > 0, "Must love at least one");

        uint256 availableLove = freeLovesAvailable <= freeLovesTaken || lovesPerWallet[_msgSender()] > 0 ? 0 : 1;
        require(loveCost.mul(_amount.sub(availableLove)) <= msg.value, "Ether value sent is not correct");

        if (availableLove > 0) freeLovesTaken++;

        for (uint256 i = 0; i < _amount; i++) {
            lovesPerWallet[_msgSender()] = lovesPerWallet[_msgSender()].add(1);
            _safeMint(_msgSender());
        }
    }

    function hate(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Token not owned or approved");
        _burn(tokenId);
    }

    function secretLove(uint256 _amount, address _receiver) external onlyOwner {
        require(_amount > 0, "Must love at least one");
        require(totalSupply().add(_amount) <= maxLovesAvailable, "Love exceeds expectations");

        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(_receiver);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(totalSupply() > tokenId, "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = ownerOf(tokenId) == address(0) ? hateURI : loveURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : "";
    }

    function setLoveCost(uint256 _value) external onlyOwner {
        loveCost = _value;
    }

    function setMaxLovesAvailable(uint256 _value) external onlyOwner {
        maxLovesAvailable = _value;
    }

    function setFreeLovesAvailable(uint256 _value) external onlyOwner {
        freeLovesAvailable = _value;
    }

    function setGameOpen(bool _open) external onlyOwner {
        isGameOpen = _open;
    }

    function setLoveURI(string memory _value) external onlyOwner {
        loveURI = _value;
    }

    function setHateURI(string memory _value) external onlyOwner {
        hateURI = _value;
    }

    function setChest(address _value) external onlyOwner {
        chestAddress = _value;
    }

    function take() external onlyOwner {
        require(chestAddress != address(0), "No chest address");
        uint256 contractBalance = address(this).balance;
        payable(chestAddress).transfer(contractBalance);
    }
}
