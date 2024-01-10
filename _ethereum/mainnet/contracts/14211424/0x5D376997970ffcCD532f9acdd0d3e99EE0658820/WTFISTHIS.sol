// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
// npx hardhat verify --network mainnet DEPLOYED_CONTRACT_ADDRESS "Constructor argument 1"
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract WTFISTHIS is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_ARTS = 88;
    uint256 public price = 0.05 ether;
    uint256 public constant MAX_PER_MINT = 4;
    
    string public baseTokenURI;
    mapping(address => uint256) private _totalClaimed;

    constructor(string memory baseURI) ERC721("EVERYBODY LOTTERY 1", "E LOTTERY 1")
    {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setPrice(uint256 p) external onlyOwner {
        price = p;
    }

    function airdrop(address receiver, uint256 amountOfArts)
        external
        onlyOwner 
    {
        uint256 _nextTokenId = totalSupply();
        for (uint256 i = 0; i < amountOfArts; i++) {
            _safeMint(receiver, _nextTokenId++);
        }
    }

    function mint(uint256 amountOfArts) external payable {
        require(totalSupply() < MAX_ARTS, "All tokens have been minted");
        require(amountOfArts > 0, "at least 1");
        require(
            amountOfArts <= MAX_PER_MINT,
            "exceeds max"
        );
        require(
            totalSupply() + amountOfArts <= MAX_ARTS,
            "exceed supply"
        );
        require(
            _totalClaimed[msg.sender] + amountOfArts <= MAX_PER_MINT,
            "exceed per address"
        );
        require(price * amountOfArts == msg.value, "wrong ETH amount");
        uint256 _nextTokenId = totalSupply();
        for (uint256 i = 0; i < amountOfArts; i++) {
            _safeMint(msg.sender, _nextTokenId++);
        }
        _totalClaimed[msg.sender] += amountOfArts;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "no balance");
        _widthdraw(owner(), address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "failed withdraw");
    }
}