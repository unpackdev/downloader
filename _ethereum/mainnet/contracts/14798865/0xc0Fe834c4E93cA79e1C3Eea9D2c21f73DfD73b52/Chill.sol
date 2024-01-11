// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*                  Ahhhhhhhhhhhhhh             Ahhhhhhhhhhhhhh
                  EdieEdieEdieEdie                EdieEdieEdieEdie
                Ahhhhhhhhhhhhhh                    Ahhhhhhhhhhhhhh
              EdieEdieEdieEdie                       EdieEdieEdieEdie
            Ahhhhhhhhhhhhhh                           Ahhhhhhhhhhhhhh
           EdieEdieEdieEdie                             EdieEdieEdieEdie
         Ahhhhhhhhhhhhhh                                  Ahhhhhhhhhhhhhh
       EdieEdieEdieEdie                                     EdieEdieEdieEdie
      Ahhhhhhhhhhhhhh                                         Ahhhhhhhhhhhhhh
    EdieEdieEdieEdie                    @                      EdieEdieEdieEdie
  Ahhhhhhhhhhhhhh              @@      @@@      @@              Ahhhhhhhhhhhhhh
 EdieEdieEdieEdie               @@@    @@@    @@@                 EdieEdieEdieEdie
                                 @@@@@@@@@@@@@@@
                                  @@@@@@@@@@@@@
                          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                                  @@@@@@@@@@@@@
                                 @@@@@@@@@@@@@@@
 Ahhhhhhhhhhhhhh               @@@     @@@     @@@                 Ahhhhhhhhhhhhhh
  EdieEdieEdieEdie            @@       @@@       @@              EdieEdieEdieEdie 
    Ahhhhhhhhhhhhhh                     @                       Ahhhhhhhhhhhhhh
      EdieEdieEdieEdie                                         EdieEdieEdieEdie 
       Ahhhhhhhhhhhhhh                                       Ahhhhhhhhhhhhhh
         EdieEdieEdieEdie                                  EdieEdieEdieEdie 
           Ahhhhhhhhhhhhhh                               Ahhhhhhhhhhhhhh
             EdieEdieEdieEdie                          EdieEdieEdieEdie 
              Ahhhhhhhhhhhhhh                         Ahhhhhhhhhhhhhh
                @PoKai Chang                        Contract Fork From
                  @pupupupuisland                  @harry830622              */


import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./Ownable.sol";

contract Chill is Ownable, ERC721A, ERC721AQueryable {  

  using Strings for uint256;  
	
  // Sales variables
	// ------------------------------------------------------------------------
	string private _baseTokenURI = "ipfs://Qmdnx1PZgy1xU3kuv8V6JR3eNB7peRuivrNc4v9EFRwpPD/";

	// Constructor
	// ------------------------------------------------------------------------
	constructor()
	ERC721A("E-Chill", "EC"){}  

	// Airdrop functions
	// ------------------------------------------------------------------------
	function airdrop(address[] calldata _to, uint256[] calldata quantity) public onlyOwner{
		uint256 count = _to.length;

		for (uint256 i = 0; i < count; i++){
			_safeMint(_to[i], quantity[i]);
		}
	}

	// Base URI Functions
	// ------------------------------------------------------------------------
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "TOKEN_NOT_EXISTS");
		
		return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
	}

	// setting functions
	// ------------------------------------------------------------------------
	function setURI(string calldata _tokenURI) external onlyOwner {
		_baseTokenURI = _tokenURI;
	}

}
