pragma solidity ^0.6.0;

import "./ExchangeHelper.sol";
import "./DefisaverLogger.sol";
import "./CompoundSaverHelper.sol";

/// @title Contract that implements repay/boost functionality
contract CompoundSaverProxy is CompoundSaverHelper, ExchangeHelper {

    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;

    /// @notice Withdraws collateral, converts to borrowed token and repays debt
    /// @dev Called through the DSProxy
    /// @param _data Amount and exchange data for the repay [amount, minPrice, exchangeType, gasCost, 0xPrice]
    /// @param _addrData Coll/Debt addresses [cCollAddress, cBorrowAddress, exchangeAddress]
    /// @param _callData 0x calldata info
    function repay(
        uint[5] memory _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
        address[3] memory _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes memory _callData
    ) public payable {
        enterMarket(_addrData[0], _addrData[1]);

        address payable user = address(uint160(getUserAddress()));

        uint maxColl = getMaxCollateral(_addrData[0], address(this));

        uint collAmount = (_data[0] > maxColl) ? maxColl : _data[0];

        require(CTokenInterface(_addrData[0]).redeemUnderlying(collAmount) == 0);

        address collToken = getUnderlyingAddr(_addrData[0]);
        address borrowToken = getUnderlyingAddr(_addrData[1]);

        uint swapAmount = 0;

        if (collToken != borrowToken) {
            swapAmount = swap(
                [collAmount, _data[1], _data[2], _data[4]], // collAmount, minPrice, exchangeType, 0xPrice
                collToken,
                borrowToken,
                _addrData[2],
                _callData
            );

            swapAmount -= getFee(swapAmount, user, _data[3], _addrData[1]);
        } else {
            swapAmount = collAmount;
            swapAmount -= getGasCost(swapAmount, _data[3], _addrData[1]);
        }

        paybackDebt(swapAmount, _addrData[1], borrowToken, user);

        // handle 0x fee
        user.transfer(address(this).balance);

        // log amount, collToken, borrowToken
        DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "CompoundRepay", abi.encode(_data[0], swapAmount, collToken, borrowToken));
    }

    /// @notice Borrows token, converts to collateral, and adds to position
    /// @dev Called through the DSProxy
    /// @param _data Amount and exchange data for the boost [amount, minPrice, exchangeType, gasCost, 0xPrice]
    /// @param _addrData Coll/Debt addresses [cCollAddress, cBorrowAddress, exchangeAddress]
    /// @param _callData 0x calldata info
    function boost(
        uint[5] memory _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
        address[3] memory _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes memory _callData
    ) public payable {
        enterMarket(_addrData[0], _addrData[1]);

        address payable user = address(uint160(getUserAddress()));

        uint maxBorrow = getMaxBorrow(_addrData[1], address(this));
        uint borrowAmount = (_data[0] > maxBorrow) ? maxBorrow : _data[0];

        require(CTokenInterface(_addrData[1]).borrow(borrowAmount) == 0);

        address collToken = getUnderlyingAddr(_addrData[0]);
        address borrowToken = getUnderlyingAddr(_addrData[1]);

        uint swapAmount = 0;

        if (collToken != borrowToken) {
            borrowAmount -= getFee(borrowAmount, user, _data[3], _addrData[1]);

            swapAmount = swap(
                [borrowAmount, _data[1], _data[2], _data[4]], // collAmount, minPrice, exchangeType, 0xPrice
                borrowToken,
                collToken,
                _addrData[2],
                _callData
            );
        } else {
            swapAmount = borrowAmount;
            swapAmount -= getGasCost(swapAmount, _data[3], _addrData[1]);
        }

        approveCToken(collToken, _addrData[0]);

        if (collToken != ETH_ADDRESS) {
            require(CTokenInterface(_addrData[0]).mint(swapAmount) == 0);
        } else {
            CEtherInterface(_addrData[0]).mint{value: swapAmount}(); // reverts on fail
        }

        // handle 0x fee
        user.transfer(address(this).balance);

        // log amount, collToken, borrowToken
        DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "CompoundBoost", abi.encode(_data[0], swapAmount, collToken, borrowToken));
    }

}
