// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract CrapHeads is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public constant PRICE = 0.01 ether;
    uint256 public constant MAX_PER_TX = 3;
    uint256 public constant MAX_SUPPLY = 600;

    bool public saleIsCraptive;

    string public baseURI;

    constructor() ERC721A("Crap Heads", "CRAPHEADS") {}

    function mint(uint256 amount) external payable {
        require(tx.origin == msg.sender, "Like someone would bot this.");

        require(saleIsCraptive, "Sale is not craptive yet.");
        require(amount <= MAX_PER_TX, "Mint less you greedy bastard!");
        require(amount + _totalMinted() <= MAX_SUPPLY, "Enough of this crap.");
        require(amount > 0, "Zero craps given.");
        require(msg.value == PRICE * amount, "No eth no crap");
        _safeMint(msg.sender, amount);
    }

    function ownerMint(uint256 amount) external onlyOwner {
        _safeMint(msg.sender, amount);
    }

    function craptivate() external onlyOwner {
        saleIsCraptive = !saleIsCraptive;
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
                : "ipfs://QmYKHPzx2gW6cTpmy1ihZMXqSVvt9yUAQGRoK61wLm7t7Z/";
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}
