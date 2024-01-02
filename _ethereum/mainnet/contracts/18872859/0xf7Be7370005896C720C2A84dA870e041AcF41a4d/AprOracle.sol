// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.21;

import "./IStrategy.sol";
import "./IOracle.sol";

contract AprOracle {
    mapping(address => address) public oracles;

    function getExpectedApr(
        address _strategy,
        int256 _debtChange
    ) external view returns (uint256) {
        address oracle = oracles[_strategy];

        // Will revert if a oracle is not set.
        return IOracle(oracle).aprAfterDebtChange(_strategy, _debtChange);
    }

    function getUtilizationInfo(
        address _strategy
    ) external view returns (uint256, uint256) {
        address oracle = oracles[_strategy];

        // Will revert if a oracle is not set.
        return IOracle(oracle).getUtilizationInfo(_strategy);
    }

    function setOracle(address _strategy, address _oracle) external {
        require(msg.sender == IStrategy(_strategy).management(), "!authorized");

        oracles[_strategy] = _oracle;
    }
}
