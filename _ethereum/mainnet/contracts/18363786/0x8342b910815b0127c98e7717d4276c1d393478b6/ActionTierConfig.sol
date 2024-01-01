// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "ImmutableOwner.sol";
import "DataTypes.sol";
import "ITierer.sol";
import "ITierStrategy.sol";

contract ActionTierConfig is ImmutableOwner, ITierer {
    mapping(bytes32 => ITierStrategy) internal _tierStrategies;

    constructor(
        address _owner,
        StrategyConfig[] memory configs
    ) ImmutableOwner(_owner) {
        // special case to allow to initialize the contract with itself
        // without knowing the address
        for (uint256 i; i < configs.length; i++) {
            if (configs[i]._contract == address(0)) {
                configs[i]._contract = address(this);
            }
        }

        _batchSetStrategy(configs, true);
    }

    struct StrategyConfig {
        address _contract;
        bytes4 _sig;
        address _strategy;
    }

    function _ruleKey(
        address _contract,
        bytes4 _sig
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_contract, _sig));
    }

    function initializeStrategy(
        address _contract,
        bytes4 _sig,
        address _strategy
    ) external onlyOwner {
        bytes32 ruleKey = _ruleKey(_contract, _sig);
        require(
            address(_tierStrategies[ruleKey]) == address(0),
            "strategy already set"
        );
        _tierStrategies[ruleKey] = ITierStrategy(_strategy);
    }

    function batchInitializeStrategy(
        StrategyConfig[] calldata configs
    ) external onlyOwner {
        _batchSetStrategy(configs, true);
    }

    function setStrategy(
        address _contract,
        bytes4 _sig,
        address _strategy
    ) external onlyOwner {
        _tierStrategies[_ruleKey(_contract, _sig)] = ITierStrategy(_strategy);
    }

    function batchSetStrategy(
        StrategyConfig[] calldata configs
    ) external onlyOwner {
        _batchSetStrategy(configs, false);
    }

    function _batchSetStrategy(
        StrategyConfig[] memory configs,
        bool initializing
    ) internal {
        for (uint256 i; i < configs.length; i++) {
            bytes32 ruleKey = _ruleKey(configs[i]._contract, configs[i]._sig);
            require(
                !initializing ||
                    address(_tierStrategies[ruleKey]) == address(0),
                "strategy already set"
            );
            _tierStrategies[ruleKey] = ITierStrategy(configs[i]._strategy);
        }
    }

    function getStrategy(
        address _contract,
        bytes4 _sig
    ) external view returns (address) {
        return address(_getStrategy(_contract, _sig));
    }

    function _getStrategy(
        address _contract,
        bytes4 _sig
    ) internal view returns (ITierStrategy) {
        ITierStrategy s = _tierStrategies[_ruleKey(_contract, _sig)];
        require(address(s) != address(0), "strategy not found");
        return s;
    }

    function getTier(
        address _contract,
        bytes calldata _calldata
    ) external view returns (DataTypes.Tier memory) {
        ITierStrategy strategy = _getStrategy(
            _contract,
            _getSelector(_calldata)
        );
        return strategy.getTier(_calldata);
    }

    function _getSelector(
        bytes memory _calldata
    ) internal pure returns (bytes4 out) {
        assembly {
            out := and(
                mload(add(_calldata, 32)),
                0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
            )
        }
    }
}
