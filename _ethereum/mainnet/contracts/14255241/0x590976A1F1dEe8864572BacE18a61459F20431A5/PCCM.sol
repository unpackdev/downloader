/*****************************************************************************************************
 ██████╗ ██╗      █████╗ ███████╗████████╗██╗ ██████╗     ██████╗ ██████╗ ███████╗███╗   ███╗ ██████╗ 
 ██╔══██╗██║     ██╔══██╗██╔════╝╚══██╔══╝██║██╔════╝    ██╔════╝██╔═══██╗██╔════╝████╗ ████║██╔═══██╗
 ██████╔╝██║     ███████║███████╗   ██║   ██║██║         ██║     ██║   ██║███████╗██╔████╔██║██║   ██║
 ██╔═══╝ ██║     ██╔══██║╚════██║   ██║   ██║██║         ██║     ██║   ██║╚════██║██║╚██╔╝██║██║   ██║
 ██║     ███████╗██║  ██║███████║   ██║   ██║╚██████╗    ╚██████╗╚██████╔╝███████║██║ ╚═╝ ██║╚██████╔╝
 ╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝ ╚═════╝     ╚═════╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝ ╚═════╝ 
*****************************************************************************************************/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721ENP.sol";

contract Plastic_Cosmo is ERC721ENP {
    constructor()
    ERC721ENP("Plastic Cosmo", "PCCM", address(0x9865e86EFe512569f1fe6B89dBD4DD9Dd7B2c9fb)) {
        enableAutoFreez();

        address payable[] memory thisAddressInArray = new address payable[](1);
        thisAddressInArray[0] = payable(address(this));
        uint256[] memory royaltyWithTwoDecimals = new uint256[](1);
        royaltyWithTwoDecimals[0] = 1000;
        _setCommonRoyalties(thisAddressInArray, royaltyWithTwoDecimals);
    }

    function pleasePushMe()
        public
        pure
        returns (string memory)
    {
        return "I'm just playing games I know that's plastic cosmo";
    }
}
