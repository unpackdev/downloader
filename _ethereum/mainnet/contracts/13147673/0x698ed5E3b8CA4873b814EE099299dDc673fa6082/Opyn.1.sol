// SPDX-License-Identifier: MIT
//  ______   ______     _____
// /\__  _\ /\  == \   /\  __-.
// \/_/\ \/ \ \  __<   \ \ \/\ \
//    \ \_\  \ \_____\  \ \____-
//     \/_/   \/_____/   \/____/
//
pragma solidity 0.8.6;

import "./Initializable.sol";
import "./IERC20.sol";

import "./Versioned.sol";
import "./Pausable.sol";
import "./Adapter.sol";
import "./IZeroExV4Exchange.sol";

//
//   ___ _ __ _ __ ___  _ __ ___
//  / _ \ '__| '__/ _ \| '__/ __|
// |  __/ |  | | | (_) | |  \__ \
//  \___|_|  |_|  \___/|_|  |___/
//
// OpynAdapterV1_1 => No oToken were purchased

contract OpynAdapterV1 is Versioned, Pausable, Adapter {
    //
    //      _        _
    //  ___| |_ __ _| |_ ___
    // / __| __/ _` | __/ _ \
    // \__ \ || (_| | ||  __/
    // |___/\__\__,_|\__\___|
    //

    // Address of 0x exchange
    IZeroExV4Exchange public zeroExV4Exchange;

    //
    //  _       _                        _
    // (_)_ __ | |_ ___ _ __ _ __   __ _| |___
    // | | '_ \| __/ _ \ '__| '_ \ / _` | / __|
    // | | | | | ||  __/ |  | | | | (_| | \__ \
    // |_|_| |_|\__\___|_|  |_| |_|\__,_|_|___/
    //

    /// @dev Perform an option purchase
    /// @param caller Address purchasing the option
    /// @param currencies List of usable currencies
    /// @param amounts List of usable currencies amounts
    /// @param data Extra data usable by adapter
    /// @return A tuple containing used amounts and output data
    function purchase(
        address caller,
        address[] memory currencies,
        uint256[] memory amounts,
        bytes calldata data
    ) internal override returns (uint256[] memory, bytes memory) {
        address token;
        address takerToken;
        bool success;
        uint256 takerTokenAmount;
        uint128 takerTokenFilledAmount;
        uint128 makerTokenFilledAmount;

        {
            uint256 etherValue;
            bytes memory callData;

            (token, callData) = abi.decode(data, (address, bytes));

            for (uint256 idx = 0; idx < currencies.length; ++idx) {
                if (currencies[idx] == address(0)) {
                    etherValue = amounts[idx];
                } else {
                    takerTokenAmount = amounts[idx];
                    takerToken = currencies[idx];
                    IERC20(currencies[idx]).approve(address(zeroExV4Exchange), takerTokenAmount);
                }
            }
            (success, callData) = address(zeroExV4Exchange).call{value: etherValue}(callData);
            require(success, string(callData));
            (takerTokenFilledAmount, makerTokenFilledAmount) = abi.decode(callData, (uint128, uint128));
            require(makerTokenFilledAmount > 0, 'OpynAdapterV1_1');
        }

        if (takerTokenAmount > takerTokenFilledAmount) {
            IERC20(takerToken).transfer(caller, takerTokenAmount - takerTokenFilledAmount);
        }

        IERC20(token).transfer(caller, makerTokenFilledAmount);

        return (
            amounts,
            abi.encode(takerToken, token, uint256(takerTokenFilledAmount), uint256(makerTokenFilledAmount))
        );
    }

    //
    //            _                        _
    //   _____  _| |_ ___ _ __ _ __   __ _| |___
    //  / _ \ \/ / __/ _ \ '__| '_ \ / _` | / __|
    // |  __/>  <| ||  __/ |  | | | | (_| | \__ \
    //  \___/_/\_\\__\___|_|  |_| |_|\__,_|_|___/
    //

    /// @dev Retrieve adapter name
    /// @return Adapter name
    function name() external pure override returns (string memory) {
        return 'OpynV1';
    }

    //
    //  _       _ _
    // (_)_ __ (_) |_
    // | | '_ \| | __|
    // | | | | | | |_
    // |_|_| |_|_|\__|
    //

    function __OpynAdapterV1__constructor(address _gateway, IZeroExV4Exchange _zeroExV4Exchange) public initVersion(1) {
        zeroExV4Exchange = _zeroExV4Exchange;
        setGateway(_gateway);
    }
}
