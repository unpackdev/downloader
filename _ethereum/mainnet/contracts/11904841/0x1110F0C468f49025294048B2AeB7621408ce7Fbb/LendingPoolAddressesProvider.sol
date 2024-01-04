//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract LendingPoolAddressesProvider {

    address lendingPool;

    constructor(address _lendingPool) public {
        lendingPool = _lendingPool;
    }

    function getLendingPool() external view returns (address) {
        return lendingPool;
    }

    function getLendingPoolCore() external view returns (address) {
        return lendingPool;
    }
}
