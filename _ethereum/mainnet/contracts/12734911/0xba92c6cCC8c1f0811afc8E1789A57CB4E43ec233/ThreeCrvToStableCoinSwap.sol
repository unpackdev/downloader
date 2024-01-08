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

contract ThreeCrvToStableCoinSwap {
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
        require(_from == basePoolToken, "from token not a 3crv token");
        (bool isBase, int128 index, uint256 n_coin) = _isBaseToken(_from);
        IERC20(_from).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 returnAmount;
        if (isBase) {
            returnAmount = _swapToBasePoolCoins(
                _from,
                _to,
                _amount,
                index,
                _minReturn
            );
        } else {
            returnAmount = _swapBaseToNonBaseToken(
                _to,
                _amount,
                n_coin,
                _minReturn
            );
        }
        IERC20(_to).safeTransfer(msg.sender, returnAmount);
        return returnAmount;
    }

    /// @notice swap 3crv tokens into three pool base tokens (DAI,USDC,USDT)
    function _swapToBasePoolCoins(
        address _from,
        address _to,
        uint256 _amount,
        int128 index,
        uint256 _minReturn
    ) private returns (uint256) {
        // IERC20(_from).safeApprove(basePool, _amount);
        _approveToken(_from, basePool, _amount);
        uint256 balanceBefore = IERC20(_to).balanceOf(address(this));
        CurveBase(basePool).remove_liquidity_one_coin(
            _amount,
            index,
            _minReturn
        );
        uint256 balanceAfter = IERC20(_to).balanceOf(address(this));
        uint256 _returnAmount = balanceAfter.sub(balanceBefore);
        return _returnAmount;
    }

    /// @notice swap 3crv tokens into base tokens
    function _swapBaseToNonBaseToken(
        address _to,
        uint256 _amount,
        uint256 _baseCoinLength,
        uint256 _minReturn
    ) private returns (uint256) {
        address mainRegistry = ICurveFunctions(curveAddressProvider)
        .get_address(0);
        address swapRegistry = ICurveFunctions(curveAddressProvider)
        .get_address(2);
        address[8] memory baseTokens = ICurveFunctions(mainRegistry).get_coins(
            basePool
        );
        for (uint256 i; i < _baseCoinLength; i++) {
            (address _pool, ) = ICurveSwap(swapRegistry).get_best_rate(
                baseTokens[i],
                _to,
                _amount
            );
            if (_pool != address(0)) {
                uint256 _returnedBasecoins = _swapToBasePoolCoins(
                    basePoolToken,
                    baseTokens[i],
                    _amount,
                    int128(uint128(i)),
                    0
                );
                _approveToken(
                    baseTokens[i],
                    stableCoinSwapper,
                    _returnedBasecoins
                );

                uint256 returnAmount = IYieldsterExchange(stableCoinSwapper)
                .swap(baseTokens[i], _to, _returnedBasecoins, _minReturn);

                return (returnAmount);
            }
        }
        revert("no swappable pool");
    }

    function _isBaseToken(address _token)
        private
        view
        returns (
            bool status,
            int128 index,
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
        for (int128 i; uint256(int256(i)) < n_coin[0]; i++) {
            if (_token == baseTokens[uint256(int256(i))]) {
                return (true, i, n_coin[0]);
            }
        }
        return (false, 0, n_coin[0]);
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
