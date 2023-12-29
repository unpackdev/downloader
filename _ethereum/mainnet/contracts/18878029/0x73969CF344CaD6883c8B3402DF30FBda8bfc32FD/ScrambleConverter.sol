// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IScramble.sol";

import "./SafeMathUint.sol";
import "./SafeMathInt.sol";

/// @title Scramble Converter
/// @dev A heavily modified version of DividendPayingToken (https://github.com/Roger-Wu/erc1726-dividend-paying-token)

contract ScrambleConverter is ERC20("Staked Scramble LP", "stSLP"), Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    IScramble public scramble;
    IUniswapV2Pair public scrambleLp;
    IUniswapV2Router02 public router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 public constant MAGNITUDE = 2 ** 128;
    uint256 public magnifiedEtherPerShare;

    event EtherDistributed(address indexed from, uint256 weiAmount);
    event Deposit(address indexed user, uint256 amountLp);
    event Withdraw(address indexed user, uint256 amountLp, uint256 voidedEthRewards);
    event Claim(address indexed user, uint256 lpStaked, uint256 ethClaimed);
    event Compound(address indexed user, uint256 lpStaked, uint256 ethClaimed, uint256 lpAdded);

    mapping(address => int256) public magnifiedEtherCorrections;
    mapping(address => uint256) public withdrawnEther;
    mapping(address => uint256) public compoundedLpTokens;
    mapping(address => uint256) public userLockEndTimestamp;

    uint256 public totalEtherDistributed;
    uint256 public lockTime = 7 days;
    address public feeReceiver;

    bool public depositAllowed;
    bool public withdrawAllowed;
    bool public claimAllowed;
    bool public compoundAllowed;

    receive() external payable {
        distributeEther();
    }

    function distributeEther() public payable {
        require(totalSupply() > 0, "Nowhere to distribute");
        if (msg.value > 0) {
            magnifiedEtherPerShare = magnifiedEtherPerShare.add((msg.value).mul(MAGNITUDE) / totalSupply());
            totalEtherDistributed += msg.value;
            emit EtherDistributed(msg.sender, msg.value);
        }
    }

    function deposit(uint256 amount) public {
        require(depositAllowed, "Deposit not allowed");
        require(amount > 0, "Amount can't be zero");
        require(amount <= scrambleLp.balanceOf(msg.sender), "Amount over user balance");
        require(amount <= scrambleLp.allowance(msg.sender, address(this)), "Not enough allowance");
        userLockEndTimestamp[msg.sender] = block.timestamp + lockTime;
        scrambleLp.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant {
        require(withdrawAllowed, "Withdraw not allowed");
        require(amount > 0, "Amount can't be zero");
        require(amount <= balanceOf(msg.sender), "Amount over user balance");
        if (lockTime > 0) {
            require(userLockEndTimestamp[msg.sender] <= block.timestamp, "Still locked");
        }
        uint256 voidedEthRewards = etherOf(msg.sender);
        withdrawnEther[msg.sender] = withdrawnEther[msg.sender].add(voidedEthRewards);
        userLockEndTimestamp[msg.sender] = block.timestamp + lockTime;
        scrambleLp.transfer(msg.sender, amount);
        _burn(msg.sender, amount);
        emit Withdraw(msg.sender, amount, voidedEthRewards);
        (bool success,) = address(this).call{value: voidedEthRewards}("");
        require(success);
    }

    function claim() public nonReentrant {
        require(claimAllowed, "Claim not allowed");
        uint256 accumulatedEther = etherOf(msg.sender);
        require(accumulatedEther > 0, "Nothing to claim");
        uint256 toWithdraw = (accumulatedEther * 80) / 100;
        uint256 toFee = accumulatedEther - toWithdraw;
        withdrawnEther[msg.sender] = withdrawnEther[msg.sender].add(accumulatedEther);
        userLockEndTimestamp[msg.sender] = block.timestamp + lockTime;
        emit Claim(msg.sender, balanceOf(msg.sender), accumulatedEther);
        payable(msg.sender).transfer(toWithdraw);
        payable(feeReceiver).transfer(toFee);
    }

    function compound(uint256 _amountOutMin, uint256 _amountTokenMin, uint256 _amountETHMin) public nonReentrant {
        require(compoundAllowed, "Compound not allowed");
        require(address(scramble) != address(0), "Scramble address not set");
        require(_amountOutMin != 0, "amountOutMin can't be zero");
        require(_amountTokenMin != 0, "amountTokenMin can't be zero");
        require(_amountETHMin != 0, "amountETHMin can't be zero");
        uint256 accumulatedEther = etherOf(msg.sender);
        require(accumulatedEther > 0, "Nothing to compound");
        uint256 toWithdraw = (accumulatedEther * 80) / 100;
        uint256 toFee = accumulatedEther - toWithdraw;
        withdrawnEther[msg.sender] = withdrawnEther[msg.sender].add(accumulatedEther);
        userLockEndTimestamp[msg.sender] = block.timestamp + lockTime;
        payable(feeReceiver).transfer(toFee);
        (, uint112 r1) = getReserves();
        uint256 toSwap = getSwapAmount(r1, toWithdraw);
        uint256 toLiquidity = toWithdraw - toSwap;
        uint scrambleBalanceBefore = scramble.balanceOf(address(this));
        router.swapExactETHForTokens{value: toSwap}(_amountOutMin, _pair(), address(this), block.timestamp);
        uint gotScramble = scramble.balanceOf(address(this)) - scrambleBalanceBefore;
        (,, uint256 gotLiquidity) = router.addLiquidityETH{value: toLiquidity}(address(scramble), gotScramble, _amountTokenMin, _amountETHMin, msg.sender, block.timestamp);
        emit Compound(msg.sender, balanceOf(msg.sender), accumulatedEther, gotLiquidity);
        deposit(gotLiquidity);
    }

    function getCompoundInputParametersOfUser(address _user, uint256 swapSlippage, uint256 liqSlippage) public view returns (uint256, uint256) {
        uint256 accumulatedEther = etherOf(_user);
        if (accumulatedEther == 0) {
            return (0, 0);
        } else {
            uint256 toWithdraw = (accumulatedEther * 80) / 100;
            (uint112 r0, uint112 r1) = getReserves();
            uint256 toSwap = getSwapAmount(r1, toWithdraw);
            uint256 toLiquidity = toWithdraw - toSwap;
            uint256 amountScramble = router.getAmountOut(toSwap, r1, r0);
            uint256 slippageScramble = (amountScramble * swapSlippage * 1e10) / 100e12;
            uint256 minAmountScramble = amountScramble - slippageScramble;
            uint256 slippageEth = (toLiquidity * liqSlippage * 1e10) / 100e12;
            uint256 minAmountEth = toLiquidity - slippageEth;
            return (minAmountScramble, minAmountEth);
        }
    }

    /*
    s = optimal swap amount
    r = amount of reserve for token a
    a = amount of token a the user currently has (not added to reserve yet)
    f = swap fee percent
    s = (sqrt(((2 - f)r)^2 + 4(1 - f)ar) - (2 - f)r) / (2(1 - f))
    source: https://github.com/stakewithus/defi-by-example/blob/main/contracts/TestUniswapOptimal.sol
    */
    function getSwapAmount(uint256 r, uint256 a) public pure returns (uint256) {
        return (sqrt(r.mul(r.mul(3988009) + a.mul(3988000))).sub(r.mul(1997))) / 1994;
    }

    function getReserves() public view returns (uint112, uint112) {
        (uint112 _reserve0, uint112 _reserve1,) = scrambleLp.getReserves();
        return address(scramble) < router.WETH() ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
    }

    function setScrambleLpAddress(address _address) external onlyOwner {
        scrambleLp = IUniswapV2Pair(_address);
    }

    function setScrambleAddress(address _address) external onlyOwner {
        scramble = IScramble(_address);
        scramble.approve(address(router), type(uint256).max); // used for gas savings in compound
    }

    function setFeeReceiverAddress(address _address) external onlyOwner {
        feeReceiver = _address;
    }

    function setLockTime(uint256 _lockTime) external onlyOwner {
        lockTime = _lockTime;
    }

    function emergencyWithdrawEth(uint256 _amount) external onlyOwner {
        payable(owner()).transfer(_amount);
    }

    function emergencyWithdrawScrambleLp(uint256 _amount) external onlyOwner {
        scrambleLp.transfer(owner(), _amount);
    }

    function setAllowedActions(bool _depositAllowed, bool _withdrawAllowed, bool _claimAllowed, bool _compoundAllowed) external onlyOwner {
        depositAllowed = _depositAllowed;
        withdrawAllowed = _withdrawAllowed;
        claimAllowed = _claimAllowed;
        compoundAllowed = _compoundAllowed;
    }

    function etherOf(address _user) public view returns (uint256) {
        return cumulativeEtherOf(_user).sub(withdrawnEther[_user]);
    }

    function percentShareOf(address _user) public view returns (uint256) {
        if (totalSupply() > 0) {
            return (balanceOf(_user) * 1e18) / totalSupply();
        } else {
            return 0;
        }
    }

    function cumulativeEtherOf(address _user) public view returns (uint256) {
        return magnifiedEtherPerShare.mul(balanceOf(_user)).toInt256Safe().add(magnifiedEtherCorrections[_user]).toUint256Safe() / MAGNITUDE;
    }

    function _transfer(address from, address to, uint256 value) internal override {
        revert("Transfer not allowed");
        super._transfer(from, to, value);
        int256 _magCorrection = magnifiedEtherPerShare.mul(value).toInt256Safe();
        magnifiedEtherCorrections[from] = magnifiedEtherCorrections[from].add(_magCorrection);
        magnifiedEtherCorrections[to] = magnifiedEtherCorrections[to].sub(_magCorrection);
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);
        magnifiedEtherCorrections[account] = magnifiedEtherCorrections[account].sub((magnifiedEtherPerShare.mul(value)).toInt256Safe());
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);
        magnifiedEtherCorrections[account] = magnifiedEtherCorrections[account].add((magnifiedEtherPerShare.mul(value)).toInt256Safe());
    }

    function _pair() internal view returns (address[] memory) {
        address[] memory pair = new address[](2);
        pair[0] = router.WETH();
        pair[1] = address(scramble);
        return pair;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0 (default value)
    }
}
