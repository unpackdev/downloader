// contracts/Stamp.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract StampFactory is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    mapping (address => uint) public mincePerWallet;
    mapping (address => uint) public presaleMincePerWallet;

    uint public constant MAX_PRESALE_STAMPS = 30;

    uint public constant MINT_PRICE = 60000000000000000; // 0.06ETH
    uint public constant MAX_MINCE_PER_WALLET = 5;

    uint public constant PRESALE_MINT_PRICE = 40000000000000000; // 0.04ETH
    uint public constant MAX_PRESALE_MINCE_PER_WALLET = 3;

    uint public maxSupply;
    uint public presaleMints = 0;

    bool public saleActive = false;    
    bool public presaleActive = false;

    string public BASE_URI;

    constructor(string memory name, string memory symbol, uint _maxSupply) ERC721(name, symbol) {
        maxSupply = _maxSupply;
    }

    function withdrawEth() public onlyOwner {
        uint balance = address(this).balance;
        address payable owner = payable(owner());
        owner.transfer(balance);
    }

    function toggleSaleActive() public onlyOwner {
        presaleActive = false;
        saleActive = !saleActive;
    }

    function togglePresaleActive() public onlyOwner {
        saleActive = false;
        presaleActive = !presaleActive;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function _setBaseURI(string memory uri) internal {
        BASE_URI = uri;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        _setBaseURI(uri);
    }

    function presaleMintStamp(uint count) public payable {
        require(msg.value >= PRESALE_MINT_PRICE.mul(count), "Not enough ETH");
        require(presaleActive, "Presale is not active");
        require(totalSupply().add(count) <= maxSupply, "All stamps minted");
        require(presaleMints.add(count) <= MAX_PRESALE_STAMPS, "All presale stamps minted");
        require(presaleMincePerWallet[msg.sender].add(count) <= MAX_PRESALE_MINCE_PER_WALLET, "You hit the presale mint limit");

        for(uint i = 0; i < count; i++) {
            uint tokenId = totalSupply();
            _safeMint(msg.sender, tokenId);
            presaleMincePerWallet[msg.sender] += 1;
            presaleMints += 1;
        }
    }

    function mintStamp(uint count) public payable {
        require(msg.value >= MINT_PRICE.mul(count), "Not enough ETH");
        require(saleActive, "Sale is not active");
        require(totalSupply().add(count) <= maxSupply, "All stamps minted");
        require(mincePerWallet[msg.sender].add(count) <= MAX_MINCE_PER_WALLET, "You hit the mint limit");

        for(uint i = 0; i < count; i++) {
            uint tokenId = totalSupply();
            _safeMint(msg.sender, tokenId);
            mincePerWallet[msg.sender] += 1;
        }
    }

    function adminMint(uint count) public onlyOwner {
        require(totalSupply().add(count) <= maxSupply, "All stamps minted");

        for(uint i = 0; i < count; i++) {
            uint tokenId = totalSupply();
            _safeMint(msg.sender, tokenId);
        }
    }
}