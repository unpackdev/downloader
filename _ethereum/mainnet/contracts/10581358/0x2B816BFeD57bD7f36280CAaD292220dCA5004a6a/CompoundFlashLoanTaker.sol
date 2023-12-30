pragma solidity ^0.6.0;

import "./GasBurner.sol";
import "./ILendingPool.sol";
import "./CompoundSaverProxy.sol";
import "./FlashLoanLogger.sol";
import "./ProxyPermission.sol";

/// @title Entry point for the FL Repay Boosts, called by DSProxy
contract CompoundFlashLoanTaker is CompoundSaverProxy, ProxyPermission, GasBurner {
    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    address payable public constant COMPOUND_SAVER_FLASH_LOAN = 0xb0a59B7fC1c92c76b3c6AB52097f38611A492b1C;

    // solhint-disable-next-line const-name-snakecase
    FlashLoanLogger public constant logger = FlashLoanLogger(
        0xb9303686B0EE92F92f63973EF85f3105329D345c
    );

    /// @notice Repays the position with it's own fund or with FL if needed
    /// @param _data Amount and exchange data [amount, minPrice, exchangeType, gasCost, 0xPrice]
    /// @param _addrData cTokens addreses and exchange [cCollAddress, cBorrowAddress, exchangeAddress]
    /// @param _callData 0x callData
    function repayWithLoan(
        uint[5] calldata _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
        address[3] calldata _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes calldata _callData
    ) external payable burnGas(25) {
        uint maxColl = getMaxCollateral(_addrData[0], address(this));

        if (_data[0] <= maxColl) {
            repay(_data, _addrData, _callData);
        } else {
            // 0x fee
            COMPOUND_SAVER_FLASH_LOAN.transfer(msg.value);

            uint loanAmount = (_data[0] - maxColl);
            bytes memory paramsData = abi.encode(_data, _addrData, _callData, true, address(this));

            givePermission(COMPOUND_SAVER_FLASH_LOAN);

            lendingPool.flashLoan(COMPOUND_SAVER_FLASH_LOAN, getUnderlyingAddr(_addrData[0]), loanAmount, paramsData);

            removePermission(COMPOUND_SAVER_FLASH_LOAN);

            logger.logFlashLoan("CompoundFlashRepay", loanAmount, _data[0], _addrData[0]);
        }
    }

    /// @notice Boosts the position with it's own fund or with FL if needed
    /// @param _data Amount and exchange data [amount, minPrice, exchangeType, gasCost, 0xPrice]
    /// @param _addrData cTokens addreses and exchange [cCollAddress, cBorrowAddress, exchangeAddress]
    /// @param _callData 0x callData
    function boostWithLoan(
        uint[5] calldata _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
        address[3] calldata _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes calldata _callData
    ) external payable burnGas(20) {
        uint maxBorrow = getMaxBorrow(_addrData[1], address(this));

        if (_data[0] <= maxBorrow) {
            boost(_data, _addrData, _callData);
        } else {
            // 0x fee
            COMPOUND_SAVER_FLASH_LOAN.transfer(msg.value);

            uint loanAmount = (_data[0] - maxBorrow);
            bytes memory paramsData = abi.encode(_data, _addrData, _callData, false, address(this));

            givePermission(COMPOUND_SAVER_FLASH_LOAN);

            lendingPool.flashLoan(COMPOUND_SAVER_FLASH_LOAN, getUnderlyingAddr(_addrData[1]), loanAmount, paramsData);

            removePermission(COMPOUND_SAVER_FLASH_LOAN);

            logger.logFlashLoan("CompoundFlashBoost", loanAmount, _data[0], _addrData[1]);
        }

    }

}
