// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract HolyCows is ERC721Enumerable, Ownable {
    using SafeMath for uint;
    using Strings for uint;

    uint public price;
    uint public immutable maxSupply;
    bool public mintingEnabled;
    uint public buyLimit;

    string private _baseURIPrefix;
    address payable immutable dev;

    constructor (string memory _name, string memory _symbol, uint _maxSupply, uint _price, uint _buyLimit, string memory _uri, address payable _dev) 
    ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
        price = _price;
        buyLimit = _buyLimit;
        _baseURIPrefix = _uri;
        dev = _dev;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    function setBaseURI(string memory newUri) external onlyOwner {
        _baseURIPrefix = newUri;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function toggleMinting() external onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    function mintNFTs(uint256 quantity) external payable {
        if (_msgSender() != owner())
            require(mintingEnabled, "Minting has not been enabled");
        require(quantity > 0, "Invalid quantity");
        require(quantity <= buyLimit, "Buy limit exceeded");
        require(totalSupply().add(quantity) <= maxSupply, "Max supply exceeded");
        require(price.mul(quantity) == msg.value, "Incorrect ETH value");

        for (uint i = 0; i < quantity; i++) {
            _safeMint(_msgSender(), totalSupply().add(1));
        }
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        uint devFee = balance.div(20);
        uint amount = balance.sub(devFee);

        dev.transfer(devFee);
        payable(owner()).transfer(amount);
    }
}
