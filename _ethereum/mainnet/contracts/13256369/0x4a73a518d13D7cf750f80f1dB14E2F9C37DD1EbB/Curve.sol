// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./SafeERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./console.sol";

interface ICvStake {
    function balanceOf(address account) external view returns (uint);
    function withdrawAndUnwrap(uint amount, bool claim) external;
    function getReward() external returns(bool);
    function extraRewards(uint index) external view returns (address);
    function extraRewardsLength() external view returns (uint);
    function earned(address account) external view returns (uint);
}

interface ICvVault {
    function deposit(uint pid, uint amount, bool stake) external;
    function withdraw(uint pid, uint amount) external;
    function poolInfo(uint pid) external view returns (address, address, address, address, address, bool);
}

interface ICurveZap {
    function getVirtualPrice() external view returns (uint);
    function compound(uint CRVAmt, uint CVXAmt, uint yieldFeePerc) external returns (uint, uint);
}

interface ICvRewards {
    function rewardToken() external view returns (address);
}

contract Curve is Initializable, ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public lpToken;
    ICvStake public cvStake;

    ICvVault constant cvVault = ICvVault(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    IERC20Upgradeable constant WETH = IERC20Upgradeable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20Upgradeable constant CVX = IERC20Upgradeable(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    IERC20Upgradeable constant CRV = IERC20Upgradeable(0xD533a949740bb3306d119CC777fa900bA034cd52);

    uint public pid; // Index for Convex pool
    ICurveZap public curveZap;

    uint public depositFeePerc;
    uint public yieldFeePerc;

    address public treasuryWallet;
    address public communityWallet;
    address public strategist;
    address public admin;

    mapping(address => bool) public isWhitelisted;
    mapping(address => uint) private depositedBlock;

    event Deposit(address indexed caller, uint amtDeposit, uint sharesMint);
    event Withdraw(address indexed caller, uint amtWithdraw, uint sharesBurn);
    event Invest(uint amtToInvest);
    event Yield(uint lpTokenBal);
    event EmergencyWithdraw(uint lptokenAmount);
    event SetCurveZap(address indexed curveZap);
    event SetWhitelistAddress(address indexed account, bool status);
    event SetFee(uint yieldFeePerc, uint depositFeePerc);
    event SetTreasuryWallet(address indexed treasuryWallet);
    event SetCommunityWallet(address indexed communityWallet);
    event SetStrategistWallet(address indexed strategistWallet);
    event SetAdminWallet(address indexed admin);

    modifier onlyOwnerOrAdmin {
        require(msg.sender == owner() || msg.sender == address(admin), "Only owner or admin");
        _;
    }

    function initialize(
        string calldata name, string calldata symbol, uint _pid,
        address _treasuryWallet, address _communityWallet, address _strategist, address _admin
    ) external initializer {
        __ERC20_init(name, symbol);
        __Ownable_init();

        treasuryWallet = _treasuryWallet;
        communityWallet = _communityWallet;
        strategist = _strategist;
        admin = _admin;

        depositFeePerc = 1000;
        yieldFeePerc = 2000;

        pid = _pid;
        (address _lpToken, , , address _cvStakeAddr, , ) = cvVault.poolInfo(_pid);
        lpToken = IERC20Upgradeable(_lpToken);
        cvStake = ICvStake(_cvStakeAddr);

        lpToken.safeApprove(address(cvVault), type(uint).max);
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
        uint lpTokenBalInFarm = cvStake.balanceOf(address(this));
        withdrawAmt = (lpTokenBalInVault + lpTokenBalInFarm) * share / totalSupply();
        _burn(msg.sender, share);

        if (withdrawAmt > lpTokenBalInVault) {
            uint amtToWithdraw = withdrawAmt - lpTokenBalInVault;
            cvStake.withdrawAndUnwrap(amtToWithdraw, false);
        }

        lpToken.safeTransfer(msg.sender, withdrawAmt);
        emit Withdraw(msg.sender, withdrawAmt, share);
    }

    function invest() public onlyOwnerOrAdmin whenNotPaused {
        uint lpTokenAmt = lpToken.balanceOf(address(this));
        cvVault.deposit(pid, lpTokenAmt, true);
        emit Invest(lpTokenAmt);
    }

    function investZap(uint amount) external {
        require(msg.sender == address(curveZap), "Only zap");

        lpToken.safeTransferFrom(address(curveZap), address(this), amount);
        cvVault.deposit(pid, amount, true);
    }

    function yield() external onlyOwnerOrAdmin whenNotPaused {
        _yield();
    }

    function _yield() private {
        cvStake.getReward();

        uint CRVAmt = CRV.balanceOf(address(this));
        uint CVXAmt = CVX.balanceOf(address(this));
        if (CRVAmt > 0) CRV.safeTransfer(address(curveZap), CRVAmt);
        if (CVXAmt > 0) CVX.safeTransfer(address(curveZap), CVXAmt);
        if (cvStake.extraRewardsLength() > 0) {
            for (uint i = 0; i < cvStake.extraRewardsLength(); i++) {
                IERC20Upgradeable extraRewardToken = IERC20Upgradeable(ICvRewards(cvStake.extraRewards(i)).rewardToken());
                uint extraRewardTokenBalance = extraRewardToken.balanceOf(address(this));
                if (extraRewardTokenBalance > 0) extraRewardToken.safeTransfer(address(curveZap), extraRewardTokenBalance);
            }
        }

        (uint lpTokenBal, uint yieldFee) = curveZap.compound(CRVAmt, CVXAmt, yieldFeePerc);
        uint portionETH = yieldFee * 2 / 5; // 40%
        (bool _a,) = admin.call{value: portionETH}(""); // 40%
        require(_a, "Fee transfer failed");
        (bool _t,) = communityWallet.call{value: portionETH}(""); // 40%
        require(_t, "Fee transfer failed");
        (bool _s,) = strategist.call{value: (address(this).balance)}(""); // 20%
        require(_s, "Fee transfer failed");
        
        emit Yield(lpTokenBal);
    }

    receive() external payable {}

    /// @notice Function to withdraw all token from strategy and pause deposit & invest function
    function emergencyWithdraw() external onlyOwnerOrAdmin {
        _pause();
        uint lpTokenAmtInFarm = cvStake.balanceOf(address(this));
        if (lpTokenAmtInFarm > 0) {
            _yield();
            cvStake.withdrawAndUnwrap(lpTokenAmtInFarm, false);
        }
        emit EmergencyWithdraw(lpTokenAmtInFarm);
    }

    function reinvest() external onlyOwnerOrAdmin whenPaused {
        _unpause();
        invest();
    }

    function setCurveZap(address _curveZap) external onlyOwnerOrAdmin {
        curveZap = ICurveZap(_curveZap);
        emit SetCurveZap(_curveZap);
    }

    function setWhitelistAddress(address addr, bool status) external onlyOwnerOrAdmin {
        isWhitelisted[addr] = status;
        emit SetWhitelistAddress(addr, status);
    }

    function setFee(uint _yieldFeePerc, uint _depositFeePerc) external onlyOwner {
        require(_yieldFeePerc < 3001 && _depositFeePerc < 1001, "Yield Fee cannot > 30%, deposit fee cannot > 10%");
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
        emit SetAdminWallet(_admin);
    }

    function getAllPool() public view returns (uint) {
        uint lpTokenAmtInFarm = cvStake.balanceOf(address(this));
        return lpToken.balanceOf(address(this)) + lpTokenAmtInFarm;
    }

    /// @return Pending rewards in CRV token
    /// @dev Amount pending CRV = amount pending CVX
    /// @dev This function doesn't show pending extra rewards
    function getPendingRewards() external view returns (uint) {
        return cvStake.earned(address(this));
    }

    function getAllPoolInNative() external view returns (uint) {
        return getAllPool() * curveZap.getVirtualPrice() / 1e18;
    }

    /// @param _native true for calculate user share in vault's native (ETH, BTC, USD), false for calculate APR
    function getPricePerFullShare(bool _native) external view returns (uint) {
        uint _pricePerFullShare = getAllPool() * 1e18 / totalSupply();
        return _native == true ? _pricePerFullShare * curveZap.getVirtualPrice() / 1e18 : _pricePerFullShare;
    }
}