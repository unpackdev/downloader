/*
                                                                                     
                                                                                     
                                 ▒ ▒▓▓▓▒                                             
                                ▓██▓ ▒██████▓▒▒                                      
                               ██████▓ ▓██████████▓▓▒                                
                              █████████▒ ▓█████████████▒                             
                            ▒████████████▒ ▓█████████████▓                           
                           ▒███████████████▒ ▓██████████████▒                        
                          ▓██████████████████▒ ▓██████████████▓                      
                         ▓█████████████████████▒ ▓██████████████▓▒                   
                        █████████████████████████▒ ████████████████▒                 
                       ████████████████████████████▒▒████████████████▓               
                     ▒██████████████████████████████▓ ▒█████████████▓▒               
                    ▒█████████████████████████████████████████████▓                  
                     ▒██████████████████████████████████████████▒                    
                       ▓██████████████████████████████████████▒                      
                        ▒██████████████████████████████████▓                         
                          ▓██████████████████████████████▓                           
                           ▒███████████████████████████▒                             
                             ▓██████████████████████▓▒                               
                              ▒███████████████████▓                                  
                                ▓██████████████▓▒                                    
                                 ▒███████▓▓▒                                         
                                   ▓▒▒                                               
                                                                                     
                                                                                     
                                                                                     
  ▓▓▓                                                ░▓▓▓▓░  ▓▓▓▓▓                   
  ███░                                                ▒██▒   █████                   
  █████   ░████████░     ▒████████░   ▓████▓██████░  ▒████░ ████████   ░████████▓    
  ████▓ ░████████████  ▒████████████  ▓████████████  ▒████░ ████████  ██████▓█████   
  ███░  █████░░░▓████░░█████   ░█████ ▓████░  █████░ ▒████░  █████   █████▓░░░████▓  
  ███░  █████████████▓▒████▓    █████░▓████   ▓████░ ▒████░  █████   █████████████▓  
  ███▓  ▓████▓░ ░▒▒░  ░█████░  ▓█████ ▓████   ▓████░ ▒████░  █████░  ▓████▓░ ░▒▒░    
  █████▓ ▓██████████▓  ░████████████  ▓████   ▓████░ ▒████░  ▓██████  ▓███████████   
  ▒████▓   ▓██████▓░     ░▓██████▓░   ░████   ▓████░ ▒████░   ░█████    ▓▓█████▓░    
                                                                                     
                                                                                     
                                                     █                               
                                                     █                               
                ██     ██     ██    ███     ██     ███    ██    ████                 
         ████  █  █   █ ██   █  █   █  █   █  █   █  █   █ ██   ██    ████           
               █  █   ██     █  █   █  █   █  █   █  █   ██       ██                 
                █ █    ███    ██    █  █    ██     ███    ███   ████                 
                  █                                                                  
                ██                                                                   
                                                                                     
                                                                                                                                                                          
  * Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
  * SPDX-License-Identifier: MIT

*/
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC2981.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract TeoniteGeonodes is ERC721URIStorage, ERC2981, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    string private _name;
    address[] private _allowedMintMessageSenders;

    constructor(string memory name_, string memory symbol_, address[] memory allowedMintMessageSenders, uint96 defaultRoyaltyFeeNumerator) ERC721(name_, symbol_) {
        _name = name_;
        _allowedMintMessageSenders = allowedMintMessageSenders;
        _setDefaultRoyalty(msg.sender, defaultRoyaltyFeeNumerator);
    }

    function supportsInterface(bytes4 interfaceId)
    public view virtual override(ERC721, ERC2981)
    returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mint(address recipient, string memory tokenURI)
    public
    onlyAllowed
    returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);

        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function upgrade(uint256 tokenId, string calldata tokenURI) public onlyAllowed {
        _setTokenURI(tokenId, tokenURI);
    }

    modifier onlyAllowed() {
        bool mintMessageSenderAllowed = false;

        for (uint i; i < _allowedMintMessageSenders.length; i++) {
            if (_allowedMintMessageSenders[i] == msg.sender) {
                mintMessageSenderAllowed = true;
                break;
            }
        }

        require(mintMessageSenderAllowed, "Operation allowed only from specific addresses!");

        _;
    }
}
