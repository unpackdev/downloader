// SPDX-License-Identifier: MIT

//
//  ______ _          _  ______       _    _ 
//  | ___ (_)        | | | ___ \     | |  (_)
//  | |_/ /___  _____| | | |_/ / ___ | | ___ 
//  |  __/| \ \/ / _ \ | | ___ \/ _ \| |/ / |
//  | |   | |>  <  __/ | | |_/ / (_) |   <| |
//  \_|   |_/_/\_\___|_| \____/ \___/|_|\_\_|
//                                         
//  Free degen Project. Feel free to copy our contract, the world is decentralized!                                         

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

contract PixelBoki is ERC721A, Ownable {
    string _baseUri;
    string _contractUri;
    
    uint public price = 0.00 ether;
    uint public maxFreeMint = 1;
    uint public maxFreeMintPerWallet = 1;
    uint public salesStartTimestamp = 1644812836;
    uint public maxSupply = 3420;
    
    mapping(address => uint) public addressToFreeMinted;

    constructor() ERC721A("Pixel Boki", "PBK") {
        _contractUri = "ipfs://QmcATHBdoiiDXxBXWDw4GdcJwW28aFBBVYYgbBhAaDVZzb";
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
        require(quantity <= 20, "max mints per transaction exceeded");
        require(totalSupply() + quantity <= maxSupply, "sold out");
        require(msg.value >= price * quantity, "ether send is under price");
        
        _safeMint(msg.sender, quantity);
    }
    
    function batchMint(address[] memory receivers, uint[] memory quantities) external onlyOwner {
        require(receivers.length == quantities.length, "receivers and quantities must be the same length");
        for (uint i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], quantities[i]);
        }
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