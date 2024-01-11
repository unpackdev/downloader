//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./ERC721A.sol";

contract BoredGateFoolTheory is ERC721A, Ownable {
    using Strings for uint256;

    bool public mintActive;
    uint256 public constant maxSupply = 5555;
    uint256 public price = 0.005 ether;
    uint256 public maxPerTxn = 10;

    string public baseURI;
    uint256 public remainingFree = 1000;
    mapping (address => bool) freeMinted;
    mapping (address => bool) staffClaimed;

    constructor (string memory _baseURI) ERC721A("Bored Gate Fool Theory", "BGFT") {
        baseURI = _baseURI;
        _safeMint(msg.sender, 1);
    }

    modifier mintCompliance(uint256 amount) {
        require(totalSupply() + amount <= maxSupply, "Not enough tokens left");
        _;
    }

    function mint(uint256 amount) public payable mintCompliance(amount) {
        require(mintActive, "Sale is not active yet");
        require(amount <= maxPerTxn, "Exceeded the limit per Txn");
        require(msg.value >= price * amount, "Not enough ether sent");

        _safeMint(msg.sender, amount);
    }

    function freeMint() public payable mintCompliance(1) {
        require(mintActive, "Sale is not active yet");
        require(tx.origin == msg.sender, "The caller is another contract");
        require(remainingFree > 0, "Not enough free tokens left");
        require(!freeMinted[msg.sender],"Exceeded the limit per Address");

        remainingFree -= 1;
        freeMinted[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function staffMint() public payable {
        address staff1 = address(0x688d3c5C21c8240d93d11458A95e670281F2B6d1);
        address staff2 = address(0xC822646009E3f2e5f1Bdb6595197b093302F90dc);
        require(mintActive, "Sale is not active yet");
        require(msg.sender == owner() || msg.sender == staff1 || msg.sender == staff2, "You are not staff");
        require(!staffClaimed[msg.sender],"Exceeded the limit per Address");

        staffClaimed[msg.sender] = true;
        _safeMint(msg.sender, 25);
    }

    function setMintActive(bool status) public onlyOwner {
        mintActive = status;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawToken(IERC20 _token, uint256 _amount) public onlyOwner {
        _token.transferFrom(address(this), owner(), _amount);
    }
}