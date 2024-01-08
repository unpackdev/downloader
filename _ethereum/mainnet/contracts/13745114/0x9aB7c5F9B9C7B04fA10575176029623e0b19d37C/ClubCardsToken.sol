// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Mintable.sol";

contract ClubCardsToken is ERC721, Ownable, Mintable {

    string public baseURI;

    constructor(address _imx) 
        ERC721("ClubCardsToken", "CLUBC") 
        Mintable(msg.sender, _imx) 
    {}

    function setBaseURI(string memory newURI) external onlyOwner {
        baseURI = newURI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _mintFor(
        address user,
        uint256 id,
        bytes memory
    ) internal override {
        _safeMint(user, id);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

}