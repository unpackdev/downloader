// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SlimeStore.sol";

contract SlimeSale is SlimeStore {

    uint256 public constant _PRICE = 0.035 ether;
    address[] artists= [0x98DF27017715583caC388E87bfDf084Fd5B43E41];
    uint256 public constant _WITHDRAW_RATE=60;
    uint public constant _MAX_MINT=6666;

    constructor(address _producer) SlimeStore(_producer) {}

    function getPrice() internal pure override returns (uint256) {
        return _PRICE;
    }

    function getArtistAddresses()
        internal
        view
        override
        returns (address[] memory)
    {        
        return artists;
    }

    function getWithdrawRate() internal pure override returns (uint256){
        return _WITHDRAW_RATE;
    }

    function getMaxMint() internal pure override returns (uint256){
        return _MAX_MINT;
    }

}
