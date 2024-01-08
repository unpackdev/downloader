//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

import "./IRecipe.sol";
import "./ILimaToken.sol";
import "./SafeERC20.sol";
import "./Context.sol";
import "./Ownable.sol";

contract AmunLendingRecipe is IRecipe, Ownable {
    using SafeERC20 for IERC20;

    function bake(
        address _inputToken,  // USDC
        address _outputToken, // ALEND
        uint256 _maxInput,
        bytes memory _data
    ) external override returns(uint256 inputAmountUsed, uint256 outputAmount) {
        IERC20 inputToken = IERC20(_inputToken);
        IERC20 outputToken = IERC20(_outputToken);

        inputToken.safeTransferFrom(_msgSender(), address(this), _maxInput);

        (uint256 mintAmount) = abi.decode(_data, (uint256));
        inputToken.approve(_outputToken, _maxInput);
        ILimaToken(_outputToken).create(inputToken, _maxInput, address(this), mintAmount, 0);

        outputAmount = outputToken.balanceOf(address(this));
        outputToken.safeTransfer(_msgSender(), outputAmount);

        return(_maxInput, outputAmount);
    }

    function encodeData(uint256 _outputAmount) external pure returns(bytes memory){
        return abi.encode((_outputAmount));
    }
}