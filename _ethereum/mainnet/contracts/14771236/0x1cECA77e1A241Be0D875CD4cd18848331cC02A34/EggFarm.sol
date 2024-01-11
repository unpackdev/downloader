// SPDX-License-Identifier: MIT
//

// $$$$$$$$\                    $$$$$$$$\                               
// $$  _____|                   $$  _____|                              
// $$ |      $$$$$$\   $$$$$$\  $$ |   $$$$$$\   $$$$$$\  $$$$$$\$$$$\  
// $$$$$\   $$  __$$\ $$  __$$\ $$$$$\ \____$$\ $$  __$$\ $$  _$$  _$$\ 
// $$  __|  $$ /  $$ |$$ /  $$ |$$  __|$$$$$$$ |$$ |  \__|$$ / $$ / $$ |
// $$ |     $$ |  $$ |$$ |  $$ |$$ |  $$  __$$ |$$ |      $$ | $$ | $$ |
// $$$$$$$$\\$$$$$$$ |\$$$$$$$ |$$ |  \$$$$$$$ |$$ |      $$ | $$ | $$ |
// \________|\____$$ | \____$$ |\__|   \_______|\__|      \__| \__| \__|
//          $$\   $$ |$$\   $$ |                                        
//          \$$$$$$  |\$$$$$$  |                                        
//            \______/  \______/                                         
//
//
//
//   ____       _     _           _____  ___ _  __
//  / ___| ___ | | __| |  _____  |___ / / _ (_)/ /
// | |  _ / _ \| |/ _` | |_____|   |_ \| | | |/ /
// | |_| | (_) | | (_| | |_____|  ___) | |_| / /_
//  \____|\___/|_|\__,_|         |____/ \___/_/(_)
//  ____  _ _                          _ ____ _  __
// / ___|(_) |_   _____ _ __   _____  / | ___(_)/ /
// \___ \| | \ \ / / _ \ '__| |_____| | |___ \ / /
//  ___) | | |\ V /  __/ |    |_____| | |___) / /_
// |____/|_|_| \_/ \___|_|            |_|____/_/(_)
//  ____                                         ____ _  __
// | __ ) _ __ ___  _ __  _______ _ __   _____  | ___(_)/ /
// |  _ \| '__/ _ \| '_ \|_  / _ \ '__| |_____| |___ \ / /
// | |_) | | | (_) | | | |/ /  __/ |    |_____|  ___) / /_
// |____/|_|  \___/|_| |_/___\___|_|            |____/_/(_)
//
// Feel free to copy. This is the beauty of blockchain!

pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract EggFarm is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string _baseUri;
    string _contractUri;

    uint public price = 0.003 ether;
    uint public constant MAX_SUPPLY = 20000;
    uint public maxFreeMint = 2000;
    bool public isSalesActive = true;
    uint public maxFreeMintPerWallet = 200;
    uint public maxNormalMintPerTx = 35;

    mapping(address => uint) public addressToFreeMinted;

    constructor() ERC721("EggFarm", "EGGF") {
        _contractUri = "ipfs://";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function freeMint(uint quantity) external {
        require(isSalesActive, "EggFarm sale is not active yet");
        require(totalSupply() + quantity <= MAX_SUPPLY, "EggFarm Sold Out");
        require(totalSupply() < maxFreeMint, "There's no more free mint left");
        require(addressToFreeMinted[msg.sender] < maxFreeMintPerWallet, "Sorry, already minted for free");

        addressToFreeMinted[msg.sender] += quantity;

        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }

    function mint(uint quantity) external payable {
        require(isSalesActive, "EggFarm sale is not active yet");
        require(quantity <= maxNormalMintPerTx, "max mints per transaction exceeded");
        require(totalSupply() + quantity <= MAX_SUPPLY, "EggFarm Sold Out");
        require(msg.value >= price * quantity, "ether send is under price");

        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
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

    function toggleSales() external onlyOwner {
        isSalesActive = !isSalesActive;
    }

    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }

    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
