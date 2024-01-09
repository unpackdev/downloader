//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./console.sol";

import "./IERC20.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

import "./ERC721X.sol";

contract Mayhem is ERC721X, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    event SaleStateUpdate();

    string public baseURI;
    string public unrevealedURI = 'ipfs://QmSkB7oLu5wV1Acg1jxu9MxtPfQdZXpZKit4GFvnZz1Jc8';

    bool public publicSaleActive;
    bool public whitelistActive;

    uint256 public totalSupply;
    uint256 public maxSupply = 7777;

    uint256 public constant price = 0.088 ether;
    uint256 public constant PURCHASE_LIMIT = 5;

    uint256[] WHITELIST_PURCHASE_LIMIT = [1, 3, 4, 5, 6];

    uint256 private constant INDEX_OFFSET = 1;

    mapping(address => mapping(uint256 => bool)) public whitelistClaimed;

    address private _signerAddress = 0x18a3443b2f9646582CE52f1D6D8bdDB1D2716bb5;

    constructor() ERC721X('World of Mayhem', 'WOM') {}

    // ------------- External -------------

    function mint(uint256 amount) external payable whenPublicSaleActive onlyHuman {
        require(amount <= PURCHASE_LIMIT, 'EXCEEDS_LIMIT');
        require(msg.value == price * amount, 'INCORRECT_VALUE');

        _mintBatchTo(msg.sender, amount);
    }

    function whitelistMint(
        uint256 amount,
        uint256 tier,
        bytes calldata signature
    ) external payable whenWhitelistActive onlyWhitelisted(tier, signature) onlyHuman {
        uint256 purchaseLimit_ = (WHITELIST_PURCHASE_LIMIT[tier - 1]);
        uint256 price_ = tier == 1 ? 0 : price;
        require(amount <= purchaseLimit_, 'EXCEEDS_LIMIT');
        require(msg.value == price_ * amount, 'INCORRECT_VALUE');

        _mintBatchTo(msg.sender, amount);
    }

    // ------------- Internal -------------

    function _mintTo(address to) internal {
        uint256 tokenId = totalSupply;
        require(tokenId < maxSupply, 'MAX_SUPPLY_REACHED');

        totalSupply++;
        _mint(to, INDEX_OFFSET + tokenId);
    }

    function _mintBatchTo(address to, uint256 amount) internal {
        uint256 tokenId = totalSupply;
        require(tokenId + amount <= maxSupply, 'MAX_SUPPLY_REACHED');

        totalSupply += amount;
        for (uint256 i; i < amount; i++) _mint(to, INDEX_OFFSET + tokenId + i);
    }

    function _validSignature(bytes memory signature, uint256 _tier) internal view returns (bool) {
        bytes32 msgHash = keccak256(abi.encode(address(this), _tier, msg.sender));
        return msgHash.toEthSignedMessageHash().recover(signature) == _signerAddress;
    }

    // ------------- Owner -------------

    function giveAway(address[] calldata accounts) external onlyOwner {
        for (uint256 i; i < accounts.length; i++) _mintTo(accounts[i]);
    }

    function setPublicSaleActive(bool active) external onlyOwner {
        publicSaleActive = active;
        emit SaleStateUpdate();
    }

    function setWhitelistActive(bool active) external onlyOwner {
        whitelistActive = active;
        emit SaleStateUpdate();
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setUnrevealedURI(string calldata _uri) external onlyOwner {
        unrevealedURI = _uri;
    }

    function setSignerAddress(address _address) external onlyOwner {
        _signerAddress = _address;
    }

    function burnUnminted() external onlyOwner {
        require(maxSupply == 7777, 'ALREADY_BURNED');
        maxSupply = totalSupply;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function recoverToken(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
    }

    // ------------- Modifier -------------

    modifier whenPublicSaleActive() {
        require(publicSaleActive, 'PUBLIC_SALE_NOT_ACTIVE');
        _;
    }

    modifier whenWhitelistActive() {
        require(whitelistActive, 'WHITELIST_NOT_ACTIVE');
        _;
    }

    modifier onlyHuman() {
        require(tx.origin == msg.sender, 'CONTRACT_CALL');
        _;
    }

    modifier onlyWhitelisted(uint256 tier, bytes memory signature) {
        require(_validSignature(signature, tier), 'NOT_WHITELISTED');
        require(!whitelistClaimed[msg.sender][tier], 'WHITELIST_USED');
        whitelistClaimed[msg.sender][tier] = true;
        _;
    }

    // ------------- ERC721X -------------

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return
            bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), '.json')) : unrevealedURI;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), 'ERC721: balance query for the zero address');
        uint256 count;
        for (uint256 i = INDEX_OFFSET; i < INDEX_OFFSET + totalSupply; i++) if (owner == _owners[i]) count++;
        return count;
    }

    function tokenIdsOf(address owner) public view returns (uint256[] memory) {
        require(owner != address(0), 'ERC721: query for the zero address');
        uint256[] memory tokenIds = new uint256[](balanceOf(owner));
        for (uint256 i = INDEX_OFFSET; i < INDEX_OFFSET + totalSupply; i++) if (owner == _owners[i]) tokenIds[i] = i;
        return tokenIds;
    }
}
