// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract Kurachan is ERC721A, Ownable {
    uint256 public constant MAX_PER_TXN = 10;
    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public mintPrice = 0.0077 ether;
    uint256 public freeMintSupply = 5000;

    constructor() ERC721A("Kurachan", "KURACHAN") {
        baseURI = "ipfs://Qme43JSiP5rG95UFuSSw2QEEXukGzfe39E5PA3pUEPxijA/";
        whitelistMerkleRoot = 0x658555a480c173c4e2646292d2fc5e802c63bd968fccbfed2d69e6b8c7eff15a;
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
     * @dev Public sale and whitelist sale mechansim
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
     * @dev Public minting
     */
    function mintPublic(uint256 _quantity)
        public
        payable
        publicSaleActive
        withinMaximumSupply(_quantity)
        withinMaximumPerTxn(_quantity, MAX_PER_TXN)
    {
        if (totalSupply() + _quantity >= freeMintSupply) {
            require(msg.value >= mintPrice * _quantity, "Insufficent funds");
        }
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

    function mintWhitelist(uint256 _quantity, bytes32[] calldata merkleProof)
        public
        payable
        whitelistSaleActive
        hasValidMerkleProof(merkleProof, whitelistMerkleRoot)
        withinMaximumSupply(_quantity)
        withinMaximumPerTxn(_quantity, MAX_PER_TXN)
    {
        if (totalSupply() + _quantity >= freeMintSupply) {
            require(msg.value >= mintPrice * _quantity, "Insufficent funds");
        }
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @dev Admin minting
     */
    function adminMint(address _recipient, uint256 _quantity)
        public
        onlyOwner
        withinMaximumSupply(_quantity)
    {
        _safeMint(_recipient, _quantity);
    }

    /**
     * @dev Allow adjustment of minting price (in wei)
     */
    function setMintPrice(uint256 _price) public onlyOwner {
        mintPrice = _price;
    }

    /**
     * @dev Allow adjustment of free mint supply
     */
    function setFreeMintSupply(uint256 _supply) public onlyOwner {
        freeMintSupply = _supply;
    }

    /**
     * @dev Base URI
     */
    string private baseURI;

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Payout mechanism
     */
    address private constant payoutAddress1 =
        0xbaF153A8AfF8352cB6539CF9168255442Def0a02;
    address private constant payoutAddress2 =
        0x942d44A7B2F9Dc4c2cA60e6FEcDbA4c0Fa4981e0;
    address private constant payoutAddress3 =
        0xf88Ad4273F85Eb80785566A328779b323B32CFe8;

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(payoutAddress1), (balance * 40) / 100);
        Address.sendValue(payable(payoutAddress2), (balance * 40) / 100);
        Address.sendValue(payable(payoutAddress3), (balance * 20) / 100);
    }
}
