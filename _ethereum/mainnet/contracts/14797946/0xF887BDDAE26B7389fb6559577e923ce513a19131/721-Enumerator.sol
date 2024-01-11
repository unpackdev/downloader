import "./IERC721Enumerable.sol";


//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
contract NftEnumerator {

    constructor(){

    }

    function getNftsOfAccount(address _addr, IERC721Enumerable nft) public view returns (uint256[] memory){
        uint256 balance = nft.balanceOf(_addr);
        uint256[] memory ids = new uint256[](balance);
        uint256 count;
        for(uint256 i; i < balance; i++){
            uint256 id = nft.tokenOfOwnerByIndex(_addr, i);
            ids[count++] = id;
        }

        return ids;
    }

}