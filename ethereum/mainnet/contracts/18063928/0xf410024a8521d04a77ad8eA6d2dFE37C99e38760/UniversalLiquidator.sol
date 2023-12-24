// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// imported contracts and libraries
import "./Ownable.sol";
import "./SafeERC20.sol";

// interfaces
import "./IERC20.sol";
import "./IUniversalLiquidator.sol";
import "./IUniversalLiquidatorRegistry.sol";
import "./ILiquidityDex.sol";

// libraries
import "./DataTypes.sol";
import "./Errors.sol";

contract UniversalLiquidator is Ownable, IUniversalLiquidator {
    using SafeERC20 for IERC20;

    address public pathRegistry;

    function swap(address _sellToken, address _buyToken, uint256 _sellAmount, uint256 _minBuyAmount, address _receiver)
        external
        override
        returns (uint256 receiveAmt)
    {
        DataTypes.SwapInfo[] memory swapInfo = IUniversalLiquidatorRegistry(pathRegistry).getPath(_sellToken, _buyToken);

        IERC20(_sellToken).safeTransferFrom(msg.sender, swapInfo[0].dex, _sellAmount);

        uint256 minBuyAmount;
        address receiver;
        for (uint256 idx; idx < swapInfo.length;) {
            if (idx != swapInfo.length - 1) {
                // if not last element, set receiver to next dex and set minBuyAmount to 1
                minBuyAmount = 1;
                receiver = swapInfo[idx + 1].dex;
            } else {
                // if last element, set minBuyAmount to _minBuyAmount
                minBuyAmount = _minBuyAmount;
                receiver = _receiver;
            }
            receiveAmt = _swap(
                IERC20(swapInfo[idx].paths[0]).balanceOf(swapInfo[idx].dex),
                minBuyAmount,
                receiver,
                swapInfo[idx].dex,
                swapInfo[idx].paths
            );
            unchecked {
                ++idx;
            }
        }
    }

    function _swap(uint256 _sellAmount, uint256 _minBuyAmount, address _receiver, address _dex, address[] memory _path)
        internal
        returns (uint256 receiveAmt)
    {
        receiveAmt = ILiquidityDex(_dex).doSwap(_sellAmount, _minBuyAmount, _receiver, _path);

        emit Swap(_path[0], _path[_path.length - 1], _receiver, msg.sender, _sellAmount, _minBuyAmount);
    }

    function setPathRegistry(address _pathRegistry) public onlyOwner {
        if (_pathRegistry == address(0)) revert Errors.InvalidAddress();
        pathRegistry = _pathRegistry;
    }

    receive() external payable {}
}
