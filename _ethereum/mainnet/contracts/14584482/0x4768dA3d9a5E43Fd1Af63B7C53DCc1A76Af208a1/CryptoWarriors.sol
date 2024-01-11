pragma solidity ^0.8.4;

import "./ERC721AQueryable.sol";

import "./Pausable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./console.sol";

contract CryptoWarriors is ERC721AQueryable, Pausable, Ownable {
    using Strings for uint256;
    uint256 public constant MAX_PER_ADDRESS = 5;
    uint256 public constant MAX_SUPPLY = 3000;

    string private _baseTokenURI;
    uint256 public price = 0.04 ether;

    modifier callerIsNotContract() {
      require(tx.origin == msg.sender, "The caller is another contract");
      _;
    }

    constructor(string memory baseURI_) ERC721A("CryptoWarriors", "CryptoWarriors") {
        _baseTokenURI = baseURI_;
        pause();
    }

    function setPrice(uint256 price_) public onlyOwner{
        price = price_;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function baseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function mint(uint256 amount) external payable callerIsNotContract whenNotPaused{
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(balanceOf(msg.sender) + amount <= MAX_PER_ADDRESS, "Exceed max buy per address");
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceed max token supply");
        require(msg.value >= amount * price, "Not enough ETH");
        _safeMint(msg.sender, amount);
    }

    function reserveMint(uint256 amount) public onlyOwner{
         _safeMint(msg.sender, amount);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw(address to,uint256 amount) external onlyOwner {
        // uint256 balance = address(this).balance;
        payable(to).transfer(amount);
    }
}