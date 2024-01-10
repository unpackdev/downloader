// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract TheBlueBirdDAO is ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant PRICE_STEP_SIZE = 0.0321 ether;

    uint256 public totalSupply;
    string public baseUri;

    constructor(string memory _baseUri) ERC721("TheBlueBirdDAO", unicode"🐔") payable {
        baseUri = _baseUri;

        unchecked {
            for (uint256 i = 1; i < 26; ++i) {
                _mint(msg.sender, i);
            }
        }
        totalSupply = 26;
    }

    function mint() external payable {
        uint256 currentSupply = totalSupply;
        require(msg.value >= getPrice(currentSupply));

        unchecked {
            require(currentSupply + 1 <= MAX_SUPPLY);
            _mint(msg.sender, currentSupply);
            totalSupply++;
        }
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(ownerOf(_tokenId) != address(0));

        return string(abi.encodePacked(
            baseUri,
            _tokenId.toString()
        ));
    }

    function getPrice(uint256 _supply) internal pure returns (uint256) {
        uint256 price;

        assembly {
            price := mul(PRICE_STEP_SIZE, add(div(sub(_supply, 1), 100), 1))
        }

        return price;
    }

    function setBaseURI(string memory _baseUri) external payable onlyOwner {
        baseUri = _baseUri;
    }

    function withdraw() external payable onlyOwner {
        (bool transfer, ) = payable(owner()).call{value: address(this).balance}("");
        require(transfer);
    }
}