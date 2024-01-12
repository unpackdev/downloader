// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721Burnable.sol";

contract ETHSMOKESHOP is Ownable, ERC721A, ReentrancyGuard {
    uint256 public immutable MAX_SUPPLY = 10000;
    uint256 public constant PRICE = 0.1 ether;
    bool public _isActive = false;

    mapping(address => uint256) public _amountCounter;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721A(name, symbol) {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // set if contract is active or not
    function setActive(bool isActive) external onlyOwner {
        _isActive = isActive;
    }

    // metadata URI
    string private _baseTokenURI;
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    //withdraw to owner wallet
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // public mint
    function publicSaleMint(uint256 quantity,address to)
        external
        payable
        nonReentrant
        callerIsUser
    {
        require(quantity > 0, "Please mint more than 0 tokens");
        require(_isActive, "Public sale has not begun yet");
        require(PRICE * quantity == msg.value, "Incorrect funds");
        require(totalSupply() + quantity <= MAX_SUPPLY,"Would exceed max supply");
        _amountCounter[msg.sender] = _amountCounter[msg.sender] + quantity;
        _safeMint(to, quantity);
    }
}