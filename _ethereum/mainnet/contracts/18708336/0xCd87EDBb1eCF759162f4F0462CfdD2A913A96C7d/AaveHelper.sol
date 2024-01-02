// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "./Declarations.sol";

abstract contract AaveHelper is Declarations {

    modifier syncPool(
        address _underlyingToken
    ) {
        if (sendingProgressAaveHub == true) {
            revert InvalidAction();
        }

        if (WISE_LENDING.sendingProgress() == true) {
            revert InvalidAction();
        }

        if (WISE_LENDING.verifiedIsolationPool(msg.sender) == false) {
            WISE_LENDING.preparePool(
                aaveTokenAddress[
                    _underlyingToken
                ]
            );
        }
        _;
    }

    function _prepareAssetsPosition(
        uint256 _nftId,
        address _underlyingToken
    )
        private
    {
        if (WISE_LENDING.verifiedIsolationPool(msg.sender) == true) {
            return;
        }

        _prepareCollaterals(
            _nftId,
            aaveTokenAddress[_underlyingToken]
        );

        _prepareBorrows(
            _nftId,
            aaveTokenAddress[_underlyingToken]
        );
    }

    function _reservePosition()
        internal
        returns (uint256)
    {
        return POSITION_NFT.reservePositionForUser(
            msg.sender
        );
    }

    function _wrapDepositExactAmount(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _depositAmount
    )
        internal
        returns (uint256)
    {
        _prepareAssetsPosition(
            _nftId,
            _underlyingAsset
        );

        AAVE.deposit(
            _underlyingAsset,
            _depositAmount,
            address(this),
            REF_CODE
        );

        uint256 lendingShares = WISE_LENDING.depositExactAmount(
            _nftId,
            aaveTokenAddress[_underlyingAsset],
            _depositAmount
        );

        return lendingShares;
    }

    function _wrapWithdrawExactAmount(
        uint256 _nftId,
        address _underlyingAsset,
        address _underlyingAssetRecipient,
        uint256 _withdrawAmount
    )
        internal
        returns (uint256)
    {
        _prepareAssetsPosition(
            _nftId,
            _underlyingAsset
        );

        uint256 withdrawnShares = WISE_LENDING.withdrawOnBehalfExactAmount(
            _nftId,
            aaveTokenAddress[_underlyingAsset],
            _withdrawAmount
        );

        AAVE.withdraw(
            _underlyingAsset,
            _withdrawAmount,
            _underlyingAssetRecipient
        );

        return withdrawnShares;
    }

    function _wrapWithdrawExactShares(
        uint256 _nftId,
        address _underlyingAsset,
        address _underlyingAssetRecipient,
        uint256 _shareAmount
    )
        internal
        returns (uint256)
    {
        _prepareAssetsPosition(
            _nftId,
            _underlyingAsset
        );

        address aaveToken = aaveTokenAddress[
            _underlyingAsset
        ];

        uint256 withdrawAmount = WISE_LENDING.cashoutAmount(
            aaveToken,
            _shareAmount
        );

        WISE_SECURITY.checksWithdraw(
            _nftId,
            msg.sender,
            aaveToken,
            withdrawAmount
        );

        WISE_LENDING.withdrawOnBehalfExactShares(
            _nftId,
            aaveToken,
            _shareAmount
        );

        AAVE.withdraw(
            _underlyingAsset,
            withdrawAmount,
            _underlyingAssetRecipient
        );

        return withdrawAmount;
    }

    function _wrapBorrowExactAmount(
        uint256 _nftId,
        address _underlyingAsset,
        address _underlyingAssetRecipient,
        uint256 _borrowAmount
    )
        internal
        returns (uint256)
    {
        _prepareAssetsPosition(
            _nftId,
            _underlyingAsset
        );

        uint256 borrowShares = WISE_LENDING.borrowOnBehalfExactAmount(
            _nftId,
            aaveTokenAddress[_underlyingAsset],
            _borrowAmount
        );

        AAVE.withdraw(
            _underlyingAsset,
            _borrowAmount,
            _underlyingAssetRecipient
        );

        return borrowShares;
    }

    function _wrapAaveReturnValueDeposit(
        address _underlyingAsset,
        uint256 _depositAmount,
        address _targetAddress
    )
        internal
        returns (uint256 res)
    {
        IERC20 token = IERC20(
            aaveTokenAddress[_underlyingAsset]
        );

        uint256 balanceBefore = token.balanceOf(
            address(this)
        );

        AAVE.deposit(
            _underlyingAsset,
            _depositAmount,
            _targetAddress,
            REF_CODE
        );

        uint256 balanceAfter = token.balanceOf(
            address(this)
        );

        res = balanceAfter
            - balanceBefore;
    }

    function _wrapSolelyDeposit(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _depositAmount
    )
        internal
    {
        AAVE.deposit(
            _underlyingAsset,
            _depositAmount,
            address(this),
            REF_CODE
        );

        WISE_LENDING.solelyDeposit(
            _nftId,
            aaveTokenAddress[_underlyingAsset],
            _depositAmount
        );
    }

    function _wrapSolelyWithdraw(
        uint256 _nftId,
        address _underlyingAsset,
        address _underlyingAssetRecipient,
        uint256 _withdrawAmount
    )
        internal
    {
        _prepareAssetsPosition(
            _nftId,
            _underlyingAsset
        );

        WISE_LENDING.solelyWithdrawOnBehalf(
            _nftId,
            aaveTokenAddress[_underlyingAsset],
            _withdrawAmount
        );

        AAVE.withdraw(
            _underlyingAsset,
            _withdrawAmount,
            _underlyingAssetRecipient
        );
    }

    function _wrapETH(
        uint256 _value
    )
        internal
    {
        WETH.deposit{
            value: _value
        }();
    }

    function _unwrapETH(
        uint256 _value
    )
        internal
    {
        WETH.withdraw(
            _value
        );
    }

    function _sendValue(
        address _recipient,
        uint256 _amount
    )
        internal
    {
        if (address(this).balance < _amount) {
            revert InvalidValue();
        }

        sendingProgressAaveHub = true;

        (bool success, ) = payable(_recipient).call{
            value: _amount
        }("");

        sendingProgressAaveHub = false;

        if (success == false) {
            revert FailedInnerCall();
        }
    }

    function _getInfoPayback(
        uint256 _ethSent,
        uint256 _maxPaybackAmount
    )
        internal
        pure
        returns (
            uint256,
            uint256
        )
    {
        if (_ethSent > _maxPaybackAmount) {
            return (
                _maxPaybackAmount,
                _ethSent - _maxPaybackAmount
            );
        }

        return (
            _ethSent,
            0
        );
    }

    function _prepareCollaterals(
        uint256 _nftId,
        address _poolToken
    )
        private
    {
        uint256 i;
        uint256 l = WISE_LENDING.getPositionLendingTokenLength(
            _nftId
        );

        for (i; i < l;) {

            address currentAddress = WISE_LENDING.getPositionLendingTokenByIndex(
                _nftId,
                i
            );

            unchecked {
                ++i;
            }

            if (currentAddress == _poolToken) {
                continue;
            }

            WISE_LENDING.preparePool(
                currentAddress
            );

            WISE_LENDING.newBorrowRate(
                _poolToken
            );
        }
    }

    function _prepareBorrows(
        uint256 _nftId,
        address _poolToken
    )
        private
    {
        uint256 i;
        uint256 l = WISE_LENDING.getPositionBorrowTokenLength(
            _nftId
        );

        for (i; i < l;) {

            address currentAddress = WISE_LENDING.getPositionBorrowTokenByIndex(
                _nftId,
                i
            );

            unchecked {
                ++i;
            }

            if (currentAddress == _poolToken) {
                continue;
            }

            WISE_LENDING.preparePool(
                currentAddress
            );

            WISE_LENDING.newBorrowRate(
                _poolToken
            );
        }
    }

    function getAavePoolAPY(
        address _underlyingAsset
    )
        public
        view
        returns (uint256)
    {
        return AAVE.getReserveData(_underlyingAsset).currentLiquidityRate
            / PRECISION_FACTOR_E9;
    }
}
