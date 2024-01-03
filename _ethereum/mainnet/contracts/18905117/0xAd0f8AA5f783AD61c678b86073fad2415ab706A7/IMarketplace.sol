pragma solidity ^0.8.19;

import "./IERC721.sol";

interface IMarketplace {
    event RaffleTradeFeeChanged(uint16 _newTradeFee);
    event RaffleAddressSet(address _raffleAddress);
    event OperatorChanged(address _newOperator);

    function initialize(
        uint16 _raffleTradeFee, 
        address _operator
    ) external; 
}