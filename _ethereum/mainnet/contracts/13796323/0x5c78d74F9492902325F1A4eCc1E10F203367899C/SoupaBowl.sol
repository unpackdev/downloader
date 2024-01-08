// SPDX-License-Identifier: MIT

/*
 .8888888.   .888888. 88888888888 .8888888.  88888888.  888     888  .8888888.   .888888.                 
8888" "8888 8888  8888    888    8888" "8888 888   8888 888     888 8888" "8888 8888  8888                
888     888 888    888    888    888     888 888    888 888     888 888     888 8888.                     
888     888 888           888    888     888 888   8888 888     888 888     888  "88888.                  
888     888 888           888    888     888 88888888"  888     888 888     888     "8888.                
888     888 888    888    888    888     888 888        888     888 888     888       "888                
8888. .8888 8888  8888    888    8888. .8888 888        8888. .8888 8888. .8888 8888  8888                
 "8888888"   "888888"     888     "8888888"  888         "8888888"   "8888888"   "888888"
                                                                                                          
 .888888.   .8888888.  888     888 88888888.     88888      8888888.    .8888888.  888       888 888      
8888  8888 8888" "8888 888     888 888   8888   888888      888  "888  8888" "8888 888       888 888      
8888.      888     888 888     888 888    888  8888888      888  .888  888     888 888  888  888 888      
 "88888.   888     888 888     888 888   8888 8888 888      8888888<.  888     888 888 88888 888 888      
    "8888. 888     888 888     888 88888888" 8888  888      888  "8888 888     888 8888888888888 888      
      "888 888     888 888     888 888      8888   888      888    888 888     888 888888 888888 888      
8888  8888 8888. .8888 8888. .8888 888     88888888888      888   8888 8888. .8888 88888   88888 888      
 "888888"   "8888888"   "8888888"  888    8888     888      88888888"   "8888888"  8888     8888 88888888

                        ___
                     .-'   `'.
                    /         \
                    |----8----;
                    |         |           ___.--,
           _.._     |0) ~ (0) |    _.---'`__.-( (_.
    __.--'`_.. '.__.\    '--. \_.-' ,.--'`     `""`
   ( ,.--'`   ',__ /./;   ;, '.__.'`    __
   _`) )  .---.__.' / |   |\   \__..--""  """--.,_
  `---' .'.''-._.-'`_./  /\ '.  \ _.-~~~````~~~-._`-.__.'
        | |  .' _.-' |  |  \  \  '.               `~---`
         \ \/ .'     \  \   '. '-._)
          \/ /        \  \    `=.__`~-.
          / /\         `) )    / / `"".`\
    , _.-'.'\ \        / /    ( (     / /
     `--~`   ) )    .-'.'      '.'.  | (
            (/`    ( (`          ) )  '-;
             `      '-;         (-'
*/

pragma solidity >=0.8.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract SoupaBowl is ERC721Enumerable, Ownable {
    using Strings for uint256;
    
    string baseURI;
    string public baseExtension = ".json";
    uint256 public maxSupply = 8;
    string public soupaSecretMessage;
                     
    constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _soupaSecretMessage
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setSoupaSecretMessage(_soupaSecretMessage);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
  
    function walletOfOwner(address _owner) 
    public
    view
        returns (uint256[] memory)
        {
            uint256 ownerTokenCount = balanceOf(_owner);
            uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    //only owner

    // this contract only has the owner mint function as it is not open to public mint 
    function ownerMint(uint256 _mintAmount) public payable onlyOwner {
        uint256 supply = totalSupply();
        require(_mintAmount > 0,                            "Cant mint 0 tokens");
        require( supply + _mintAmount <= maxSupply,         "Exceeds maximum supply");

        for (uint256 i = 1; i <= _mintAmount; i++) {
          _safeMint(msg.sender, supply + i);
        }
    }
    
    // change the base URI
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setSoupaSecretMessage(string memory _newSoupaSecretMessage) public onlyOwner {
        soupaSecretMessage = _newSoupaSecretMessage;
    }
    
    // change base extension
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }
 
    // withdraw contract funds to owner
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}