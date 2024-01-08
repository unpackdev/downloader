// Be name Khoda
// Bime Abolfazl

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

import "./DEIPool.sol";

contract Pool_USDC is DEIPool {
    address public USDC_address;
    constructor(
        address _dei_contract_address,
        address _deus_contract_address,
        address _collateral_address,
        address _trusty_address,
        address _admin_address,
        uint256 _pool_ceiling,
        address _library
    ) 
    DEIPool(_dei_contract_address, _deus_contract_address, _collateral_address, _trusty_address, _admin_address, _pool_ceiling, _library)
    public {
        require(_collateral_address != address(0), "Zero address detected");

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        USDC_address = _collateral_address;
    }
}

//Dar panah khoda