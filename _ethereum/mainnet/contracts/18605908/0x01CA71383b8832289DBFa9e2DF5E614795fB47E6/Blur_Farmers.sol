// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";

contract Blur_Farmers is ERC721A, Ownable {

    /// ============ STORAGE ============

    string private baseURIUnrevealed;
    string private baseURIRevealed;
    bool private revealed;

    uint256 constant public MAX_SUPPLY = 4444;
    uint256 constant public MAX_MINT_PER_WALLET = 5;
    uint256 constant public PRICE = 0.00269 ether;

    uint256 public saleStartTimestamp;

    mapping(address => uint256) public mintedCount;

    /// ============ CONSTRUCTOR ============

    constructor(
        uint256 _saleStartTimestamp,
        string memory _baseURIUnrevealed
    ) ERC721A("Blur Farmers", "BLURF") {
        saleStartTimestamp = _saleStartTimestamp;
        baseURIUnrevealed = _baseURIUnrevealed;
    }

    /// ============ MAIN ============

    function mint(uint256 quantity) public payable {
        require(msg.sender == tx.origin, "No contracts");
        require(block.timestamp >= saleStartTimestamp, "Sale has not started");
        require(quantity > 0, "Quantity must be greater than 0");
        require(quantity + mintedCount[msg.sender] <= MAX_MINT_PER_WALLET, "Quantity must be less than max mint per wallet");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Quantity must be less than max supply");
        require(msg.value >= PRICE * quantity, "Ether value sent is not correct");

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

    function reveal(string calldata _baseURIRevealed) external onlyOwner {
        require(!revealed, "Already revealed");
        baseURIRevealed = _baseURIRevealed;
        revealed = true;
    }

    function updateRevealedBaseURI(string calldata _baseURIRevealed) external onlyOwner {
        require(revealed, "Not revealed yet");
        baseURIRevealed = _baseURIRevealed;
    }

    function setbaseURIUnrevealed(string calldata _baseURIUnrevealed) external onlyOwner {
        baseURIUnrevealed = _baseURIUnrevealed;
    }

    function setbaseURIRevealed(string calldata _baseURIRevealed) external onlyOwner {
        baseURIRevealed = _baseURIRevealed;
    }

    /// ============ METADATA ============

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

        if (revealed) {
            return string(abi.encodePacked(baseURIRevealed, _toString(tokenId)));
        } else {
            return baseURIUnrevealed;
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

}
