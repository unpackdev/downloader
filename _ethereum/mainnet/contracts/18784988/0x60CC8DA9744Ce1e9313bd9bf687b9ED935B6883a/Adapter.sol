// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.21;

/**
 * @author René Hochmuth
 * @author Vitally Marinchenko
 */

import "./AdapterHelper.sol";

contract Adapter is AdapterHelper {

    constructor(
        address _tokenProfitAddress,
        address _uniV2RouterAddress,
        address _liquidNFTsRouterAddress,
        address _liquidNFTsWETHPool,
        address _liquidNFTsUSDCPool,
        address _wiseLendingAddress,
        bool _isPaused
    )
        AdapterDeclarations(
            _tokenProfitAddress,
            _uniV2RouterAddress,
            _liquidNFTsRouterAddress,
            _liquidNFTsWETHPool,
            _liquidNFTsUSDCPool,
            _wiseLendingAddress,
            _isPaused
        )
    {
        admin = tx.origin;
        multisig = tx.origin;
    }

    /**
    * @dev Overview for services and ability to syncronize them
    */
    function syncServices()
        external
    {
        liquidNFTsUSDCPool.manualSyncPool();
        liquidNFTsWETHPool.manualSyncPool();
    }

    /**
    * @dev Allows admin to swap USDC for ETH using UniswapV2
    */
    function swapUSDCForETH(
        uint256 _amount,
        uint256 _minAmountOut
    )
        external
        onlyMultiSig
        returns (
            uint256 amountIn,
            uint256 amountOut
        )
    {
        address[] memory path = new address[](2);

        path[0] = USDC_ADDRESS;
        path[1] = WETH_ADDRESS;

        uint256[] memory amounts = _executeSwap(
            path,
            _amount,
            _minAmountOut
        );

        emit AdminSwap(
            USDC_ADDRESS,
            WETH_ADDRESS,
            amounts[0],
            amounts[1]
        );

        return (
            amounts[0],
            amounts[1]
        );
    }

    function _precisionWithFee()
        internal
        view
        returns (uint256)
    {
        return FEE_PRECISION + buyFee;
    }

    /**
     * @dev Calculates tokens to mint given exact ETH amount
     * input for the TokenProfit contract during mint
     */
    function getTokenAmountFromEthAmount(
        uint256 _ethAmount
    )
        external
        view
        returns (uint256)
    {
        return tokenProfit.totalSupply()
            * _ethAmount
            * FEE_PRECISION
            / _precisionWithFee()
            / _calculateTotalEthValue(
                0
            );
    }

    /**
     * @dev Calculates ETH amount necessary to pay to
     * receive fixed token amount from the TokenProfit contract
     */
    function getEthAmountFromTokenAmount(
        uint256 _tokenAmount,
        uint256 _msgValue
    )
        external
        view
        returns (uint256)
    {
        return _calculateTotalEthValue(
            _msgValue
        )
            * _tokenAmount
            * PRECISION_FACTOR
            * _precisionWithFee()
            / FEE_PRECISION
            / tokenProfit.totalSupply()
            / PRECISION_FACTOR;
    }

    function proposeNewMultisig(
        address _proposedMultisig
    )
        external
        onlyMultiSig
    {
        address oldProposedMultisig = proposedMultisig;
        proposedMultisig = _proposedMultisig;

        emit MultisigUpdateProposed(
            oldProposedMultisig,
            _proposedMultisig
        );
    }

    function claimMultisigOwnership()
        external
        onlyProposedMultisig
    {
        address oldMultisig = multisig;
        multisig = proposedMultisig;
        proposedMultisig = ZERO_ADDRESS;

        emit MultisigUpdate(
            oldMultisig,
            multisig
        );
    }

    /**
     * @dev Starts the process to change the admin address
     */
    function proposeNewAdmin(
        address _newProposedAdmin
    )
        external
        onlyMultiSig
    {
        address oldProposedAdmin = proposedAdmin;
        proposedAdmin = _newProposedAdmin;

        emit AdminUpdateProposed(
            oldProposedAdmin,
            _newProposedAdmin
        );
    }

    /**
     * @dev Finalize the change of the admin address
     */
    function claimAdminOwnership()
        external
        onlyProposedAdmin
    {
        address oldAdmin = admin;
        admin = proposedAdmin;
        proposedAdmin = ZERO_ADDRESS;

        emit AdminUpdate(
            oldAdmin,
            admin
        );
    }

    /**
     * @dev Ability for multisig to change the buy fee
     */
    function changeBuyFee(
        uint256 _newFeeValue
    )
        external
        onlyMultiSig
    {
        if (_newFeeValue > FEE_THRESHOLD) {
            revert ValueTooHigh();
        }

        if (_newFeeValue < FEE_LOWER_BOUND) {
            revert ValueTooLow();
        }

        uint256 oldValue = buyFee;
        buyFee = _newFeeValue;

        emit BuyFeeChanged(
            oldValue,
            _newFeeValue
        );
    }

    /**
     * @dev Allows multisig to swap ETH for USDC using UniswapV2
     */
    function swapETHforUSDC(
        uint256 _amount,
        uint256 _minAmountOut
    )
        external
        onlyMultiSig
        returns (
            uint256 amountIn,
            uint256 amountOut
        )
    {
        address[] memory path = new address[](2);

        path[0] = WETH_ADDRESS;
        path[1] = USDC_ADDRESS;

        uint256[] memory amounts = _executeSwapWithValue(
            path,
            _amount,
            _minAmountOut
        );

        emit AdminSwap(
            WETH_ADDRESS,
            USDC_ADDRESS,
            amounts[0],
            amounts[1]
        );

        return (
            amounts[0],
            amounts[1]
        );
    }

    /**
     * @dev Allows admin to deposit funds into WiseLending protocol
     */
    function depositWiseLending(
        address _poolToken,
        uint256 _depositAmount
    )
        external
        onlyAdmin
    {
        if (_poolToken == WETH_ADDRESS) {
            _wrapETH(
                _depositAmount
            );
        }

        IERC20(_poolToken).approve(
            address(WISE_LENDING),
            _depositAmount
        );

        _depositWiseLendingWrapper(
            _poolToken,
            _depositAmount
        );
    }

    /**
     * @dev Allows admin to deposit funds into WiseLending protocol
     */
    function withdrawWiseLending(
        address _poolToken,
        uint256 _withdrawAmount
    )
        external
        onlyAdmin
    {
        _withdrawWiseLendingWrapper(
            _poolToken,
            _withdrawAmount
        );

        if (_poolToken == WETH_ADDRESS) {
            _unwrapETH(
                _withdrawAmount
            );
        }
    }

    /**
     * @dev Allows admin to deposit ETH into LiquidNFTs pool
     */
    function depositETHLiquidNFTs(
        uint256 _amount
    )
        external
        onlyAdmin
    {
        _wrapETH(
            _amount
        );

        _depositLiquidNFTsWrapper(
            liquidNFTsWETHPool,
            _amount
        );
    }

    /**
     * @dev Allows admin to deposit USDC into LiquidNFTs pool
     */
    function depositUSDCLiquidNFTs(
        uint256 _amount
    )
        external
        onlyAdmin
    {
        _depositLiquidNFTsWrapper(
            liquidNFTsUSDCPool,
            _amount
        );
    }

    /**
     * @dev Allows admin to withdraw USDC from LiquidNFTs pool
     */
    function withdrawUSDCLiquidNFTs(
        uint256 _amount
    )
        external
        onlyAdmin
    {
        _withdrawLiquidNFTsWrapper(
            liquidNFTsUSDCPool,
            _amount
        );
    }

    /**
     * @dev Allows admin to withdraw ETH from LiquidNFTs pool
     */
    function withdrawETHLiquidNFTs(
        uint256 _amount
    )
        external
        onlyAdmin
    {
        _withdrawLiquidNFTsWrapper(
            liquidNFTsWETHPool,
            _amount
        );

        _unwrapETH(
            WETH.balanceOf(
                TOKEN_PROFIT_ADDRESS
            )
        );
    }

    /**
     * @dev Allows TokenProfit contract to withdraw tokens from services
     */
    function assistWithdrawTokens(
        uint256 _index,
        uint256 _amount
    )
        external
        onlyTokenProfit
        returns (uint256)
    {
        if (tokens[_index].tokenERC20 == USDC) {
            return _USDCRoutine(
                _amount
            );
        }

        revert InvalidToken();
    }

    /**
     * @dev Allows TokenProfit contract to withdraw ETH from services
     */
    function assistWithdrawETH(
        uint256 _amount
    )
        external
        onlyTokenProfit
        returns (uint256)
    {
        uint256 wethAmountReturned = _WETHRoutine(
            _amount
        );

        _unwrapETH(
            wethAmountReturned
        );

        return wethAmountReturned;
    }

    /**
     * @dev Allows admin to forward activeNFT to a new address
     */
    function transferNFT(
        address _newAddress
    )
        external
        onlyAdmin
    {
        POSITION_NFTS.transferFrom(
            address(this),
            _newAddress,
            ACTIVE_NFT
        );

        emit NFTForwarded(
            ACTIVE_NFT,
            _newAddress
        );
    }
}
