//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ReentrancyGuard.sol";

contract UNDW3Collection is Ownable, ERC721A, ReentrancyGuard {
    uint256 public maxSupply = 11212;
    uint256 public maxFreeSupply = 1000;

    uint256 public maxPerTxDuringMint = 10;
    uint256 public maxPerAddressDuringMint = 100;
    uint256 public maxPerAddressDuringFreeMint = 1;

    uint256 public price = 0.04 ether;

    string private _baseTokenURI;

    mapping(address => uint256) public freeMintedAmount;
    mapping(address => uint256) public mintedAmount;

    constructor() ERC721A("UNDW3 Lacoste", "UNDW3") {
        _safeMint(msg.sender, 100);
    }

    modifier mintCompliance() {
        require(tx.origin == msg.sender, "Wrong Caller");
        _;
    }

    function MintNFT(uint256 _quantity) external payable mintCompliance {
        require(msg.value >= price * _quantity, "GDZ: Insufficient Fund.");
        require(
            maxSupply >= totalSupply() + _quantity,
            "GDZ: Exceeds max supply."
        );
        uint256 _mintedAmount = mintedAmount[msg.sender];
        require(
            _mintedAmount + _quantity <= maxPerAddressDuringMint,
            "GDZ: Exceeds max mints per address!"
        );
        require(
            _quantity > 0 && _quantity <= maxPerTxDuringMint,
            "Invalid mint amount."
        );
        mintedAmount[msg.sender] = _mintedAmount + _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function freeMint(uint256 _quantity) external mintCompliance {
        require(
            maxFreeSupply >= totalSupply() + _quantity,
            "GDZ: Exceeds max supply."
        );
        uint256 _freeMintedAmount = freeMintedAmount[msg.sender];
        require(
            _freeMintedAmount + _quantity <= maxPerAddressDuringFreeMint,
            "GDZ: Exceeds max free mints per address!"
        );
        freeMintedAmount[msg.sender] = _freeMintedAmount + _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxPerTx(uint256 _amount) external onlyOwner {
        maxPerTxDuringMint = _amount;
    }

    function setMaxPerAddress(uint256 _amount) external onlyOwner {
        maxPerAddressDuringMint = _amount;
    }

    function setMaxFreePerAddress(uint256 _amount) external onlyOwner {
        maxPerAddressDuringFreeMint = _amount;
    }

    function cutMaxSupply(uint256 _amount) public onlyOwner {
        require(
            maxSupply - _amount >= totalSupply(),
            "Supply cannot fall below minted tokens."
        );
        maxSupply -= _amount;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool succ, ) = payable(owner()).call{value: address(this).balance}("");
        require(succ, "transfer failed");
    }
}
