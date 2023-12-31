// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./SafeMathUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./IrUSTPool.sol";
import "./ICurve.sol";
import "./ISTBT.sol";
import "./IMinter.sol";

contract BorrowLooper is AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
	using SafeMathUpgradeable for uint256;
	using SafeERC20Upgradeable for IERC20Upgradeable;

	bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
	bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
	bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

	IERC20Upgradeable public stbt;
	IERC20Upgradeable public usdc;

	ICurve public curvePool;
	IMinter public stbtMinter;
	IrUSTPool public rustpool;

	function initialize(
		address _admin,
		address _rustpool,
		address _stbt,
		address _usdc
	) public initializer {
		__AccessControl_init();
		__Pausable_init();
		__ReentrancyGuard_init();

		_setupRole(DEFAULT_ADMIN_ROLE, _admin);
		_setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
		_setRoleAdmin(MANAGER_ROLE, ADMIN_ROLE);

		_setupRole(ADMIN_ROLE, _admin);
		_setupRole(MANAGER_ROLE, _admin);

		rustpool = IrUSTPool(_rustpool);
		stbt = IERC20Upgradeable(_stbt);
		usdc = IERC20Upgradeable(_usdc);
	}

	function setCurvePool(address _curvePool) external onlyRole(MANAGER_ROLE) {
		require(_curvePool != address(0), "target address not be zero.");
		curvePool = ICurve(_curvePool);
	}

	function setSTBTMinter(address _stbtMinter) external onlyRole(MANAGER_ROLE) {
		require(_stbtMinter != address(0), "!_stbtMinter");
		stbtMinter = IMinter(_stbtMinter);
	}

	function applyFlashLiquidateProvider() external onlyRole(MANAGER_ROLE) {
		rustpool.applyFlashLiquidateProvider();
	}

	function cancelFlashLiquidateProvider() external onlyRole(MANAGER_ROLE) {
		rustpool.cancelFlashLiquidateProvider();
	}

	function depostSTBT(uint256 amount) external onlyRole(DEPOSITOR_ROLE) {
		stbt.safeTransferFrom(msg.sender, address(this), amount);
		stbt.safeApprove(address(rustpool), type(uint256).max);
		rustpool.supplySTBT(amount);
		stbt.safeApprove(address(rustpool), 0);
	}

	function withdrawSTBT(uint256 amount) external onlyRole(DEPOSITOR_ROLE) {
		rustpool.withdrawSTBT(amount);
		stbt.safeTransfer(msg.sender, stbt.balanceOf(address(this)));
	}

	function withdrawAllSTBT() external onlyRole(DEPOSITOR_ROLE) {
		rustpool.withdrawAllSTBT();
		stbt.safeTransfer(msg.sender, stbt.balanceOf(address(this)));
	}

	function depositUSDC(uint256 amount) external onlyRole(DEPOSITOR_ROLE) {
		usdc.safeTransferFrom(msg.sender, address(this), amount);
		usdc.safeApprove(address(rustpool), type(uint256).max);
		rustpool.supplyUSDC(amount);
		usdc.safeApprove(address(rustpool), 0);
	}

	function withdrawUSDC(uint256 amount) external onlyRole(DEPOSITOR_ROLE) {
		rustpool.withdrawUSDC(amount);
		usdc.safeTransfer(msg.sender, usdc.balanceOf(address(this)));
	}

	function withdrawAllUSDC() external onlyRole(DEPOSITOR_ROLE) {
		rustpool.withdrawAllUSDC();
		usdc.safeTransfer(msg.sender, usdc.balanceOf(address(this)));
	}

	function repayUSDC(uint256 amount) external onlyRole(DEPOSITOR_ROLE) {
		usdc.safeTransferFrom(msg.sender, address(this), amount);
		usdc.safeApprove(address(rustpool), type(uint256).max);
		rustpool.repayUSDC(amount);
		usdc.safeApprove(address(rustpool), 0);
	}

	function loopByCurve(
		uint256 minUSDCPrice,
		uint256 minBorrowUSDC,
		uint256 looptime
	) external onlyRole(MANAGER_ROLE) returns (uint256 totalSTBTAmount, uint256 totalUSDCBorrow) {
		uint256 safeCollateralRate = rustpool.safeCollateralRate();
		usdc.safeApprove(address(curvePool), type(uint256).max);
		stbt.safeApprove(address(rustpool), type(uint256).max);
		for (uint i = 0; i < looptime; i++) {
			uint256 availableUSDC = usdc.balanceOf(address(rustpool));
			if (availableUSDC <= minBorrowUSDC) {
				break;
			}
			uint256 borrowMAX = ((ISTBT(address(stbt))
				.getAmountByShares(rustpool.depositedSharesSTBT(address(this)))
				.mul(1e18)
				.mul(100) / safeCollateralRate) - rustpool.getBorrowedAmount(address(this))).div(
					1e12
				);
			borrowMAX = borrowMAX > availableUSDC ? availableUSDC : borrowMAX;
			uint256 dy = curvePool.get_dy_underlying(2, 0, borrowMAX);
			if (dy.mul(1e6).div(borrowMAX.mul(1e12)) < minUSDCPrice) {
				break;
			}
			rustpool.borrowUSDC(borrowMAX);
			curvePool.exchange_underlying(2, 0, borrowMAX, dy.mul(999).div(1000));
			uint256 stbtAmount = stbt.balanceOf(address(this));
			rustpool.supplySTBT(stbtAmount);
			totalSTBTAmount += stbtAmount;
			totalUSDCBorrow += borrowMAX;
			if (borrowMAX == availableUSDC) {
				break;
			}
		}
		usdc.safeApprove(address(curvePool), 0);
		stbt.safeApprove(address(rustpool), 0);
	}

	function borrowUSDCAndMintSTBT(uint256 borrowAmount) external onlyRole(MANAGER_ROLE) {
		rustpool.borrowUSDC(borrowAmount);
		usdc.safeApprove(address(stbtMinter), type(uint256).max);
		bytes32 salt = keccak256(abi.encodePacked(msg.sender, borrowAmount, block.timestamp));
		stbtMinter.mint(
			address(usdc),
			borrowAmount,
			borrowAmount.mul(1e12),
			salt,
			bytes("looper: mint stbt")
		);
		usdc.safeApprove(address(stbtMinter), 0);
	}

	function depostMintedSTBT() external onlyRole(MANAGER_ROLE) {
		stbt.safeApprove(address(rustpool), type(uint256).max);
		rustpool.supplySTBT(stbt.balanceOf(address(this)));
		stbt.safeApprove(address(rustpool), 0);
	}

	function getBorrowMax() public view returns (uint256) {
		uint256 safeCollateralRate = rustpool.safeCollateralRate();
		uint256 borrowMAX = ((ISTBT(address(stbt))
			.getAmountByShares(rustpool.depositedSharesSTBT(address(this)))
			.mul(1e18)
			.mul(100) / safeCollateralRate) - rustpool.getBorrowedAmount(address(this))).div(1e12);
		uint256 availableUSDC = usdc.balanceOf(address(rustpool));
		return borrowMAX > availableUSDC ? availableUSDC : borrowMAX;
	}

	function getDy() external view returns (uint256 dy) {
		dy = curvePool.get_dy_underlying(2, 0, getBorrowMax());
	}
}
