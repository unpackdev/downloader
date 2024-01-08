// SPDX-License-Identifier: MIT
//  ______   ______     _____
// /\__  _\ /\  == \   /\  __-.
// \/_/\ \/ \ \  __<   \ \ \/\ \
//    \ \_\  \ \_____\  \ \____-
//     \/_/   \/_____/   \/____/
//
pragma solidity 0.8.6;

import "./Initializable.sol";

import "./Versioned.sol";
import "./Pausable.sol";
import "./Adapter.sol";
import "./HegicETHOptions.888.sol";
import "./HegicWBTCOptions.888.sol";
import "./OptionType.888.sol";

//
//   ___ _ __ _ __ ___  _ __ ___
//  / _ \ '__| '__/ _ \| '__/ __|
// |  __/ |  | | | (_) | |  \__ \
//  \___|_|  |_|  \___/|_|  |___/
//
// Hegic888AdapterV1_1  => Invalid data length received
// Hegic888AdapterV1_2  => Invalid currency length received. Should be 1 (only ETH)
// Hegic888AdapterV1_3  => Invalid amounts length received. Should be 1 (only ETH)
// Hegic888AdapterV1_4  => While process ETH option purchase, invalid currency found, expected address(0) for ETH
// Hegic888AdapterV1_5  => While process ETH option purchase, amount received is not enough to perform purchase
// Hegic888AdapterV1_6  => While process ETH option purchase, an error occured when trying to send back extra ETH received
// Hegic888AdapterV1_7  => While process WBTC option purchase, invalid currency found, expected address(0) for ETH
// Hegic888AdapterV1_8  => While process WBTC option purchase, amount received is not enough to perform purchase
// Hegic888AdapterV1_9  => While process WBTC option purchase, an error occured when trying to send back extra ETH received
// Hegic888AdapterV1_10 => Invalid asset type provided

/// @title Hegic888AdapterV1
/// @author Iulian Rotaru
/// @notice Adapter to purchase Hegic ETH or WBTC options
contract Hegic888AdapterV1 is Versioned, Pausable, Adapter {
    //
    //      _        _
    //  ___| |_ __ _| |_ ___
    // / __| __/ _` | __/ _ \
    // \__ \ || (_| | ||  __/
    // |___/\__\__,_|\__\___|
    //

    // Address of Hegic ETH options contract
    HegicETHOptionsV888 public hegicEthOptions;

    // Address of Hegic WBTC options contract
    HegicWBTCOptionsV888 public hegicWbtcOptions;

    //
    //   ___ _ __  _   _ _ __ ___  ___
    //  / _ \ '_ \| | | | '_ ` _ \/ __|
    // |  __/ | | | |_| | | | | | \__ \
    //  \___|_| |_|\__,_|_| |_| |_|___/
    //

    // Enum of supported asset types
    enum AssetType {
        Eth,
        Wbtc
    }

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
        require(data.length == 160, 'Hegic888AdapterV1_1');
        require(currencies.length == 1, 'Hegic888AdapterV1_2');
        require(amounts.length == 1, 'Hegic888AdapterV1_3');

        AssetType _assetType; // Stack depth optimizations
        uint256 total;
        uint256[] memory totalETH = new uint256[](1);
        uint256 optionID;

        {
            OptionTypeV888.OptionType _optionType;
            uint256 _period;
            uint256 _amount;
            uint256 _strike;
            (_optionType, _assetType, _period, _amount, _strike) = abi.decode(
                data,
                (OptionTypeV888.OptionType, AssetType, uint256, uint256, uint256)
            );

            if (_assetType == AssetType.Eth) {
                require(currencies[0] == address(0), 'Hegic888AdapterV1_4');
                (total, , , ) = hegicEthOptions.fees(_period, _amount, _strike, _optionType);
                totalETH[0] = total;
                require(msg.value >= totalETH[0], 'Hegic888AdapterV1_5');
                optionID = hegicEthOptions.create{value: totalETH[0]}(_period, _amount, _strike, _optionType);

                if (address(this).balance > 0) {
                    (bool success, ) = payable(caller).call{value: address(this).balance}('');
                    require(success, 'Hegic888AdapterV1_6');
                }
            } else if (AssetType(_assetType) == AssetType.Wbtc) {
                require(currencies[0] == address(0), 'Hegic888AdapterV1_7');
                (total, totalETH[0], , , ) = hegicWbtcOptions.fees(_period, _amount, _strike, _optionType);
                require(msg.value >= totalETH[0], 'Hegic888AdapterV1_8');
                optionID = hegicWbtcOptions.create{value: totalETH[0]}(_period, _amount, _strike, _optionType);

                if (address(this).balance > 0) {
                    (bool success, ) = payable(caller).call{value: address(this).balance}('');
                    require(success, 'Hegic888AdapterV1_9');
                }
            } else {
                revert('Hegic888AdapterV1_10');
            }
        }

        if (_assetType == AssetType.Wbtc) {
            hegicWbtcOptions.transfer(optionID, payable(caller));
        } else {
            hegicEthOptions.transfer(optionID, payable(caller));
        }

        return (totalETH, abi.encode(total, optionID));
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
        return 'Hegic888V1';
    }

    //
    //  _       _ _
    // (_)_ __ (_) |_
    // | | '_ \| | __|
    // | | | | | | |_
    // |_|_| |_|_|\__|
    //

    function __Hegic888AdapterV1__constructor(address _gateway, address _hegicEthOptions, address _hegicWbtcOptions)
        public
        initVersion(1)
    {
        hegicEthOptions = HegicETHOptionsV888(_hegicEthOptions);
        hegicWbtcOptions = HegicWBTCOptionsV888(_hegicWbtcOptions);
        setGateway(_gateway);
    }
}
