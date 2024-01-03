pragma solidity >=0.6.6;

import "./IxEXCV.sol";
import "./IERC20.sol";
import "./IEXCV.sol";
import "./IExcavoFactory.sol";
import "./IExcavoPair.sol";
import "./ExcavoLibrary.sol";
import "./Math.sol";
import "./ReentrancyGuard.sol";

contract xEXCV is IxEXCV, IERC20, ReentrancyGuard {
    // each time user adds liquidity to EXCV generating pairs, add active pair address
    // each time user removes liquidity to EXCV generating pairs, remove active pair address
    using SafeMath for uint;

    event Redeem(address indexed sender, address indexed recipient, uint amount);

    uint constant MIN_LIQUIDITY_PAIR_COUNT = 3;
    
    address public immutable override getEXCV;
    address public override factory;
    address public override excvEthPair;
    address[] private _liquidityPairs;

    string public constant override symbol = "xEXCV";
    string public constant override name = "xEXCV";
    uint8 public constant override decimals = 18; 

    constructor() public {
        getEXCV = msg.sender;
    }

    function initialize(address _factory) external override nonReentrant {
        require(msg.sender == getEXCV && factory == address(0) && excvEthPair == address(0), "xEXCV: FORBIDDEN");
        factory = _factory;
        address WETH = IExcavoFactory(_factory).WETHToken();
        excvEthPair = ExcavoLibrary.pairFor(_factory, getEXCV, WETH);
    }

    function addPair(address tokenA, address tokenB) external override nonReentrant {
        require(ExcavoLibrary.pairFor(factory, tokenA, tokenB) == msg.sender, "xEXCV: FORBIDDEN");
        if (!_pairExists(msg.sender)) {
            _liquidityPairs.push(msg.sender);
        }
    }

    function redeem(address recipient) external override nonReentrant {
        address[] memory pairs = _liquidityPairs;
        uint _circulatingSupply = circulatingSupply();
        uint excvQuantity;
        for (uint i = 0; i < pairs.length; i++) {
            uint lastK = IExcavoPair(pairs[i]).totalSupply();
            uint claimedLiquidity = IExcavoPair(pairs[i]).claimAllLiquidity(msg.sender);
            excvQuantity = excvQuantity.add(claimedLiquidity.mul(_circulatingSupply).div(lastK));
        }
        IEXCV(getEXCV).mint(recipient, excvQuantity);
        emit Redeem(msg.sender, recipient, excvQuantity);
    }

    function redeemPair(address recipient, address pair, uint claimedLiquidityAmount) external override nonReentrant {
        require(_pairExists(pair), "xEXCV: unknown pair");

        uint _circulatingSupply = circulatingSupply();
        uint lastK = IExcavoPair(pair).totalSupply();
        IExcavoPair(pair).claimLiquidity(msg.sender, claimedLiquidityAmount);
        uint excvQuantity = claimedLiquidityAmount.mul(_circulatingSupply).div(lastK);

        IEXCV(getEXCV).mint(recipient, excvQuantity);
        emit Redeem(msg.sender, recipient, excvQuantity);
    }

    function totalSupply() external view override returns (uint) {
        return IERC20(getEXCV).totalSupply();
    }

    function balanceOf(address owner) external view override returns (uint) {
        address[] memory pairs = _liquidityPairs;
        uint _circulatingSupply = circulatingSupply();
        uint excvQuantity;
        for (uint i = 0; i < pairs.length; i++) {
            uint accumulatedLiquidity = IExcavoPair(pairs[i]).unclaimedLiquidityOf(owner);
            uint lastK = IExcavoPair(pairs[i]).totalSupply();
            excvQuantity = excvQuantity.add(accumulatedLiquidity.mul(_circulatingSupply).div(lastK));
        }
        return excvQuantity;
    }

    function liquidityPairs() external view override returns (address[] memory) {
        return _liquidityPairs;
    }

    function pairBalanceOf(address owner, address pair) external view override returns (uint) {
        if (!_pairExists(pair)) {
            return 0;
        }
        uint lastK = IExcavoPair(pair).totalSupply();
        if (lastK == 0) {
            return 0;
        }
        uint _circulatingSupply = circulatingSupply();
        uint accumulatedLiquidity = IExcavoPair(pair).unclaimedLiquidityOf(owner);
        return accumulatedLiquidity.mul(_circulatingSupply) / lastK;
    }

    function circulatingSupply() private view returns (uint) {
        (uint reserve0, uint reserve1, ) = IExcavoPair(excvEthPair).getReserves();
        return IExcavoPair(excvEthPair).token0() == getEXCV ? reserve0 : reserve1;
    }

    function _pairExists(address pair) private view returns (bool) {
        address[] memory pairs = _liquidityPairs;
        for (uint i = 0; i < pairs.length; ++i) {
            if (pairs[i] == pair) {
                return true;
            }
        }
        return false;
    }

    function allowance(address /*owner*/, address /*spender*/) external view override returns (uint) {
        revert("xEXCV: FORBIDDEN");
    }

    function approve(address /*spender*/, uint /*value*/) external override returns (bool) {
        revert("xEXCV: FORBIDDEN");
    }

    function transfer(address /*to*/, uint /*value*/) external override returns (bool) {
        revert("xEXCV: FORBIDDEN");
    }

    function transferFrom(address /*from*/, address /*to*/, uint /*value*/) external override returns (bool) {
        revert("xEXCV: FORBIDDEN");
    }
}