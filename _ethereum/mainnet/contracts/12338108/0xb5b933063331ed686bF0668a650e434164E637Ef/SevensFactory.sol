pragma solidity 0.5.16;

import "./Sevens.sol";

contract SevensFactory {
    address[] public addressList;
    address payable public sevens;

    event StoreLaunch(
      address indexed store,
      string name,
      string symbol
    );

    constructor() public {
      sevens = msg.sender;
    }

    function launchStore(
      string memory name,
      string memory symbol,
      string memory uri
    ) public returns (address item) {
        address newStore = address(new Sevens(name, symbol, uri, sevens, msg.sender));
        addressList.push(newStore);
        emit StoreLaunch(newStore, name, symbol);
        return newStore;
    }

    function getCount() public view returns (uint exchangeCount) {
        return addressList.length;
    }
}