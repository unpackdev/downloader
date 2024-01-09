// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Address.sol";
import "./MerkleProof.sol";

contract Gunnerz is ERC721, Ownable {
    using Counters for Counters.Counter;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory baseURI_
    ) ERC721(_name, _symbol) {
        baseURI = baseURI_;
    }

    /**
     * Minting functionality
     */
    uint256 public constant MAX_PER_TXN = 10;
    uint256 public constant MAX_SUPPLY_ABSOLUTE = 5000;
    uint256 public constant SALE_PRICE = 0.02 ether;
    uint256 public mintableSupply = 5000;
    uint256 public freeMintAmount = 1000;
    Counters.Counter private supplyCounter;

    modifier withinQuantityLimits(uint256 _quantity) {
        require(_quantity > 0 && _quantity <= MAX_PER_TXN, "Invalid quantity");
        _;
    }

    modifier withinMaximumSupply(uint256 _quantity) {
        require(totalSupply() + _quantity <= mintableSupply, "Surpasses supply");
        _;
    }

    modifier hasCorrectAmount(uint256 _wei, uint256 _quantity) {
        require(_wei >= mintPrice(_quantity), "Insufficent funds");
        _;
    }

    function mintWhitelist(uint256 _quantity, bytes32[] calldata merkleProof)
        public
        payable
        whitelistSaleActive
        hasValidMerkleProof(merkleProof, whitelistMerkleRoot)
        hasCorrectAmount(msg.value, _quantity)
    {
        _mintGunner(_msgSender(), _quantity);
    }

    function mintPublic(uint256 _quantity)
        public
        payable
        publicSaleActive
        hasCorrectAmount(msg.value, _quantity)
    {
        _mintGunner(_msgSender(), _quantity);
    }

    function _mintGunner(address recipient, uint256 _quantity)
        private
        withinQuantityLimits(_quantity)
        withinMaximumSupply(_quantity)
    {
        for (uint256 i = 0; i < _quantity; i++) {
            supplyCounter.increment();
            _mint(recipient, totalSupply());
        }
    }

    function totalSupply() public view returns (uint256) {
        return supplyCounter.current();
    }

    function mintPrice(uint256 _quantity) public view returns (uint256) {
        if (totalSupply() + _quantity <= freeMintAmount) {
            return 0;
        }
        return SALE_PRICE * _quantity;
    }

    function setMintableSupply(uint256 _total) public onlyOwner {
        require(_total <= MAX_SUPPLY_ABSOLUTE, "Surpasses absolute maximum");
        require(_total >= totalSupply(), "Must be above total minted");
        mintableSupply = _total;
    }

    function setFreeMintTotal(uint256 _total) public onlyOwner {
        require(_total <= MAX_SUPPLY_ABSOLUTE, "Surpasses absolute maximum");
        require(_total >= totalSupply(), "Must be above total minted");
        freeMintAmount = _total;
    }

    /**
     * Gift a mint
     */
    function mintAdmin(address recipient, uint256 _quantity)
        public
        payable
        onlyOwner
    {
        _mintGunner(recipient, _quantity);
    }

    /**
     * Public and Whitelist Sale Toggle
     */
    bool public publicSale = false;
    bool public whitelistSale = false;

    modifier publicSaleActive() {
        require(publicSale, "Public sale has not started");
        _;
    }

    function setPublicSale(bool toggle) external onlyOwner {
        publicSale = toggle;
    }

    modifier whitelistSaleActive() {
        require(whitelistSale, "Whitelist has not started");
        require(!publicSale, "Public sale has started");
        _;
    }

    function setWhitelistSale(bool toggle) external onlyOwner {
        whitelistSale = toggle;
    }

    /**
     * Whitelist merkle root
     */
    bytes32 public whitelistMerkleRoot;

    modifier hasValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address not whitelisted"
        );
        _;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
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
     * Withdrawal (owner restricted)
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }
}
