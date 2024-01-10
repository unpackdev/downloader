// SPDX-License-Identifier: MIT
// Ducklebutts by Crap Heads
pragma solidity ^0.8.9;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Ducklebutts is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public constant PRICE = 0.01 ether;
    uint256 public constant MAX_PER_TX = 3;
    uint256 public constant MAX_SUPPLY = 600;

    bool public saleIsDuckingActive;

    string public baseURI;

    constructor() ERC721A("Ducklebutts", "DUCKLEBUTTS") {}

    function mint(uint256 amount) external payable {
        require(tx.origin == msg.sender, "Like someone would bot this.");

        require(saleIsDuckingActive, "Sale is not ducking active yet.");
        require(amount <= MAX_PER_TX, "Mint less you greedy bastard!");
        require(amount + _totalMinted() <= MAX_SUPPLY, "Enough of this ducking crap.");
        require(amount > 0, "Zero ducks given.");
        require(msg.value == PRICE * amount, "No eth no ducks");
        _safeMint(msg.sender, amount);
    }

    function ownerMint(uint256 amount) external onlyOwner {
        _safeMint(msg.sender, amount);
    }

    function ducktivate() external onlyOwner {
        saleIsDuckingActive = !saleIsDuckingActive;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(abi.encodePacked(baseURI, tokenId.toString()), ".json"))
                : "ipfs://QmbLqD9bfWyGWEqK1hq9oMRAkD1nKZkdiLsB6JuYZjoohE/";
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}
