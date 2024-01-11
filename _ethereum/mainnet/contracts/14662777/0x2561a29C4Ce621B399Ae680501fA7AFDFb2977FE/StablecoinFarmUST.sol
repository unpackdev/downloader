//SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "./IRouter.sol";
import "./StablecoinFarm.sol";

/**
    Special farm for UST as ETH Anchor doesn't have a conversion pool for UST.
 */
contract StablecoinFarmUST is StablecoinFarm {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    
    IRouter immutable public router;

    constructor(
        IRouter _router,
        IConversionPool _conversionPool,
        IERC20 _inputToken, 
        IERC20 _outputToken, 
        address _feeCollector,
        uint24 _feePercentage,
        uint128 _autoGlobalDepositAmount
    ) StablecoinFarm(_conversionPool, _inputToken, _outputToken, _inputToken, _feeCollector, _feePercentage, _autoGlobalDepositAmount, false) {
        require(address(_router.wUST()) == address(_inputToken));
        require(address(_router.aUST()) == address(_outputToken));
        router = _router;
    }

    function _anchorDeposit(uint256 amount, uint256 minReceived) internal override {
        inputToken.safeIncreaseAllowance(address(router), amount);
        router.depositStable(amount);
    }

    function _anchorWithdraw(uint256 shares) internal override {
        outputToken.safeIncreaseAllowance(address(router), shares);
        router.redeemStable(shares);
    }
}