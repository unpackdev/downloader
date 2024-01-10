//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./PaymentSplitter.sol";
import "./SafeMath.sol";

contract NFT is ERC721A, Ownable, Pausable, PaymentSplitter {
    using SafeMath for uint256;

    uint256 constant public maxSupply = 333;
    uint256 constant public max = 5;
    uint256 public price = 0.15 ether;

    string public baseTokenURI;

    uint256[] private _shares = [85, 15];
    address[] private _shareholders = [
        0x74135276BE855a16a76DC27b34f357272979E1F9,
        0x42cf4F70Dc37d84F74f26801498216DaeC3b8646
    ];

    constructor() ERC721A("0xPGodjira", "0xPGJ") PaymentSplitter(_shareholders, _shares) {
        _pause();
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 334;
    }

    modifier enoughSupply(uint256 _amount) {
        require(_totalMinted().add(_amount) <= maxSupply, "Minting would exceed max supply");
        _;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        for (uint256 sh; sh < _shareholders.length; sh++) {
            address payable wallet = payable(_shareholders[sh]);
            release(wallet);
        }
    }

    function mint(uint _amount) external payable whenNotPaused enoughSupply(_amount) {
        require(msg.value >= price.mul(_amount), "Not enough ETH");
        require(_numberMinted(msg.sender).add(_amount) <= max, "Minting would exceed address allowance");
        _safeMint(msg.sender, _amount);
    }

    function teamMint(uint _amount) external onlyOwner enoughSupply(_amount) {
        _safeMint(msg.sender, _amount);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        price  = _mintPrice;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}