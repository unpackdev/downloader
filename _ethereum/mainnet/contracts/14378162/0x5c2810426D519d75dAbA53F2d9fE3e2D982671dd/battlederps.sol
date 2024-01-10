pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT
/*   

   ____    ____    
U | __")u |  _"\   
 \|  _ \//| | | |  
  | |_) |U| |_| |\ 
  |____/  |____/ u 
 _|| \\_   |||_    
(__) (__) (__)_)     */

import "./ERC721.sol";
import "./Ownable.sol";
import "./RandomlyAssigned.sol";

contract BattleDerps is ERC721, Ownable, RandomlyAssigned {
  using Strings for uint256;
  // uint256 public requested;
  uint256 public currentSupply = 0;
  
  string public baseURI = "unset";

  mapping(address => uint256) public amountPerWallets;

  bool public paused = true;

  constructor() 
    ERC721("Battle Derps", "BD")
    RandomlyAssigned(4200,1) // Max. 4200 NFTs available; Start counting from 1 (instead of 0)
    {
       
    }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

    
  function mint (uint256 _amount)
      public
      payable
  {
      require( tokenCount() + _amount <= totalSupply(), "YOU CAN'T MINT MORE THAN MAXIMUM SUPPLY");
      require( availableTokenCount() - _amount >= 0, "YOU CAN'T MINT MORE THAN AVALABLE TOKEN COUNT"); 
      require( tx.origin == msg.sender, "CANNOT MINT THROUGH A CUSTOM CONTRACT");

      if (msg.sender != owner()) {  
        require( msg.value >= _amount * 0.0069 ether, "NOT ENOUGH FEE");
        require(
				  amountPerWallets[msg.sender] + _amount <= 20,
				  "CAN'T MINT MORE THAN 20 PER WALLET"
			  );
        require(
			    paused == false,
			    "MINTING PAUSED"
		    );
      }

      

      for (uint256 i = 0; i < _amount; i++) {
        currentSupply++;
        amountPerWallets[msg.sender] ++;
        uint256 id = nextToken();
        _safeMint(msg.sender, id);
      } 
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistant token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
        : "";
  }

  function setBaseUri(string memory _baseURI) external onlyOwner {
		baseURI = _baseURI;
  }

  function pause(bool _paused) external onlyOwner {
		paused = _paused;
	}

  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}