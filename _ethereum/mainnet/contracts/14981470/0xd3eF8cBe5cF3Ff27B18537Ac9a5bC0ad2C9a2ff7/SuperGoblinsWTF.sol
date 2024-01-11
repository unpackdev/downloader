// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Address.sol";



contract SuperGoblinsWTF is ERC721A, Ownable {
    uint256 public constant RESERVED_SUPPLY = 1;
    uint256 public constant MAX_SUPPLY = 2000;
    uint256 public constant MAX_PER_WALLET = 20;
    uint256 public constant MAX_FREE_PER_TXN = 5;
    uint256 public constant MAX_PER_TXN = 10;

    constructor() ERC721A("SuperGoblinsWTF", "SGWTF") {}

    /**
     * Public sale mechanism
     */
    bool public publicSale = false;
    uint256 public freeRedeemed = 0;
    uint256 public MINT_PRICE = .005 ether;
    uint256 public FREE_SUPPLY = 1000;

    bool public reserved = false;

    function setPublicSale(bool toggle) external onlyOwner {
        publicSale = toggle;
    }

    function increaseFreeSupply(uint256 amount) external onlyOwner {
        require(amount > FREE_SUPPLY);
        FREE_SUPPLY = amount;
    }

    function decreasePrice(uint256 price) external onlyOwner {
        require(price < MINT_PRICE);
        MINT_PRICE = price;
    }

    /**
     * Public minting
     */
    mapping(address => uint256) public publicAddressMintCount;

    function mintFree5pTxn20Total(uint256 _quantity) public payable {
        require(msg.sender == tx.origin);
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Surpasses supply");
        require(
            publicAddressMintCount[msg.sender] + _quantity <= MAX_PER_WALLET,
            "Surpasses max per wallet"
        );
        require(_quantity <= MAX_FREE_PER_TXN, "Surpasses max free per txn");
        require(publicSale, "Public sale not started");
        require(
            freeRedeemed + _quantity <= FREE_SUPPLY,
            "Surpasses free supply"
        );

        publicAddressMintCount[msg.sender] += _quantity;
        freeRedeemed += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function mintPaid10Txn20Total(uint256 _quantity) public payable {
        require(msg.sender == tx.origin);
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Surpasses supply");
        require(
            publicAddressMintCount[msg.sender] + _quantity <= MAX_PER_WALLET,
            "Surpasses max per wallet"
        );
        require(publicSale, "Public sale not started");
        require(_quantity <= MAX_PER_TXN, "Surpasses max per txn");
        require(msg.value == MINT_PRICE * _quantity, "Invalid price");
        publicAddressMintCount[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function reserve() public onlyOwner {
        require(!reserved);
        reserved = true;
        _safeMint(msg.sender, RESERVED_SUPPLY);
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
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }
}
