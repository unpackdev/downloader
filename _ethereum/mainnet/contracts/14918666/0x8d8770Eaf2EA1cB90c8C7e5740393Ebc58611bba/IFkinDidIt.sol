//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract IFkinDidIt is ERC721A, Pausable, Ownable {
    uint256 public constant MAX_SUPPLY = 2222;
    uint256 public constant MAX_MINTS_PER_TX = 20;
    uint256 public constant FREE_MINTS_PER_TX = 2;

    mapping(address => bool) public freeMinters;

    uint256 public mintPrice = .005 ether;
    uint256 public freeMintsAvailable = 1000;

    address private _founder1 = 0x92d10AE9D686e8EADfcFCAE73762525f9E95A80d;
    address private _founder2 = 0xF7cB5Da16aF09528e6Ea503F48Eb8ccDCE38F676;

    string private _tokenBaseURI;

    event Mint(uint256 totalMinted);
    event FreeMint(uint256 totalMinted, uint256 freeMintsAvailable);

    constructor(
        string memory tokenBaseURI_,
        uint256 quantity
    ) ERC721A("I Fkin Did It", "IFKINDIDIT") {
        _tokenBaseURI = tokenBaseURI_;
        _mint(_founder1, quantity);
        _mint(_founder2, quantity);
    }

    function mint(uint256 quantity) external payable whenNotPaused {
        require(quantity > 0 && quantity <= MAX_MINTS_PER_TX, "Invalid quantity.");
        require(msg.value >= quantity * mintPrice, "Wrong amount sent.");
        require(quantity + _totalMinted() <= MAX_SUPPLY, "Quantity unavailable.");
        _mint(msg.sender, quantity);
        emit Mint(_totalMinted());
    }

    function freeMint() external whenNotPaused {
        require(freeMintsAvailable > 0, "No more free mints.");
        require(!freeMinters[msg.sender], "Free minted already.");
        require(FREE_MINTS_PER_TX + _totalMinted() <= MAX_SUPPLY, "Quantity unavailable.");
        freeMinters[msg.sender] = true;
        freeMintsAvailable -= FREE_MINTS_PER_TX;
        _mint(msg.sender, FREE_MINTS_PER_TX);
        emit FreeMint(_totalMinted(), freeMintsAvailable);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    function setBaseURI(string memory tokenBaseURI_) external onlyOwner {
        _tokenBaseURI = tokenBaseURI_;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
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

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
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
