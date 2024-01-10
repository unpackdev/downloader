// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract EVERYBODY_LOTTERY_2 is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public MAX_ARTS = 111;
    uint256 public price = 0.05 ether;
    uint256 public constant MAX_PER_MINT = 4;
    
    string public baseTokenURI;
    mapping(address => uint256) private _totalClaimed;
    mapping(address => uint256) private _allowList;

    constructor(
        string memory baseURI, 
        address[] memory addresses
    ) ERC721("EVERYBODY LOTTERY 2", "E LOTTERY 2")
    {
        baseTokenURI = baseURI;

        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = 1;
        }
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

    function setMaxArt(uint256 max) external onlyOwner {
        MAX_ARTS = max;
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

    function setAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = 1;
        }
    }

    function claim() external {
        uint256 _nextTokenId = totalSupply();

        require(_allowList[msg.sender] >= 1, "Address not in Whitelist or already Claim");

        _allowList[msg.sender] = 0;
        _safeMint(msg.sender, _nextTokenId);
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