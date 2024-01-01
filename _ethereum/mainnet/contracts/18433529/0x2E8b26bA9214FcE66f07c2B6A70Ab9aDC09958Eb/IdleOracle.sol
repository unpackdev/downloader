// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IdleCDO.sol";
import "./IdleCDOTranche.sol";
import "./FullMath.sol";
import "./IBaseOracle.sol";

contract IdleOracle is IBaseOracle {
    function quote(
        address token,
        uint256 amount,
        bytes memory
    ) public view override returns (address[] memory tokens, uint256[] memory tokenAmounts) {
        IdleCDO minter = IdleCDO(IdleCDOTranche(token).minter());
        tokens = new address[](1);
        tokens[0] = minter.token();

        tokenAmounts = new uint256[](1);
        tokenAmounts[0] = (amount * minter.tranchePrice(token)) / minter.ONE_TRANCHE_TOKEN();
    }
}
