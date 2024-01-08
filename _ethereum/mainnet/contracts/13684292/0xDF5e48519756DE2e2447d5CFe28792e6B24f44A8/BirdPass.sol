// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

contract BirdPass is ERC1155Burnable, ERC1155Supply, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256; 
    string public baseURI = "https://to.wtf/contract_uri/bowerbird/metadata/";
    string public contractURI = "https://bowerbirdcollective.io/metadata/bowerbird.json";
    uint256 public pricePerPass = 0.08 ether;
    uint256 public maxSupply = 600;

    constructor() ERC1155(baseURI) {
        pause();
    }

    function mint(uint256 count) public payable whenNotPaused nonReentrant virtual {
        uint256 _supply = totalSupply(1);
        require(count > 0, "count is 0");
        require(count <= 5, "Greater than max"); 
        require(_supply < maxSupply, "sold out");
        require(_supply + count < maxSupply, "exceeds supply");
        require(pricePerPass.mul(count) == msg.value, "Invalid eth sent");
        _mint(msg.sender, 1, count, "");
        delete _supply;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool paid, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(paid);
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }
}