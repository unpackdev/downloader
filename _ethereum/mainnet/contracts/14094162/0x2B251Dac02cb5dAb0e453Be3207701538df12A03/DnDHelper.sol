// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 <0.9.0;

import "./IERC721Enumerable.sol";


/**
 * @title DnDHelper contract
 * @author @FrankPoncelet
 * 
 */
 contract DnDHelper{
    IERC721Enumerable public dorkisContract;
    IERC721Enumerable public evilsContract;
    struct Pair {
        uint256 id;
        address owner;
    }
    constructor() {
        dorkisContract = IERC721Enumerable(address(0x0588a0182eE72F74D0BA3b1fC6f5109599A46A9C));
        evilsContract = IERC721Enumerable(address(0xf3B4215cDbA99d4564C42b143593BA59535b507b));

        }

    function getDorkisForWallets(address[] memory owners) external view returns (Pair[] memory){
            return getTokensForWallet(owners,dorkisContract );
        }

    function getEvilsForWallets(address[] memory owners) external view returns (Pair[] memory){
            return getTokensForWallet(owners,evilsContract );
        }

    function getTokensForWallet(address[] memory owners, IERC721Enumerable tokenContract) private view returns (Pair[] memory){
        uint tokens = 0;
        for (uint i=0; i<owners.length; i++) {
            tokens += tokenContract.balanceOf(owners[i]);
        }
        Pair[] memory pairs = new Pair[](tokens);
        uint counter=0;
        for (uint i=0; i<owners.length; i++) {
            uint tokenCount = tokenContract.balanceOf(owners[i]);
            for(uint index = 0; index < tokenCount; index++){
                pairs[counter] = Pair(tokenContract.tokenOfOwnerByIndex(owners[i],index), owners[i]);
                counter += 1;
            }
        }
        return pairs;
    }
 }