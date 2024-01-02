// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721AQueryable.sol";
import "./ERC721ABurnable.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";

contract Tesseract is
    ERC721A,
    ERC721AQueryable,
    ERC721ABurnable,
    Ownable,
    ReentrancyGuard
{
    string private _baseURIextended;
    uint256 public constant MAX_SUPPLY = 1024;
    uint256 public count = 0;
    uint256 public constant PRICE = 0.05 ether;
    uint256 public constant WHITELIST_MINT_LIMIT = 2;
    uint256 public constant PUBLIC_MINT_LIMIT = 5;
    bytes32 public merkleRoot;
    mapping(address => uint256) public whitelistMinted;
    mapping(address => uint256) public publicMinted;
    uint256 public whitelistSaleStartTime;
    uint256 public whitelistSaleDuration = 2 hours;
    uint256 public publicSaleStartTime;

    constructor() ERC721A("TESSERACT", "TESSERACT") {
        whitelistSaleStartTime = 1701792000;
        publicSaleStartTime = whitelistSaleStartTime + whitelistSaleDuration;
    }

    modifier onlyDuringWhitelistSale() {
        require(
            block.timestamp >= whitelistSaleStartTime &&
                block.timestamp < publicSaleStartTime,
            "Not in whitelist sale period"
        );
        _;
    }

    modifier onlyDuringPublicSale() {
        require(
            block.timestamp >= publicSaleStartTime,
            "Public sale not started"
        );
        _;
    }

    modifier checkPayment(uint256 quantity) {
        require(msg.value == PRICE * quantity, "Incorrect Ether value");
        _;
    }

    modifier checkWhitelistLimit(uint256 quantity) {
        require(
            whitelistMinted[msg.sender] + quantity <= WHITELIST_MINT_LIMIT,
            "Exceeds whitelist limit"
        );
        _;
    }

    modifier checkPublicLimit(uint256 quantity) {
        require(
            publicMinted[msg.sender] + quantity <= PUBLIC_MINT_LIMIT,
            "Exceeds public mint limit"
        );
        _;
    }

    modifier checkMaxSupply(uint256 quantity) {
        require(count + quantity <= MAX_SUPPLY, "Exceeds max supply");
        _;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============
    function whitelistMint(
        uint256 quantity,
        bytes32[] calldata merkleProof
    )
        external
        payable
        onlyDuringWhitelistSale
        checkPayment(quantity)
        checkWhitelistLimit(quantity)
        checkMaxSupply(quantity)
        returns (uint256)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "Invalid proof"
        );

        whitelistMinted[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
        count += quantity;
        return count - quantity;
    }

    function publicMint(
        uint256 quantity
    )
        external
        payable
        onlyDuringPublicSale
        checkPayment(quantity)
        checkPublicLimit(quantity)
        checkMaxSupply(quantity)
        returns (uint256)
    {
        publicMinted[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
        count += quantity;
        return count - quantity;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function adminMint(
        uint256 quantity
    ) external onlyOwner checkMaxSupply(quantity) returns (uint256) {
        _safeMint(msg.sender, quantity);
        count += quantity;
        return count - quantity;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
}
