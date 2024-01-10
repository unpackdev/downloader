// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract JiraBibiz is ERC721, Ownable {
    using SafeMath for uint256;

    bool public isOpen = false;

    uint256 public price = 0.002 ether;
    uint256 public maxPerWallet = 5;
    uint256 public maxTotalSupply = 500;

    address private withdrawAddress = address(0);

    string public baseURI;

    mapping(address => uint256) public mintsPerWallet;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function mint(uint256 _amount) external payable {
        require(isOpen, "Sale not open");
        require(_amount > 0, "Must mint at least one");
        require(_amount.add(mintsPerWallet[_msgSender()]) <= maxPerWallet, "Exceeds max per wallet");
        require(totalSupply().add(_amount) <= maxTotalSupply, "Exceeds available supply");
        require(price.mul(_amount) <= msg.value, "Incorrect amount * price value");

        for (uint256 i = 0; i < _amount; i++) {
            mintsPerWallet[_msgSender()] = mintsPerWallet[_msgSender()].add(1);
            _safeMint(_msgSender());
        }
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Token not owned or approved");
        _burn(tokenId);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxTotalSupply(uint256 _maxValue) external onlyOwner {
        maxTotalSupply = _maxValue;
    }

    function setMaxPerWallet(uint256 _maxValue) external onlyOwner {
        maxPerWallet = _maxValue;
    }

    function setIsOpen(bool _open) external onlyOwner {
        isOpen = _open;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWithdrawAddress(address _newAddress) external onlyOwner {
        withdrawAddress = _newAddress;
    }

    function withdraw() external onlyOwner {
        require(withdrawAddress != address(0), "Withdraw address not set");
        uint256 ethBalance = address(this).balance;
        payable(withdrawAddress).transfer(ethBalance);
    }
}
