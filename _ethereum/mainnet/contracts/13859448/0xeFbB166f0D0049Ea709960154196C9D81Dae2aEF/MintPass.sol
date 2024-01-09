// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./Ownable.sol";

contract GuildedGodsMintPass is ERC1155, Ownable, ERC1155Burnable {

    string _contractUri;
    uint _tokenCounter;

    uint public constant MAX_SUPPLY = 6666;
    uint public price;
    uint public maxFreeMints;
    uint public maxFreeMintsPerWallet;
    bool public isSalesActive;

    mapping(address => uint) public addressToFreeMinted;

    constructor() ERC1155("ipfs://QmNqwyZjfHhRwyr3gyknpc9xYzhVJJVVgd9jZ4nDzR7moZ/{id}.json") {
        price = 0.06 ether;
        maxFreeMints = 1250;
        maxFreeMintsPerWallet = 3;
        isSalesActive = false;
        _contractUri = "ipfs://QmTq75TtkExq178yaKDsK3SnE7Lpj2P9CSzq1f83tLZJvH";
    }

    function name() external pure returns (string memory) {
        return "Guilded Gods Mint Pass";
    }

    function symbol() external pure returns (string memory) {
        return "GG";
    }

    function freeMint() external {
        require(isSalesActive, "sale is not active");
        require(totalSupply() < maxFreeMints, "theres no free mints remaining");
        require(addressToFreeMinted[msg.sender] < maxFreeMintsPerWallet, "no remaining free tokens to mint");
        
        addressToFreeMinted[msg.sender]++;
        mint(msg.sender, 1);
    }
    
    function mint(uint amount) external payable {
        require(isSalesActive, "sale is not active");
        require(totalSupply() + amount <= MAX_SUPPLY, "sold out");
        require(msg.value >= price * amount, "ether send is under price");
        
        mint(msg.sender, amount);
    }

    function mint(address account, uint256 amount) internal {
        _mint(account, 0, amount, "");
        _tokenCounter += amount;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function totalSupply() public view returns (uint) {
        return _tokenCounter;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractUri = newContractURI;
    }
    
    function toggleSales() external onlyOwner {
        isSalesActive = !isSalesActive;
    }
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function withdraw(uint amount) external onlyOwner {
        require(payable(msg.sender).send(amount));
    }
    
    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}