// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICurveFunctions.sol";
import "./ICurveSwap.sol";
import "./ICurveUSDCPoolExchange.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

interface CurveBase {
    function add_liquidity(uint256[3] calldata, uint256) external;

    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    ) external;
}

interface IYieldsterExchange {
    function swap(
        address,
        address,
        uint256,
        uint256
    ) external returns (uint256);
}

contract Stable3crvSwap {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    address public curveAddressProvider;
    address public owner;
    address public stableCoinSwapper;

    address public basePool;
    address public basePoolToken;
    address[] public baseUnderlying;

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    constructor(address _stableCoinSwapper) {
        owner = msg.sender;
        curveAddressProvider = address(
            0x0000000022D53366457F9d5E68Ec105046FC4383
        );
        stableCoinSwapper = _stableCoinSwapper;
        basePool = address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
        basePoolToken = (0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function changeAddressProvider(address _newAddress) external onlyOwner {
        curveAddressProvider = _newAddress;
    }

    function swap(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _minReturn
    ) external returns (uint256) {
        (bool isBase, uint256 index, uint256 n_coin) = _isBaseToken(_from);
        IERC20(_from).safeTransferFrom(msg.sender, address(this), _amount);
        uint256[3] memory baseTokenShare;

        if (!isBase) {
            (
                uint256 returnAmount,
                uint256 baseTokenIndex,
                address _swappedAsset
            ) = _swapNonBase(_from, _amount, n_coin);
            _approveToken(_swappedAsset, basePool, returnAmount);
            // IERC20(_swappedAsset).safeApprove(basePool, returnAmount);
            baseTokenShare[baseTokenIndex] = returnAmount;
        } else {
            baseTokenShare[index] = _amount;
            // IERC20(_from).safeApprove(basePool, _amount);
            _approveToken(_from, basePool, _amount);
        }
        uint256 balanceBefore = IERC20(_to).balanceOf(address(this));
        CurveBase(basePool).add_liquidity(baseTokenShare, _minReturn);
        uint256 balanceAfter = IERC20(_to).balanceOf(address(this));
        uint256 _returnAmount = balanceAfter.sub(balanceBefore);
        IERC20(_to).safeTransfer(msg.sender, _returnAmount);
        return _returnAmount;
    }

    function _isBaseToken(address _token)
        private
        view
        returns (
            bool status,
            uint256 index,
            uint256 length
        )
    {
        address mainRegistry = ICurveFunctions(curveAddressProvider)
        .get_address(0);
        uint256[2] memory n_coin = ICurveFunctions(mainRegistry).get_n_coins(
            basePool
        );
        address[8] memory baseTokens = ICurveFunctions(mainRegistry).get_coins(
            basePool
        );
        for (uint256 i; i < n_coin[0]; i++) {
            if (_token == baseTokens[i]) {
                return (true, i, n_coin[0]);
            }
        }
        return (false, 0, n_coin[0]);
    }

    function _swapNonBase(
        address _from,
        uint256 _amount,
        uint256 _baseCoinLength
    )
        private
        returns (
            uint256,
            uint256,
            address
        )
    {
        address mainRegistry = ICurveFunctions(curveAddressProvider)
        .get_address(0);
        address swapRegistry = ICurveFunctions(curveAddressProvider)
        .get_address(2);
        address[8] memory baseTokens = ICurveFunctions(mainRegistry).get_coins(
            basePool
        );
        for (uint256 i; i < _baseCoinLength; i++) {
            (address _pool, ) = ICurveSwap(swapRegistry).get_best_rate(
                _from,
                baseTokens[i],
                _amount
            );
            if (_pool != address(0)) {
                // IERC20(_from).safeApprove(stableCoinSwapper, _amount);

                _approveToken(_from, stableCoinSwapper, _amount);
                uint256 returnAmount = IYieldsterExchange(stableCoinSwapper)
                .swap(_from, baseTokens[i], _amount, 0);

                return (returnAmount, i, baseTokens[i]);
            }
        }
        revert("no swappable pool");
    }

    function _approveToken(
        address _token,
        address _spender,
        uint256 _amount
    ) internal {
        if (IERC20(_token).allowance(address(this), _spender) > 0) {
            IERC20(_token).safeApprove(_spender, 0);
            IERC20(_token).safeApprove(_spender, _amount);
        } else IERC20(_token).safeApprove(_spender, _amount);
    }
}
