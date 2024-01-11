// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

//  ___             
//  [___]       _  
//  |  ~|     =)_)= 
//  |   |      (_(           _                     _                      ___                  
//  |   |      )_)          | |    __ ___   ____ _| |_ ___  _ __ _   _   / _ \ _ __   ___  ___ 
//  \___|                   | |   / _` \ \ / / _` | __/ _ \| '__| | | | | | | | '_ \ / _ \/ __|
//   |  `========,          | |__| (_| |\ V / (_| | || (_) | |  | |_| | | |_| | | | |  __/\__ \
//  __`.        .'______    |_____\__,_| \_/ \__,_|\__\___/|_|   \__, |  \___/|_| |_|\___||___/
//      `.    .'                                                  |___/                        
//      _|    |_...    
//     (________);;;; 
//          :::::::' 

contract LavatoryOnes is Ownable, ERC721A, ReentrancyGuard {

    string public baseURI;

    uint256 public constant MAX_SUPPLY = 4444;
    uint256 public constant PRICE = 0.02 ether;
    uint256 private constant PRICE_MAX_MINT = 0.015 ether;
    uint256 private constant MAX_MINT_PER_TX = 10;
    uint256 private constant MAX_FREE_MINT_PER_TX = 3;
    
    bool public paused = false;
    uint256 public freeMintsLeft = 444;

    address creator1 = 0x02e2d629498acd54d9F222a6e0024AB64AB14A8b;
    address creator2 = 0x5f91B7E67613e6F19f9C6Eadf2640521Ab975EfD;
    address creator3 = 0x50d03190B6726f90695EeBb0D974D2e4bfC49763;
    address creator4 = 0x0cC0fc1E6817619206c1A24324A7A791f60d66A7;

    constructor(string memory _newBaseURI) ERC721A("Lavatory Ones", "LONES") {
        baseURI = _newBaseURI;
    }

    function mint(uint256 _quantity) external payable nonReentrant {
        uint256 totalSupply = totalSupply();
        require(!paused, "Sale paused");
        require(_quantity > 0, "Mint at least 1");
        require(totalSupply + _quantity <= MAX_SUPPLY, "Exceeds maximum supply");
        
        if (msg.sender == owner()) {
            _safeMint(msg.sender, _quantity);
            return;
        }

        require(_quantity <= MAX_MINT_PER_TX, "Exceeds maximum mint amount");

        uint256 price = (_quantity == MAX_MINT_PER_TX) ? (PRICE_MAX_MINT * _quantity) : (PRICE * _quantity);

        if (_quantity <= freeMintsLeft && _quantity <= MAX_FREE_MINT_PER_TX) {
            price = 0;
            freeMintsLeft -= _quantity;
            require(freeMintsLeft >= 0, "Free mints exceeded");
        }

        require(msg.value >= price, "Value sent is too low");

        _safeMint(msg.sender, _quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function setFreeMintsLeft(uint256 _freeMints) external onlyOwner {
        freeMintsLeft = _freeMints;
    }

    function withdraw() external onlyOwner {
        uint256 share1 = address(this).balance * 30 / 100;
        uint256 share2 = address(this).balance * 25 / 100;
        uint256 share3 = address(this).balance * 25 / 100;
        uint256 share4 = address(this).balance * 20 / 100;

        (bool success1, ) = payable(creator1).call{value: share1}("");
        require(success1);

        (bool success2, ) = payable(creator2).call{value: share2}("");
        require(success2);

        (bool success3, ) = payable(creator3).call{value: share3}("");
        require(success3);

        (bool success4, ) = payable(creator4).call{value: share4}("");
        require(success4);
    }
}