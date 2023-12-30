pragma solidity ^0.6.0;

import "./SafeERC20.sol";
import "./ExchangeHelper.sol";
import "./CTokenInterface.sol";
import "./Discount.sol";
import "./CompoundSaverHelper.sol";
import "./DefisaverLogger.sol";

/// @title Implements the actual logic of Repay/Boost with FL
contract CompoundSaverFlashProxy is ExchangeHelper, CompoundSaverHelper  {

    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;

    using SafeERC20 for ERC20;

    /// @notice Repays the position and sends tokens back for FL
    /// @param _data Amount and exchange data [amount, minPrice, exchangeType, gasCost, 0xPrice]
    /// @param _addrData cTokens addreses and exchange [cCollAddress, cBorrowAddress, exchangeAddress]
    /// @param _callData 0x callData
    /// @param _flashLoanData Data about FL [amount, fee]
    function flashRepay(
        uint[5] memory _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
        address[3] memory _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes memory _callData,
        uint[2] memory _flashLoanData // amount, fee
    ) public payable {
        enterMarket(_addrData[0], _addrData[1]);

        address payable user = address(uint160(getUserAddress()));
        uint flashBorrowed = _flashLoanData[0] + _flashLoanData[1];

        uint maxColl = getMaxCollateral(_addrData[0], address(this));

        // draw max coll
        require(CTokenInterface(_addrData[0]).redeemUnderlying(maxColl) == 0);

        address collToken = getUnderlyingAddr(_addrData[0]);
        address borrowToken = getUnderlyingAddr(_addrData[1]);

        uint swapAmount = 0;

        if (collToken != borrowToken) {
            // swap max coll + loanAmount
            swapAmount = swap(
                [(maxColl + _flashLoanData[0]), _data[1], _data[2], _data[4]], // collAmount, minPrice, exchangeType, 0xPrice
                collToken,
                borrowToken,
                _addrData[2],
                _callData
            );

            // get fee
            swapAmount -= getFee(swapAmount, user, _data[3], _addrData[1]);
        } else {
            swapAmount = (maxColl + _flashLoanData[0]);
            swapAmount -= getGasCost(swapAmount, _data[3], _addrData[1]);
        }

        // payback debt
        paybackDebt(swapAmount, _addrData[1], borrowToken, user);

        // draw collateral for loanAmount + loanFee
        require(CTokenInterface(_addrData[0]).redeemUnderlying(flashBorrowed) == 0);

        // repay flash loan
        returnFlashLoan(collToken, flashBorrowed);

        DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "CompoundRepay", abi.encode(_data[0], swapAmount, collToken, borrowToken));
    }

    /// @notice Boosts the position and sends tokens back for FL
    /// @param _data Amount and exchange data [amount, minPrice, exchangeType, gasCost, 0xPrice]
    /// @param _addrData cTokens addreses and exchange [cCollAddress, cBorrowAddress, exchangeAddress]
    /// @param _callData 0x callData
    /// @param _flashLoanData Data about FL [amount, fee]
    function flashBoost(
        uint[5] memory _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
        address[3] memory _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes memory _callData,
        uint[2] memory _flashLoanData // amount, fee
    ) public payable {
        enterMarket(_addrData[0], _addrData[1]);

        address payable user = address(uint160(getUserAddress()));
        uint flashBorrowed = _flashLoanData[0] + _flashLoanData[1];

        // borrow max amount
        uint borrowAmount = getMaxBorrow(_addrData[1], address(this));
        require(CTokenInterface(_addrData[1]).borrow(borrowAmount) == 0);

        address collToken = getUnderlyingAddr(_addrData[0]);
        address borrowToken = getUnderlyingAddr(_addrData[1]);

        uint swapAmount = 0;

        if (collToken != borrowToken) {
            // get dfs fee
            borrowAmount -= getFee((borrowAmount + _flashLoanData[0]), user, _data[3], _addrData[1]);

            // swap borrowed amount and fl loan amount
            swapAmount = swap(
                [(borrowAmount + _flashLoanData[0]), _data[1], _data[2], _data[4]], // collAmount, minPrice, exchangeType, 0xPrice
                borrowToken,
                collToken,
                _addrData[2],
                _callData
            );
        } else {
            swapAmount = (borrowAmount + _flashLoanData[0]);
            swapAmount -= getGasCost(swapAmount, _data[3], _addrData[1]);
        }

        // deposit swaped collateral
        depositCollateral(collToken, _addrData[0], swapAmount);

        // borrow token to repay flash loan
        require(CTokenInterface(_addrData[1]).borrow(flashBorrowed) == 0);

        // repay flash loan
        returnFlashLoan(borrowToken, flashBorrowed);

        DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "CompoundBoost", abi.encode(_data[0], swapAmount, collToken, borrowToken));
    }

    /// @notice Helper method to deposit tokens in Compound
    /// @param _collToken Token address of the collateral
    /// @param _cCollToken CToken address of the collateral
    /// @param _depositAmount Amount to deposit
    function depositCollateral(address _collToken, address _cCollToken, uint _depositAmount) internal {
        approveCToken(_collToken, _cCollToken);

        if (_collToken != ETH_ADDRESS) {
            require(CTokenInterface(_cCollToken).mint(_depositAmount) == 0);
        } else {
            CEtherInterface(_cCollToken).mint{value: _depositAmount}(); // reverts on fail
        }
    }

    /// @notice Returns the tokens/ether to the msg.sender which is the FL contract
    /// @param _tokenAddr Address of token which we return
    /// @param _amount Amount to return
    function returnFlashLoan(address _tokenAddr, uint _amount) internal {
        if (_tokenAddr != ETH_ADDRESS) {
            ERC20(_tokenAddr).safeTransfer(msg.sender, _amount);
        }

        msg.sender.transfer(address(this).balance);
    }

}
