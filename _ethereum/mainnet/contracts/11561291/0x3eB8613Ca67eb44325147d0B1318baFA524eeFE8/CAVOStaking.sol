pragma solidity >=0.6.6;

import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./ExcavoLibrary.sol";
import "./ICAVO.sol";
import "./IxCAVO.sol";
import "./IEXCV.sol";
import "./IWETH.sol";
import "./IExcavoFactory.sol";
import "./IExcavoRouter.sol";
import "./IExcavoERC20.sol";
import "./IExcavoPair.sol";
import "./ICAVOStaking.sol";

contract CAVOStaking is ICAVOStaking, ReentrancyGuard {
    using SafeMath for uint;

    string public constant override name = 'xCAVO';
    string public constant override symbol = 'xCAVO';
    uint8 public constant override decimals = 18;
    
    mapping(address => mapping(address => uint)) public override allowance;
    mapping(address => uint) public override liquidityOf;

    address private WETH;
    address private xCAVO;
    address private CAVO;
    address private EXCV;
    address private router;
    address private factory;
    address private creator;
    address private excvEthPair;

    uint constant private BASE = 10**18;
    uint private accumulatedKGrowthOverTotalSupplyInBase; 
    uint private accumulatedKGrowth;
    uint private lastTotalK; 
    mapping(address => uint) private lastAccumulatedKGrowthOverTotalSupplyInBase;
    mapping(address => uint) private lastAccumulatedKGrowth;
    mapping(address => uint) private lastAccumulatedMintableCAVOAmount;
    mapping(address => uint) private _unclaimedOf;

    event Redeem(address indexed sender, address indexed recipient, uint amount);
    event Stake(address indexed sender, uint liquidity);
    event Unstake(address indexed sender, uint liquidity);

    constructor(address _router) public {
        CAVO = IExcavoRouter(_router).CAVO();
        require(ICAVO(CAVO).creator() == msg.sender, 'EXCAVO: FORBIDDEN');
        router = _router;
        factory = IExcavoRouter(_router).factory();
        WETH = IExcavoRouter(_router).WETH();
        xCAVO = ICAVO(CAVO).xCAVOToken();
        EXCV = ICAVO(CAVO).EXCVToken();
        creator = msg.sender;
        excvEthPair = ExcavoLibrary.pairFor(factory, EXCV, WETH);
        IExcavoERC20(EXCV).approve(_router, uint(-1));
        address excvEthPairCheck = IExcavoFactory(factory).getPair(EXCV, WETH);
        if (excvEthPairCheck == address(0)) {
            excvEthPairCheck = IExcavoFactory(factory).createPair(WETH, EXCV);
        }
        require(excvEthPair == excvEthPairCheck, 'EXCAVO: INVALID');
        IExcavoERC20(excvEthPair).approve(_router, uint(-1));
    }

    function approve(address spender, uint value) external override returns (bool) {
        revert('CAVO: FORBIDDEN');
    }

    function transfer(address to, uint value) external override returns (bool) {
        revert('CAVO: FORBIDDEN');
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        revert('CAVO: FORBIDDEN');
    }

    function totalSupply() public view override returns (uint) {
        return IExcavoERC20(CAVO).balanceOf(address(this));
    }

    function emergencyWithdraw() external override nonReentrant {
        require(msg.sender == creator, 'CAVO: FORBIDDEN');
        TransferHelper.safeTransfer(CAVO, creator, IExcavoERC20(CAVO).balanceOf(address(this)));
    }
    
    function stakeLiquidityETH(
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        uint deadline
    ) external override payable ensure(deadline) nonReentrant returns (uint amountToken, uint amountETH, uint liquidity) {
        _accumulateK(msg.sender);
        
        (amountToken, amountETH) = _addLiquidity(
            EXCV,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = ExcavoLibrary.pairFor(factory, EXCV, WETH);
        TransferHelper.safeTransferFrom(EXCV, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IExcavoPair(pair).mint(address(this));
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);

        liquidityOf[msg.sender] = liquidityOf[msg.sender].add(liquidity);
        _update(msg.sender);

        emit Stake(msg.sender, liquidity);
    }

    function unstakeLiquidityETH(
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external override nonReentrant {
        _accumulateK(msg.sender);
        
        liquidityOf[msg.sender] = liquidityOf[msg.sender].sub(liquidity);
        
        IExcavoRouter(router).removeLiquidityETH(
            EXCV,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );

        _update(msg.sender);

        emit Unstake(msg.sender, liquidity);
    }

    function redeem(address to) external override nonReentrant {
        (uint newK, uint newTotalK, uint unclaimed) = _accumulateK(msg.sender);
        _update(msg.sender);
        uint amount = balanceOf(to);
        require(amount > 0, 'CAVO: INSUFFICIENT_AMOUNT');
        _unclaimedOf[msg.sender] = 0;
        TransferHelper.safeTransfer(CAVO, to, amount);
        
        emit Redeem(msg.sender, to, amount);
    }

    function balanceOf(address account) public view override returns (uint) {
        (,, uint unclaimed) = unclaimedOf(account);
        return Math.min(unclaimed, totalSupply());
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IExcavoFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IExcavoFactory(factory).createPair(tokenA, tokenB);
        }

        (uint reserveA, uint reserveB) = ExcavoLibrary.getReserves(factory, tokenA, tokenB);

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = ExcavoLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'ExcavoRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = ExcavoLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'ExcavoRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function unclaimedOf(address account) public view override returns (uint kGrowthOverTotalSupplyInBase, uint kGrowth, uint unclaimed) {
        uint totalLiquidity = IExcavoPair(excvEthPair).balanceOf(address(this));
        if (totalLiquidity == 0) {
            return (0, 0, _unclaimedOf[account]);
        }
        uint newTotalK = _getK(); // can be zero
        if (newTotalK > lastTotalK) {
            kGrowth = newTotalK - lastTotalK;
            kGrowthOverTotalSupplyInBase = kGrowth.mul(BASE) / totalLiquidity;
        }
        uint newUnclaimed = _calculateNewUnclaimed(account, kGrowthOverTotalSupplyInBase, kGrowth);
        unclaimed = _unclaimedOf[account].add(newUnclaimed);
    }

    function _calculateNewUnclaimed(address account, uint kGrowthOverTotalSupplyInBase, uint kGrowth) private view returns (uint newUnclaimed) {
        uint totalKGrowth = (accumulatedKGrowth + kGrowth) - lastAccumulatedKGrowth[account];
        if (totalKGrowth > 0) {
            uint newCAVO = (IxCAVO(xCAVO).accumulatedMintableCAVOAmount() - lastAccumulatedMintableCAVOAmount[account]) / 200;  
            uint newKGrowthInBase = ((accumulatedKGrowthOverTotalSupplyInBase + kGrowthOverTotalSupplyInBase) - lastAccumulatedKGrowthOverTotalSupplyInBase[account]);
            uint userKGrowthInBase = liquidityOf[account].mul(newKGrowthInBase);
            newUnclaimed = (userKGrowthInBase.mul(newCAVO) / BASE) / totalKGrowth;
        }
    }

    function _accumulateK(address account) private returns (uint kGrowthOverTotalSupplyInBase, uint kGrowth, uint unclaimed) {
        (kGrowthOverTotalSupplyInBase, kGrowth, unclaimed) = unclaimedOf(account);
        if (kGrowthOverTotalSupplyInBase > 0) {
            accumulatedKGrowthOverTotalSupplyInBase += kGrowthOverTotalSupplyInBase; // overflow desired
            accumulatedKGrowth += kGrowth;
        }
        if (unclaimed > _unclaimedOf[account]) {
            _unclaimedOf[account] = unclaimed;
        }
    }

    function _getK() private view returns (uint k) {
        uint totalSupply = IExcavoPair(excvEthPair).totalSupply();
        if (totalSupply > 0) {
            uint stakedLiquidity = IExcavoPair(excvEthPair).balanceOf(address(this));
            (uint _reserve0, uint _reserve1,) = IExcavoPair(excvEthPair).getReserves();
            uint amount0 = stakedLiquidity.mul(_reserve0) / totalSupply;
            uint amount1 = stakedLiquidity.mul(_reserve1) / totalSupply;
            k = Math.sqrt(amount0.mul(amount1)); 
        }
    }

    function _update(address account) private {
        lastTotalK = _getK(); // can be zero
        lastAccumulatedMintableCAVOAmount[account] = IxCAVO(xCAVO).accumulatedMintableCAVOAmount();
        lastAccumulatedKGrowthOverTotalSupplyInBase[account] = accumulatedKGrowthOverTotalSupplyInBase;
        lastAccumulatedKGrowth[account] = accumulatedKGrowth;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'ExcavoRouter: EXPIRED');
        _;
    }
}