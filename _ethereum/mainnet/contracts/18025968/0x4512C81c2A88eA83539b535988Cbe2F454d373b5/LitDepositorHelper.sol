// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./IBalancerCore.sol";
import "./ILitDepositorHelper.sol";
import "./ICrvDepositor.sol";
import "./BalInvestor.sol";

interface IWETH {
    function deposit() external payable;
}

/**
 * @title   LitDepositorHelper
 * @notice  Converts LIT -> balBPT and then wraps to liqLIT via the crvDepositor
 */
contract LitDepositorHelper is ILitDepositorHelper, BalInvestor, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public immutable crvDeposit;

    constructor(
        address _crvDeposit,
        IBalancerVault _balancerVault,
        address _lit,
        address _weth,
        bytes32 _balETHPoolId
    ) BalInvestor(_balancerVault, _lit, _weth, _balETHPoolId) {
        crvDeposit = _crvDeposit;
    }

    function setApprovals() external {
        _setApprovals();
        require(IERC20(BALANCER_POOL_TOKEN).approve(crvDeposit, type(uint256).max), "!approval");
    }

    /**
     * @dev Gets minimum output based on BPT oracle price
     * @param _amount Units of LIT to deposit
     * @param _outputBps Multiplier where 100% == 10000, 99.5% == 9950 and 98% == 9800
     * @param _asset Address of the asset to query minOut
     * @return minOut Units of BPT to expect as output
     */
    function getMinOut(
        uint256 _amount,
        uint256 _outputBps,
        address _asset
    ) external view returns (uint256) {
        require(_asset == LIT || _asset == ETH || _asset == WETH, "!asset");
        return (_asset == LIT) ? _getMinOut(_amount, _outputBps, 1) : _getMinOut(_amount, _outputBps, 0);
    }

    function deposit(
        uint256 _amount,
        uint256 _minOut,
        bool _lock,
        address _stakeAddress,
        address _asset
    ) external payable nonReentrant returns (uint256 bptOut) {
        bptOut = _depositFor(msg.sender, _amount, _minOut, _lock, _stakeAddress, _asset);
    }

    function depositFor(
        address _for,
        uint256 _amount,
        uint256 _minOut,
        bool _lock,
        address _stakeAddress,
        address _asset
    ) external payable nonReentrant returns (uint256 bptOut) {
        bptOut = _depositFor(_for, _amount, _minOut, _lock, _stakeAddress, _asset);
    }

    function _depositFor(
        address _for,
        uint256 _amount,
        uint256 _minOut,
        bool _lock,
        address _stakeAddress,
        address _asset
    ) internal returns (uint256 bptOut) {
        require(_asset == LIT || _asset == ETH || _asset == WETH, "!asset");

        if (_asset == LIT) {
            IERC20(LIT).safeTransferFrom(msg.sender, address(this), _amount);
            _investSingleToPool(_amount, _minOut, 1);
        } else if (_asset == ETH) {
            IWETH(WETH).deposit{ value: _amount }();
            _investSingleToPool(_amount, _minOut, 0);
        } else {
            IERC20(WETH).safeTransferFrom(msg.sender, address(this), _amount);
            _investSingleToPool(_amount, _minOut, 0);
        }

        bptOut = IERC20(BALANCER_POOL_TOKEN).balanceOf(address(this));
        ICrvDepositor(crvDeposit).depositFor(_for, bptOut, _lock, _stakeAddress);
    }

    /**
     * @dev Converts LIT to LIT/WETH and sends BPT to user
     * @param _amount Units of LIT to deposit
     * @param _minOut Units of BPT to expect as output
     */
    function convertLitToBpt(uint256 _amount, uint256 _minOut) external returns (uint256 bptOut) {
        IERC20(LIT).safeTransferFrom(msg.sender, address(this), _amount);
        _investSingleToPool(_amount, _minOut, 1);

        bptOut = IERC20(BALANCER_POOL_TOKEN).balanceOf(address(this));
        if (bptOut > 0) {
            IERC20(BALANCER_POOL_TOKEN).safeTransfer(msg.sender, bptOut);
        }
    }

    /**
     * @dev Converts WETH to LIT/WETH and sends BPT to user
     * @param _amount Units of WETH to deposit
     * @param _minOut Units of BPT to expect as output
     */
    function convertWethToBpt(uint256 _amount, uint256 _minOut) external returns (uint256 bptOut) {
        IERC20(WETH).safeTransferFrom(msg.sender, address(this), _amount);
        _investSingleToPool(_amount, _minOut, 0);

        bptOut = IERC20(BALANCER_POOL_TOKEN).balanceOf(address(this));
        if (bptOut > 0) {
            IERC20(BALANCER_POOL_TOKEN).safeTransfer(msg.sender, bptOut);
        }
    }

    /**
     * @dev Converts ETH to LIT/WETH and sends BPT to user
     * @param _minOut Units of BPT to expect as output
     */
    function convertEthToBpt(uint256 _minOut) external payable nonReentrant returns (uint256 bptOut) {
        IWETH(WETH).deposit{ value: msg.value }();
        _investSingleToPool(msg.value, _minOut, 0);

        bptOut = IERC20(BALANCER_POOL_TOKEN).balanceOf(address(this));
        if (bptOut > 0) {
            IERC20(BALANCER_POOL_TOKEN).safeTransfer(msg.sender, bptOut);
        }
    }
}
