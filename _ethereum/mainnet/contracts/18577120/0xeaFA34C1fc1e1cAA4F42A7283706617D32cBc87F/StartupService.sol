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

// Local imports - Structs
import "./RequestTypes.sol";
import "./EnumTypes.sol";

// Local imports - Constants
import "./RaiseConstants.sol";

// Local imports - Errors
import "./CrossChainErrors.sol";
import "./RaiseErrors.sol";
import "./RequestErrors.sol";

// Local imports - Storages
import "./LibRaise.sol";
import "./LibNonce.sol";
import "./LibERC20Asset.sol";
import "./LibStartupFundsInfo.sol";
import "./LibEscrow.sol";

// Local imports - Services
import "./RaiseService.sol";

// Local imports - Interfaces
import "./IEscrow.sol";

library StartupService {
    /// @dev Validate set token request.
    /// @dev Validation: Checks validity of sender, request, raise and contained ERC20.
    /// @param _request SetTokenRequest struct
    function validateSetTokenRequest(RequestTypes.SetTokenRequest calldata _request) internal view {
        // tx.members
        address sender_ = msg.sender;
        uint256 now_ = block.timestamp;
        string memory raiseId_ = _request.raiseId;

        // check replay attack
        uint256 nonce_ = _request.base.nonce;
        if (nonce_ <= LibNonce.getLastNonce(sender_)) {
            revert RequestErrors.NonceExpired(sender_, nonce_);
        }

        // check request expiration
        if (now_ > _request.base.expiry) {
            revert RequestErrors.RequestExpired(sender_, _request.base.expiry);
        }

        // verify sender
        if (sender_ != _request.base.sender) {
            revert RequestErrors.IncorrectSender(sender_);
        }

        // existence check
        if (!RaiseService.isRaiseExists(raiseId_)) {
            revert RaiseErrors.RaiseDoesNotExists(raiseId_);
        }

        // get ERC-20 asset chain id
        uint256 erc20AssetChainId_ = LibERC20Asset.getChainId(raiseId_);

        // validate if ERC-20 asset is on the current chain
        if (erc20AssetChainId_ != block.chainid) {
            revert CrossChainErrors.InvalidChainId(block.chainid, erc20AssetChainId_);
        }

        // validate if sender is startup
        if (LibRaise.getOwner(raiseId_) != sender_) {
            revert RaiseErrors.CallerNotStartup(sender_, raiseId_);
        }

        // validate raise type
        if (LibRaise.getType(raiseId_) != EnumTypes.RaiseType.EarlyStage) {
            revert RaiseErrors.OnlyForEarlyStage(raiseId_);
        }

        // validate if address hasn't been already set
        if (LibERC20Asset.getAddress(raiseId_) != address(0)) {
            revert RaiseErrors.TokenAlreadySet(raiseId_);
        }
    }

    /// @dev Validate possibility to perform reclaim unsold.
    /// @param _raiseId ID of the raise
    function validateReclaimUnsold(string memory _raiseId) internal view {
        // tx.members
        address sender_ = msg.sender;

        // existence check
        if (!RaiseService.isRaiseExists(_raiseId)) {
            revert RaiseErrors.RaiseDoesNotExists(_raiseId);
        }

        // get ERC-20 asset chain id
        uint256 erc20AssetChainId_ = LibERC20Asset.getChainId(_raiseId);

        // validate if ERC-20 asset is on the current chain
        if (erc20AssetChainId_ != block.chainid) {
            revert CrossChainErrors.InvalidChainId(block.chainid, erc20AssetChainId_);
        }

        // check if token for EarlyStage type is set
        if (LibRaise.getType(_raiseId) == EnumTypes.RaiseType.EarlyStage) {
            revert RaiseErrors.CannotForEarlyStage(_raiseId);
        }

        // validate if sender is startup
        if (LibRaise.getOwner(_raiseId) != sender_) {
            revert RequestErrors.IncorrectSender(sender_);
        }

        // check if raise is finished already
        if (!RaiseService.isRaiseFinished(_raiseId)) {
            revert RaiseErrors.RaiseNotFinished(_raiseId);
        }

        // check if raise reach softcap
        if (!RaiseService.isSoftcapAchieved(_raiseId)) {
            revert RaiseErrors.SoftcapNotAchieved(_raiseId);
        }

        // ToDo : Comment
        if (LibStartupFundsInfo.getReclaimed(_raiseId)) {
            revert RaiseErrors.AlreadyReclaimed(_raiseId);
        }
    }

    /// @dev Validate amount to reclaim.
    /// @param _raiseId ID of the raise
    /// @return _unsold Unsolded tokens
    function validateAmountToReclaim(string memory _raiseId) private view returns (uint256 _unsold) {
        // check if hardcap achieved
        uint256 hardcap_ = LibRaise.getHardcap(_raiseId);
        uint256 raised_ = LibRaise.getRaised(_raiseId);
        uint256 diff_ = hardcap_ - raised_;
        if (diff_ == 0) {
            revert RaiseErrors.HardcapAchieved(_raiseId);
        }

        // get unsold tokens
        _unsold = RaiseService.calculateUnsold(_raiseId, diff_);
        if (_unsold == 0) {
            revert RaiseErrors.NothingToReclaim(_raiseId);
        }
    }

    /// @dev Reclaim unsold tokens.
    /// @dev Events: Escrow.Withdraw(address token, address receiver, uint256 amount).
    /// @param _sender Receiver address
    /// @param _raiseId ID of raise
    function reclaimUnsold(address _sender, string memory _raiseId) internal returns (uint256 _unsold) {
        // validate and return amount to reclaim
        _unsold = validateAmountToReclaim(_raiseId);

        // prepare data
        IEscrow.ReceiverData memory receiverData_ = IEscrow.ReceiverData({ receiver: _sender, amount: _unsold });

        // get erc20
        address erc20_ = LibERC20Asset.getAddress(_raiseId);

        // get escrow
        address escrow_ = LibEscrow.getEscrow(_raiseId);

        // send tokens
        IEscrow(escrow_).withdraw(erc20_, receiverData_);
    }

    /// @dev Validate refund collateral to startup.
    /// @dev Validation: Validate raise, sender and ability to refund.
    /// @param _raiseId ID of raise
    function validateRefundStartup(string memory _raiseId) internal view {
        // tx.members
        address sender_ = msg.sender;

        // check if raise exists
        if (!RaiseService.isRaiseExists(_raiseId)) {
            revert RaiseErrors.RaiseDoesNotExists(_raiseId);
        }

        // get ERC-20 asset chain id
        uint256 erc20AssetChainId_ = LibERC20Asset.getChainId(_raiseId);

        // validate if ERC-20 asset is on the current chain
        if (erc20AssetChainId_ != block.chainid) {
            revert CrossChainErrors.InvalidChainId(block.chainid, erc20AssetChainId_);
        }

        // check if token for EarlyStage type is set
        if (LibRaise.getType(_raiseId) == EnumTypes.RaiseType.EarlyStage && LibERC20Asset.getAddress(_raiseId) == address(0)) {
            revert RaiseErrors.TokenNotSet(_raiseId);
        }

        // check if raise is finished already
        if (!RaiseService.isRaiseFinished(_raiseId)) {
            revert RaiseErrors.RaiseNotFinished(_raiseId);
        }

        // check if raise reach softcap
        if (RaiseService.isSoftcapAchieved(_raiseId)) {
            revert RaiseErrors.SoftcapAchieved(_raiseId);
        }

        // check if _sender is startup of this raise
        if (LibRaise.getOwner(_raiseId) != sender_) {
            revert RaiseErrors.CallerNotStartup(sender_, _raiseId);
        }

        // check collateral
        if (LibStartupFundsInfo.getCollateralRefunded(_raiseId)) {
            revert RaiseErrors.CollateralAlreadyRefunded(_raiseId);
        }
    }

    /// @dev Refund collateral to startup.
    /// @param _raiseId ID of the raise
    /// @return collateral_ Amount of refunded tokens
    function refundCollateral(string memory _raiseId) internal returns (uint256 collateral_) {
        // tx.members
        address sender_ = msg.sender;

        // get Escrow address
        address escrow_ = LibEscrow.getEscrow(_raiseId);

        // get collateral
        collateral_ = LibERC20Asset.getAmount(_raiseId);

        // get vested token address
        address vestedToken_ = LibERC20Asset.getAddress(_raiseId);

        // prepare Escrow 'ReceiverData'
        IEscrow.ReceiverData memory receiverData_ = IEscrow.ReceiverData({ receiver: sender_, amount: collateral_ });

        // transfer
        IEscrow(escrow_).withdraw(vestedToken_, receiverData_);
    }
}
