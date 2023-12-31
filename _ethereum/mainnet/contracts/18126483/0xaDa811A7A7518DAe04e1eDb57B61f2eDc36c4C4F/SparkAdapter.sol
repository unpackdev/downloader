// SPDX-License-Identifier: AGPL-3.0-or-later

/// SparkAdapter.sol

// Copyright (C) 2023 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.0;

import "./SparkProxyActions.sol";
import "./IAccountImplementation.sol";
import "./IAdapter.sol";
import "./McdView.sol";

contract SparkAdapter is IExecutableAdapter {
    address public immutable sparkPA;
    address public immutable botAddress;
    string private constant SPARK_PROXY_ACTIONS = "SPARK_PROXY_ACTIONS";
    string private constant AUTOMATION_BOT_KEY = "AUTOMATION_BOT_V2";

    constructor(ServiceRegistry _serviceRegistry) {
        sparkPA = _serviceRegistry.getRegisteredService(SPARK_PROXY_ACTIONS);
        botAddress = _serviceRegistry.getRegisteredService(AUTOMATION_BOT_KEY);
    }

    function decode(
        bytes memory triggerData
    )
        public
        pure
        returns (address proxyAddress, uint256 triggerType, uint256 maxCoverage, address debtToken)
    {
        (proxyAddress, triggerType, maxCoverage, debtToken) = abi.decode(
            triggerData,
            (address, uint16, uint256, address)
        );
    }

    function getCoverage(
        bytes memory triggerData,
        address receiver,
        address coverageToken,
        uint256 amount
    ) external {
        require(msg.sender == botAddress, "spark-adapter/only-bot");
        (address proxy, , uint256 maxCoverage, address debtToken) = decode(triggerData);
        require(debtToken == coverageToken, "spark-adapter/invalid-coverage-token");
        require(amount <= maxCoverage, "spark-adapter/coverage-too-high");
        //reverts if code fails
        IAccountImplementation(proxy).execute(
            sparkPA,
            abi.encodeWithSelector(
                SparkProxyActions.drawDebt.selector,
                coverageToken,
                receiver,
                amount
            )
        );
    }
}
