/*

  << Transfer Platform Token >>

*/

import "./ReentrancyGuarded.sol";

pragma solidity 0.7.5;

contract TransferPlatformToken is ReentrancyGuarded {
    function transferETH(address[] calldata addrs, uint[] calldata amounts) external payable reentrancyGuard returns (bool) {
        require(addrs.length == amounts.length, "transferETH: Addresses and amounts must match in quantity");

        for (uint i = 0; i < amounts.length; i++) {
            address(uint160(addrs[i])).transfer(amounts[i]);
        }

        return true;
    }

    // important to receive ETH
    receive() payable external {}
}
