pragma solidity ^0.8.19;

import "./IERC721.sol";

interface IMarketplace {
    struct Item {
        uint itemId;
        IERC721 nft;
        uint tokenId;
        uint price;
        address payable seller;
        bool sold;
    }

    event RaffleTradeFeeChanged(uint16 _newTradeFee);
    event RaffleAddressSet(address _raffleAddress);
    event OperatorChanged(address _newOperator);

    function initialize(
        uint16 _raffleTradeFee, 
        address _operator
    ) external; 
}