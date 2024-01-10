// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract DoodleKevins is ERC721A, Ownable {
    uint256 public constant MAX_SUPPLY = 4444;
    uint256 public constant FREE_MINTS = 444;
    uint256 public constant MINT_LIMIT = 10;
    uint256 public constant MINT_PRICE = 0.0099 ether;

    string public baseURI;

    constructor(string memory baseURI_) ERC721A("Doodle Kevins", "DEVIN") {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function mint(uint256 quantity) external payable {
        require(totalSupply() + quantity <= MAX_SUPPLY, "DEVIN: mint exceeds total supply");
        require(msg.value >= (MINT_PRICE * quantity), "DEVIN: insufficient eth sent");
        require(quantity <= MINT_LIMIT, "DEVIN: mint quantity too high");

        _mint(msg.sender, quantity, "", false);
    }

    function freeMint() external {
        require(totalSupply() + 1 <= FREE_MINTS, "DEVIN: free mints exhausted");

        _mint(msg.sender, 1, "", false);
    }

    function transferEth(address payable dest, uint256 amount) external onlyOwner {
        dest.transfer(amount);
    }
}
