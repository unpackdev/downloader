pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./LibAtomic.sol";

interface IExchangeWithAtomic {
    function lockAtomic(LibAtomic.LockOrder memory swap) payable external;
}
