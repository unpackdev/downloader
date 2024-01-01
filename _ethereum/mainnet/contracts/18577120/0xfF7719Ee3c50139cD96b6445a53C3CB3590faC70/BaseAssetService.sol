// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

// OpenZeppelin imports
import "./SafeERC20.sol";
import "./IERC20.sol";

// Local imports - Errors
import "./RaiseErrors.sol";

// Local imports - Storages
import "./LibEscrow.sol";
import "./LibBaseAsset.sol";
import "./LibInvestorFundsInfo.sol";

// Local imports - Interfaces
import "./IEscrow.sol";

library BaseAssetService {
    using SafeERC20 for IERC20;

    /// @dev Collect base asset from investor.
    /// @dev Validation: Requires investor to have assets and provide enough allowance.
    /// @dev Events: Transfer(address from, address to, uint256 value).
    /// @param _raiseId Id of the raise
    /// @param _sender Address of investor
    /// @param _investment Amount of investment
    function collectBaseAsset(string memory _raiseId, address _sender, uint256 _investment) internal {
        // get base asset address
        IERC20 baseAsset_ = IERC20(LibBaseAsset.getAddress(_raiseId));

        // get Escrow address
        address escrow_ = LibEscrow.getEscrow(_raiseId);

        // check balance
        if (baseAsset_.balanceOf(_sender) < _investment) revert RaiseErrors.NotEnoughBalanceForInvestment(_sender, _investment);

        // check approval
        if (baseAsset_.allowance(_sender, address(this)) < _investment)
            revert RaiseErrors.NotEnoughAllowance(_sender, address(this), _investment);

        // transfer
        baseAsset_.safeTransferFrom(_sender, escrow_, _investment);
    }

    /// @dev Refund base asset to investor.
    /// @dev Validation: Requires investor to have assets and provide enough allowance.
    /// @dev Events: Transfer(address from, address to, uint256 value).
    /// @param _raiseId Id of the raise
    /// @param _account Address of investor
    /// @return investment_ Amount of investment
    function refundBaseAsset(string memory _raiseId, address _account) internal returns (uint256 investment_) {
        // get Escrow address
        address escrow_ = LibEscrow.getEscrow(_raiseId);

        // get investment
        investment_ = LibInvestorFundsInfo.getInvested(_raiseId, _account);

        // prepare for transfer
        LibInvestorFundsInfo.setInvestmentRefunded(_raiseId, _account, true);

        // get base asset address
        address baseAsset_ = LibBaseAsset.getAddress(_raiseId);

        // prepare Escrow 'ReceiverData'
        IEscrow.ReceiverData memory receiverData_ = IEscrow.ReceiverData({ receiver: _account, amount: investment_ });

        // transfer
        IEscrow(escrow_).withdraw(baseAsset_, receiverData_);
    }
}
