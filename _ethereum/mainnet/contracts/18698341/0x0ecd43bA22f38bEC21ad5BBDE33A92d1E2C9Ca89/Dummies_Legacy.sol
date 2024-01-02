// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";

contract Dummies_Legacy is ERC721A, Ownable {

    /// ============ STORAGE ============

    string private baseURIUnrevealed;
    string private baseURIRevealed;
    bool private revealed;

    uint256 constant public MAX_SUPPLY = 2550;
    uint256 constant public MAX_MINT_PER_WALLET = 5;
    uint256 constant public PRICE = 0.008 ether;

    uint256 public mintCounter;

    uint256 public saleStartTimestamp;

    mapping(address => bool) public partners;
    uint256 public partnersCount;
    mapping(address => bool) public isPartnerMinted;
    mapping(address => uint256) public mintedCount;

    /// ============ CONSTRUCTOR ============

    constructor(
        uint256 _saleStartTimestamp,
        string memory _baseURIUnrevealed
    ) ERC721A("Dummies Legacy", "DUMMIES") {
        saleStartTimestamp = _saleStartTimestamp;
        baseURIUnrevealed = _baseURIUnrevealed;
        _mint(msg.sender, 1);
    }

    /// ============ MAIN ============

    function mint(uint256 quantity) public payable {
        require(msg.sender == tx.origin, "No contracts");
        require(block.timestamp >= saleStartTimestamp, "Sale has not started");
        require(quantity + mintedCount[msg.sender] <= MAX_MINT_PER_WALLET, "Quantity must be less than max mint per wallet");
        require(mintCounter + quantity <= MAX_SUPPLY - 50, "Quantity must be less than max supply");
        require(msg.value >= PRICE * quantity, "Ether value sent is not correct");

        if (partners[msg.sender] && !isPartnerMinted[msg.sender] && partnersCount < 50) {
            isPartnerMinted[msg.sender] = true;
            partnersCount++;
            _mint(msg.sender, 1);
        } else {
            require(quantity > 0, "Quantity must be greater than 0");
        }

        if (quantity > 0) {
            mintedCount[msg.sender] += quantity;
            mintCounter += quantity;
            _mint(msg.sender, quantity);
        }
    }

    /// ============ ONLY OWNER ============

    function setPartners(address[] calldata _partners, bool _flag) external onlyOwner {
        for (uint256 i = 0; i < _partners.length; i++) {
            partners[_partners[i]] = _flag;
        }
    }

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

    /// ============ METADATA ============

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

        if (revealed) {
            return string(abi.encodePacked(baseURIRevealed, _toString(tokenId), ".json"));
        } else {
            return baseURIUnrevealed;
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

}
