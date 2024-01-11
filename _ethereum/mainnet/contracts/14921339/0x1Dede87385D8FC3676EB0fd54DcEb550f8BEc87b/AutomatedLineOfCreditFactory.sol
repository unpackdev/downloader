// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20WithDecimals} from "IERC20WithDecimals.sol";
import {IAutomatedLineOfCredit} from "IAutomatedLineOfCredit.sol";
import {BasePortfolioFactory} from "BasePortfolioFactory.sol";

contract AutomatedLineOfCreditFactory is BasePortfolioFactory {
    function createPortfolio(
        uint256 _duration,
        IERC20WithDecimals _underlyingToken,
        uint256 _maxSize,
        IAutomatedLineOfCredit.InterestRateParameters memory _interestRateParameters,
        address _depositStrategy,
        address _withdrawStrategy,
        address _transferStrategy,
        string calldata name,
        string calldata symbol
    ) external onlyRole(MANAGER_ROLE) {
        bytes memory initCalldata = abi.encodeWithSelector(
            IAutomatedLineOfCredit.initialize.selector,
            protocolConfig,
            _duration,
            _underlyingToken,
            msg.sender,
            _maxSize,
            _interestRateParameters,
            _depositStrategy,
            _withdrawStrategy,
            _transferStrategy,
            name,
            symbol
        );
        _deployPortfolio(initCalldata);
    }
}
