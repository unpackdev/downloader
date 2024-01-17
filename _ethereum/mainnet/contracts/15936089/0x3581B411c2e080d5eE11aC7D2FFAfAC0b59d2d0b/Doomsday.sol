// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./Owned.sol";
import "./ReentrancyGuard.sol";
/*
 (                                              
 )\ )                          (                
(()/(                )         )\ )    )  (     
 /(_))   (    (     (     (   (()/( ( /(  )\ )  
(_))_    )\   )\    )\  ' )\   ((_)))(_))(()/(  
 |   \  ((_) ((_) _((_)) ((_)  _| |((_)_  )(_)) 
 | |) |/ _ \/ _ \| '  \()(_-</ _` |/ _` || || | 
 |___/ \___/\___/|_|_|_| /__/\__,_|\__,_| \_, | 
                                          |__/  
*/
contract Doomsday is ERC721A, Owned, ReentrancyGuard {

    string public baseURI;

    uint256 public mintPrice = 0.0069 ether;
    uint256 public maxSupply = 5555;
    uint256 public maxPerWallet = 10;

    bool public saleActive;

    modifier StockCount(uint256 _amount) {
        require(totalSupply() + _amount <= maxSupply, "Sorry Sold Out!");
        _;
    }

    constructor() ERC721A("Doomsday", "DD") Owned(msg.sender) {}

    function mint(uint256 _amount) external payable StockCount(_amount) nonReentrant {
        require(saleActive, "Sale has not started");
        
        require(tx.origin == msg.sender, "Caller must be EOA");
        
        require(msg.value == _amount * mintPrice, "Please send the exact amount of ETH in order to mint");

        require(_numberMinted(msg.sender) + _amount <= maxPerWallet, "You have minted the max amount allowed per wallet.");

        require(_amount <= maxPerWallet, "You are ony allowed 10 per tx.");

        _mint(msg.sender, _amount);
    } 

    function teamMint(uint256 _amount, address _sendTo) external StockCount(_amount) nonReentrant onlyOwner {
        _mint(_sendTo, _amount);
    }

    function setMintPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function toggleSale() external onlyOwner {
        saleActive = !saleActive;
    }

    function setBaseURI(string calldata _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}