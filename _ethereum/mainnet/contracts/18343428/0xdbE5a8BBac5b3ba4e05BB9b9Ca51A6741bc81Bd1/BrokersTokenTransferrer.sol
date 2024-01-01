// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./BrokersStorage.sol";
import "./DataTypes.sol";

abstract contract BrokersTokenTransferrer is BrokersStorage {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using SafeERC20 for IERC20;

    /// -----------------------------------------------------------------------
    /// Transfer action
    /// -----------------------------------------------------------------------

    function _transferAssets(
        Assets calldata _assets,
        bool contraOption,
        Fees calldata contraFees,
        address from,
        address to
    ) internal {
        unchecked {
            uint256 i;
            uint len = _assets.assets.length;
            bool deductedContra = false;
            for (i = 0; i < len; ) {
                if (_assets.assets[i].assetType == AssetType.ERC_721) {
                    IERC721(_assets.assets[i].token).safeTransferFrom(
                        from,
                        to,
                        _assets.assets[i].tokenId
                    );
                } else if (_assets.assets[i].assetType == AssetType.ERC_1155) {
                    IERC1155(_assets.assets[i].token).safeTransferFrom(
                        from,
                        to,
                        _assets.assets[i].tokenId,
                        _assets.assets[i].amount,
                        ""
                    );
                } else if (_assets.assets[i].assetType == AssetType.KITTIES) {
                    _transferFromKitty(
                        _assets.assets[i].token,
                        _assets.assets[i].tokenId,
                        from,
                        to
                    );
                } else if (_assets.assets[i].assetType == AssetType.PUNK) {
                    _receivePunk(
                        _assets.assets[i].token,
                        _assets.assets[i].tokenId,
                        from
                    );
                    _sendPunk(
                        _assets.assets[i].token,
                        _assets.assets[i].tokenId,
                        to
                    );
                } else if (_assets.assets[i].assetType == AssetType.ERC_20) {
                    uint256 deduction = 0;

                    // If the "contra" option of another user is true, then the original user
                    // transfers the that user's fee to both the broker and protocol first,
                    // and then sends the remaining amount back to that user.
                    if (
                        _assets.assets[i].token == contraFees.token &&
                        contraOption
                    ) {
                        deduction =
                            contraFees.brokerAmount +
                            contraFees.platformAmount;
                        if (deduction > _assets.assets[i].amount) {
                            revert BrokersError(
                                BrokersErrorCodes
                                    .INSUFFICIENT_TOKEN_AMOUNT_FOR_FEE_DEDUCTION
                            );
                        }
                        _transferFee(from, contraFees);
                        deductedContra = true;
                    }

                    IERC20(_assets.assets[i].token).safeTransferFrom(
                        from,
                        to,
                        _assets.assets[i].amount - deduction
                    );
                } else {
                    revert BrokersError(BrokersErrorCodes.INVALID_ASSET_TYPE);
                }
                ++i;
            }
            if (contraOption && !deductedContra) {
                revert BrokersError(
                    BrokersErrorCodes.FEE_TOKEN_MISSING_FROM_CONTRA
                );
            }
        }
        emit AssetsTransferred(_assets, from, to);
    }

    /// -----------------------------------------------------------------------
    /// Helper functions
    /// -----------------------------------------------------------------------

    /// @dev Transfer fee to the brokers.
    /// @param _from User address
    /// @param fees Fees details to be transferred
    function _transferFee(address _from, Fees calldata fees) internal {
        if (fees.brokerAmount > 0)
            IERC20(fees.token).safeTransferFrom(
                _from,
                fees.broker,
                fees.brokerAmount
            );

        if (fees.platformAmount > 0)
            IERC20(fees.token).safeTransferFrom(
                _from,
                fees.platform,
                fees.platformAmount
            );

        emit FeeTransferred(_from, fees);
    }

    /// @dev Send crypto punk NFT.
    /// @param _punkAddress Address of crypto punk contract
    /// @param _punkIndex TokenId of PUNK
    /// @param _to Receiver address
    function _sendPunk(
        address _punkAddress,
        uint256 _punkIndex,
        address _to
    ) internal {
        bytes memory data = abi.encodeWithSignature(
            "transferPunk(address,uint256)",
            _to,
            _punkIndex
        );
        (bool success, ) = _punkAddress.call(data);
        if (!success) {
            revert BrokersError(BrokersErrorCodes.INVALID_PUNK);
        }
    }

    /// @dev Receive crypto punk NFT.
    /// @param _punkAddress Address of crypto punk contract
    /// @param _punkIndex TokenId of PUNK
    /// @param _from Sender address
    function _receivePunk(
        address _punkAddress,
        uint256 _punkIndex,
        address _from
    ) internal {
        // Ensure no front running.
        bytes memory punkIndexToAddress = abi.encodeWithSignature(
            "punkIndexToAddress(uint256)",
            _punkIndex
        );
        (bool checkSuccess, bytes memory result) = _punkAddress.staticcall(
            punkIndexToAddress
        );
        address punkOwner = abi.decode(result, (address));
        if (!(checkSuccess && punkOwner == _from)) {
            revert BrokersError(BrokersErrorCodes.INVALID_PUNK);
        }
        // transfer punk to vault
        bytes memory data = abi.encodeWithSignature(
            "buyPunk(uint256)",
            _punkIndex
        );
        (bool success, ) = address(_punkAddress).call(data);
        if (!success) {
            revert BrokersError(BrokersErrorCodes.INVALID_PUNK);
        }
    }

    /// @dev Send crypto kitty nft.
    /// @param _token CryptoKitty contract address
    /// @param _tokenId CryptoKitty tokenId
    /// @param _from Sender address
    /// @param _to Receiver address
    function _transferFromKitty(
        address _token,
        uint256 _tokenId,
        address _from,
        address _to
    ) internal {
        bytes memory data = abi.encodeWithSelector(
            IERC721.transferFrom.selector,
            _from,
            _to,
            _tokenId
        );
        (bool success, ) = address(_token).call(data);
        if (!success) {
            revert BrokersError(BrokersErrorCodes.INVALID_KITTY);
        }
    }
}
