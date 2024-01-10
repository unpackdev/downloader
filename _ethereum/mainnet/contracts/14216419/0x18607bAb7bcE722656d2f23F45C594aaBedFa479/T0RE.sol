/***********************************************************************************************
 ,---------.  .-```````-. .-------.        .-''-.          ,---.   .--. ________ ,---------.  
 \          \/ ,```````. \|  _ _   \     .'_ _   \         |    \  |  ||        |\          \ 
  `--.  ,---'|/ .-./ )  \|| ( ' )  |    / ( ` )   '        |  ,  \ |  ||   .----' `--.  ,---' 
     |   \   || \ '_ .')|||(_ o _) /   . (_ o _)  |        |  |\_ \|  ||  _|____     |   \    
     :_ _:   ||(_ (_) _)||| (_,_).' __ |  (_,_)___|        |  _( )_\  ||_( )_   |    :_ _:    
     (_I_)   ||  / .  \ |||  |\ \  |  |'  \   .---.        | (_ o _)  |(_ o._)__|    (_I_)    
    (_(=)_)  ||  `-'`"` |||  | \ `'   / \  `-'    /        |  (_,_)\  ||(_,_)       (_(=)_)   
     (_I_)   \'._______.'/|  |  \    /   \       /         |  |    |  ||   |         (_I_)    
     '---'    '._______.' ''-'   `'-'     `'-..-'          '--'    '--''---'         '---'    
                                                                                              
***********************************************************************************************/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721E.sol";

contract T0RE is ERC721E {
    using Strings for uint256;

    constructor()
    ERC721E("T0RE", "T0RE") {}

    uint256 private constant _TOTAL = 2000;
    string private _BASE_URI = "ipfs://xxxx/";

    function setBaseURI(string memory uri )
        public
        onlyAdmin
        emergencyMode
    {
        _BASE_URI = uri;
    }

    function getBaseURI()
        public
        view
        onlyAdmin
        returns(string memory)
    {
        return _BASE_URI;
    }

    function duplicate()
        public
        emergencyMode
    {
        require(totalSupply() < _TOTAL, "can not mint");
        uint256 currentNumber = totalSupply() + 1;
        _safeMint(owner(), currentNumber);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(_BASE_URI, tokenId.toString(), '.json'));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override
        emergencyMode
    {
        if(from == owner() && totalSupply() < _TOTAL ){
            duplicate();
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
