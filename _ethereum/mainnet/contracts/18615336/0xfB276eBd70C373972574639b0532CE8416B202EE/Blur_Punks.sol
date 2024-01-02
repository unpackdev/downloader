// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";

contract Blur_Punks is ERC721A, Ownable {

    /// ============ STORAGE ============

    string private baseURI;

    uint256 constant public MAX_SUPPLY = 2222;
    uint256 constant public MAX_MINT_PER_WALLET = 6;
    uint256 constant public PRICE = 0.004 ether;

    uint256 public saleStartTimestamp;

    mapping(address => uint256) public mintedCount;

    /// ============ CONSTRUCTOR ============

    constructor(
        uint256 _saleStartTimestamp,
        string memory _baseURI
    ) ERC721A("Blur Punks", "BLURP") {
        saleStartTimestamp = _saleStartTimestamp;
        baseURI = _baseURI;
        _mint(msg.sender, 1);
    }

    /// ============ MAIN ============

    function mint(uint256 quantity) public payable {
        require(msg.sender == tx.origin, "No contracts");
        require(block.timestamp >= saleStartTimestamp, "Sale has not started");
        require(quantity > 0, "Quantity must be greater than 0");
        require(quantity + mintedCount[msg.sender] <= MAX_MINT_PER_WALLET, "Quantity must be less than max mint per wallet");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Quantity must be less than max supply");
        if (mintedCount[msg.sender] == 0) {
            require(msg.value >= PRICE * (quantity - 1), "Ether value sent is not correct");
        } else {
            require(msg.value >= PRICE * quantity, "Ether value sent is not correct");
        }

        mintedCount[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    /// ============ ONLY OWNER ============

    function setSaleStartTimestamp(uint256 _saleStartTimestamp) external onlyOwner {
        saleStartTimestamp = _saleStartTimestamp;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setbaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /// ============ METADATA ============

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

        return string(abi.encodePacked(baseURI, _toString(tokenId)));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

}
