// SPDX-License-Identifier: MIT

//
// __     __  __            __  __        __            ________         __                            __           
///  |   /  |/  |          /  |/  |      /  |          /        |       /  |                          /  |          
//$$ |   $$ |$$/   _______ $$/ $$ |____  $$ |  ______  $$$$$$$$/______  $$/   ______   _______    ____$$ |  _______ 
//$$ |   $$ |/  | /       |/  |$$      \ $$ | /      \ $$ |__  /      \ /  | /      \ /       \  /    $$ | /       |
//$$  \ /$$/ $$ |/$$$$$$$/ $$ |$$$$$$$  |$$ |/$$$$$$  |$$    |/$$$$$$  |$$ |/$$$$$$  |$$$$$$$  |/$$$$$$$ |/$$$$$$$/ 
// $$  /$$/  $$ |$$      \ $$ |$$ |  $$ |$$ |$$    $$ |$$$$$/ $$ |  $$/ $$ |$$    $$ |$$ |  $$ |$$ |  $$ |$$      \ 
//  $$ $$/   $$ | $$$$$$  |$$ |$$ |__$$ |$$ |$$$$$$$$/ $$ |   $$ |      $$ |$$$$$$$$/ $$ |  $$ |$$ \__$$ | $$$$$$  |
//   $$$/    $$ |/     $$/ $$ |$$    $$/ $$ |$$       |$$ |   $$ |      $$ |$$       |$$ |  $$ |$$    $$ |/     $$/ 
//    $/     $$/ $$$$$$$/  $$/ $$$$$$$/  $$/  $$$$$$$/ $$/    $$/       $$/  $$$$$$$/ $$/   $$/  $$$$$$$/ $$$$$$$/  
//                                                                                                                  
//                                                                                                                  
//                                                                                                                 
pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "./Ownable.sol";

contract VisibleFriends is ERC721A, Ownable {
    string _baseUri;
    string _contractUri;
    
    uint public maxSupply = 5000;
    uint public price = 0.08 ether;
    uint public maxFreeMint = 100;
    uint public maxFreeMintPerWallet = 10;
    uint public salesStartTimestamp = 1645826400;
    
    mapping(address => uint) public addressToFreeMinted;

    constructor() ERC721A("Visible Friends", "VSBLE") {
        _contractUri = "ipfs://QmV9J8H43fGaqckGi96qqQkipqkQncscSvVCCnpqVmejSB";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
    
    function freeMint(uint quantity) external {
        require(isSalesActive(), "sale is not active");
        require(totalSupply() + quantity <= maxFreeMint, "theres no free mints remaining");
        require(addressToFreeMinted[msg.sender] + quantity <= maxFreeMintPerWallet, "caller already minted for free");
        
        addressToFreeMinted[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }
    
    function mint(uint quantity) external payable {
        require(isSalesActive(), "sale is not active");
        require(quantity <= 50, "max mints per transaction exceeded");
        require(totalSupply() + quantity <= maxSupply, "sold out");
        require(msg.value >= price * quantity, "ether sent is under price");
        
        _safeMint(msg.sender, quantity);
    }

    function updateFreeMint(uint maxFree, uint maxPerWallet) external onlyOwner {
        maxFreeMint = maxFree;
        maxFreeMintPerWallet = maxPerWallet;
    }
    
    function updateMaxSupply(uint newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    function isSalesActive() public view returns (bool) {
        return salesStartTimestamp <= block.timestamp;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseUri = newBaseURI;
    }
    
    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractUri = newContractURI;
    }
    
    function setSalesStartTimestamp(uint newTimestamp) external onlyOwner {
        salesStartTimestamp = newTimestamp;
    }
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}