// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./IPToken.sol";

interface IPTokensFactory {
    /**
     * @dev Deploying a new PToken contract. Can be called by BucketsFactory only.
     * @param _name The name of the new PToken.
     * @param _symbol The symbol of the new PToken.
     */
    function createPToken(string memory _name, string memory _symbol, uint8 _decimals) external returns (IPToken);

    /**
     * @dev Sets the BucketsFactory address. Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param bucketsFactory The BucketsFactory address.
     */
    function setBucketsFactory(address bucketsFactory) external;

    /**
     * @dev Gets a BucketsFactory contract address.
     */
    function bucketsFactory() external view returns (address);

    /**
     * @dev Gets a Registry contract address.
     */
    function registry() external view returns (address);
}
