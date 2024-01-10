// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: XYZ.CHURCH
/// @author: colt.xyz

import "./ERC1155CreatorProxy.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//                                                                                       //
//              _  _  _  _  ____    ___  _   _  __  __  ____   ___  _   _                //
//             ( \/ )( \/ )(_   )  / __)( )_( )(  )(  )(  _ \ / __)( )_( )               //
//              )  (  \  /  / /_  ( (__  ) _ (  )(__)(  )   /( (__  ) _ (                //
//             (_/\_) (__) (____)()\___)(_) (_)(______)(_)\_) \___)(_) (_)               //
//                                                                                       //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract XYZ is ERC1155CreatorProxy {
    string public constant name="XYZ.CHURCH";

    constructor() ERC1155CreatorProxy() {}

    function contractURI() public view returns (string memory) {
        return "https://ipfs.io/ipfs/QmcTYE518d7oufMLMf7fHyvggmHXuvx8btzoKZ3ZcEyrA5/contractUri.json";
    }
}