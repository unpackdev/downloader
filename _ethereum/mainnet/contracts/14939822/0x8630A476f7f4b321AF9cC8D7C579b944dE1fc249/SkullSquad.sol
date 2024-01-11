// SPDX-License-Identifier: MIT
/** 
SKULL
*/

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract SkullSquad is ERC721Enumerable, Ownable {

    using Strings for uint256;
    
    uint256 public totalSkulls = 3333;
    uint256 public tokenPrice = 80000000000000000;

    string public baseUrl = "https://www.theskullsquad.com/tokens/";

    bool public tokensAvailable = false;
    
    constructor() ERC721("The Skull Squad", "SKULL") {}

    function setSupply(uint256 supply) public onlyOwner {
        totalSkulls = supply;
    }

    function setTokenPrice(uint256 price) public onlyOwner {
        tokenPrice = price;
    }

    function transferToOwner() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setBaseUrl(string memory url) public onlyOwner {
        baseUrl = url;
    }

    function baseTokenURI() public view returns (string memory) {
      return baseUrl;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId));
        return string(abi.encodePacked(
            baseTokenURI(),
            _tokenId.toString()
        ));
    }
    
    function makeAvailable() public onlyOwner {
        tokensAvailable = !tokensAvailable;
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokens = balanceOf(_owner);
        if (tokens == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokens);
            uint256 index;
            for (index = 0; index < tokens; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function mintSkull(uint256 quantity) public payable {
        
        require(tokensAvailable, "Minting is disabled");
        require(quantity <= totalSkulls - totalSupply(), "All Tokens Minted");
        require(msg.value >= tokenPrice * quantity, "Not enough ETH sent");
        
        for (uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < totalSkulls) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }  
}