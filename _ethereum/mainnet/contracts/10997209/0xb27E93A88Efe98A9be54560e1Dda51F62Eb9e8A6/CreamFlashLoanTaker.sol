pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./GasBurner.sol";
import "./ILendingPool.sol";
import "./CreamSaverProxy.sol";
import "./DefisaverLogger.sol";
import "./ProxyPermission.sol";

/// @title Entry point for the FL Repay Boosts, called by DSProxy
contract CreamFlashLoanTaker is CreamSaverProxy, ProxyPermission, GasBurner {
    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    address payable public constant COMPOUND_SAVER_FLASH_LOAN = 0xCeB190A35D9D4804b9CE8d0CF79239f6949BfCcB;

    /// @notice Repays the position with it's own fund or with FL if needed
    /// @param _exData Exchange data
    /// @param _cAddresses cTokens addreses and exchange [cCollAddress, cBorrowAddress, exchangeAddress]
    /// @param _gasCost Gas cost for specific transaction
    function repayWithLoan(
        ExchangeData memory _exData,
        address[2] memory _cAddresses, // cCollAddress, cBorrowAddress
        uint256 _gasCost
    ) public payable burnGas(25) {
        uint maxColl = getMaxCollateral(_cAddresses[0], address(this));

        if (_exData.srcAmount <= maxColl) {
            repay(_exData, _cAddresses, _gasCost);
        } else {
            // 0x fee
            COMPOUND_SAVER_FLASH_LOAN.transfer(msg.value);

            uint loanAmount = (_exData.srcAmount - maxColl);
            bytes memory encoded = packExchangeData(_exData);
            bytes memory paramsData = abi.encode(encoded, _cAddresses, _gasCost, true, address(this));

            givePermission(COMPOUND_SAVER_FLASH_LOAN);

            lendingPool.flashLoan(COMPOUND_SAVER_FLASH_LOAN, getUnderlyingAddr(_cAddresses[0]), loanAmount, paramsData);

            removePermission(COMPOUND_SAVER_FLASH_LOAN);

            logger.Log(address(this), msg.sender, "CreamFlashRepay", abi.encode(loanAmount, _exData.srcAmount, _cAddresses[0]));
        }
    }

    /// @notice Boosts the position with it's own fund or with FL if needed
    /// @param _exData Exchange data
    /// @param _cAddresses cTokens addreses and exchange [cCollAddress, cBorrowAddress, exchangeAddress]
    /// @param _gasCost Gas cost for specific transaction
    function boostWithLoan(
        ExchangeData memory _exData,
        address[2] memory _cAddresses, // cCollAddress, cBorrowAddress
        uint256 _gasCost
    ) public payable burnGas(20) {
        uint maxBorrow = getMaxBorrow(_cAddresses[1], address(this));

        if (_exData.srcAmount <= maxBorrow) {
            boost(_exData, _cAddresses, _gasCost);
        } else {
            // 0x fee
            COMPOUND_SAVER_FLASH_LOAN.transfer(msg.value);

            uint loanAmount = (_exData.srcAmount - maxBorrow);
            bytes memory paramsData = abi.encode(packExchangeData(_exData), _cAddresses, _gasCost, false, address(this));

            givePermission(COMPOUND_SAVER_FLASH_LOAN);

            lendingPool.flashLoan(COMPOUND_SAVER_FLASH_LOAN, getUnderlyingAddr(_cAddresses[1]), loanAmount, paramsData);

            removePermission(COMPOUND_SAVER_FLASH_LOAN);

            logger.Log(address(this), msg.sender, "CreamFlashBoost", abi.encode(loanAmount, _exData.srcAmount, _cAddresses[1]));
        }

    }
}
