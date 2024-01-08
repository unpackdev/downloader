// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract GalaxiatorsContract {
    function burnGalaxiator(uint tokenId) public {}
    function ownerOf(uint256 tokenId) external view returns (address owner){}
}

contract BurnProxy is Ownable{

    GalaxiatorsContract immutable _contract1;
    GalaxiatorsContract immutable _contract2;

    constructor(address contract1, address contract2){
        _contract1 = GalaxiatorsContract(contract1);
        _contract2 = GalaxiatorsContract(contract2);
    }

    function burnTokensOwner(uint256[] calldata tokenIDs, bool secondContract) external onlyOwner {
        GalaxiatorsContract _contract = _contract1;
        if (secondContract) {
            _contract = _contract2;
        }

        for (uint i = 0; i < tokenIDs.length; i++) {
            _contract.burnGalaxiator(tokenIDs[i]);
        }
    }

    function burnTokensUser(uint256[] calldata tokenIDs, bool secondContract) external {
        GalaxiatorsContract _contract = _contract1;
        if (secondContract) {
            _contract = _contract2;
        }

        for (uint i = 0; i < tokenIDs.length; i++) {
            require(_contract.ownerOf(tokenIDs[i]) == msg.sender, "Can't burn a token you don't own");
            _contract.burnGalaxiator(tokenIDs[i]);
        }
    }

}