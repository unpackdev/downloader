// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ArthPool.sol";

contract Pool_WMATIC is ArthPool {
    /**
     * State variable.
     */
    address public WMATIC_address;

    /**
     * Constructor.
     */
    constructor(
        address _arthContractAddres,
        address _arthxContractAddres,
        address _collateralAddress,
        address _creatorAddress,
        address _timelockAddress,
        address _mahaToken,
        address _arthController,
        uint256 _poolCeiling
    )
        ArthPool(
            _arthContractAddres,
            _arthxContractAddres,
            _collateralAddress,
            _creatorAddress,
            _timelockAddress,
            _mahaToken,
            _arthController,
            _poolCeiling
        )
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        WMATIC_address = _collateralAddress;
    }
}
