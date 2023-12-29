// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

/**************************************

    Pool interface

 **************************************/

abstract contract IPool {

    // events
    event Withdraw(address receiver, uint256 amount);

    // errors
    error InvalidSender(address sender, address expected);

    // functions
    function withdraw(address, uint256) public virtual;
    function poolInfo() external virtual view returns (uint256);

}
