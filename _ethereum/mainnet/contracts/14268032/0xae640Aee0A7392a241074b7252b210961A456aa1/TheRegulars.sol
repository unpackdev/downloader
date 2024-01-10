// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract TheRegulars is ERC721A, Ownable {
    uint256 public constant MAX_PER_TXN = 10;
    uint256 public constant MAX_PER_TXN_WHITELIST = 5;
    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public mintPrice = 0.06 ether;

    constructor() ERC721A("The Regulars NFT", "REGULAR") {
        baseURI = "ipfs://QmfVpkc7tdMdJGYLxMe55L1vx2LZaK2yRi8e8xpLCbmdrL/";
    }

    modifier hasCorrectAmount(uint256 _wei, uint256 _quantity) {
        require(_wei >= mintPrice * _quantity, "Insufficent funds");
        _;
    }

    modifier withinMaximumSupply(uint256 _quantity) {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Surpasses supply");
        _;
    }

    modifier withinMaximumPerTxn(uint256 _quantity, uint256 _limit) {
        require(_quantity > 0 && _quantity <= _limit, "Over maximum per txn");
        _;
    }

    /**
     * Public sale and whitelist sale mechansim
     */
    bool public publicSale = false;
    bool public whitelistSale = false;

    modifier publicSaleActive() {
        require(publicSale, "Public sale not started");
        _;
    }

    modifier whitelistSaleActive() {
        require(whitelistSale, "Whitelist sale not started");
        _;
    }

    function setPublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function setWhitelistSale() external onlyOwner {
        whitelistSale = !whitelistSale;
    }

    /**
     * Public minting
     */
    function mintPublic(uint256 _quantity)
        public
        payable
        publicSaleActive
        hasCorrectAmount(msg.value, _quantity)
        withinMaximumSupply(_quantity)
        withinMaximumPerTxn(_quantity, MAX_PER_TXN)
    {
        _safeMint(msg.sender, _quantity);
    }

    /**
     * Whitelist minting
     */
    bytes32 public whitelistMerkleRoot;

    modifier hasValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address not eligible"
        );
        _;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function mintWhitelist(
        uint256 _quantity,
        bytes32[] calldata merkleProof
    )
        public
        payable
        whitelistSaleActive
        hasValidMerkleProof(merkleProof, whitelistMerkleRoot)
        hasCorrectAmount(msg.value, _quantity)
        withinMaximumSupply(_quantity)
        withinMaximumPerTxn(_quantity, MAX_PER_TXN_WHITELIST)
    {
        _safeMint(msg.sender, _quantity);
    }

    /**
     * Admin minting
     */
    function mintAdmin(address _recipient, uint256 _quantity)
        public
        onlyOwner
        withinMaximumSupply(_quantity)
    {
        _safeMint(_recipient, _quantity);
    }

    /**
     * Allow adjustment of minting price (in wei)
     */
    function setMintPrice(uint256 _price) public onlyOwner {
        mintPrice = _price;
    }

    /**
     * Base URI
     */
    string private baseURI;

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Withdrawal
     */
    address private constant address1 =
        0x36Ce383013bA91EA1b6f6206f44f05Ccd5eb340a;
    address private constant address2 =
        0x55d7fA5BF699F6082d4387419dA405157C6E44bf;
    address private constant address3 =
        0xe49B4ffDb33A1F690C9214C2B3dD6BFF9dCC4362;

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(address1), (balance * 75) / 100);
        Address.sendValue(payable(address2), (balance * 15) / 100);
        Address.sendValue(payable(address3), (balance * 10) / 100);
    }
}
