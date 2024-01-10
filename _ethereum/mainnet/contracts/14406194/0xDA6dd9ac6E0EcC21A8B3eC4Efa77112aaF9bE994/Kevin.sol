// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./PaymentSplitter.sol";

contract Kevin is ERC721A, Ownable, PaymentSplitter {
    bool public saleIsActive = false;
    string private _baseURIextended;
    uint256 public constant MAX_SUPPLY = 2000;
    uint256 public constant PUBLIC_PRICE = 0.01 ether;

    constructor(address[] memory payees, uint256[] memory shares)
        ERC721A("Kevin", "KEVIN")
        PaymentSplitter(payees, shares)
    {}

    function mint(uint256 nMints)
        external
        payable
        checksIfSaleActive
        checksTotalSupply(nMints)
        checksPaymentValue(nMints)
    {
        uint256 numChunks = nMints / 5;
        uint256 remainder = nMints % 5;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, 5);
        }
        if (remainder != 0) {
            _safeMint(msg.sender, remainder);
        }
    }

    function mintTo(address to, uint256 nMints)
        external
        onlyOwner
        checksTotalSupply(nMints)
    {
        uint256 numChunks = nMints / 5;
        uint256 remainder = nMints % 5;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(to, 5);
        }
        if (remainder != 0) {
            _safeMint(to, remainder);
        }
    }

    function reserveMint(uint256 nMints)
        external
        onlyOwner
        checksTotalSupply(nMints)
    {
        uint256 numChunks = nMints / 5;
        uint256 remainder = nMints % 5;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, 5);
        }
        if (remainder != 0) {
            _safeMint(msg.sender, remainder);
        }
    }

    function release(address payable account) public override {
        require(
            msg.sender == account || owner() == msg.sender,
            "Withdraw account mismatch."
        );
        super.release(account);
    }

    function toggleSaleIsActive() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        require(bytes(baseURI_).length != 0, "Can't update to an empty value");
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIextended;
    }

    modifier checksIfSaleActive() {
        require(saleIsActive, "Public sale not active");
        _;
    }

    modifier checksTotalSupply(uint256 nMints) {
        require(totalSupply() + nMints <= MAX_SUPPLY, "Exceeds max supply");
        _;
    }

    modifier checksPaymentValue(uint256 nMints) {
        require(PUBLIC_PRICE * nMints <= msg.value, "Payment value incorrect");
        _;
    }
}
