// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";

import "./AggregatorInterface.sol";
import "./Denominations.sol";

import "./IChainLinkFeedsRegistry.sol";
import "./BinaryExp.sol";

contract ChainLinkFeedsRegistry is IChainLinkFeedsRegistry {
    using SafeMath for uint256;
    using SafeMath for uint256;

    mapping(address => Registry) public assets2USD;
    mapping(address => Registry) public assets2ETH;

    address public nextgov;
    address public governance;
    address public immutable USD;
    address public immutable WETH;

    modifier onlyGov() {
        require(msg.sender == governance, "gov");
        _;
    }

    function transferGovernance(address _nextgov) external onlyGov {
        nextgov = _nextgov;
    }

    function acceptGovrnance() external {
        require(msg.sender == nextgov, "nextgov");
        governance = nextgov;
        nextgov = address(0);
    }

    constructor(
        address _governance,
        address _weth,
        InputInitParam[] memory params
    ) {
        governance = _governance;
        WETH = _weth;
        USD = Denominations.USD;
        for (uint256 i = 0; i < params.length; i++) {
            if (params[i].isUSD) {
                assets2USD[params[i].asset] = Registry({
                    index: params[i].registry,
                    decimals: params[i].decimals
                });
            } else {
                assets2ETH[params[i].asset] = Registry({
                    index: params[i].registry,
                    decimals: params[i].decimals
                });
            }
        }
    }

    // VIEW
    // All USD registry decimals is 8, all ETH registry decimals is 18

    // Return 1e8
    function getUSDPrice(address asset)
        external
        view
        override
        returns (uint256)
    {
        uint256 price = 0;
        if (assets2USD[asset].index != address(0)) {
            price = uint256(
                AggregatorInterface(assets2USD[asset].index).latestAnswer()
            );
        } else if (
            assets2ETH[asset].index != address(0) &&
            assets2USD[WETH].index != address(0)
        ) {
            uint256 tokenETHPrice = uint256(
                AggregatorInterface(assets2ETH[asset].index).latestAnswer()
            );
            uint256 ethUSDPrice = uint256(
                AggregatorInterface(assets2USD[WETH].index).latestAnswer()
            );
            price = tokenETHPrice.mul(ethUSDPrice).div(
                BinaryExp.pow(10, assets2ETH[asset].decimals)
            );
        }
        return price;
    }

    // Returns 1e18
    function getETHPrice(address asset)
        external
        view
        override
        returns (uint256)
    {
        uint256 price = 0;
        if (assets2ETH[asset].index != address(0)) {
            price = uint256(
                AggregatorInterface(assets2ETH[asset].index).latestAnswer()
            );
        }
        return price;
    }

    function addUSDFeed(
        address asset,
        address index,
        uint256 decimals
    ) external override onlyGov {
        assets2USD[asset] = Registry({index: index, decimals: decimals});
    }

    function addETHFeed(
        address asset,
        address index,
        uint256 decimals
    ) external override onlyGov {
        assets2ETH[asset] = Registry({index: index, decimals: decimals});
    }

    function removeUSDFeed(address asset) external override onlyGov {
        delete assets2USD[asset];
    }

    function removeETHFeed(address asset) external override onlyGov {
        delete assets2ETH[asset];
    }
}
