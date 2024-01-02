// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ISFrxEth.sol";
import "./IFrxEthStableSwap.sol";
import "./IOracle.sol";
import "./ITokenOracle.sol";

/**
 * @title Oracle for `sFraxEthToken`
 * @dev Based on https://etherscan.deth.net/address/0x27942aFe4EcB7F9945168094e0749CAC749aC97B#code
 * @dev `WETH/FRXETH` Curve pool's oracle is safer than `ETH/FRXETH`
 */
contract SFraxEthTokenOracle is ITokenOracle {
    uint256 public constant MAX_FRXETH_PRICE = 1e18;
    uint256 public constant MIN_FRXETH_PRICE = 0.9e18;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IFrxEthStableSwap public constant WETH_FRXETH_CURVE_POOL =
        IFrxEthStableSwap(0x9c3B46C0Ceb5B9e304FCd6D88Fc50f7DD24B31Bc);
    ISFrxEth public constant SFRXETH = ISFrxEth(0xac3E018457B222d93114458476f3E3416Abbe38F);

    /// @inheritdoc ITokenOracle
    function getPriceInUsd(address) external view override returns (uint256 _priceInUsd) {
        // ETH/USD price from Chainlink
        uint256 _ethPriceInUsd = IOracle(msg.sender).getPriceInUsd(WETH);

        // FrxETH/ETH price
        uint256 _frxEthPriceInEth = WETH_FRXETH_CURVE_POOL.price_oracle();

        if (_frxEthPriceInEth > MAX_FRXETH_PRICE) {
            _frxEthPriceInEth = MAX_FRXETH_PRICE;
        } else if (_frxEthPriceInEth < MIN_FRXETH_PRICE) {
            _frxEthPriceInEth = MIN_FRXETH_PRICE;
        }

        // sFrxETH/FrxETH price from `pricePerShare`
        return ((SFRXETH.pricePerShare() * _frxEthPriceInEth * _ethPriceInUsd) / (1e36));
    }
}
