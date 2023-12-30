pragma solidity ^0.6.0;

import "./MCDSaverProxy.sol";
import "./FlashLoanReceiverBase.sol";

contract MCDSaverFlashLoan is MCDSaverProxy, FlashLoanReceiverBase {
    Manager public constant MANAGER = Manager(MANAGER_ADDRESS);

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    address payable public owner;

    constructor()
        FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER)
        public {
            owner = msg.sender;
    }

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params)
    external override {

        //check the contract has the specified balance
        require(_amount <= getBalanceInternal(address(this), _reserve),
            "Invalid balance for the contract");

        (
            uint[6] memory data,
            address joinAddr,
            address exchangeAddress,
            bytes memory callData,
            bool isRepay
        )
         = abi.decode(_params, (uint256[6],address,address,bytes,bool));

        if (isRepay) {
            repayWithLoan(data, _amount, joinAddr, exchangeAddress, callData, _fee);
        } else {
            boostWithLoan(data, _amount, joinAddr, exchangeAddress, callData, _fee);
        }

        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }
    }

    function boostWithLoan(
        uint256[6] memory _data,
        uint256 _loanAmount,
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData,
        uint _fee
    ) internal boostCheck(_data[0]) {

        // maxDebt,    daiDrawn,   dfsFee,     amountToSwap, swapedAmount
        // amounts[0], amounts[1], amounts[2], amounts[3],   amounts[4]
        uint[] memory amounts = new uint[](5);
        address owner = getOwner(MANAGER, _data[0]);

        // Draw users Dai
        amounts[0] = getMaxDebt(_data[0], manager.ilks(_data[0]));
        amounts[1] = drawDai(_data[0], MANAGER.ilks(_data[0]), amounts[0]);

        // Calc. fees
        amounts[2] = getFee((amounts[1] + _loanAmount), _data[4], owner);
        amounts[3] = (amounts[1] + _loanAmount) - amounts[2];

        // Swap Dai to collateral
        amounts[4] = swap(
            [amounts[3], _data[2], _data[3], _data[5]],
            DAI_ADDRESS,
            getCollateralAddr(_joinAddr),
            _exchangeAddress,
            _callData
        );

        // Return collateral
        addCollateral(_data[0], _joinAddr, amounts[4]);

        // Draw Dai to repay the flash loan
        drawDai(_data[0],  manager.ilks(_data[0]), (_loanAmount + _fee));

        SaverLogger(LOGGER_ADDRESS).LogBoost(_data[0], owner, (amounts[1] + _loanAmount), amounts[4]);
    }

    function repayWithLoan(
        uint256[6] memory _data,
        uint256 _loanAmount,
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData,
        uint _fee
    ) internal repayCheck(_data[0]) {

        // maxColl,    collDrawn,  swapedAmount, dfsFee
        // amounts[0], amounts[1], amounts[2],   amounts[3]
        uint[] memory amounts = new uint[](4);
        address owner = getOwner(MANAGER, _data[0]);

        // Draw collateral
        amounts[0] = getMaxCollateral(_data[0], manager.ilks(_data[0]), _joinAddr);
        amounts[1] = drawCollateral(_data[0], manager.ilks(_data[0]), _joinAddr, amounts[0]);

        // Swap for Dai
        amounts[2] = swap(
            [(amounts[1] + _loanAmount), _data[2], _data[3], _data[5]],
            getCollateralAddr(_joinAddr),
            DAI_ADDRESS,
            _exchangeAddress,
            _callData
        );

        // Get our fee
        amounts[3] = getFee(amounts[2], _data[4], owner);

        uint paybackAmount = (amounts[2] - amounts[3]);
        paybackAmount = limitLoanAmount(_data[0], manager.ilks(_data[0]), paybackAmount, owner);

        // Payback the debt
        paybackDebt(_data[0], MANAGER.ilks(_data[0]), paybackAmount, owner);

        // Draw collateral to repay the flash loan
        drawCollateral(_data[0], manager.ilks(_data[0]), _joinAddr, (_loanAmount + _fee));

        SaverLogger(LOGGER_ADDRESS).LogRepay(_data[0], owner, (amounts[1] + _loanAmount), amounts[2]);
    }

    receive() external override payable {}

    /// @notice Handles that the amount is not bigger than cdp debt and not dust
    function limitLoanAmount(uint _cdpId, bytes32 _ilk, uint _paybackAmount, address _owner) internal returns (uint256) {
        uint debt = getAllDebt(address(vat), manager.urns(_cdpId), manager.urns(_cdpId), _ilk);

        if (_paybackAmount > debt) {
            ERC20(DAI_ADDRESS).transfer(_owner, (_paybackAmount - debt));
            return debt;
        }

        uint debtLeft = debt - _paybackAmount;

        // Less than dust value
        if (debtLeft < 20 ether) {
            uint amountOverDust = ((20 ether) - debtLeft);

            ERC20(DAI_ADDRESS).transfer(_owner, amountOverDust);

            return (_paybackAmount - amountOverDust);
        }

        return _paybackAmount;
    }

    // ADMIN ONLY FAIL SAFE FUNCTION IF FUNDS GET STUCK
    function withdrawStuckFunds(address _tokenAddr, uint _amount) public {
        require(msg.sender == owner, "Only owner");

        if (_tokenAddr == KYBER_ETH_ADDRESS) {
            owner.transfer(_amount);
        } else {
            ERC20(_tokenAddr).transfer(owner, _amount);
        }
    }
}
