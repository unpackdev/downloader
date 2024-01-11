// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
                      %%%%%  *%%%%%  &#####@/.    ######                                            
                     %%%%%%%%%%%%%% &%#####%%%%%% ######                                            
          (%%%%%%%######((((((###%%#############((((((#####&                                        
          %%%%%%%%######((((((###%%#############((((((#####@                                        
            %%%%%%######((((((##(((########//////////////////////////////////,                      
       %%%%%%%%%%%######((((((##((((######(//////////////////////////////////                       
       %%%%%%%%%%#######(((((######%/ /////(((((((((((((((((((((((((((((((((((((((((               
             ,%%%#######(((((########## (((((((((((((((((((((((((((((((((((((((((((((               
              %%######(((((((########## (((((((((((((((((((((((((((((((%@&&&&&%%&((((               
               #(#(((((((((((########## (((((&&&&&&&&&%#@((((((((((((((@&&&&&###@(((,               
               #(((((((((((((########## (((((&&&&&&&&&(#@((((((((((((((&#&&&&###@(((                
                   @((((((((((######### (((((&&&&#%%##&&&&&%#(((((%&#####&&&&####(((                
                   @#(((((((((#########/(((((&&&&#####&&&&&#(#((((@      &&&&###/(((                
                %#((((((((((((##########(((((&&&&@     (@@@#@@@%%@((((((((#&###((((                
                @#((((((((((((##########(((((@&&&##/(((((((((@@@##@((((((((@##@#((((                
                ,##((((((((((/(#########(((((@&&&##/(((((((((%/&@@/(((((((((((((((((                
                 ##((((((((((((#########(((((/(((((((((((((((((((((((((((((((((((((                 
                   &(((((((((((#########((((((((((((((((((((((((((#(((( #%%#(((((((                 
                       (((((((((&#######(((((((((((   #%*((((  (%#((((# %##(((((((,                 
                   ((((((((((((((((#####(((((((((((   %#,((((    ,//,#%%###((((                     
                   ((((((((((((#(((#####(((((((((((                  %%%,##((((                     
                            %%%%(((######%%%%%(((((    %##%%&&%#######% ###.                        
                                   ######## %#(((((  &&& ################((                         
                                   ########/###((   &&&&&&&####%%& #  %%#((                         
                                    #########((((  *&&&&%&&##%%%&&&#####(((                         
                                      ######(((((  *%&&%&&%&&%%% /&#% #(((/                         
                                        ####(((#(  *&%%%%%%%&%%&%## /////                           
                                          ##((##(%%%%,&&%##*%%%((%### (((                           
                                           ##%%%%###### %%%#,((((##%#*(((                           
                                             ##%%%######%%#  ((((((((((((                           
                                               #########((((((((((((((                              
                                                 #####((((((/                                       
*/

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract RugBurn is ERC721A, Ownable {
    uint256 public maxSupply = 1000;
    string public ipfsString = "QmXwAULH9BGq6tP8xQ66nQxrd9T28nsDZ11GaAx9JcbZLP";
    string public ipfsExt = ".json";
    constructor() ERC721A("RugBurn", "RBN") {}

    // -- Mint + Airdrop function -- //

    function mint(uint256 quantity) external payable {
        require(msg.value >= 0.05 ether, "Not enough ETH sent: check price.");
        require(
            (totalSupply() + quantity) <= maxSupply,
            "We're out. Go complain to 6969."
        );
        _mint(msg.sender, quantity);
    }

    function batchTransfer(address[] calldata _addrs, uint256[] calldata _tokenIds) onlyOwner public  {
        require(_addrs.length == _tokenIds.length, "Lenght mismatch");
        for(uint256 i = 0; i < _addrs.length; i++) {
            _mintToken(_addrs[i], _tokenIds[i]);
        }
    }

    // -- Other stuff -- //

    function setIpfsString(string calldata _ipfsString, string calldata _ipfsExt) onlyOwner public {
        ipfsString = _ipfsString;
        ipfsExt = _ipfsExt;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "ipfs://",
                    ipfsString,
                    "/",
                    Strings.toString(_tokenId),
                    ipfsExt
                )
            );
    }
}
