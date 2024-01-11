//*~~~> SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface INFTMarket { 
    function transferNftForSale(address receiver, uint itemId) external returns(bool);
}