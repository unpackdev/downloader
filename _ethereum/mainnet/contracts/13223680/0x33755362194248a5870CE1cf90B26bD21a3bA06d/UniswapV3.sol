//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./LiquidityAmounts.sol";
import "./TickMath.sol";

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }
    function mint(
        MintParams memory params
    ) external returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }
    function increaseLiquidity(
        IncreaseLiquidityParams memory params
    ) external returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }
    function decreaseLiquidity(
        DecreaseLiquidityParams memory params
    ) external returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }
    function collect(
        CollectParams memory params
    ) external returns (uint256 amount0, uint256 amount1);

    function positions(uint256 tokenId) external view returns (
        uint96 nonce, address operator, address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper,
        uint128 liquidity, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, uint128 tokensOwed0, uint128 tokensOwed1
    );
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(
        ExactInputSingleParams memory params
    ) external returns (uint256 amountOut);
}

interface IUniswapV3Pool {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
    function tickSpacing() external view returns (int24);
    function slot0() external view returns (uint160, int24, uint16, uint16, uint16, uint8, bool);
}

interface IChainlink {
    function latestAnswer() external view returns (int256);
}

interface IWETH is IERC20Upgradeable {
    function withdraw(uint amount) external;
}

contract UniswapV3 is Initializable, ERC20Upgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IWETH;

    IUniswapV3Pool public uniswapV3Pool;
    IERC20Upgradeable public token0;
    IERC20Upgradeable public token1;
    IWETH constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); 

    INonfungiblePositionManager constant nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    ISwapRouter constant router  = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    uint public depositFeePerc;
    uint public yieldFeePerc;
    uint public vaultPositionTokenId;

    uint24 public poolFee;
    int24 public lowerTick;
    int24 public upperTick;

    address public admin;
    address public treasuryWallet;
    address public communityWallet;
    address public strategist;

    mapping(address => bool) public isWhitelisted;
    mapping(address => uint) private depositedBlock;

    event Deposit(address indexed caller, uint amt0Deposited, uint amt1Deposited, uint sharesMinted);
    event Withdraw(address indexed caller, uint amt0Withdrawed, uint amt1Withdrawed, uint sharesBurned);
    event Yield(uint amount);
    event EmergencyWithdraw(uint amtToken0Withdrawed, uint amtToken1Withdrawed);
    event Reinvest(uint amount0, uint amount1);
    event AddLiquidity(uint amount0, uint amount1, uint liquidity);
    event DecreaseLiquidity(uint amount0, uint amount1, uint liquidity);
    event Collect(uint amount0, uint amount1);
    event SetWhitelistAddress(address indexed _address, bool indexed status);
    event SetFee(uint _yieldFeePerc, uint _depositFeePerc);
    event SetTreasuryWallet(address indexed treasuryWallet);
    event SetCommunityWallet(address indexed communityWallet);
    event SetStrategistWallet(address indexed strategistWallet);
    event SetAdmin(address indexed admin);

    modifier onlyOwnerOrAdmin {
        require(msg.sender == owner() || msg.sender == address(admin), "Only owner or admin");
        _;
    }

    function initialize(
        string calldata name, string calldata symbol, IUniswapV3Pool _uniswapV3Pool,
        address _treasuryWallet, address _communityWallet, address _strategist, address _admin
    ) external initializer {
        __ERC20_init(name, symbol);
        __Ownable_init();

        uniswapV3Pool = _uniswapV3Pool;
        token0 = IERC20Upgradeable(_uniswapV3Pool.token0());
        token1 = IERC20Upgradeable(_uniswapV3Pool.token1());
        poolFee = _uniswapV3Pool.fee();
        int24 tickspacing = _uniswapV3Pool.tickSpacing();
        lowerTick = (-887272 / tickspacing) * tickspacing; // Min tick
        upperTick = (887272 / tickspacing) * tickspacing; // Max tick

        depositFeePerc = 1000;
        yieldFeePerc = 2000;

        admin = _admin;
        treasuryWallet = _treasuryWallet;
        communityWallet = _communityWallet;
        strategist = _strategist;

        IERC20Upgradeable(token0).approve( address(nonfungiblePositionManager), type(uint).max);
        IERC20Upgradeable(token1).approve( address(nonfungiblePositionManager), type(uint).max);
        token0.approve(address(router), type(uint).max);
        token1.approve(address(router), type(uint).max);
    }

    function deposit(uint amount0, uint amount1) external nonReentrant whenNotPaused {
        require(amount0 > 0 && amount1 > 0, "Amount < 0");
        uint amt0Deposit = amount0;
        uint amt1Deposit = amount1;

        token0.safeTransferFrom(msg.sender, address(this), amount0);
        token1.safeTransferFrom(msg.sender, address(this), amount1);
        depositedBlock[msg.sender] = block.number;

        if (!isWhitelisted[msg.sender]) {
            uint fee0 = amount0 * depositFeePerc / 10000;
            amount0 = amount0 - fee0;
            uint fee1 = amount1 * depositFeePerc / 10000;
            amount1 = amount1 - fee1;

            uint portionFee0 = fee0 * 2 / 5; // 40%
            token0.safeTransfer(treasuryWallet, portionFee0); // 40%
            token0.safeTransfer(communityWallet, portionFee0); // 40%
            token0.safeTransfer(strategist, fee0 - portionFee0 - portionFee0); // 20%

            uint portionFee1 = fee1 * 2 / 5;
            token1.safeTransfer(treasuryWallet, portionFee1);
            token1.safeTransfer(communityWallet, portionFee1);
            token1.safeTransfer(strategist, fee1 - portionFee1 - portionFee1);
        }

        uint128 pool;
        if (vaultPositionTokenId != 0) (,,,,,,, pool,,,,) = nonfungiblePositionManager.positions(vaultPositionTokenId);
        uint amtLiquidity = addLiquidity(amount0, amount1);

        uint _totalSupply = totalSupply();
        uint share = _totalSupply == 0 ? amtLiquidity : amtLiquidity * _totalSupply / pool;
        _mint(msg.sender, share);
        emit Deposit(msg.sender, amt0Deposit, amt1Deposit, share);
    }

    function withdraw(uint share) external nonReentrant returns (uint amt0Collected, uint amt1Collected) {
        require(share > 0, "Share must > 0");

        if (!paused()) {
            (,,,,,,, uint128 pool,,,,) = nonfungiblePositionManager.positions(vaultPositionTokenId);
            uint amtliquidity = share * pool / totalSupply();
            _burn(msg.sender, share);

            (uint amount0, uint amount1) = decreaseLiquidity(amtliquidity);
            (amt0Collected, amt1Collected) = collect(amount0, amount1);

            token0.safeTransfer(msg.sender, amt0Collected);
            token1.safeTransfer(msg.sender, amt1Collected);
            emit Withdraw(msg.sender, amt0Collected, amt1Collected, share);
        } else {
            uint sharePerc = share * 1e18 / totalSupply();
            _burn(msg.sender, share);
            uint token0Amt = token0.balanceOf(address(this));
            uint token1Amt = token1.balanceOf(address(this));
            token0.safeTransfer(msg.sender, token0Amt * sharePerc / 1e18);
            token1.safeTransfer(msg.sender, token1Amt * sharePerc / 1e18);
            emit Withdraw(msg.sender, token0Amt, token1Amt, share);
        }
    }

    function yield() external onlyOwnerOrAdmin whenNotPaused {
        collect(type(uint).max, type(uint).max);
        uint amount0 = token0.balanceOf(address(this));
        uint amount1 = token1.balanceOf(address(this));
        if (amount0 > 0 && amount1 > 0) {
            (uint amount0AfterFee, uint amount1AfterFee) = calcFee(amount0, amount1);
            uint liquidity = addLiquidity(amount0AfterFee, amount1AfterFee);
            emit Yield(liquidity);
        }
    }

    function emergencyWithdraw() external onlyOwnerOrAdmin {
        _pause();
        (,,,,,,, uint128 pool,,,,) = nonfungiblePositionManager.positions(vaultPositionTokenId);
        decreaseLiquidity(pool);
        (uint amount0, uint amount1) = collect(type(uint).max, type(uint).max);
        emit EmergencyWithdraw(amount0, amount1);
    }

    function reinvest() external onlyOwnerOrAdmin {
        _unpause();
        uint token0Amt = token0.balanceOf(address(this));
        uint token1Amt = token1.balanceOf(address(this));
        addLiquidity(token0Amt, token1Amt);
        emit Reinvest(token0Amt, token1Amt);
    }

    function swap(address tokenIn, address tokenOut, uint amount) private returns (uint) {
        ISwapRouter.ExactInputSingleParams memory param = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn, 
            tokenOut: tokenOut, 
            fee: poolFee,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        return router.exactInputSingle(param);
    }

    function addLiquidity(uint amount0, uint amount1) private returns (uint) {
        if(vaultPositionTokenId == 0) {
            // add liquidity for the first time
            INonfungiblePositionManager.MintParams memory params =
                INonfungiblePositionManager.MintParams({
                    token0: address(token0),
                    token1: address(token1),
                    fee: poolFee,
                    tickLower: lowerTick, 
                    tickUpper: upperTick, 
                    amount0Desired: amount0,
                    amount1Desired: amount1,
                    amount0Min: 0,
                    amount1Min: 0,
                    recipient: address(this),
                    deadline: block.timestamp
                });
            (uint _tokenId, uint liquidity,,) = nonfungiblePositionManager.mint(params);
            vaultPositionTokenId = _tokenId;
            emit AddLiquidity(amount0, amount1, liquidity);
            return liquidity;
        } else {
            INonfungiblePositionManager.IncreaseLiquidityParams memory params =
                INonfungiblePositionManager.IncreaseLiquidityParams({
                    tokenId: vaultPositionTokenId,
                    amount0Desired: amount0,
                    amount1Desired: amount1,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                });
            (uint liquidity,,) = nonfungiblePositionManager.increaseLiquidity(params);
            emit AddLiquidity(amount0, amount1, liquidity);
            return liquidity;
        }
    }

    function decreaseLiquidity(uint liquidity) private returns (uint amount0, uint amount1) {
         INonfungiblePositionManager.DecreaseLiquidityParams memory params =
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: vaultPositionTokenId,
                liquidity: uint128(liquidity),
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });
        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(params);
        emit DecreaseLiquidity(amount0, amount1, liquidity);
    }

    function collect(uint amount0, uint amount1) private returns (uint amt0Collected, uint amt1Collected) {
        INonfungiblePositionManager.CollectParams memory collectParams =
            INonfungiblePositionManager.CollectParams({
                tokenId: vaultPositionTokenId,
                recipient: address(this),
                amount0Max: uint128(amount0),
                amount1Max: uint128(amount1)
            });
        (amt0Collected, amt1Collected) =  nonfungiblePositionManager.collect(collectParams);
        emit Collect(amt0Collected, amt1Collected);
    }

    function calcFee(uint amount0, uint amount1) private returns (uint amt0AfterFee, uint amt1AfterFee) {
        uint amt0Fee = amount0 * yieldFeePerc / 10000;
        amt0AfterFee = amount0 - amt0Fee;

        uint amt1Fee = amount1 * yieldFeePerc / 10000;
        amt1AfterFee = amount1 - amt1Fee;

        uint WETHAmtSwap;
        if (token0 == WETH) {
            WETHAmtSwap = swap(address(token1), address(token0), amt1Fee);
            WETH.withdraw(WETHAmtSwap + amt0Fee);
        } else {
            WETHAmtSwap = swap(address(token0), address(token1), amt0Fee);
            WETH.withdraw(WETHAmtSwap + amt1Fee);
        }

        uint portionETH = address(this).balance * 2 / 5; // 40%
        (bool _a,) = admin.call{value: portionETH}(""); // 40%
        require(_a, "Fee transfer failed");
        (bool _t,) = communityWallet.call{value: portionETH}(""); // 40%
        require(_t, "Fee transfer failed");
        (bool _s,) = strategist.call{value: (address(this).balance)}(""); // 20%
        require(_s, "Fee transfer failed");
    }

    receive() external payable {}
    
    function setWhitelistAddress(address _addr, bool _status) external onlyOwnerOrAdmin {
        isWhitelisted[_addr] = _status;
        emit SetWhitelistAddress(_addr, _status);
    }

    function setFee(uint _depositFeePerc, uint _yieldFeePerc) external onlyOwner {
        depositFeePerc = _depositFeePerc;
        yieldFeePerc =_yieldFeePerc;
        emit SetFee(_yieldFeePerc, _depositFeePerc);
    }

    function setTreasuryWallet(address _treasuryWallet) external onlyOwner {
        treasuryWallet = _treasuryWallet;
        emit SetTreasuryWallet(_treasuryWallet);
    }

    function setCommunityWallet(address _communityWallet) external onlyOwner {
        communityWallet = _communityWallet;
        emit SetCommunityWallet(_communityWallet);
    }

    function setStrategistWallet(address _strategistWallet) external onlyOwner {
        strategist = _strategistWallet;
        emit SetStrategistWallet(_strategistWallet);
    }

    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
        emit SetAdmin(_admin);
    }

    /// @return feeGrowthInside0LastX128 feeGrowthInside1LastX128 Pending rewards for token0 & token1 in pair
    function getPendingRewards() external view returns (uint feeGrowthInside0LastX128, uint feeGrowthInside1LastX128) {
        (,,,,,,,, feeGrowthInside0LastX128, feeGrowthInside1LastX128,,) = nonfungiblePositionManager.positions(vaultPositionTokenId);
    }

    function getAllPool() public view returns (uint amount0, uint amount1) {
        if (vaultPositionTokenId == 0) return (0, 0);
        (,,,,,int24 tickLower, int24 tickHigher, uint128 liquidity,,,,) =  nonfungiblePositionManager.positions(vaultPositionTokenId);
        (uint160 sqrtRatioX96,,,,,,) = uniswapV3Pool.slot0();
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickHigher);
        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(sqrtRatioX96, sqrtRatioAX96, sqrtRatioBX96, liquidity);
    }

    function getAllPoolInETH() public view returns (uint) {
        if (vaultPositionTokenId == 0) return 0;
        (uint amount0, uint amount1) = getAllPool();
        return token0 == WETH ? amount0 * 2 : amount1 * 2; // Assume both token have same value
    }

    function getAllPoolInUSD() public view returns (uint) {
        uint ETHPriceInUSD = uint(IChainlink(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419).latestAnswer()); // 8 decimals
        return getAllPoolInETH() * ETHPriceInUSD / 1e8;
    }

    /// @param inUSD true for calculate user share in USD, false for calculate APR
    function getPricePerFullShare(bool inUSD) external view returns (uint) {
        (,,,,,,, uint pool,,,,) = nonfungiblePositionManager.positions(vaultPositionTokenId);
        uint _totalSupply = totalSupply();
        if (_totalSupply == 0) return 0;
        return inUSD == true ?
            getAllPoolInUSD() * 1e18 / _totalSupply :
            pool * 1e18 / _totalSupply;
    }
}
