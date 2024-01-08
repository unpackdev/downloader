// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <council@enzyme.finance>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./ValueInterpreter.sol";

/// @title AssetValueCalculator Contract
/// @author Enzyme Council <security@enzyme.finance>
/// @notice A peripheral contract for calculating asset values
/// @dev These are convenience functions intended for off-chain consumption,
/// some of which involve potentially expensive state transitions
contract AssetValueCalculator {
    address private immutable VALUE_INTERPRETER;

    constructor(address _valueInterpreter) public {
        VALUE_INTERPRETER = _valueInterpreter;
    }

    // EXTERNAL FUNCTIONS

    /// @notice Calculates the value of a given amount of one asset in terms of another asset
    /// @param _baseAsset The asset from which to convert
    /// @param _amount The amount of the _baseAsset to convert
    /// @param _quoteAsset The asset to which to convert
    /// @return timestamp_ The current block timestamp
    /// @return value_ The equivalent quantity in the _quoteAsset
    function calcCanonicalAssetValue(
        address _baseAsset,
        uint256 _amount,
        address _quoteAsset
    )
        external
        returns (
            uint256 timestamp_,
            uint256 value_,
            bool valueIsValid_
        )
    {
        timestamp_ = block.timestamp;

        try
            ValueInterpreter(getValueInterpreter()).calcCanonicalAssetValue(
                _baseAsset,
                _amount,
                _quoteAsset
            )
        returns (uint256 value, bool isValid) {
            if (isValid) {
                value_ = value;
                valueIsValid_ = true;
            }
        } catch {}

        return (timestamp_, value_, valueIsValid_);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `VALUE_INTERPRETER` variable
    /// @return valueInterpreter_ The `VALUE_INTERPRETER` variable value
    function getValueInterpreter() public view returns (address valueInterpreter_) {
        return VALUE_INTERPRETER;
    }
}
