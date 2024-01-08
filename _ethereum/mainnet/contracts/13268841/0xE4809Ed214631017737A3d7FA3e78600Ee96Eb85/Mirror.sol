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

    function swapExactTokensForETH(
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
    ) external returns (uint amountA, uint amountB, uint liquidity) ;

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

interface IPair is IERC20Upgradeable {
    function getReserves() external view returns (uint, uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface ILpPool {
    function balanceOf(address _account) external view returns (uint);
    function earned(address _account) external view returns (uint);
    function lpt() external view returns (address);
    function getReward() external;
    function stake(uint _amount) external;
    function withdraw(uint _amount) external;
}

interface IChainlink {
    function latestAnswer() external view returns (int256);
}

contract Mirror is Initializable, ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IPair;

    IRouter constant uniRouter = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    ILpPool public lpPool;

    IPair public lpToken;
    address public mAsset;
    address public token1;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IERC20Upgradeable constant MIR  = IERC20Upgradeable(0x09a3EcAFa817268f77BE1283176B946C4ff2E608);
    IERC20Upgradeable constant UST = IERC20Upgradeable(0xa47c8bf37f92aBed4A126BDA807A7b7498661acD);

    address public admin;
    address public treasuryWallet;
    address public communityWallet;
    address public strategist;

    uint public yieldFee;
    uint public depositFee;

    mapping(address => bool) public isWhitelisted;
    mapping(address => uint) depositedBlock;

    event Deposit(address caller, uint amtDeposited, uint sharesMinted);
    event Withdraw(address caller, uint amtWithdrawed, uint sharesBurned);
    event Invest(uint amount);
    event Yield(uint amount);
    event EmergencyWithdraw(uint amount);
    event SetWhitelistAddress(address account, bool status);
    event SetFeePerc(uint oldYieldFee, uint newYieldFee, uint oldDepositFee, uint newDepositFee);
    event SetTreasuryWallet(address oldTreasuryWallet, address newTreasuryWallet);
    event SetCommunityWallet(address oldCommunityWallet, address newCommunityWallet);
    event SetStrategistWallet(address oldStrategistWallet, address newStrategistWallet);
    event SetAdminWallet(address oldAdmin, address newAdmin);

    modifier onlyOwnerOrAdmin {
        require(msg.sender == owner() || msg.sender == admin, "Only owner or admin");
        _;
    }

    function initialize(
        string calldata name, string calldata symbol, ILpPool _lpPool,
        address _treasuryWallet, address _communityWallet, address _strategist, address _admin
    ) external initializer {
        __ERC20_init(name, symbol);
        __Ownable_init();

        treasuryWallet = _treasuryWallet;
        communityWallet = _communityWallet;
        strategist = _strategist;
        admin = _admin;

        lpPool = _lpPool;
        lpToken = IPair(lpPool.lpt());
        token1 = lpToken.token1();
        mAsset = token1 == address(UST) ? lpToken.token0() : token1;

        yieldFee = 2000;
        depositFee = 1000;

        IERC20Upgradeable(mAsset).approve(address(uniRouter), type(uint).max);
        UST.safeApprove(address(uniRouter), type(uint).max);
        lpToken.safeApprove(address(uniRouter), type(uint).max);
        lpToken.safeApprove(address(_lpPool), type(uint).max);
        MIR.safeApprove(address(uniRouter), type(uint).max);
    }

    function deposit(uint amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must > 0");
        uint amtDeposit = amount;

        uint _pool = getAllPool();
        lpToken.safeTransferFrom(msg.sender, address(this), amount);
        depositedBlock[msg.sender] = block.number;

        if(!isWhitelisted[msg.sender]) {
            uint fees = amount * depositFee / 10000;
            amount = amount - fees;

            uint fee = fees * 2 / 5;
            lpToken.safeTransfer(treasuryWallet, fee);
            lpToken.safeTransfer(communityWallet, fee);
            lpToken.safeTransfer(strategist, fees - fee - fee);
        }

        uint _totalSupply = totalSupply();
        uint share = _totalSupply == 0 ? amount : amount * _totalSupply / _pool;

        _mint(msg.sender, share);
        emit Deposit(msg.sender, amtDeposit, share);
    }

    function withdraw(uint share) external nonReentrant returns (uint withdrawAmt) {
        require(share > 0, "Share must > 0");
        require(share <= balanceOf(msg.sender), "Not enough shares to withdraw");
        require(depositedBlock[msg.sender] != block.number, "Withdraw within same block");

        uint lpTokenBalInVault = lpToken.balanceOf(address(this));
        uint lpTokenBalInFarm = lpPool.balanceOf(address(this));
        withdrawAmt = (lpTokenBalInVault + lpTokenBalInFarm) * share / totalSupply();
        _burn(msg.sender, share);

        if(withdrawAmt > lpTokenBalInVault) {
            lpPool.withdraw(withdrawAmt - lpTokenBalInVault);
        }

        lpToken.safeTransfer(msg.sender, withdrawAmt);
        emit Withdraw(msg.sender, withdrawAmt, share);
    }

    function invest() external onlyOwnerOrAdmin whenNotPaused {
        uint lpTokenAmt = lpToken.balanceOf(address(this));
        _invest(lpTokenAmt);
    }   

    function _invest(uint lpTokenAmt) private {
        lpPool.stake(lpTokenAmt);
        emit Invest(lpTokenAmt);
    }

    function yield() external onlyOwnerOrAdmin whenNotPaused { 
        _yield();
    }

    function _yield() private {
        uint rewardMIR = lpPool.earned(address(this));
        if(rewardMIR > 0) {
            uint _rewardMIR = rewardMIR; // For event

            lpPool.getReward();
            uint fee = rewardMIR * yieldFee / 10000;
            rewardMIR -= fee;

            uniRouter.swapExactTokensForETH(fee, 0, getPath(address(MIR), address(WETH)), address(this), block.timestamp);
            uint portionETH = address(this).balance * 2 / 5; // 40%
            (bool _a,) = admin.call{value: portionETH}(""); // 40%
            require(_a, "Fee transfer failed");
            (bool _t,) = communityWallet.call{value: portionETH}(""); // 40%
            require(_t, "Fee transfer failed");
            (bool _s,) = strategist.call{value: (address(this).balance)}(""); // 20%
            require(_s, "Fee transfer failed");

            uint outAmount0;
            uint outAmount1;
            if(mAsset == address(MIR)) {
                outAmount0 = rewardMIR / 2;
                outAmount1 = swap(address(MIR), address(UST), outAmount0); // rewardMIR / 2
            } else {
                uint USTAmt = swap(address(MIR), address(UST), rewardMIR);
                outAmount1 = USTAmt / 2;
                outAmount0 = swap(address(UST), address(mAsset), outAmount1); // USTAmt / 2
            }
            (,,uint lpTokenAmt) = uniRouter.addLiquidity(mAsset, address(UST), outAmount0, outAmount1, 0, 0, address(this), block.timestamp);

            _invest(lpTokenAmt);

            emit Yield(_rewardMIR);
        }
    }

    receive() external payable {}

    function emergencyWithdraw() external onlyOwnerOrAdmin whenNotPaused { 
        _pause();
        _yield();
        uint stakedTokens = lpPool.balanceOf(address(this));
        if(stakedTokens > 0 ) {
            lpPool.withdraw(stakedTokens);
        }
        emit EmergencyWithdraw(stakedTokens);
    }

    function reinvest() external onlyOwnerOrAdmin whenPaused {
        _unpause();
        uint lpTokenAmt = lpToken.balanceOf(address(this));
        _invest(lpTokenAmt);
    }

    function swap(address tokenIn, address tokenOut, uint amount) private returns (uint) {
        return uniRouter.swapExactTokensForTokens(amount, 0, getPath(tokenIn, tokenOut), address(this), block.timestamp)[1];
    }

    function setWhitelistAddress(address addr, bool status) external onlyOwnerOrAdmin {
        isWhitelisted[addr] = status;
        emit SetWhitelistAddress(addr, status);
    }

    function setFeePerc(uint _yieldFee, uint _depositFee) external onlyOwner {
        uint oldYieldFee = yieldFee;
        yieldFee = _yieldFee;

        uint oldDepositFee = depositFee;
        depositFee = _depositFee;

        emit SetFeePerc(oldYieldFee, _yieldFee, oldDepositFee, _depositFee);
    }

    function setTreasuryWallet(address _treasuryWallet) external onlyOwner {
        address oldTreasuryWallet = treasuryWallet;
        treasuryWallet = _treasuryWallet;
        emit SetTreasuryWallet(oldTreasuryWallet, _treasuryWallet);
    }

    function setCommunityWallet(address _communityWallet) external onlyOwner {
        address oldCommunityWallet = communityWallet;
        communityWallet = _communityWallet;
        emit SetCommunityWallet(oldCommunityWallet, _communityWallet);
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == strategist || msg.sender == owner(), "Only owner or strategist");
        address oldStrategist = strategist;
        strategist = _strategist;
        emit SetStrategistWallet(oldStrategist, _strategist);
    }

