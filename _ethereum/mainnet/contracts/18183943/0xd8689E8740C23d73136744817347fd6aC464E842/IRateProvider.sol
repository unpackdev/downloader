// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRateProvider {
    /**
     * @dev Returns an 18 decimal fixed point number that is the exchange rate of the token to some other underlying
     * token. The meaning of this rate depends on the context.
     * https://github.com/balancer/balancer-v2-monorepo/blob/master/pkg/interfaces/contracts/pool-utils/IRateProvider.sol
     */
    function getRate() external view returns (uint256);
}
