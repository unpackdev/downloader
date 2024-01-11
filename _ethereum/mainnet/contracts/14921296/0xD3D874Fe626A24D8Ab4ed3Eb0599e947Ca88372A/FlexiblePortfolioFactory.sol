// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IFlexiblePortfolio} from "IFlexiblePortfolio.sol";
import {IERC20WithDecimals} from "IERC20WithDecimals.sol";
import {IDebtInstrument} from "IDebtInstrument.sol";
import {IValuationStrategy} from "IValuationStrategy.sol";
import {BasePortfolioFactory} from "BasePortfolioFactory.sol";

contract FlexiblePortfolioFactory is BasePortfolioFactory {
    function createPortfolio(
        IERC20WithDecimals _underlyingToken,
        uint256 _duration,
        uint256 _maxValue,
        IFlexiblePortfolio.Strategies calldata strategies,
        IDebtInstrument[] calldata _allowedInstruments,
        uint256 _managerFee,
        IFlexiblePortfolio.ERC20Metadata calldata tokenMetadata
    ) external onlyRole(MANAGER_ROLE) {
        bytes memory initCalldata = abi.encodeWithSelector(
            IFlexiblePortfolio.initialize.selector,
            protocolConfig,
            _duration,
            _underlyingToken,
            msg.sender,
            _maxValue,
            strategies,
            _allowedInstruments,
            _managerFee,
            tokenMetadata
        );
        _deployPortfolio(initCalldata);
    }
}
