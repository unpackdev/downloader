// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 <0.9.0;

import "./PunksMarket.sol";
import "./PunksV1Wrapper.sol";

/**
 * @title MPHelper contract
 * @author @FrankNFT.eth
 * 
 */
 contract MPHelper{
    PunksMarket public mPContract;
    PunksV1Wrapper public wrapper;

    constructor() {
        mPContract = PunksMarket(payable(0x759c6C1923910930C18ef490B3c3DbeFf24003cE));
        wrapper = PunksV1Wrapper(0x282BDD42f4eb70e7A9D9F40c8fEA0825B7f68C5D);
        }

    function getAllBids(uint256[] memory ids) external view returns (PunksMarket.Punk[] memory){
        uint tokens = 0;
        for (uint i=0; i<ids.length; i++) {
            if(wrapper.exists(ids[i])){
                PunksMarket.Punk memory punk = mPContract.getPunksDetails(ids[i]);
                if (punk.bid.hasBid && !isForSale(punk)){
                 tokens+=1;
                }
            }
        }
        PunksMarket.Punk[] memory punks = new PunksMarket.Punk[](tokens);
        uint index = 0;
        for (uint i=0; i<ids.length; i++) {
            if(wrapper.exists(ids[i])){
                PunksMarket.Punk memory punk = mPContract.getPunksDetails(ids[i]);
                if (punk.bid.hasBid && !isForSale(punk)){
                    punks[index]=mPContract.getPunksDetails(ids[i]);
                    index +=1;
                }
            }
        }

        return punks;
    }

    function getAllForSale(uint256[] memory ids) external view returns (PunksMarket.Punk[] memory){
        uint tokens = 0;
        for (uint i=0; i<ids.length; i++) {
            if(wrapper.exists(ids[i])){
                PunksMarket.Punk memory punk = mPContract.getPunksDetails(ids[i]);
                if (isForSale(punk)){
                    tokens+=1;
                }
            }
        }
        PunksMarket.Punk[] memory punks = new PunksMarket.Punk[](tokens);
        uint index = 0;
        for (uint i=0; i<ids.length; i++) {
            if(wrapper.exists(ids[i])){
            PunksMarket.Punk memory punk = mPContract.getPunksDetails(ids[i]);
                if (isForSale(punk)){
                    punks[index]=mPContract.getPunksDetails(ids[i]);
                    index +=1;
                }
            }
        }
        return punks;
    }

    function getDetailsForIds(uint256[] memory ids) external view returns (PunksMarket.Punk[] memory){
        PunksMarket.Punk[] memory punks = new PunksMarket.Punk[](ids.length);
        for (uint i=0; i<ids.length; i++) {
            if(wrapper.exists(ids[i])){
                punks[i]=mPContract.getPunksDetails(ids[i]);
            }
        }
        return punks;
    }

    function isForSale(PunksMarket.Punk memory punk) public pure returns (bool){
        return punk.offer.isForSale && punk.owner==punk.offer.seller;
    }
 }