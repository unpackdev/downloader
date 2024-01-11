// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

abstract contract CohortFactory {
    /**
     * @notice factory owner
     * @return owner
     */
    function owner() public view virtual returns (address);

    /**
     * @notice derive storage contracts
     * @return registry contract address
     * @return nftManager contract address
     * @return rewardRegistry contract address
     */

    function getStorageContracts()
        public
        view
        virtual
        returns (
            address registry,
            address nftManager,
            address rewardRegistry
        );
}
