pragma solidity ^0.8.17;

/** 

 https://x.com/_KawaiiWarriors

*/

import "./ERC721A.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./DefaultOperatorFilterer.sol";

error NonExistentTokenURI();
error WithdrawTransfer();

contract KawaiiWarriors is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Strings for uint256;

    string public baseURI;
    uint256 public constant MAX_SUPPLY = 5_000;
    uint256 public mintPrice = 0.0069 ether;
    mapping(address => bool) freeMint;
    bool public paused = true;

    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721A(_name, _symbol) {
        baseURI = _baseURI;
    }

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) nonReentrant isUser {
        require(!paused, "Mint not open yet!");

        if (freeMint[_msgSender()]) {
            // Free mint used up
            require(msg.value >= _mintAmount * mintPrice, "Insufficient Funds!");
        } else {
            // Update price include a free mint
            require(msg.value >= (_mintAmount - 1) * mintPrice, "Insufficient Funds!");
            freeMint[_msgSender()] = true;
        }

        _safeMint(_msgSender(), _mintAmount);
    }

    function devMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) nonReentrant onlyOwner {
        _safeMint(_msgSender(), _mintAmount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert NonExistentTokenURI();
        }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function setURI(string memory newuri) public onlyOwner {
        baseURI = newuri;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setPrice(uint256 _price) public onlyOwner {
        mintPrice = _price;
    }

    function isFreeAvailable() public view returns (bool) {
        return !freeMint[_msgSender()];
    }

    function withdrawPayments(address payable payee) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool transferTx,) = payee.call{value: balance}("");
        if (!transferTx) {
            revert WithdrawTransfer();
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    modifier isUser() {
        require(tx.origin == msg.sender, "Invalid User");
        _;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount <= 10, "Max 10 per transaction");
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Max Supply Exceeded!");
        _;
    }
}
