//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

import "./IERC721A.sol";

contract ERC721AWalletOfOwner {

    /// @author devberry.eth

    constructor(){}

    function walletOfOwner(address _contract, address owner) public view returns (uint256[] memory) {

        IERC721A target = IERC721A(_contract);

        uint256 totalSupply = target.totalSupply();

        uint256 totalOwned = target.balanceOf(owner);

        uint256 index;

        uint256[] memory tokenIds = new uint256[](totalOwned);

        for(uint256 i = 0; i < totalSupply; i++){
            try target.ownerOf(i) returns (address _owner) {
                if(_owner==owner){
                    tokenIds[index++] = i;
                }
            } catch {
                totalSupply++;
            }
            if(index == totalOwned){
                break;
            }
        }

        return tokenIds;

    }

}
