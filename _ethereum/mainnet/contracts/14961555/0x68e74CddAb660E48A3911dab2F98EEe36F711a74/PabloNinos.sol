//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract PabloNinos is ERC721A, Pausable, Ownable {
    uint256 public constant MAX_SUPPLY = 6969;

    uint256 public mintPrice = .0069 ether;
    uint256 public maxMintsPerTx = 20;
    uint256 public freeMintsPerTx = 3;
    uint256 public freeMintsAvailable = 3480;

    string private _tokenBaseURI;
    address private _founder1 = 0x9186e9B8BdF0d6d9014Bbf1D359965d086168BdA;
    address private _founder2 = 0xB2B964AF6991bCfd6B3a24101636aD9F5fCE59a4;

    mapping(address => bool) public freeMinters;

    constructor(string memory tokenBaseURI_) ERC721A("pabloninos.lol", "PABLONINOSLOL") {
        _tokenBaseURI = tokenBaseURI_;
        _pause();
    }

    function mint(uint256 quantity) external payable whenNotPaused {
        require(quantity > 0 && quantity <= maxMintsPerTx, "Invalid quantity.");
        require(msg.value >= quantity * mintPrice, "Wrong amount sent.");
        require(quantity + _totalMinted() <= MAX_SUPPLY, "Quantity unavailable.");
        _mint(msg.sender, quantity);
    }

    function freeMint() external whenNotPaused {
        require(freeMintsAvailable > 0, "No more free mints.");
        require(!freeMinters[msg.sender], "Free minted already.");
        require(freeMintsPerTx + _totalMinted() <= MAX_SUPPLY, "Quantity unavailable.");
        freeMinters[msg.sender] = true;
        freeMintsAvailable -= freeMintsPerTx;
        _mint(msg.sender, freeMintsPerTx);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    function setTokenBaseURI(string memory tokenBaseURI_) external onlyOwner {
        _tokenBaseURI = tokenBaseURI_;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxMintsPerTx(uint256 _maxMintsPerTx) external onlyOwner {
        maxMintsPerTx = _maxMintsPerTx;
    }

    function setFreeMintsPerTx(uint256 _freeMintsPerTx) external onlyOwner {
        freeMintsPerTx = _freeMintsPerTx;
    }

    function setFreeMintsAvailable(uint256 _freeMintsAvailable) external onlyOwner {
        freeMintsAvailable = _freeMintsAvailable;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        uint256 half = address(this).balance / 2;
        (bool withdrawal1, ) = _founder1.call{value: half}("");
        require(withdrawal1, "Withdrawal 1 failed");
        (bool withdrawal2, ) = _founder2.call{value: half}("");
        require(withdrawal2, "Withdrawal 2 failed");
    }

    receive() external payable {}
}
