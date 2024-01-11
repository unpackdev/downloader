// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "./IERC20.sol";
import "./Utils.sol";
import "./AugustusStorage.sol";

interface IWETHGateway {
    function depositETH(
        address lendingPool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(
        address lendingPool,
        uint256 amount,
        address onBehalfOf
    ) external;
}

interface IAaveLendingPool {
    function deposit(
        IERC20 asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        IERC20 asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

contract Aavee2 {
    struct AaveeData {
        address aToken;
    }

    uint16 public immutable refCode;
    address public immutable lendingPool;
    address public immutable wethGateway;

    constructor(
        uint16 _refCode,
        address _lendingPool,
        address _wethGateway
    ) public {
        refCode = _refCode;
        lendingPool = _lendingPool;
        wethGateway = _wethGateway;
    }

    function swapOnAaveeV2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        bytes calldata payload
    ) internal {
        _swapOnAaveeV2(fromToken, toToken, fromAmount, payload);
    }

    function buyOnAaveeV2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        bytes calldata payload
    ) internal {
        _swapOnAaveeV2(fromToken, toToken, fromAmount, payload);
    }

    function _swapOnAaveeV2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        bytes memory payload
    ) private {
        AaveeData memory data = abi.decode(payload, (AaveeData));

        if (address(fromToken) == address(data.aToken)) {
            if (address(toToken) == Utils.ethAddress()) {
                Utils.approve(wethGateway, address(fromToken), fromAmount);
                IWETHGateway(wethGateway).withdrawETH(lendingPool, fromAmount, address(this));
            } else {
                Utils.approve(lendingPool, address(fromToken), fromAmount);
                IAaveLendingPool(lendingPool).withdraw(toToken, fromAmount, address(this));
            }
        } else if (address(toToken) == address(data.aToken)) {
            if (address(fromToken) == Utils.ethAddress()) {
                IWETHGateway(wethGateway).depositETH{ value: fromAmount }(lendingPool, address(this), refCode);
            } else {
                Utils.approve(lendingPool, address(fromToken), fromAmount);
                IAaveLendingPool(lendingPool).deposit(fromToken, fromAmount, address(this), refCode);
            }
        } else {
            revert("Invalid aToken");
        }
    }
}
