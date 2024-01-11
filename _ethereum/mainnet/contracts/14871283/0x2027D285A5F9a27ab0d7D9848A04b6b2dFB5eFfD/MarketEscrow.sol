// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./AssetLib.sol";
import "./BasisPointLib.sol";
import "./PartLib.sol";
import "./MarketTransfer.sol";

/**
 * @title MarketEscrow
 * MarketEscrow - This contract manages the escrow for Market.
 */
abstract contract MarketEscrow is MarketTransfer {
    using BasisPointLib for uint256;
    using SafeMath for uint256;

    enum UpdateAssetStatus {
        TypeChange,
        ValueChangeUp,
        ValueChangeDown,
        NoChange
    }

    mapping(bytes32 => AssetLib.AssetData) private _deposits;
    mapping(bytes32 => bool) private _completed;

    event Deposited(
        bytes32 id,
        address indexed payee,
        AssetLib.AssetData asset
    );
    event Paid(
        bytes32 id,
        PartLib.PartData[] payouts,
        PartLib.PartData[] fees,
        AssetLib.AssetData asset
    );
    event Withdrawn(
        bytes32 id,
        address indexed payee,
        AssetLib.AssetData asset
    );

    modifier whenEscrowDeposited(bytes32 id) {
        require(
            getDeposit(id).value != 0 &&
                getDeposit(id).assetType.assetClass != bytes4(0),
            "MarketEscrow: escrow already not depositd"
        );
        _;
    }

    modifier whenNotEscrowCompleted(bytes32 id) {
        require(!getCompleted(id), "MarketEscrow: escrow already completed");
        _;
    }

    function getCompleted(bytes32 id) public view returns (bool) {
        return _completed[id];
    }

    function getDeposit(bytes32 id)
        public
        view
        returns (AssetLib.AssetData memory)
    {
        return _deposits[id];
    }

    function _createDeposit(
        bytes32 id,
        address payee,
        AssetLib.AssetData memory asset
    ) internal whenNotEscrowCompleted(id) {
        _setDeposit(id, asset);
        _transfer(asset, payee, address(this));
        emit Deposited(id, payee, asset);
    }

    function _updateDeposit(
        bytes32 id,
        address payee,
        AssetLib.AssetData memory newAsset
    ) internal whenEscrowDeposited(id) whenNotEscrowCompleted(id) {
        AssetLib.AssetData memory currentAsset = getDeposit(id);
        UpdateAssetStatus status = _matchUpdateAssetStatus(
            currentAsset,
            newAsset
        );
        if (status == UpdateAssetStatus.TypeChange) {
            _setDeposit(id, newAsset);
            _transfer(currentAsset, address(this), payee);
            _transfer(newAsset, payee, address(this));
        } else if (status == UpdateAssetStatus.ValueChangeDown) {
            uint256 diffValue = currentAsset.value.sub(newAsset.value);
            _setDeposit(id, newAsset);
            _transfer(
                AssetLib.AssetData(currentAsset.assetType, diffValue),
                address(this),
                payee
            );
        } else if (status == UpdateAssetStatus.ValueChangeUp) {
            uint256 diffValue = newAsset.value.sub(currentAsset.value);
            _setDeposit(id, newAsset);
            _transfer(
                AssetLib.AssetData(currentAsset.assetType, diffValue),
                payee,
                address(this)
            );
        } else {
            revert("MarketEscrow: no asset change");
        }
        emit Deposited(id, payee, newAsset);
    }

    function _pay(
        bytes32 id,
        PartLib.PartData[] memory payouts,
        PartLib.PartData[] memory fees
    ) internal whenEscrowDeposited(id) whenNotEscrowCompleted(id) {
        AssetLib.AssetData memory asset = _deposits[id];
        _setCompleted(id, true);
        uint256 rest = asset.value;
        (rest, ) = _transferFees(
            asset.assetType,
            rest,
            asset.value,
            address(this),
            fees
        );
        _transferPayouts(asset.assetType, rest, address(this), payouts);
        emit Paid(id, payouts, fees, asset);
    }

    function _withdraw(bytes32 id, address payee)
        internal
        whenEscrowDeposited(id)
        whenNotEscrowCompleted(id)
    {
        AssetLib.AssetData memory asset = _deposits[id];
        _setCompleted(id, true);
        _transfer(asset, address(this), payee);
        emit Withdrawn(id, payee, asset);
    }

    function _transferFees(
        AssetLib.AssetType memory assetType,
        uint256 rest,
        uint256 amount,
        address from,
        PartLib.PartData[] memory fees
    ) internal returns (uint256 restValue, uint256 totalFees) {
        totalFees = 0;
        restValue = rest;
        for (uint256 i = 0; i < fees.length; i++) {
            totalFees = totalFees.add(fees[i].value);
            (uint256 newRestValue, uint256 feeValue) = _subFeeInBp(
                restValue,
                amount,
                fees[i].value
            );
            restValue = newRestValue;
            if (feeValue > 0) {
                _transfer(
                    AssetLib.AssetData(assetType, feeValue),
                    from,
                    fees[i].account
                );
            }
        }
    }

    function _transferPayouts(
        AssetLib.AssetType memory assetType,
        uint256 amount,
        address from,
        PartLib.PartData[] memory payouts
    ) internal {
        uint256 sumBps = 0;
        uint256 restValue = amount;
        for (uint256 i = 0; i < payouts.length - 1; i++) {
            uint256 currentAmount = amount.bp(payouts[i].value);
            sumBps = sumBps.add(payouts[i].value);
            if (currentAmount > 0) {
                restValue = restValue.sub(currentAmount);
                _transfer(
                    AssetLib.AssetData(assetType, currentAmount),
                    from,
                    payouts[i].account
                );
            }
        }
        PartLib.PartData memory lastPayout = payouts[payouts.length - 1];
        sumBps = sumBps.add(lastPayout.value);
        require(
            sumBps == 10000,
            "MarketEscrow: sum payouts bps not equal 100%"
        );
        if (restValue > 0) {
            _transfer(
                AssetLib.AssetData(assetType, restValue),
                from,
                lastPayout.account
            );
        }
    }

    function _matchUpdateAssetStatus(
        AssetLib.AssetData memory currentAsset,
        AssetLib.AssetData memory newAsset
    ) internal pure returns (UpdateAssetStatus) {
        bool matchAssetClass = currentAsset.assetType.assetClass ==
            newAsset.assetType.assetClass;
        bool matchToken;
        bool matchTokenId;
        if (
            matchAssetClass &&
            currentAsset.assetType.assetClass == AssetLib.ERC20_ASSET_CLASS
        ) {
            (address currentToken, ) = AssetLib.decodeAssetTypeData(
                currentAsset.assetType
            );
            (address newToken, ) = AssetLib.decodeAssetTypeData(
                newAsset.assetType
            );
            matchToken = currentToken == newToken;
        } else if (
            matchAssetClass &&
            (currentAsset.assetType.assetClass == AssetLib.ERC721_ASSET_CLASS ||
                currentAsset.assetType.assetClass ==
                AssetLib.ERC1155_ASSET_CLASS)
        ) {
            (address currentToken, uint256 currentTokenId) = AssetLib
                .decodeAssetTypeData(currentAsset.assetType);
            (address newToken, uint256 newTokenId) = AssetLib
                .decodeAssetTypeData(newAsset.assetType);
            matchToken = currentToken == newToken;
            matchTokenId = currentTokenId == newTokenId;
        }
        if (
            !matchAssetClass ||
            (!matchToken &&
                (currentAsset.assetType.assetClass ==
                    AssetLib.ERC20_ASSET_CLASS ||
                    currentAsset.assetType.assetClass ==
                    AssetLib.ERC721_ASSET_CLASS ||
                    currentAsset.assetType.assetClass ==
                    AssetLib.ERC1155_ASSET_CLASS)) ||
            (!matchTokenId &&
                (currentAsset.assetType.assetClass ==
                    AssetLib.ERC721_ASSET_CLASS ||
                    currentAsset.assetType.assetClass ==
                    AssetLib.ERC1155_ASSET_CLASS))
        ) {
            return UpdateAssetStatus.TypeChange;
        } else {
            if (currentAsset.value > newAsset.value) {
                return UpdateAssetStatus.ValueChangeDown;
            } else if (currentAsset.value < newAsset.value) {
                return UpdateAssetStatus.ValueChangeUp;
            }
            return UpdateAssetStatus.NoChange;
        }
    }

    function _setDeposit(bytes32 id, AssetLib.AssetData memory asset) internal {
        _deposits[id] = asset;
    }

    function _setCompleted(bytes32 id, bool status) internal {
        _completed[id] = status;
    }

    function _subFeeInBp(
        uint256 value,
        uint256 total,
        uint256 feeInBp
    ) internal pure returns (uint256 newValue, uint256 realFee) {
        return _subFee(value, total.bp(feeInBp));
    }

    function _subFee(uint256 value, uint256 fee)
        internal
        pure
        returns (uint256 newValue, uint256 realFee)
    {
        if (value > fee) {
            newValue = value.sub(fee);
            realFee = fee;
        } else {
            newValue = 0;
            realFee = value;
        }
    }
}
