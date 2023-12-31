// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Chibae is Ownable, ERC721A, ReentrancyGuard {
    // Total Supply is 5555
    uint256 public maxSupply = 1000;

    bool public paused = true;
    string public baseURI;
    uint256 public price = 0.0019 ether;
    address private teamWallet = 0xc00fCD5e5c7D931b1d42b84bf9292b2D28B9Aec5;

    // For checking minted per wallet
    mapping(address => uint) public minted;

    constructor() ERC721A('Chibae', 'CHIBAE') {
        // Mint 50 to team wallet
        _safeMint(teamWallet, 50);
    }

    /** MINTING FUNCTIONS */

    /**
     * @dev Allows you to mint 10 tokens per transaction in public sale
     */
    function mint(uint _mintAmount) public nonReentrant payable {
        // Checks if wallet has minted
        require(tx.origin == _msgSender(), "Only EOA");
        require(!paused, "Sale is paused.");
        require(_mintAmount <= 10, "No more than 10 per tx.");
        require(minted[msg.sender] <= 10, "Max number of free mints reached!");
        require(totalSupply() + _mintAmount <= maxSupply, "Not enough mints left.");
        require(msg.value >= price * _mintAmount, "Not enough ether");

        minted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function setPause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}