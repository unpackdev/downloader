// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract RarePunks is ERC721Enumerable, Ownable, ReentrancyGuard {

    event Affiliate(address indexed ref, address indexed minter, uint indexed value);

    using SafeMath for uint;
    string internal baseURI;

    uint public constant MAX_SUPPLY = 500;

    constructor(address owner, string memory tokenBaseUri) ERC721("RarePunks", "RARE") {
        Ownable.transferOwnership(owner);
        baseURI = tokenBaseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata newBaseUri) external onlyOwner {
        baseURI = newBaseUri;
    }

    function getPrice(uint quantity) public view returns (uint) {
        uint supply = totalSupply();
        uint price = 0;
        for(uint i = 1; i <= quantity; i++){
            uint tokenId = supply + i;
            if(tokenId > 500) {
            } else if (tokenId > 460) {
                price += 0.8 ether; // 461- 500 0.8 ETH
            } else if (tokenId > 400) {
                price += 0.4 ether; // 401 - 460 0.4 ETH
            } else if (tokenId > 300) {
                price += 0.2 ether; // 301 - 400 0.2 ETH
            } else if (tokenId > 200) {
                price += 0.1 ether; // 201 - 300 0.1 ETH
            } else if (tokenId > 0) {
                price += 0.05 ether; // 1 - 200 0.05 ETH
            }
        }
        return price;
    }

    function mint(uint quantity, address ref) public payable nonReentrant {
        uint supply = totalSupply();
        require(supply < MAX_SUPPLY, "All tokens are minted");
        require(quantity > 0, "Quantity can not be 0");
        require(supply.add(quantity) <= MAX_SUPPLY, "Exceeds max supply");
        require(msg.value >= getPrice(quantity), "Incorrect ETH value");

        for (uint i = 1; i <= quantity; i++) {
            _safeMint(_msgSender(), supply + i);
        }

        if (ref != address(0)) {
            uint value = msg.value.mul(3).div(10);
            payable(ref).transfer(value);
            emit Affiliate(ref, _msgSender(), value);
        }
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function tokensIdOf(address owner) public view returns(uint[] memory) {
        uint length = balanceOf(owner);
        uint[] memory tokensId = new uint[](length);
        for(uint i = 0; i < length; i++){
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }
}