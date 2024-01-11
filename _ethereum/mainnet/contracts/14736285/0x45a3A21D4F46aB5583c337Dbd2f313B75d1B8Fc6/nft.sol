// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";

contract wavegmi is ERC721A, ERC721ABurnable, Ownable,ReentrancyGuard {
    using SafeMath for uint256;

    uint256 private constant COLLECTIONS_SIZE = 444;
    uint256 public constant MAX_PER_WALLET = 4;
    uint256 public constant PUBLIC_MAX_MINT = 2;
    uint256 public constant MAX_AIRDROP_AMOUNT = 44; // giveways and marketing
    
    uint256 public NFTPrice = 500000000000000000;  // 0.5 ETH
    bool public isActive = false;  
    
    uint256 private _refundsUntil = 1652608800; // 15th May 2022; 10:00 AM GMT
    string private _baseTokenURI;


    constructor() ERC721A("Wave", "WAVE") {}


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function mint(uint256 quantity) external payable {
        require(isActive, 'sale is not active yet');
        require(quantity <= PUBLIC_MAX_MINT, 'can not purchase this many tokens');
        require(numberMinted(msg.sender) + quantity <= MAX_PER_WALLET,"quantity exceeds public limit");
        require(totalSupply() + quantity <= COLLECTIONS_SIZE, "reached max supply");
        require(NFTPrice.mul(quantity) == msg.value, "ether value sent is not correct");
        _safeMint(msg.sender, quantity);
    }

    function refund(uint256 tokenId) external nonReentrant {
        require(block.timestamp < _refundsUntil, 'refund period expired');
        TokenOwnership memory owner = _ownershipOf(tokenId);
        if (owner.addr != msg.sender) revert TransferFromIncorrectOwner();
        (bool success, ) = msg.sender.call{value: 500000000000000000}("");
        require(success, "transfer failed.");
        _burn(tokenId);
    }

   function startSale(bool _isActive) external onlyOwner {
        isActive = _isActive;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function airdrop(uint256 quantity, address to) external onlyOwner {
        require(isActive, 'sale is not active yet');
        require(totalSupply() + quantity <= COLLECTIONS_SIZE, "reached max supply");
        require(numberMinted(msg.sender) + quantity <= MAX_AIRDROP_AMOUNT,"quantity exceeds airdrop limit");
        _safeMint(to,quantity);
    }


    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "transfer failed.");
    }

    function extend_refund_period(uint256 newdate) external onlyOwner {
        require(_refundsUntil < newdate, 'new refund period needs to be later than the current one');
        require(1672531200 > newdate, 'new refund period can not be later than 01/01/23'); // 01/01/2023 12:00AM GMT
        _refundsUntil = newdate;
    }
}