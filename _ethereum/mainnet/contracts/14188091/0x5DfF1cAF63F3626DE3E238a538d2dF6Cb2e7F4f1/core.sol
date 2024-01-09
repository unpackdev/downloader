// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    Bored Abe Campaign - 2022
*/
                                          
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract BoredAbeCampaign is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant ABE_PUBLIC = 10000;
    uint256 public constant ABE_PRICE = 0.01 ether;
    
    string private _contractURI = "ipfs://bafkreibfl5m5efds3pxx4btryvguc5662wvokieze6n63kkk3btp4qxpze";
    string private _tokenBaseURI = "ipfs://bafybeifiyqazjr2gqqvhnda52rqjgqaoq6bjy3dqmra7swcs4gvzrtwc4y/";

    bool public saleLive;
    
    constructor() ERC721("BoredAbeCampaign", "ABE") { }
    
    function buy(uint256 tokenQuantity) external payable {
        require(saleLive, "SALE_CLOSED");
        require(totalSupply() + tokenQuantity < ABE_PUBLIC, "OUT_OF_STOCK");
        require(ABE_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
        
        for(uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }
    
    function gift(address[] calldata receivers) external onlyOwner {
        require(totalSupply() + receivers.length <= ABE_PUBLIC, "MAX_MINT");
        
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }
    
    function withdraw(address _vault) external onlyOwner {
        (bool success, ) = _vault.call{value: address(this).balance}("");
        require(success, "Failed to send to team.");
    }
    
    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }
    
    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }
    
    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString(), ".json"));
    }
}