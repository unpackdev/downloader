//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.0;
import "./Ownable.sol";

interface IPalace {
    function addCard(uint256 cardId, uint256 amount) external;

    function transferOwnership(address newOwner) external;
}

contract BatchAddCard is Ownable {
    IPalace public palace;

    constructor(IPalace _palaceAddress) public {
        palace = _palaceAddress;
    }

    function passOwnership(address _newOwner) public onlyOwner {
        palace.transferOwnership(_newOwner);
    }

    function batchAddCard(
        uint256 _startID,
        uint256 _endID,
        uint256 _cardCost
    ) public onlyOwner {
        for (uint256 i = _startID; i <= _endID; i++) {
            palace.addCard(i, _cardCost);
        }
    }
}
