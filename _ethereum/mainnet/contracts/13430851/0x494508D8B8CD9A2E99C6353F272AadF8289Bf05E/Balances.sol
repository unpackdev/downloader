// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./Base.sol";

abstract contract Balances is Base {
    function withdrawTeamMemberBalanceTo(address to, uint256 valueToWithdraw)
        public
    {
        uint8 index = getValidIndex() - 1;
        uint256 value = currentTeamBalance[index];
        require(value > 0, NO_BALANCE);
        require(value >= valueToWithdraw, TOO_MANY);
        valueToWithdraw = valueToWithdraw > 0 ? valueToWithdraw : value;
        currentTeamBalance[index] = value - valueToWithdraw;
        sendValueTo(to, valueToWithdraw);
    }

    function getCurrentTeamMemberBalanceToWithdraw()
        public
        view
        returns (uint256)
    {
        uint8 index = getValidIndex() - 1;
        return currentTeamBalance[index];
    }

    function changeTeamMemberAddress(address newAddress) public {
        uint8 index = getValidIndex();
        addressToIndex[msg.sender] = 0;
        addressToIndex[newAddress] = index;
        receiverAddresses[index - 1] = newAddress;
    }

    function getValidIndex() internal view returns (uint8 index) {
        index = addressToIndex[msg.sender];
        require(index > 0, NO_ACCESS);
    }
}
