// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC721AQueryable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract MPP is ERC721AQueryable, Pausable, Ownable {
    using Strings for uint256;

    string public baseURI;
    uint256 public constant MAX_SUPPLY = 30; // Maximum supply of NFTs

    constructor(string memory baseURI_) 
        ERC721A("Multipool Pioneers", "MPP") {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function mintTo(address to, uint quantity) external whenNotPaused onlyOwner {
        require(to != address(0), "Can't mint to empty address");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds maximum supply");
        _safeMint(to, quantity);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

}
