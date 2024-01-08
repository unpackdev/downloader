//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./ERC721.sol";
import "./Ownable.sol";

contract CommunityColors is Ownable, ERC721 {
    
    bool locked = false;

    constructor() ERC721("Community Colors", "COLOR") {}

    function mintTheColor(address recipient, string memory tokenURI, uint256 _tokenId)
        public 
        payable
    {
        require(
            totalSupply()  <= 16777216,
            "All colors have been minted."
        );
        require(_tokenId <=  16777216 && _tokenId >=1, "Not a valid color.");
        require(msg.value >=  0.01 ether, "Not enough ETH sent: check price.");
        _mint(recipient, _tokenId);
        _setTokenURI(_tokenId, tokenURI);
    }


function withdraw() public onlyOwner{
            require(owner() == msg.sender, "Ownable: caller is not the owner");
            require(!locked, "Reentrant call detected!");
            locked = true;
            uint256 amount = address(this).balance;
            (bool success, ) = msg.sender.call{value:amount}("");            
            require(success, "Transfer failed.");
            locked = false;  
}
    
}