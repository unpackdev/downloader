//
//
//
////////////////////////////////////////////////////////////////////////////////////////////////////
//  ██████╗ ██╗███████╗ ██████╗ ██████╗ ██████╗ ██╗███████╗ ██████╗██╗   ██╗██╗████████╗███████╗  //
//  ██╔══██╗██║██╔════╝██╔════╝██╔═══██╗██╔══██╗██║██╔════╝██╔════╝██║   ██║██║╚══██╔══╝██╔════╝  //
//  ██║  ██║██║███████╗██║     ██║   ██║██████╔╝██║███████╗██║     ██║   ██║██║   ██║   █████╗    //
//  ██║  ██║██║╚════██║██║     ██║   ██║██╔══██╗██║╚════██║██║     ██║   ██║██║   ██║   ██╔══╝    //
//  ██████╔╝██║███████║╚██████╗╚██████╔╝██████╔╝██║███████║╚██████╗╚██████╔╝██║   ██║   ███████╗  //
//  ╚═════╝ ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═════╝ ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝   ╚═╝   ╚══════╝  //
////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155PresetMinterPauser.sol";

contract DiscoBiscuite is ERC1155PresetMinterPauser, Ownable {

    string public name = "Trotz und Wasser by Discobiscuite";
    string public symbol = "Trotz und Wasser";
    
    string public contractUri = "https://nft.discobiscuite.art/contract"; 

    constructor() ERC1155PresetMinterPauser("https://nft.discobiscuite.art/{id}") {
    }

    function setUri(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

     function setContractURI(string memory newuri) public onlyOwner {
        contractUri = newuri;
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    

    function mintMass(
        address[] memory to,
        uint256[] memory id,        
        uint256[] memory amount
    ) onlyOwner public {
        require(to.length == id.length, "Contract Info: to and id length mismatch");
        require(to.length == amount.length, "Contract Info: to and amount length mismatch");

        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], id[i], amount[i], "");
        }

    }
}