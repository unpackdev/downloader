pragma solidity 0.7.5;

import "./Ownable.sol";
import "./ITollar.sol";
import "./IUniswapV2Pair.sol";
import "./UniswapV2Library.sol";
import "./SafeMath.sol";
import "./SafeMathInt.sol";
import "./UInt256Lib.sol";

/**
 * @dev Handles decentralized, autonomous, random rebasing on-chain.
 * @author Over1 Team
 */
contract TollarRebaser is Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using UInt256Lib for uint256;

    // Log rebase event
    event LogRebase(uint256 price, int256 delta, uint256 totalSupply);

    // Reference to Tollar ERC20 token contract
    ITollar public immutable tollar;

    // Uniswap V2 Pairs for DAI-TLR to calculate 
    IUniswapV2Pair public pairUSD;

    // Last rebase stats
    uint256 private _rebasePrice;
    int256 private _rebaseDelta;
    uint256 private _rebaseTotalSupply;

    // Price Target $1 USD inflation adjusted
    uint256 private _priceTarget;

    uint256 private constant TLR_DECIMALS = 9;
    uint256 private constant ETH_DECIMALS = 18;

    // Currently using DAI
    uint256 private constant USD_DECIMALS = 18;

    uint256 private constant PRICE_PRECISION = 10**9;

    uint256 private PRICE_THRESHOLD_DEVIATION = 5 * 10**16;

    uint256 private _priceThresholdMax = 105 * 10**16;
    uint256 private _priceThresholdMin = 95 * 10**16;

    constructor(ITollar _tollar) public Ownable() {
        tollar = _tollar;

        _priceTarget = 10**USD_DECIMALS;
        _priceThresholdMax = _priceTarget.add(PRICE_THRESHOLD_DEVIATION);
        _priceThresholdMin = _priceTarget.sub(PRICE_THRESHOLD_DEVIATION);
    }

    /**
     * @return return last rebase stats for automated reporting.
     */
    function getRebaseLastStats() external view returns (uint256, int256, uint256) {
        return (_rebasePrice, _rebaseDelta, _rebaseTotalSupply) ;
    }

    /**
     * @dev change Tollar owner address, to allow for Rebaser.sol.
     */
    function transferTollarOwner(address newOwner) external onlyOwner {
        tollar.transferOwnership(newOwner);
    }

    /**
     * @dev Add a transaction that gets called for a downstream receiver of rebases.
     */
    function addTollarTransaction(address destination, bytes memory data) external onlyOwner {
        tollar.addTransaction(destination, data);
    }

    /**
     * @dev Remove tollar transaction
     */
    function removeTransaction(uint index) external onlyOwner {
        tollar.removeTransaction(index);
    }

    /**
     * @dev set price target.
     */
    function setPriceTarget(uint256 priceTarget) external onlyOwner {
        _priceTarget = priceTarget;

        _priceThresholdMax = _priceTarget.add(PRICE_THRESHOLD_DEVIATION);
        _priceThresholdMin = _priceTarget.sub(PRICE_THRESHOLD_DEVIATION);
    }

    /**
     * @dev set Uniswap V2 pair DAI-TLR.
     */
    function setPairUSD(address factory, address token0, address token1) external onlyOwner {
        pairUSD = IUniswapV2Pair(UniswapV2Library.pairFor(factory, token0, token1));
    }

    /**
     * @dev Main rebase function.
     */
    function rebase() external onlyOwner returns (int256) {
        require(address(pairUSD) != address(0));

        int256 supplyDelta = 0;
        uint256 price = getPriceTLR_USD();

        if (price < _priceThresholdMin || price > _priceThresholdMax) {
            uint256 totalSupply = tollar.totalSupply();

            // Calcluate new supply delta
            supplyDelta = totalSupply.toInt256Safe().mul(price.toInt256Safe().sub(_priceTarget.toInt256Safe())).div(_priceTarget.toInt256Safe());

            // Rebase Tollar token
            uint256 totalSupplyNew = tollar.rebase(supplyDelta);

            _rebasePrice = price;
            _rebaseDelta = supplyDelta;
            _rebaseTotalSupply = totalSupplyNew;

            emit LogRebase(_rebasePrice, _rebaseDelta, _rebaseTotalSupply);
        }
        return supplyDelta;
    }

    function getPriceTLR_USD() internal view returns (uint256) {

        require(address(pairUSD) != address(0));

        address token0 = pairUSD.token0();
        (uint reserve0, uint reserve1,) = pairUSD.getReserves();
        (uint reserveDAI, uint reserveTLR) = address(tollar) != token0 ? (reserve0, reserve1) : (reserve1, reserve0);

        uint256 price = reserveDAI.mul(PRICE_PRECISION).div(reserveTLR);

        return price;
    }
}
