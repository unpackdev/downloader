//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./NiftyKitOperator.sol";
import "./NiftyKitStorefront.sol";

contract NiftyKitMaster is NiftyKitOperator, NiftyKitStorefront {
    constructor(uint256 commission, address treasury) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        setCommission(commission);
        setTreasury(treasury);
    }
}
