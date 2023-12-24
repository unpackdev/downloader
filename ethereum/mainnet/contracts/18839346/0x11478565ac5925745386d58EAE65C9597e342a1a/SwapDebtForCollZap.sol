// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "Address.sol";
import "IERC20.sol";
import "IDebtToken.sol";

interface IFeeConverter {
    function swapDebtForColl(address collateral, uint256 debtAmount) external returns (uint256);
}

/**
    @title Swap Debt for Collateral Zap
 */
contract SwapDebtForCollZap {
    using Address for address;
    bytes32 private constant _RETURN_VALUE = keccak256("ERC3156FlashBorrower.onFlashLoan");

    IDebtToken public immutable debtToken;
    IFeeConverter public immutable feeConverter;

    constructor(IDebtToken _debtToken, IFeeConverter _feeConverter) {
        debtToken = _debtToken;
        feeConverter = _feeConverter;

        _debtToken.approve(address(_feeConverter), type(uint256).max);
        _debtToken.approve(address(_debtToken), type(uint256).max);
    }

    /**
        @notice Use a flashloan to purchase available collateral with mkUSD and
                sell the collateral in the same transaction
        @dev Remaining mkUSD and `collateral` balances are transferred to the caller.
             The transaction will revert if it is not profitable.
        @param collateral Collateral to purchase
        @param debtAmount Amount of mkUSD to flashloan and use to purchase `collateral`
        @param minCollReceived Minimum amount of `collateral` received
        @param swapRouter Router contract used to swap `collateral` back to `debt`
        @param swapData Calldata used when calling `swapRouter`. Must be generated
                        off-chain.
     */
    function swapDebtForColl(
        IERC20 collateral,
        uint256 debtAmount,
        uint256 minCollReceived,
        address swapRouter,
        bytes calldata swapData
    ) external {
        bytes memory data = abi.encode(collateral, minCollReceived, swapRouter, swapData);

        debtToken.flashLoan(address(this), address(debtToken), debtAmount, data);

        uint256 amount = collateral.balanceOf(address(this));
        if (amount != 0) collateral.transfer(msg.sender, amount);

        amount = debtToken.balanceOf(address(this));
        if (amount != 0) debtToken.transfer(msg.sender, amount);
    }

    function onFlashLoan(
        address caller,
        address token,
        uint amount,
        uint fee,
        bytes calldata data
    ) external returns (bytes32) {
        require(caller == address(this));

        (address collateral, uint256 minCollReceived, address swapRouter, bytes memory swapData) = abi.decode(
            data,
            (address, uint256, address, bytes)
        );

        uint256 collAmount = feeConverter.swapDebtForColl(collateral, amount);

        require(collAmount >= minCollReceived);

        IERC20(collateral).approve(swapRouter, collAmount);
        swapRouter.functionCall(swapData);

        return _RETURN_VALUE;
    }
}