    function setAdmin(address _admin) external onlyOwner {
        address oldAdmin = admin;
        admin = _admin;
        emit SetAdminWallet(oldAdmin, _admin);
    }

    function getPath(address tokenA, address tokenB) private pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
    }

    /// @return Pending rewards in MIR token
    function getPendingRewards() external view returns (uint) {
        return lpPool.earned(address(this));
    }

    function getAllPool() public view returns (uint) {
        return lpToken.balanceOf(address(this)) + lpPool.balanceOf(address(this));
    }

    function _getReserves() private view returns (uint _mAssetReserve, uint _ustReserve) {
        (_mAssetReserve, _ustReserve) = lpToken.getReserves();
        if(token1 == mAsset) (_mAssetReserve, _ustReserve) = (_ustReserve, _mAssetReserve);
    }

    /// @return Returns the value of lpToken in ETH (18 decimals)
    function getAllPoolInETH() public view returns (uint) {
        uint USTPriceInETH = uniRouter.getAmountsOut(1e18, getPath(address(UST), address(WETH)))[1];
        return getAllPoolInUSD() * USTPriceInETH / 1e18;
    }
    
    /// @return Returns the value of lpToken in USD (18 decimals)
    function getAllPoolInUSD() public view returns (uint) {
        uint pool = getAllPool();
        (uint reserveMAsset, uint reserveUST) = _getReserves();
        uint _totalSupply = lpToken.totalSupply();
        uint totalmAsset = pool * reserveMAsset / _totalSupply;
        uint totalUST = pool * reserveUST / _totalSupply;

        uint mAssetPriceInUST = uniRouter.getAmountsOut(1e18, getPath(address(mAsset), address(UST)))[1];
        return (totalmAsset * mAssetPriceInUST / 1e18) + totalUST;
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
