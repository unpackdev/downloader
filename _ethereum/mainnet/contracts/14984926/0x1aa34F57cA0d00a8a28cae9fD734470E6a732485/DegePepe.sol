// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract DegePepe is ERC721A, Ownable {
    using SafeMath for uint256;

    string public baseTokenURI;
    bool public publicSale = false;
    uint256 public pepesLimit = 3333;
    uint256 public freeLimit = 1;
    uint256 public price = 0.008 ether;
    mapping(address => uint256) public numPepes;

    constructor() ERC721A("Dege Pepe", "DGP") {}

    function mintPepe(uint256 _amount) external payable {
        uint256 currentPepe = totalSupply();
        require(publicSale, "Public sale not active");
        if (numPepes[msg.sender] >= freeLimit) {
            require(msg.value == price.mul(_amount), "Mint price sent is not correct. You can free mint max 1 DGP per wallet, please consider minting for 0.008 eth per mint");
        }
        // If number of pepes in the wallet is less than freeLimit, counting price for every NFT, excepting first one (because its's free)
        if (_amount >= freeLimit && numPepes[msg.sender] < freeLimit) {
            require(msg.value == price.mul(_amount - freeLimit), "Mint price sent is not correct. You can free mint max 1 DGP per wallet, please consider minting for 0.008 eth per mint");
        }
        require(currentPepe + _amount <= pepesLimit, "Pepe supply would be exceeded");
        _safeMint(msg.sender, _amount);
        numPepes[msg.sender] += _amount;
    }

    function airdrop(address _address, uint256 _amount) public onlyOwner {
        uint256 currentPepe = totalSupply();
        require(currentPepe + _amount <= pepesLimit);
        _safeMint(_address, _amount);
    }

    function setPublicSale(bool _publicSale) external onlyOwner {
        publicSale = _publicSale;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    function _startTokenId() public pure override returns (uint256) {
        return 1;
    }

    function withdraw(address payable _to, uint256 _amount) public onlyOwner {
        _to.transfer(_amount);
    }
}
