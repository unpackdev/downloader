// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./Ownable.sol";
import "./ContextMixin.sol";
import "./ERC721.sol";
import "./ERC721Royalty.sol";

//
//           /.                                                             
//           //                         /////.                              
//          *//.                      ,*//////                              
//          *,,,                      //...,,,.                             
//         ,,,,,.                    .*****////*       */,                  
//         ******                     ..******(##,    //***                 
//          ***.                      ..******(###,,,///****/               
//         ,,,,,,                     //***///,,,,**********//              
//         *****/                      ///////,,,,***///********            
//          /*,,                  //*,,,///###*,,,,,,///,,,,***//           
//           **                    /*,,,***(((*******///,,,****///          
//           //                   ***...***///////###///*******///,         
//           ,,               ,//*******///*******///(((*//*,,,***/         
//           */              *///,******///***,,,,///*******,,,*****        
//           *,             **///****,,,***///****///*******////////        
//           *,          ************,,,***///****///*******////////        
//           **     .*/((((****,,///*******///,,, **********//////**        
//           //                      ***///*** .,   ,,,,////,,,///,         
//           **                       *****//          / ...******          
//           **                 *,,,  *****//                               
//           **                 .****///***,,,,,,,**,                       
//           ,,            ,//*******//////,,,,,,,///                       
//           ,*          ,,/////////////*******/////////                    
//            *         ,,,/////////////**********/////////                 
//                    ***********///////******,,,,***//                     
//                     ,//////***###/,,,******///                           
//

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract CryptoQuijote is ERC721, ERC721Royalty, ContextMixin, Ownable {
    string public provenance;

    address public proxyRegistryAddress;

    string  private _baseTokenURI;

    constructor(
        string memory name, 
        string memory symbol,
        string memory tokenURI,
        string memory provenance_,
        uint256 numTokens,
        uint96  feeNumerator,
        address proxyRegistryAddress_
    )
        ERC721(name, symbol)
        Ownable()
    {
        _mint(msg.sender, numTokens);

        _setBaseURI(tokenURI);

        if (feeNumerator > 0) {
            _setDefaultRoyalty(msg.sender, feeNumerator);
        }

        provenance = provenance_;
        proxyRegistryAddress = proxyRegistryAddress_;
    }

    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);

        if (proxyRegistryAddress != address(0) && address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function resetTokenRoyalty(uint256 tokenId) public onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    function setBaseURI(string memory tokenURI) public onlyOwner {
        _setBaseURI(tokenURI);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setProxyRegistryAddress(address proxyRegistryAddress_)
        public
        onlyOwner
    {
        proxyRegistryAddress = proxyRegistryAddress_;
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return _baseTokenURI;
    }

    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    function _setBaseURI(string memory tokenURI) internal {
        _baseTokenURI = tokenURI;
    }
}
