// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./Auth.sol";
import "./IUniV2.sol";

/// @notice Contract for withdrawing LP positions.
/// @dev Calling unwindPairs() withdraws the LP position into one of the two tokens
contract Unwindooor is Auth {

    error SlippageProtection();
    error TransferFailed();

    bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    constructor(address _owner, address _user) Auth(_owner, _user) {}

    function unwindPairs(
        IUniV2[] calldata lpTokens,
        uint256[] calldata amounts,
        uint256[] calldata minimumOuts,
        bool[] calldata keepToken0
    ) external onlyTrusted {
        for (uint256 i = 0; i < lpTokens.length; i++) {
            if (_unwindPair(lpTokens[i], amounts[i], keepToken0[i]) < minimumOuts[i]) revert SlippageProtection();
        }
    }

    // Burn liquidity and sell one of the tokens for the other.
    function _unwindPair(
        IUniV2 pair,
        uint256 amount,
        bool keepToken0
    ) private returns (uint256 amountOut) {

        pair.transfer(address(pair), amount);
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        if (keepToken0) {
            _safeTransfer(pair.token1(), address(pair), amount1);
            amountOut = _getAmountOut(amount1, uint256(reserve1), uint256(reserve0));
            pair.swap(amountOut, 0, address(this), "");
            amountOut += amount0;
        } else {
            _safeTransfer(pair.token0(), address(pair), amount0);
            amountOut = _getAmountOut(amount0, uint256(reserve0), uint256(reserve1));
            pair.swap(0, amountOut, address(this), "");
            amountOut += amount1;
        }
    }

    // Incase we don't want to sell one of the tokens for the other.
    function burnPairs(
        IUniV2[] calldata lpTokens,
        uint256[] calldata amounts,
        uint256[] calldata minimumOut0,
        uint256[] calldata minimumOut1
    ) external onlyTrusted {
        for (uint256 i = 0; i < lpTokens.length; i++) {
            IUniV2 pair = lpTokens[i];
            pair.transfer(address(pair), amounts[i]);
            (uint256 amount0, uint256 amount1) = pair.burn(address(this));
            if (amount0 < minimumOut0[i] || amount1 < minimumOut1[i]) revert SlippageProtection();
        }
    }

    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256) {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        return numerator / denominator;
    }

    function _safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_SELECTOR, to, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
    }

}
