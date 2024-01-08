//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

interface IRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

interface IPair is IERC20Upgradeable {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IMasterChef {
    function deposit(uint pid, uint amount) external;
    function withdraw(uint pid, uint amount) external;
    function userInfo(uint pid, address user) external view returns (uint amount, uint rewardDebt);
    function poolInfo(uint pid) external view returns (address lpToken, uint allocPoint, uint lastRewardBlock, uint accSushiPerShare);
    function pendingSushi(uint pid, address user) external view returns (uint);
}

interface IChainlink {
    function latestAnswer() external view returns (int256);
}

interface IWETH is IERC20Upgradeable {
    function withdraw(uint amount) external;
}

contract Sushi is Initializable, ERC20Upgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IPair;
    using SafeERC20Upgradeable for IWETH;

    IRouter constant sushiRouter = IRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);    
    IMasterChef constant masterChef = IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    uint public poolId;

    IPair public lpToken;
    IERC20Upgradeable public token0;
    IERC20Upgradeable public token1;
    uint baseTokenDecimals;
    IWETH constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); 
    IERC20Upgradeable constant SUSHI = IERC20Upgradeable(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    
    address public admin; 
    address public treasuryWallet;
    address public communityWallet;
    address public strategist;

    uint public yieldFeePerc;
    uint public depositFeePerc;

    mapping(address => bool) public isWhitelisted;
    mapping(address => uint) private depositedBlock;

    event Deposit(address caller, uint amtDeposited, uint sharesMinted);
    event Withdraw(address caller, uint amtWithdrawed, uint sharesBurned);
    event Invest(uint amtInvested);
    event Yield(uint amount);
    event EmergencyWithdraw(uint amtTokenWithdrawed);
    event SetWhitelistAddress(address account, bool status);
    event SetFee(uint _yieldFeePerc, uint _depositFeePerc);
    event SetTreasuryWallet(address treasuryWallet);
    event SetCommunityWallet(address communityWallet);
    event SetAdminWallet(address admin);
    event SetStrategistWallet(address strategistWallet);
    event SetAdmin(address admin);

    modifier onlyOwnerOrAdmin {
        require(msg.sender == owner() || msg.sender == address(admin), "Only owner or admin");
        _;
    }

    function initialize(
            string calldata name, string calldata symbol, uint _poolId,
            address _treasuryWallet, address _communityWallet, address _strategist, address _admin
        ) external initializer {
        __ERC20_init(name, symbol);
        __Ownable_init();

        treasuryWallet = _treasuryWallet;
        communityWallet = _communityWallet;
        strategist = _strategist;
        admin = _admin;

        poolId = _poolId;
        (address _lpToken,,,) = masterChef.poolInfo(_poolId);
        lpToken = IPair(_lpToken);

        yieldFeePerc = 2000;
        depositFeePerc = 1000;

        token0 = IERC20Upgradeable(lpToken.token0());
        token1 = IERC20Upgradeable(lpToken.token1());
        address baseToken = address(token0) == address(WETH) ? address(token1) : address(token0);
        baseTokenDecimals = ERC20Upgradeable(baseToken).decimals();

        token0.safeApprove(address(sushiRouter), type(uint).max);
        token1.safeApprove(address(sushiRouter), type(uint).max);
        lpToken.safeApprove(address(sushiRouter), type(uint).max);
        lpToken.safeApprove(address(masterChef), type(uint).max);
        SUSHI.safeApprove(address(sushiRouter), type(uint).max);
    }
        
    function deposit(uint amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must > 0");
        uint amtDeposit = amount;

        uint pool = getAllPool();
        lpToken.safeTransferFrom(msg.sender, address(this), amount);
        depositedBlock[msg.sender] = block.number;

        if (!isWhitelisted[msg.sender]) {
            uint fees = amount * depositFeePerc / 10000;
            amount = amount - fees;

            uint fee = fees * 2 / 5; // 40%
            lpToken.safeTransfer(treasuryWallet, fee);
            lpToken.safeTransfer(communityWallet, fee);
            lpToken.safeTransfer(strategist, fees - fee - fee);
        }

        uint _totalSupply = totalSupply();
        uint share = _totalSupply == 0 ? amount : amount * _totalSupply / pool;
        _mint(msg.sender, share);
        emit Deposit(msg.sender, amtDeposit, share);
    }

    function withdraw(uint share) external nonReentrant returns (uint withdrawAmt) {
        require(share > 0, "Share must > 0");
        require(share <= balanceOf(msg.sender), "Not enough shares to withdraw");
        require(depositedBlock[msg.sender] != block.number, "Withdraw within same block");

        uint lpTokenBalInVault = lpToken.balanceOf(address(this));
        (uint lpTokenBalInFarm,) = masterChef.userInfo(poolId, address(this));
        withdrawAmt = (lpTokenBalInVault + lpTokenBalInFarm) * share / totalSupply();
        _burn(msg.sender, share);

        if (withdrawAmt > lpTokenBalInVault) {
            uint amtToWithdraw = withdrawAmt - lpTokenBalInVault;
            masterChef.withdraw(poolId, amtToWithdraw);
        }

        lpToken.safeTransfer(msg.sender, withdrawAmt);
        emit Withdraw(msg.sender, withdrawAmt, share);
    }

    function invest() public onlyOwnerOrAdmin whenNotPaused {
        masterChef.deposit(poolId, lpToken.balanceOf(address(this)));
    }

    function yield() external onlyOwnerOrAdmin whenNotPaused {
        masterChef.deposit(poolId, 0); // To collect SUSHI
        uint sushiBalance = SUSHI.balanceOf(address(this));
        uint WETHAmt = (sushiRouter.swapExactTokensForTokens(
            sushiBalance, 0, getPath(address(SUSHI), address(WETH)), address(this), block.timestamp
        ))[1];

        uint fee = WETHAmt * yieldFeePerc / 10000;
        WETH.withdraw(fee);
        WETHAmt = WETHAmt - fee;

        uint portionETH = address(this).balance * 2 / 5; // 40%
        (bool _a,) = admin.call{value: portionETH}(""); // 40%
        require(_a, "Fee transfer failed");
        (bool _t,) = communityWallet.call{value: portionETH}(""); // 40%
        require(_t, "Fee transfer failed");
        (bool _s,) = strategist.call{value: (address(this).balance)}(""); // 20%
        require(_s, "Fee transfer failed");

        uint WETHAmtHalf = WETHAmt / 2;
        address baseToken = address(token0) == address(WETH) ? address(token1) : address(token0);
        uint baseTokenAmt = (sushiRouter.swapExactTokensForTokens(
            WETHAmtHalf, 0, getPath(address(WETH), baseToken), address(this), block.timestamp
        ))[1];
        sushiRouter.addLiquidity(address(baseToken), address(WETH), baseTokenAmt, WETHAmtHalf, 0, 0, address(this), block.timestamp);

        emit Yield(WETHAmt);
    }

    receive() external payable {}

    function emergencyWithdraw() external onlyOwnerOrAdmin {
        _pause();
        (uint lpTokenAmtInFarm,) = masterChef.userInfo(poolId, address(this));
        if (lpTokenAmtInFarm > 0) {
            masterChef.withdraw(poolId, lpTokenAmtInFarm);
        }
        emit EmergencyWithdraw(lpTokenAmtInFarm);
    }

    function reinvest() external onlyOwnerOrAdmin whenPaused {
        _unpause();
        invest();
    }

    function setWhitelistAddress(address addr, bool status) external onlyOwnerOrAdmin {
        isWhitelisted[addr] = status;
        emit SetWhitelistAddress(addr, status);
    }

    function setFee(uint _yieldFeePerc, uint _depositFeePerc) external onlyOwner {
        yieldFeePerc = _yieldFeePerc;
        depositFeePerc = _depositFeePerc;
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

    function getPath(address tokenA, address tokenB) private pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
    }

    function getLpTokenPriceInETH() private view returns (uint) {
        address baseToken;
        uint reserveBaseToken;
        uint reserveWETH;

        (uint112 reserveToken0, uint112 reserveToken1,) = lpToken.getReserves();
        if (address(token0) == address(WETH)) {
            baseToken = address(token1);
            reserveWETH = reserveToken0;
            reserveBaseToken = reserveToken1;
        } else {
            baseToken = address(token0);
            reserveWETH = reserveToken1;
            reserveBaseToken = reserveToken0;
        }

        uint _baseTokenDecimals = baseTokenDecimals;
        uint baseTokenPriceInETH = (sushiRouter.getAmountsOut(10 ** _baseTokenDecimals, getPath(baseToken, address(WETH))))[1];
        uint totalReserveInETH = reserveBaseToken * baseTokenPriceInETH / 10 ** _baseTokenDecimals + reserveWETH;
        return totalReserveInETH * 1e18 / lpToken.totalSupply();
    }

    function getLpTokenPriceInUSD() private view returns (uint) {
        uint ETHPriceInUSD = uint(IChainlink(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419).latestAnswer()); // 8 decimals
        return getLpTokenPriceInETH() * ETHPriceInUSD / 1e8;
    }

    /// @return Pending rewards in SUSHI token
    /// @dev Rewards also been claimed while deposit or withdraw through masterChef contract
    function getPendingRewards() external view returns (uint) {
        uint pendingRewards = masterChef.pendingSushi(poolId, address(this));
        return pendingRewards + SUSHI.balanceOf(address(this));
    }

    function getAllPool() public view returns (uint) {
        (uint lpTokenAmtInFarm, ) = masterChef.userInfo(poolId, address(this));
        return lpToken.balanceOf(address(this)) + lpTokenAmtInFarm;
    }

    function getAllPoolInETH() public view returns (uint) {
        return getAllPool() * getLpTokenPriceInETH() / 1e18;
    }

    function getAllPoolInUSD() public view returns (uint) {
        return getAllPool() * getLpTokenPriceInUSD() / 1e18;
    }

    /// @param inUSD true for calculate user share in USD, false for calculate APR
    function getPricePerFullShare(bool inUSD) external view returns (uint) {
        uint _totalSupply = totalSupply();
        if (_totalSupply == 0) return 0;
        return inUSD == true ?
            getAllPoolInUSD() * 1e18 / _totalSupply :
            getAllPool() * 1e18 / _totalSupply;
    }
}
