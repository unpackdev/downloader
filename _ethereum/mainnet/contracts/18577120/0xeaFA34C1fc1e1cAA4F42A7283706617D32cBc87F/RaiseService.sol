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
import "./StorageTypes.sol";
import "./EnumTypes.sol";

// Local imports - Errors
import "./RequestErrors.sol";
import "./RaiseErrors.sol";

// Local imports - Storages
import "./LibRaise.sol";
import "./LibERC20Asset.sol";
import "./LibBaseAsset.sol";
import "./LibNonce.sol";

library RaiseService {
    /// @dev Set to storage all raise and assets data.
    /// @param _raiseId ID of the raise
    /// @param _sender Message sender
    /// @param _nonce Used nonce
    /// @param _raise StorageTypes.Raise struct
    /// @param _raiseDetails StorageTypes.RaiseDetails struct
    /// @param _erc20Asset StorageTypes.ERC20Asset struct
    /// @param _baseAsset StorageTypes.BaseAsset struct
    function setRaiseCreationData(
        string memory _raiseId,
        address _sender,
        uint256 _nonce,
        StorageTypes.Raise memory _raise,
        StorageTypes.RaiseDetails memory _raiseDetails,
        StorageTypes.ERC20Asset memory _erc20Asset,
        StorageTypes.BaseAsset memory _baseAsset
    ) internal {
        // set raise to storage
        LibRaise.setRaise(_raiseId, _raise);
        // set raise details to storage
        LibRaise.setRaiseDetails(_raiseId, _raiseDetails);
        // set ERC-20 asset to storage
        LibERC20Asset.setERC20Asset(_raiseId, _erc20Asset);
        // set base asset to storage
        LibBaseAsset.setBaseAsset(_raiseId, _baseAsset);
        // set nonce as used to storage
        LibNonce.setNonce(_sender, _nonce);
    }

    function validateCreationRequest(
        StorageTypes.Raise memory _raise,
        StorageTypes.RaiseDetails memory _raiseDetails,
        StorageTypes.ERC20Asset memory _erc20Asset,
        address _sender,
        uint256 _nonce
    ) internal view {
        if (_nonce <= LibNonce.getLastNonce(_sender)) {
            revert RequestErrors.NonceExpired(_sender, _nonce);
        }

        // check raise id
        if (bytes(_raise.raiseId).length == 0) {
            revert RaiseErrors.InvalidRaiseId(_raise.raiseId);
        }

        // verify if raise does not exist
        if (RaiseService.isRaiseExists(_raise.raiseId)) {
            revert RaiseErrors.RaiseAlreadyExists(_raise.raiseId);
        }

        // check start and end date
        if (_raiseDetails.start >= _raiseDetails.end) {
            revert RaiseErrors.InvalidRaiseStartEnd(_raiseDetails.start, _raiseDetails.end);
        }

        // check if tokens are vested
        if (_erc20Asset.amount == 0) {
            revert RaiseErrors.InvalidVestedAmount();
        }

        // validate price per token == vested / hardcap
        if (_raiseDetails.tokensPerBaseAsset != (_erc20Asset.amount * LibRaise.PRICE_PRECISION) / _raiseDetails.hardcap) {
            revert RaiseErrors.PriceNotMatchConfiguration(_raiseDetails.tokensPerBaseAsset, _raiseDetails.hardcap, _erc20Asset.amount);
        }

        // validate token address for Early Stage type
        if (_raise.raiseType != EnumTypes.RaiseType.EarlyStage && _erc20Asset.erc20 == address(0)) {
            revert RaiseErrors.InvalidTokenAddress(_erc20Asset.erc20);
        }
    }

    /// @dev Get amount of sold tokens.
    /// @param _raiseId ID of raise
    /// @return Amount of tokens to claim by investor
    function getSold(string memory _raiseId) internal view returns (uint256) {
        // get tokens per base asset
        uint256 tokensPerBaseAsset_ = LibRaise.getTokensPerBaseAsset(_raiseId);

        // get raised
        uint256 raised_ = LibRaise.getRaised(_raiseId);

        // calculate how much tokens are sold
        return (tokensPerBaseAsset_ * raised_) / LibRaise.PRICE_PRECISION;
    }

    /**************************************

        Get unsold tokens

     **************************************/

    /// @dev Get amount of unsold tokens.
    /// @param _raiseId ID of raise
    /// @return Amount of tokens to reclaim by startup
    function getUnsold(string memory _raiseId) internal view returns (uint256) {
        // get all vested tokens
        uint256 vested_ = LibERC20Asset.getAmount(_raiseId);

        // get sold tokens
        uint256 sold_ = getSold(_raiseId);

        // return
        return vested_ - sold_;
    }

    /// @dev Get amount of unsold tokens.
    /// @param _raiseId ID of raise
    /// @param _diff Amount of unsold base asset
    /// @return Amount of tokens to reclaim
    function calculateUnsold(string memory _raiseId, uint256 _diff) internal view returns (uint256) {
        // calculate how much tokens are unsold
        return (LibRaise.getTokensPerBaseAsset(_raiseId) * _diff) / LibRaise.PRICE_PRECISION;
    }

    /// @dev Check if raise for given id exists.
    /// @param _raiseId ID of the raise
    /// @return True if raise exists
    function isRaiseExists(string memory _raiseId) internal view returns (bool) {
        // return
        return bytes(LibRaise.getId(_raiseId)).length != 0;
    }

    /// @dev Check if raise is finished.
    /// @param _raiseId ID of raise
    /// @return True if investment round is finished
    function isRaiseFinished(string memory _raiseId) internal view returns (bool) {
        // return
        return LibRaise.getEnd(_raiseId) < block.timestamp;
    }

    /**************************************

        Check if given raise achieved softcap

     **************************************/

    /// @dev Check if softcap was achieved.
    /// @param _raiseId ID of raise
    /// @return True if softcap was achieved
    function isSoftcapAchieved(string memory _raiseId) internal view returns (bool) {
        // return
        return LibRaise.getSoftcap(_raiseId) <= LibRaise.getRaised(_raiseId);
    }

    /// @dev Check if raise is active.
    /// @param _raiseId ID of raise
    /// @return True if investment round is ongoing
    function isRaiseActive(string memory _raiseId) internal view returns (bool) {
        // tx.members
        uint256 now_ = block.timestamp;

        // get raise start time
        uint256 start_ = LibRaise.getStart(_raiseId);
        // get raise end time
        uint256 end_ = LibRaise.getEnd(_raiseId);

        // final check
        return start_ <= now_ && now_ <= end_;
    }
}
