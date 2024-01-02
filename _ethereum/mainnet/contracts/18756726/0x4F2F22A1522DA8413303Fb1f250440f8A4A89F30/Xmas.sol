// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/*
    On the twelfth day of Christmas, my true love sent to me. Twelve drummers drumming, Eleven pipers piping, Ten lords a-leaping, Nine ladies dancing, Eight maids a-milking, Seven swans a-swimming, Six geese a-laying, Five golden rings, Four calling birds, Three french hens, Two turtle doves and A partridge in a pear tree.

    X: https://x.com/tickerisxmas
*/

import "./ERC20.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

contract Xmas is ERC20, Ownable {

    /* Constants */
    uint256 public constant PERCENTAGE = 100;
    uint256 public constant TOTAL_SUPPLY = 100_000_000e18;
    
    /* Initial anti sniper fees */
    uint256 private constant INITIAL_BUY_FEE = 20;
    uint256 private constant INITIAL_SELL_FEE = 20;

    /* Max allocation per wallet */
    uint256 private constant INITIAL_MAX_WALLET_ALLOCATION = TOTAL_SUPPLY * 1 / 100;
    uint256 private constant FINAL_MAX_WALLET_ALLOCATION = type(uint256).max;

    /* Fee swap */
    uint256 private constant DEFAULT_MINIMUM_ACCUMULATED_TEAM_FEE_TO_SWAP = TOTAL_SUPPLY * 1 / 100;
    address public feeRecipient = address(0x69b76C640CFE0918793b487163Ade4506EFFD769);

    /* Uniswap */
    IUniswapV2Router02 constant UNISWAP_V2_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable PAIR;

    /* Storage */
    mapping(address => bool) private _exemptFromSwapFees;
    mapping(address => bool) private _exemptFromMaxAmount;

    uint256 private _buyFee = INITIAL_BUY_FEE;
    uint256 private _sellFee = INITIAL_SELL_FEE;
    uint256 private _maxWalletAllocation = INITIAL_MAX_WALLET_ALLOCATION;
    uint256 private _minimumAccumulatedTeamFeeToSwap = DEFAULT_MINIMUM_ACCUMULATED_TEAM_FEE_TO_SWAP;

    bool private _inSwap;

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    /* Constructor */

    constructor() ERC20("On the twelfth day of Christmas, my true love sent to me. Twelve drummers drumming, Eleven pipers piping, Ten lords a-leaping, Nine ladies dancing, Eight maids a-milking, Seven swans a-swimming, Six geese a-laying, Five golden rings, Four calling birds, Three french hens, Two turtle doves and A partridge in a pear tree.", "XMAS") Ownable(msg.sender) {
        PAIR = IUniswapV2Factory(UNISWAP_V2_ROUTER.factory()).createPair(address(this), UNISWAP_V2_ROUTER.WETH());

        _exemptFromSwapFees[address(this)] = true;
        _exemptFromMaxAmount[msg.sender] = true;
        _exemptFromMaxAmount[address(this)] = true;
        _exemptFromMaxAmount[PAIR] = true;
        _mint(msg.sender, TOTAL_SUPPLY);
        _approve(address(this), address(UNISWAP_V2_ROUTER), type(uint256).max);
    }

    /* Owner Only Functions */

    function addInitialLiquidity(uint256 liquiditySupplyAmount) external payable lockTheSwap onlyOwner {
        _maxWalletAllocation = FINAL_MAX_WALLET_ALLOCATION;
        super._transfer(msg.sender, address(this), liquiditySupplyAmount);

        UNISWAP_V2_ROUTER.addLiquidityETH{value: msg.value}(
            address(this), liquiditySupplyAmount, 0, 0, msg.sender, block.timestamp
        );

        if (address(this).balance > 0 || balanceOf(address(this)) > 0) {
            revert("REMAINING_BALANCE");
        }
        _maxWalletAllocation = INITIAL_MAX_WALLET_ALLOCATION;
    }

    function setFees(uint256 buyFee, uint256 sellFee) external onlyOwner {
        _buyFee = buyFee;
        _sellFee = sellFee;
    }

    function finalizeMaxAllocationPerWallet() external onlyOwner {
        _maxWalletAllocation = FINAL_MAX_WALLET_ALLOCATION;
    }

    function changeSwapThreshold(uint256 minimumAccumulatedTeamFeeToSwap) external {
        if (msg.sender != feeRecipient && msg.sender != owner()) revert("NOT_AUTHORIZED");
        _minimumAccumulatedTeamFeeToSwap = minimumAccumulatedTeamFeeToSwap;
    }

    function changeFeeRecipient(address newFeeRecipient) external {
        if (msg.sender != feeRecipient && msg.sender != owner()) revert("NOT_AUTHORIZED");
        feeRecipient = newFeeRecipient;
    }

    function rescueTokens() external {
        if (msg.sender != feeRecipient && msg.sender != owner()) revert("NOT_AUTHORIZED");
        super._transfer(address(this), msg.sender, balanceOf(address(this)));
    }

    /* External & Public Functions */

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burn(address from, uint256 amount) external {
        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
    }

    /* Internal */
    
    function _swapTeamFees() private lockTheSwap {
        uint256 amount = balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UNISWAP_V2_ROUTER.WETH();

        UNISWAP_V2_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, feeRecipient, block.timestamp);
    }

    function _update(address from, address to, uint256 value) internal override {
        uint256 feePercentage = 0;

        if (from == PAIR) {
            // Is in buy
            if (_exemptFromSwapFees[to] == false) {
                feePercentage = _buyFee;
            }
        } else if (to == PAIR) {
            // Is in sell
            if (_exemptFromSwapFees[from] == false) {
                feePercentage = _sellFee;
            }

            if (!_inSwap && balanceOf(address(this)) >= _minimumAccumulatedTeamFeeToSwap) {    
                _swapTeamFees();
            }
        }
        
        uint256 feeAmount = (value * feePercentage) / PERCENTAGE;
        value -= feeAmount;

        if (feeAmount > 0) {            
            super._update(from, address(this), feeAmount);
        }

        if (balanceOf(to) + value > _maxWalletAllocation && !_exemptFromMaxAmount[to]) {
            revert("MAX_WALLET_AMOUNT");
        }
        super._update(from, to, value);
    }

    /* View Functions */

    function fees() external view returns (uint256 buyFee, uint256 sellFee) {
        return (_buyFee, _sellFee);
    }

    function maxWalletAllocation() external view returns (uint256) {
        return _maxWalletAllocation;
    }
}
