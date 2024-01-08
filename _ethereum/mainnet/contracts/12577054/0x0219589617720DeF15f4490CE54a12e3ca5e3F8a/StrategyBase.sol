// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./ReceiptToken.sol";
import "./IUniswapRouter.sol";
import "./Storage.sol";

contract StrategyBase is Storage, Initializable, UUPSUpgradeable, OwnableUpgradeable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    /// @notice Event emitted when user makes a deposit and receipt token is minted
    event ReceiptMinted(address indexed user, uint256 amount);
    /// @notice Event emitted when user withdraws and receipt token is burned
    event ReceiptBurned(address indexed user, uint256 amount);

    /**
     * @notice Create a new strategy contract
     * @param _sushiswapRouter Sushiswap Router address
     * @param _token Token address
     * @param _weth WETH address
     * @param _treasuryAddress treasury address
     * @param _feeAddress fee address
     */
    function __StrategyBase_init(
      address _sushiswapRouter, address _token,
      address _weth,
      address payable _treasuryAddress,
      address payable _feeAddress,
      uint256 _cap) internal initializer {
        require(_sushiswapRouter != address(0), "ROUTER_0x0");
        require(_token != address(0), "TOKEN_0x0");
        require(_weth != address(0), "WETH_0x0");
        require(_treasuryAddress != address(0), "TREASURY_0x0");
        require(_feeAddress != address(0), "FEE_0x0");
        sushiswapRouter = IUniswapRouter(_sushiswapRouter);
        token = _token;
        weth = _weth;
        treasuryAddress = _treasuryAddress;
        feeAddress = _feeAddress;
        cap = _cap;
        _minSlippage = 10; //0.1%
        lockTime = 1;
        fee = uint256(100);
        __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {

    }


    function _validateCommon(
        uint256 deadline,
        uint256 amount,
        uint256 _slippage
    ) internal view {
        require(deadline >= block.timestamp, "DEADLINE_ERROR");
        require(amount > 0, "AMOUNT_0");
        require(_slippage >= _minSlippage, "SLIPPAGE_ERROR");
        require(_slippage <= feeFactor, "MAX_SLIPPAGE_ERROR");
    }

    function _validateDeposit(
        uint256 deadline,
        uint256 amount,
        uint256 total,
        uint256 slippage
    ) internal view {
        _validateCommon(deadline, amount, slippage);

        require(total.add(amount) <= cap, "CAP_REACHED");
    }

    function _mintParachainAuctionTokens(uint256 _amount) internal {
        receiptToken.mint(msg.sender, _amount);
        emit ReceiptMinted(msg.sender, _amount);
    }

    function _burnParachainAuctionTokens(uint256 _amount) internal {
        receiptToken.burn(msg.sender, _amount);
        emit ReceiptBurned(msg.sender, _amount);
    }

    function _calculateFee(uint256 _amount) internal view returns (uint256) {
        return _calculatePortion(_amount, fee);
    }

    function _getBalance(address _token) internal view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function _increaseAllowance(
        address _token,
        address _contract,
        uint256 _amount
    ) internal {
        IERC20(_token).safeIncreaseAllowance(address(_contract), _amount);
    }

    function _getRatio(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) internal pure returns (uint256) {
        if (numerator == 0 || denominator == 0) {
            return 0;
        }
        uint256 _numerator = numerator * 10**(precision + 1);
        uint256 _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    function _swapTokenToEth(
        address[] memory swapPath,
        uint256 exchangeAmount,
        uint256 deadline,
        uint256 slippage,
        uint256 ethPerToken
    ) internal returns (uint256) {
        uint256[] memory amounts =
            sushiswapRouter.getAmountsOut(exchangeAmount, swapPath);
        uint256 sushiAmount = amounts[amounts.length - 1]; //amount of ETH
        uint256 portion = _calculatePortion(sushiAmount, slippage);
        uint256 calculatedPrice = (exchangeAmount.mul(ethPerToken)).div(10**18);
        uint256 decimals = ERC20(swapPath[0]).decimals();
        if (decimals < 18) {
            calculatedPrice = calculatedPrice.mul(10**(18 - decimals));
        }
        if (sushiAmount > calculatedPrice) {
            require(
                sushiAmount.sub(calculatedPrice) <= portion,
                "PRICE_ERROR_1"
            );
        } else {
            require(
                calculatedPrice.sub(sushiAmount) <= portion,
                "PRICE_ERROR_2"
            );
        }

        _increaseAllowance(
            swapPath[0],
            address(sushiswapRouter),
            exchangeAmount
        );
        uint256[] memory tokenSwapAmounts =
            sushiswapRouter.swapExactTokensForETH(
                exchangeAmount,
                _getMinAmount(sushiAmount, slippage),
                swapPath,
                address(this),
                deadline
            );
        return tokenSwapAmounts[tokenSwapAmounts.length - 1];
    }

    function _swapEthToToken(
        address[] memory swapPath,
        uint256 exchangeAmount,
        uint256 deadline,
        uint256 slippage,
        uint256 tokensPerEth
    ) internal returns (uint256) {
        uint256[] memory amounts =
            sushiswapRouter.getAmountsOut(exchangeAmount, swapPath);
        uint256 sushiAmount = amounts[amounts.length - 1];
        uint256 portion = _calculatePortion(sushiAmount, slippage);
        uint256 calculatedPrice =
            (exchangeAmount.mul(tokensPerEth)).div(10**18);
        uint256 decimals = ERC20(swapPath[0]).decimals();
        if (decimals < 18) {
            calculatedPrice = calculatedPrice.mul(10**(18 - decimals));
        }
        if (sushiAmount > calculatedPrice) {
            require(
                sushiAmount.sub(calculatedPrice) <= portion,
                "PRICE_ERROR_1"
            );
        } else {
            require(
                calculatedPrice.sub(sushiAmount) <= portion,
                "PRICE_ERROR_2"
            );
        }

        uint256[] memory swapResult =
            sushiswapRouter.swapExactETHForTokens{value: exchangeAmount}(
                _getMinAmount(sushiAmount, slippage),
                swapPath,
                address(this),
                deadline
            );

        return swapResult[swapResult.length - 1];
    }

    function _getMinAmount(uint256 amount, uint256 slippage)
        private
        pure
        returns (uint256)
    {
        uint256 portion = _calculatePortion(amount, slippage);
        return amount.sub(portion);
    }

    function _calculatePortion(uint256 _amount, uint256 _fee)
        private
        pure
        returns (uint256)
    {
        return (_amount.mul(_fee)).div(feeFactor);
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}
