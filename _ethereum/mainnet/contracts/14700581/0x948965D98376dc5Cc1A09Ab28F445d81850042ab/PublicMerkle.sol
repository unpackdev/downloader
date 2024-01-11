// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
import "./Ownable.sol";

contract PublicMerkle is Ownable {
    function isPermitted(address, bytes32[] calldata)
        public
        pure
        returns (bool)
    {
        return true;
    }
}
