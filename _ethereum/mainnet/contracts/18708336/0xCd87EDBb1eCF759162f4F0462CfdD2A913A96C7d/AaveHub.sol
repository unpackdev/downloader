// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

/**
 * @author Christoph Krpoun
 * @author René Hochmuth
 * @author Vitally Marinchenko
 */

import "./AaveHelper.sol";
import "./TransferHelper.sol";
import "./ApprovalHelper.sol";

/**
 * @dev Purpose of this contract is to optimize capital efficency by using
 * aave pools. Not borrowed funds are deposited into correspoding aave pools
 * to earn supply APY.
 *
 * The aToken are holded by the wiseLending contract but the accounting
 * is managed by the position NFTs. This is possible due to the included
 * onBehlaf functionallity inside wiseLending.
 */

contract AaveHub is AaveHelper, TransferHelper, ApprovalHelper {

    constructor(
        address _master,
        address _aaveAddress,
        address _lendingAddress
    )
        Declarations(
            _master,
            _aaveAddress,
            _lendingAddress
        )
    {}

    /**
     * @dev Adds new mapping to aaveHub. Needed
     * to link underlying assets with corresponding
     * aTokens. Can only be called by master.
     */
    function setAaveTokenAddress(
        address _underlyingAsset,
        address _aaveToken
    )
        external
        onlyMaster
    {
        _setAaveTokenAddress(
            _underlyingAsset,
            _aaveToken
        );

    }

    /**
     * @dev Adds new mapping to aaveHub in bulk.
     * Needed to link underlying assets with
     * corresponding aTokens. Can only be called by master.
     */

    function setAaveTokenAddressBulk(
        address[] calldata _underlyingAssets,
        address[] calldata _aaveTokens
    )
        external
        onlyMaster
    {
        for (uint256 i = 0; i < _underlyingAssets.length; i++) {
            _setAaveTokenAddress(
                _underlyingAssets[i],
                _aaveTokens[i]
            );
        }
    }

    /**
     * @dev Receive functions forwarding
     * sent ETH to the master address
     */
    receive()
        external
        payable
    {
        if (msg.sender == WETH_ADDRESS) {
            return;
        }

        _sendValue(
            master,
            msg.value
        );
    }

    /**
     * @dev Allows deposit ERC20 token to
     * wiseLending and takes token amount
     * as arguement. Also mints position
     * NFT to reduce needed transactions.
     */
    function depositExactAmountMint(
        address _underlyingAsset,
        uint256 _amount
    )
        external
        returns (uint256)
    {
        return depositExactAmount(
            _reservePosition(),
            _underlyingAsset,
            _amount
        );
    }

    /**
     * @dev Allows deposit ERC20 token to
     * wiseLending and takes token amount as
     * argument.
     */
    function depositExactAmount(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _amount
    )
        public
        syncPool(_underlyingAsset)
        returns (uint256)
    {
        _checkDeposit(
            _nftId,
            _underlyingAsset,
            _amount
        );

        _safeTransferFrom(
            _underlyingAsset,
            msg.sender,
            address(this),
            _amount
        );

        uint256 lendingShares = _wrapDepositExactAmount(
            _nftId,
            _underlyingAsset,
            _amount
        );

        emit IsDepositAave(
            _nftId,
            block.timestamp
        );

        return lendingShares;
    }

    /**
     * @dev Allows to deposit ETH token directly to
     * wiseLending and takes token amount as argument.
     * Also mints position NFT to avoid extra transaction.
     */
    function depositExactAmountETHMint()
        external
        payable
        returns (uint256)
    {
        return depositExactAmountETH(
            _reservePosition()
        );
    }

    /**
     * @dev Allows to deposit ETH token directly to
     * wiseLending and takes token amount as argument.
     */
    function depositExactAmountETH(
        uint256 _nftId
    )
        public
        payable
        syncPool(WETH_ADDRESS)
        returns (uint256)
    {
        _checkDeposit(
            _nftId,
            WETH_ADDRESS,
            msg.value
        );

        _wrapETH(
            msg.value
        );

        uint256 lendingShares = _wrapDepositExactAmount(
            _nftId,
            WETH_ADDRESS,
            msg.value
        );

        emit IsDepositAave(
            _nftId,
            block.timestamp
        );

        return lendingShares;
    }

    /**
     * @dev Allows to withdraw deposited ERC20 token.
     * Takes _withdrawAmount as argument.
     */
    function withdrawExactAmount(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _withdrawAmount
    )
        external
        syncPool(_underlyingAsset)
        returns (uint256)
    {
        _checkOwner(
            _nftId
        );

        _checksWithdraw(
            _nftId,
            _underlyingAsset,
            _withdrawAmount
        );

        uint256 withdrawnShares = _wrapWithdrawExactAmount(
            _nftId,
            _underlyingAsset,
            msg.sender,
            _withdrawAmount
        );

        emit IsWithdrawAave(
            _nftId,
            block.timestamp
        );

        return withdrawnShares;
    }

    /**
     * @dev Allows to withdraw deposited ETH token.
     * Takes token amount as argument.
     */
    function withdrawExactAmountETH(
        uint256 _nftId,
        uint256 _withdrawAmount
    )
        external
        syncPool(WETH_ADDRESS)
        returns (uint256)
    {
        _checkOwner(
            _nftId
        );

        _checksWithdraw(
            _nftId,
            WETH_ADDRESS,
            _withdrawAmount
        );

        uint256 withdrawnShares = _wrapWithdrawExactAmount(
            _nftId,
            WETH_ADDRESS,
            address(this),
            _withdrawAmount
        );

        _unwrapETH(
            _withdrawAmount
        );

        _sendValue(
            msg.sender,
            _withdrawAmount
        );

        emit IsWithdrawAave(
            _nftId,
            block.timestamp
        );

        return withdrawnShares;
    }

    /**
     * @dev Allows to withdraw deposited ERC20 token.
     * Takes _shareAmount as argument.
     */
    function withdrawExactShares(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _shareAmount
    )
        external
        syncPool(_underlyingAsset)
        returns (uint256)
    {
        _checkOwner(
            _nftId
        );

        uint256 withdrawAmount = _wrapWithdrawExactShares(
            _nftId,
            _underlyingAsset,
            msg.sender,
            _shareAmount
        );

        emit IsWithdrawAave(
            _nftId,
            block.timestamp
        );

        return withdrawAmount;
    }

    /**
     * @dev Allows to withdraw deposited ETH token.
     * Takes _shareAmount as argument.
     */
    function withdrawExactSharesETH(
        uint256 _nftId,
        uint256 _shareAmount
    )
        external
        syncPool(WETH_ADDRESS)
        returns (uint256)
    {
        _checkOwner(
            _nftId
        );

        uint256 withdrawAmount = _wrapWithdrawExactShares(
            _nftId,
            WETH_ADDRESS,
            address(this),
            _shareAmount
        );

        _unwrapETH(
            withdrawAmount
        );

        _sendValue(
            msg.sender,
            withdrawAmount
        );

        emit IsWithdrawAave(
            _nftId,
            block.timestamp
        );

        return withdrawAmount;
    }

    /**
     * @dev Allows to borrow ERC20 token from a
     * wiseLending pool. Needs supplied collateral
     * inside the same position and to approve
     * aaveHub to borrow onBehalf for the caller.
     * Takes token amount as argument.
     */
    function borrowExactAmount(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _borrowAmount
    )
        external
        syncPool(_underlyingAsset)
        returns (uint256)
    {
        _checkOwner(
            _nftId
        );

        _checksBorrow(
            _nftId,
            _underlyingAsset,
            _borrowAmount
        );

        uint256 borrowShares = _wrapBorrowExactAmount(
            _nftId,
            _underlyingAsset,
            msg.sender,
            _borrowAmount
        );

        emit IsBorrowAave(
            _nftId,
            block.timestamp
        );

        return borrowShares;
    }

    /**
     * @dev Allows to borrow ETH token from
     * wiseLending. Needs supplied collateral
     * inside the same position and to approve
     * aaveHub to borrow onBehalf for the caller.
     * Takes token amount as argument.
     */
    function borrowExactAmountETH(
        uint256 _nftId,
        uint256 _borrowAmount
    )
        external
        syncPool(WETH_ADDRESS)
        returns (uint256)
    {
        _checkOwner(
            _nftId
        );

        _checksBorrow(
            _nftId,
            WETH_ADDRESS,
            _borrowAmount
        );

        uint256 borrowShares = _wrapBorrowExactAmount(
            _nftId,
            WETH_ADDRESS,
            address(this),
            _borrowAmount
        );

        _unwrapETH(
            _borrowAmount
        );

        _sendValue(
            msg.sender,
            _borrowAmount
        );

        emit IsBorrowAave(
            _nftId,
            block.timestamp
        );

        return borrowShares;
    }

    /**
     * @dev Allows to payback ERC20 token for
     * any postion. Takes _paybackAmount as argument.
     */
    function paybackExactAmount(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _paybackAmount
    )
        external
        syncPool(_underlyingAsset)
        returns (uint256)
    {
        _checkPositionLocked(
            _nftId
        );

        address aaveToken = aaveTokenAddress[
            _underlyingAsset
        ];

        _safeTransferFrom(
            _underlyingAsset,
            msg.sender,
            address(this),
            _paybackAmount
        );

        uint256 actualAmountDeposit = _wrapAaveReturnValueDeposit(
            _underlyingAsset,
            _paybackAmount,
            address(this)
        );

        uint256 borrowSharesReduction = WISE_LENDING.paybackExactAmount(
            _nftId,
            aaveToken,
            actualAmountDeposit
        );

        emit IsPaybackAave(
            _nftId,
            block.timestamp
        );

        return borrowSharesReduction;
    }

    /**
     * @dev Allows to payback ETH token for
     * any postion. Takes token amount as argument.
     */
    function paybackExactAmountETH(
        uint256 _nftId
    )
        external
        payable
        syncPool(WETH_ADDRESS)
        returns (uint256)
    {
        _checkPositionLocked(
            _nftId
        );

        address aaveWrappedETH = aaveTokenAddress[
            WETH_ADDRESS
        ];

        uint256 userBorrowShares = WISE_LENDING.getPositionBorrowShares(
            _nftId,
            aaveWrappedETH
        );

        uint256 maxPaybackAmount = WISE_LENDING.paybackAmount(
            aaveWrappedETH,
            userBorrowShares
        );

        (
            uint256 paybackAmount,
            uint256 ethRefundAmount

        ) = _getInfoPayback(
            msg.value,
            maxPaybackAmount
        );

        _wrapETH(
            paybackAmount
        );

        uint256 actualAmountDeposit = _wrapAaveReturnValueDeposit(
            WETH_ADDRESS,
            paybackAmount,
            address(this)
        );

        uint256 borrowSharesReduction = WISE_LENDING.paybackExactAmount(
            _nftId,
            aaveWrappedETH,
            actualAmountDeposit
        );

        if (ethRefundAmount > 0) {
            _sendValue(
                msg.sender,
                ethRefundAmount
            );
        }

        emit IsPaybackAave(
            _nftId,
            block.timestamp
        );

        return borrowSharesReduction;
    }

    /**
     * @dev Allows to payback ERC20 token for
     * any postion. Takes shares as argument.
     */
    function paybackExactShares(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _shares
    )
        external
        syncPool(_underlyingAsset)
        returns (uint256)
    {
        _checkPositionLocked(
            _nftId
        );

        address aaveToken = aaveTokenAddress[
            _underlyingAsset
        ];

        uint256 paybackAmount = WISE_LENDING.paybackAmount(
            aaveToken,
            _shares
        );

        _safeTransferFrom(
            _underlyingAsset,
            msg.sender,
            address(this),
            paybackAmount
        );

        AAVE.deposit(
            _underlyingAsset,
            paybackAmount,
            address(this),
            REF_CODE
        );

        WISE_LENDING.paybackExactShares(
            _nftId,
            aaveToken,
            _shares
        );

        emit IsPaybackAave(
            _nftId,
            block.timestamp
        );

        return paybackAmount;
    }

    /**
     * @dev Allows to deposit ERC20 token in
     * private mode. These funds are saved from
     * borrowed out. User can withdraw private funds
     * anytime even the pools are empty. Private funds
     * do not earn any APY! Also a postion NFT is minted
     * to reduce transactions.
     */
    function solelyDepositMint(
        address _underlyingAsset,
        uint256 _depositAmount
    )
        external
    {
        solelyDeposit(
            _reservePosition(),
            _underlyingAsset,
            _depositAmount
        );
    }

    /**
     * @dev Allows to deposit ERC20 token in
     * private mode. These funds are saved from
     * borrowing by other users. User can withdraw
     * private funds anytime even the pools are empty.
     * Private funds do not earn any APY!
     */
    function solelyDeposit(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _depositAmount
    )
        public
        syncPool(_underlyingAsset)
    {
        _checkDeposit(
            _nftId,
            _underlyingAsset,
            _depositAmount
        );

        _safeTransferFrom(
            _underlyingAsset,
            msg.sender,
            address(this),
            _depositAmount
        );

        _wrapSolelyDeposit(
            _nftId,
            _underlyingAsset,
            _depositAmount
        );

        emit IsSolelyDepositAave(
            _nftId,
            block.timestamp
        );
    }

    /**
     * @dev Allows to withdraw ERC20 token from
     * private mode.
     */
    function solelyWithdraw(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _withdrawAmount
    )
        external
        syncPool(_underlyingAsset)
    {
        _checkOwner(
            _nftId
        );

        _checksSolelyWithdraw(
            _nftId,
            _underlyingAsset,
            _withdrawAmount
        );

        _wrapSolelyWithdraw(
            _nftId,
            _underlyingAsset,
            msg.sender,
            _withdrawAmount
        );

        emit IsSolelyWithdrawAave(
            _nftId,
            block.timestamp
        );
    }

    /**
     * @dev Allows to deposit ETH token in
     * private mode. These funds are saved from
     * borrowing by other users. User can withdraw
     * private funds anytime even the pools are empty.
     * Private funds do not earn any APY! Also a position
     * NFT is minted to reduce transactions.
     */
    function solelyDepositETHMint()
        external
        payable
    {
        solelyDepositETH(
            _reservePosition()
        );
    }

    /**
     * @dev Allows to deposit ETH token in
     * private mode. These funds are saved from
     * borrowing by other users. User can withdraw
     * private funds anytime even the pools are empty.
     * Private funds do not earn any APY!
     */
    function solelyDepositETH(
        uint256 _nftId
    )
        public
        payable
        syncPool(WETH_ADDRESS)
    {
        _checkDeposit(
            _nftId,
            WETH_ADDRESS,
            msg.value
        );

        _wrapETH(
            msg.value
        );

        _wrapSolelyDeposit(
            _nftId,
            WETH_ADDRESS,
            msg.value
        );

        emit IsSolelyDepositAave(
            _nftId,
            block.timestamp
        );
    }

    /**
     * @dev Allows to withdraw ETH token from
     * private mode.
     */
    function solelyWithdrawETH(
        uint256 _nftId,
        uint256 _withdrawAmount
    )
        external
        syncPool(WETH_ADDRESS)
    {
        _checkOwner(
            _nftId
        );

        _checksSolelyWithdraw(
            _nftId,
            WETH_ADDRESS,
            _withdrawAmount
        );

        _wrapSolelyWithdraw(
            _nftId,
            WETH_ADDRESS,
            address(this),
            _withdrawAmount
        );

        _unwrapETH(
            _withdrawAmount
        );

        _sendValue(
            msg.sender,
            _withdrawAmount
        );

        emit IsSolelyWithdrawAave(
            _nftId,
            block.timestamp
        );
    }

    /**
     * @dev View functions returning the combined rate
     * from aave supply APY and wiseLending borrow APY
     * of a pool.
     */
    function getLendingRate(
        address _underlyingAsset
    )
        external
        view
        returns (uint256)
    {
        address aToken = aaveTokenAddress[
            _underlyingAsset
        ];

        uint256 lendingRate = WISE_SECURITY.getLendingRate(
            aToken
        );

        uint256 aaveRate = getAavePoolAPY(
            _underlyingAsset
        );

        uint256 utilization = WISE_LENDING.globalPoolData(
            aToken
        ).utilization;

        return aaveRate
            * (PRECISION_FACTOR_E18 - utilization)
            / PRECISION_FACTOR_E18
            + lendingRate;
    }

    function _setAaveTokenAddress(
        address _underlyingAsset,
        address _aaveToken
    )
        internal
    {
        if (aaveTokenAddress[_underlyingAsset] > ZERO_ADDRESS) {
            revert AlreadySet();
        }

        aaveTokenAddress[_underlyingAsset] = _aaveToken;

        _safeApprove(
            _aaveToken,
            address(WISE_LENDING),
            MAX_AMOUNT
        );

        _safeApprove(
            _underlyingAsset,
            AAVE_ADDRESS,
            MAX_AMOUNT
        );

        emit SetAaveTokenAddress(
            _underlyingAsset,
            _aaveToken,
            block.timestamp
        );
    }
}
