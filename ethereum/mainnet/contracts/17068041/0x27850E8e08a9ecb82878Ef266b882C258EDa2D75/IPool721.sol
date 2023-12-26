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

import "./IPool.sol";

/**************************************

    Pool interface that supports NFTs

 **************************************/

abstract contract IPool721 is IPool {

    // functions
    function withdraw(address, uint256[] calldata) public virtual;

}
