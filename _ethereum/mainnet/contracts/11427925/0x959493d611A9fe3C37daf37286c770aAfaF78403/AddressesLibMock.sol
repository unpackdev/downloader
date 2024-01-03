//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "./AddressesLib.sol";

contract AddressesLibMock {
    using AddressesLib for address[];

    address[] public result;

    constructor(address[] memory initialData) public {
        result = initialData;
    }

    function getResult() external view returns (address[] memory) {
        return result;
    }

    function add(address newItem) external {
        result.add(newItem);
    }

    function removeAt(uint256 indexAt) external {
        result.removeAt(indexAt);
    }

    function getIndex(address item) external view returns (bool found, uint256 indexAt) {
        return result.getIndex(item);
    }

    function remove(address item) external {
        result.remove(item);
    }
}
