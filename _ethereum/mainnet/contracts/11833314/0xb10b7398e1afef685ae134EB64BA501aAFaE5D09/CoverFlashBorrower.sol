// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./IProtocol.sol";
import "./IFlashBorrower.sol";
import "./IERC3156FlashLender.sol";
import "./ICover.sol";
import "./IBPool.sol";
import "./IERC20.sol";
import "./IYERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

/**
 * @title Cover FlashBorrower
 * @author alan
 */
contract CoverFlashBorrower is Ownable, IFlashBorrower {
    using SafeERC20 for IERC20;

    IERC3156FlashLender public flashLender;
    IERC20 public constant dai = IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
    IYERC20 public constant ydai = IYERC20(0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01);

    modifier onlySupportedCollaterals(address _collateral) {
        require(_collateral == address(dai) || _collateral == address(ydai), "only supports DAI and yDAI collaterals");
        _;
    }
    
    constructor (IERC3156FlashLender _flashLender) {
        flashLender = _flashLender;
    }

    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator, 
        address token, 
        uint256 amount, 
        uint256 fee, 
        bytes calldata data
    ) external override returns(bytes32) {
        require(msg.sender == address(flashLender), "CoverFlashBorrower: Untrusted lender");
        require(initiator == address(this), "CoverFlashBorrower: Untrusted loan initiator");
        require(token == address(dai), "!dai"); // For v1, can only flashloan DAI
        uint256 amountOwed = amount + fee;
        FlashLoanData memory flashLoanData = abi.decode(data, (FlashLoanData));
        if (flashLoanData.isBuy) {
            _onFlashLoanBuyClaim(flashLoanData, amount, amountOwed);
        } else {
            _onFlashLoanSellClaim(flashLoanData, amount, amountOwed);
        }
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    /**
     * @dev Flash loan the amount of collateral needed to mint `_amountCovTokens` covTokens
     * - If collateral is yDAI, `_amountCovTokens` is scaled by current price of yDAI to flash borrow enough DAI
     */
    function flashBuyClaim(
        IBPool _bpool,
        IProtocol _protocol, 
        address _collateral, 
        uint48 _timestamp, 
        uint256 _amountToBuy, 
        uint256 _maxAmountToSpend
    ) external override onlySupportedCollaterals(_collateral) {
        bytes memory data = abi.encode(FlashLoanData({
            isBuy: true,
            bpool: _bpool,
            protocol: _protocol,
            caller: msg.sender,
            collateral: _collateral,
            timestamp: _timestamp,
            amount: _amountToBuy,
            limit: _maxAmountToSpend
        }));
        uint256 amountDaiNeeded;
        if (_collateral == address(dai)) {
            amountDaiNeeded = _amountToBuy;
        } else if (_collateral == address(ydai)) {
            amountDaiNeeded = _amountToBuy * ydai.getPricePerFullShare();
        }
        require(amountDaiNeeded <= flashLender.maxFlashAmount(address(dai)), "_amount > lender reserves");
        uint256 _allowance = dai.allowance(address(this), address(flashLender));
        uint256 _fee = flashLender.flashFee(address(dai), amountDaiNeeded);
        uint256 _repayment = amountDaiNeeded + _fee;
        dai.approve(address(flashLender), _allowance + _repayment);
        flashLender.flashLoan(address(this), address(dai), amountDaiNeeded, data);
    }

    /**
     * @dev Flash loan the amount of DAI needed to buy enough NOCLAIM to redeem with CLAIM tokens
     */
    function flashSellClaim(
        IBPool _bpool,
        IProtocol _protocol, 
        address _collateral, 
        uint48 _timestamp, 
        uint256 _amountToSell, 
        uint256 _minAmountToReturn
    ) external override onlySupportedCollaterals(_collateral) {
        bytes memory data = abi.encode(FlashLoanData({
            isBuy: false,
            bpool: _bpool,
            protocol: _protocol,
            caller: msg.sender,
            collateral: _collateral,
            timestamp: _timestamp,
            amount: _amountToSell,
            limit: _minAmountToReturn
        }));
        (, IERC20 noclaimToken) = _getCovTokenAddresses(_protocol, _collateral, _timestamp);
        uint256 amountDaiNeeded = _calcInGivenOut(_bpool, address(dai), address(noclaimToken), _amountToSell);
        require(amountDaiNeeded <= flashLender.maxFlashAmount(address(dai)), "_amount > lender reserves");
        uint256 _allowance = dai.allowance(address(this), address(flashLender));
        uint256 _fee = flashLender.flashFee(address(dai), amountDaiNeeded);
        uint256 _repayment = amountDaiNeeded + _fee;
        dai.approve(address(flashLender), _allowance + _repayment);
        flashLender.flashLoan(address(this), address(dai), amountDaiNeeded, data);
    }

    function setFlashLender(address _flashLender) external override onlyOwner {
        require(_flashLender != address(0), "_flashLender is 0");
        flashLender = IERC3156FlashLender(_flashLender);
    }

    /// @notice Tokens that are accidentally sent to this contract can be recovered
    function collect(IERC20 _token) external override onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "_token balance is 0");
        _token.transfer(msg.sender, balance);
    }

    function getBuyClaimCost(
        IBPool _bpool, 
        IProtocol _protocol, 
        address _collateral, 
        uint48 _timestamp, 
        uint256 _amountToBuy
    ) external override view onlySupportedCollaterals(_collateral) returns (uint256 totalCost) {
        uint256 amountDaiNeeded = _amountToBuy;
        if (_collateral == address(ydai)) {
            amountDaiNeeded = amountDaiNeeded * ydai.getPricePerFullShare();
        }
        uint256 flashFee = flashLender.flashFee(address(dai), amountDaiNeeded);
        uint256 daiReceivedFromSwap;
        {
            (, IERC20 noclaimToken) = _getCovTokenAddresses(_protocol, _collateral, _timestamp);
            daiReceivedFromSwap = _calcOutGivenIn(_bpool, address(noclaimToken), _amountToBuy, address(dai));
        }
        totalCost = amountDaiNeeded - daiReceivedFromSwap + flashFee;
    }

    function getSellClaimReturn(
        IBPool _bpool, 
        IProtocol _protocol, 
        address _collateral, 
        uint48 _timestamp, 
        uint256 _amountToSell,
        uint256 _redeemFeeNumerator
    ) external override view onlySupportedCollaterals(_collateral) returns (uint256 totalReturn) {
        (, IERC20 noclaimToken) = _getCovTokenAddresses(_protocol, _collateral, _timestamp);
        uint256 amountDaiNeeded = _calcInGivenOut(_bpool, address(dai), address(noclaimToken), _amountToSell);
        uint256 flashFee = flashLender.flashFee(address(dai), amountDaiNeeded);
        uint256 daiReceivedFromRedeem;
        if (_collateral == address(dai)) {
            daiReceivedFromRedeem = _amountToSell;
        } else if (_collateral == address(ydai)) {
            // Adjust for price of yDAI
            daiReceivedFromRedeem = _amountToSell * ydai.getPricePerFullShare();
        }
        // Adjust for redemption fee
        daiReceivedFromRedeem = daiReceivedFromRedeem * (10000 - _redeemFeeNumerator) / 10000;
        totalReturn = daiReceivedFromRedeem - amountDaiNeeded - flashFee;
    }

    /**
     * - If collateral is yDAI, wrap borrowed DAI
     * - Deposit collateral for covTokens
     * - Sell NOCLAIM tokens on Balancer to receive DAI
     * - Calculate amount user needs to pay to repay loan + slippage + fee
     * - Send minted CLAIM tokens to user
     */
    function _onFlashLoanBuyClaim(FlashLoanData memory data, uint256 amount, uint256 amountOwed) internal {
        uint256 mintAmount;

        // Wrap DAI to yDAI if necessary
        if (data.collateral == address(dai)) {
            mintAmount = amount;
            _approve(dai, address(data.protocol), mintAmount);
        } else if (data.collateral == address(ydai)) {
            _approve(dai, address(ydai), amount);
            uint256 ydaiBalBefore = ydai.balanceOf(address(this));
            ydai.deposit(amount);
            mintAmount = ydai.balanceOf(address(this)) - ydaiBalBefore;
            _approve(ydai, address(data.protocol), mintAmount);
        }

        // Mint claim and NOCLAIM tokens using collateral
        data.protocol.addCover(data.collateral, data.timestamp, mintAmount);
        (IERC20 claimToken, IERC20 noclaimToken) = _getCovTokenAddresses(
            data.protocol, 
            data.collateral, 
            data.timestamp
        );

        // Swap exact number of NOCLAIM tokens for DAI on Balancer
        _approve(noclaimToken, address(data.bpool), mintAmount);
        (uint256 daiReceived, ) = data.bpool.swapExactAmountIn(
            address(noclaimToken),
            mintAmount,
            address(dai),
            0,
            type(uint256).max
        );
        // Make sure cost is not greater than limit
        require(amountOwed - daiReceived <= data.limit, "cost exceeds limit");
        // User pays for slippage + flash loan fee
        dai.transferFrom(data.caller, address(this), amountOwed - daiReceived);
        // Resolve the flash loan
        dai.transfer(msg.sender, amountOwed);
        // Transfer claim tokens to caller
        claimToken.transfer(data.caller, mintAmount);
    }

    /**
     * - Sell DAI for NOCLAIM tokens
     * - Transfer CLAIM tokens from user to this contract
     * - Redeem CLAIM and NOCLAIM tokens for collateral
     * - If collateral is yDAI, unwrap to DAI
     * - Calculate amount user needs to repay loan + slippage + fee
     * - Send leftover DAI to user
     */
    function _onFlashLoanSellClaim(FlashLoanData memory data, uint256 amount, uint256 amountOwed) internal {
        uint256 daiAvailable = amount;
        _approve(dai, address(data.bpool), amount);
        (IERC20 claimToken, IERC20 noclaimToken) = _getCovTokenAddresses(
            data.protocol, 
            data.collateral, 
            data.timestamp
        );
        // Swap DAI for exact number of NOCLAIM tokens
        (uint256 daiSpent, ) = data.bpool.swapExactAmountOut(
            address(dai),
            amount,
            address(noclaimToken),
            data.amount,
            type(uint256).max
        );
        daiAvailable = daiAvailable - daiSpent;
        // Need an equal number of CLAIM and NOCLAIM tokens
        claimToken.transferFrom(data.caller, address(this), data.amount);
        
        // Redeem CLAIM and NOCLAIM tokens for collateral
        uint256 collateralBalBefore = IERC20(data.collateral).balanceOf(address(this));
        address cover = data.protocol.coverMap(data.collateral, data.timestamp);
        ICover(cover).redeemCollateral(data.amount);
        uint256 collateralReceived = IERC20(data.collateral).balanceOf(address(this)) - collateralBalBefore;
        // Unwrap yDAI to DAI if necessary
        if (data.collateral == address(dai)) {
            daiAvailable = daiAvailable + collateralReceived;
        } else if (data.collateral == address(ydai)) {
            _approve(ydai, address(ydai), collateralReceived);
            uint256 daiBalBefore = dai.balanceOf(address(this));
            ydai.withdraw(collateralReceived);
            uint256 daiReceived = dai.balanceOf(address(this)) - daiBalBefore;
            daiAvailable = daiAvailable + daiReceived;
        }
        // Make sure return is not less than limit
        require(daiAvailable - amountOwed >= data.limit, "returns are less than limit");
        // Resolve the flash loan
        dai.transfer(msg.sender, amountOwed);
        // Transfer leftover DAI to caller
        dai.transfer(data.caller, daiAvailable - amountOwed);
    }

    function _calcInGivenOut(IBPool _bpool, address _tokenIn, address _tokenOut, uint256 _tokenAmountOut) internal view returns (uint256 tokenAmountIn) {
        uint256 tokenBalanceIn = _bpool.getBalance(_tokenIn);
        uint256 tokenWeightIn = _bpool.getNormalizedWeight(_tokenIn);
        uint256 tokenBalanceOut = _bpool.getBalance(_tokenOut);
        uint256 tokenWeightOut = _bpool.getNormalizedWeight(_tokenOut);
        uint256 swapFee = _bpool.getSwapFee();

        tokenAmountIn = _bpool.calcInGivenOut(
            tokenBalanceIn,
            tokenWeightIn,
            tokenBalanceOut,
            tokenWeightOut,
            _tokenAmountOut,
            swapFee
        );
    }

    function _calcOutGivenIn(IBPool _bpool, address _tokenIn, uint256 _tokenAmountIn, address _tokenOut) internal view returns (uint256 tokenAmountOut) {
        uint256 tokenBalanceIn = _bpool.getBalance(_tokenIn);
        uint256 tokenWeightIn = _bpool.getNormalizedWeight(_tokenIn);
        uint256 tokenBalanceOut = _bpool.getBalance(_tokenOut);
        uint256 tokenWeightOut = _bpool.getNormalizedWeight(_tokenOut);
        uint256 swapFee = _bpool.getSwapFee();

        tokenAmountOut = _bpool.calcOutGivenIn(
            tokenBalanceIn,
            tokenWeightIn,
            tokenBalanceOut,
            tokenWeightOut,
            _tokenAmountIn,
            swapFee
        );
    } 

    function _getCovTokenAddresses(
        IProtocol _protocol, 
        address _collateral, 
        uint48 _timestamp
    ) internal view returns (IERC20 claimToken, IERC20 noclaimToken) {
        address cover = _protocol.coverMap(_collateral, _timestamp);
        claimToken = ICover(cover).claimCovToken();
        noclaimToken = ICover(cover).noclaimCovToken();
    }

    function _approve(IERC20 _token, address _spender, uint256 _amount) internal {
        if (_token.allowance(address(this), _spender) < _amount) {
            _token.approve(_spender, type(uint256).max);
        }
    }
}