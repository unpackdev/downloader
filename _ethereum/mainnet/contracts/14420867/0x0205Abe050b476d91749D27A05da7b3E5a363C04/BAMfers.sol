// SPDX-License-Identifier: MIT
// Creators: Chiru Labs

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

error QuantityToMintTooHigh();
error MaxSupplyExceeded();
error FreeMintReserveExceeded();
error InsufficientFunds();
error SaleIsNotActive();
error TheCallerIsAnotherContract();

contract BAMfers is ERC721A, Ownable, ReentrancyGuard {
    string public constant PROVENANCE =
        "7468c91ddf3ff60cf14cc8fd0abe0c042c3337c94c1434c7b88b2874a9efaedd";
    uint256 public constant MAX_PURCHASE_PER_TX = 20;
    uint256 public constant MAX_BAMFERS = 3333;
    uint256 public constant BAMFERS_PRICE = 0.01 ether;
    uint256 public constant MAX_FREE_MINT_RESERVE = 333;

    string private _uriPrefix = "";
    uint256 private _freeMintCount = 0;
    bool public saleIsActive = false;

    constructor(string memory baseUri) ERC721A("BAMfers", "BAMFERS") {
        setBaseUri(baseUri);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _uriPrefix;
    }

    modifier mintCompliance(uint256 quantity) {
        if (!saleIsActive) revert SaleIsNotActive();
        if (quantity > MAX_PURCHASE_PER_TX) revert QuantityToMintTooHigh();
        if (totalSupply() + quantity > MAX_BAMFERS) revert MaxSupplyExceeded();
        _;
    }

    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert TheCallerIsAnotherContract();
        _;
    }

    function mint(uint256 quantity)
        public
        payable
        callerIsUser
        nonReentrant
        mintCompliance(quantity)
    {
        if (msg.value < BAMFERS_PRICE * quantity) revert InsufficientFunds();

        _safeMint(_msgSender(), quantity, "");
    }

    function freeMintReserve() public view returns (uint256) {
        unchecked {
            return MAX_FREE_MINT_RESERVE - _freeMintCount;
        }
    }

    function freeMint(uint256 quantity)
        public
        callerIsUser
        nonReentrant
        mintCompliance(quantity)
    {
        if (_freeMintCount + quantity > MAX_FREE_MINT_RESERVE)
            revert FreeMintReserveExceeded();

        _safeMint(_msgSender(), quantity, "");

        unchecked {
            _freeMintCount += quantity;
        }
    }

    function setBaseUri(string memory newBaseUri) public onlyOwner {
        _uriPrefix = newBaseUri;
    }

    function changeSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
