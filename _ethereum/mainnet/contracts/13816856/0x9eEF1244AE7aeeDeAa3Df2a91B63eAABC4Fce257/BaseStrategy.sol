// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";

import "./IController.sol";

abstract contract BaseStrategy {
	using SafeERC20 for IERC20;
	using Address for address;

	uint256 public performanceFee = 1500;
	uint256 public withdrawalFee = 50;
	uint256 public constant FEE_DENOMINATOR = 10000;

	address public governance;
	address public controller;
	address public strategist;
	address public want;

	uint256 public earned;

	event Harvested(uint256 wantEarned, uint256 lifetimeEarned);

	constructor(address _controller, address _want) {
		governance = msg.sender;
		strategist = msg.sender;
		controller = _controller;
		want = _want;
	}

	modifier onlyGovernance() {
		require(msg.sender == governance, "!governance");
		_;
	}

	modifier onlyController() {
		require(msg.sender == controller, "!controller");
		_;
	}

	modifier onlyAdmin() {
		require(msg.sender == controller || msg.sender == strategist, "!admin");
		_;
	}

	function clean(IERC20 _asset) external onlyGovernance returns (uint256 balance) {
		require(want != address(_asset), "want");
		balance = _asset.balanceOf(address(this));
		_asset.safeTransfer(governance, balance);
	}

	function withdraw(uint256 _amount) external virtual onlyController {
		uint256 _balance = IERC20(want).balanceOf(address(this));

		if (_balance < _amount) {
			_withdrawSome(_amount - _balance);
		}

		uint256 _fee = _amount * withdrawalFee / FEE_DENOMINATOR;
		IERC20(want).safeTransfer(IController(controller).rewards(), _fee);
		address _vault = IController(controller).vaults(address(want));
		require(_vault != address(0), "!vault");
		IERC20(want).safeTransfer(_vault, _amount - _fee);
	}

	function withdrawAll() external virtual onlyController returns (uint256 balance) {
		_withdrawSome(balanceOfPool());

		balance = IERC20(want).balanceOf(address(this));

		address _vault = IController(controller).vaults(address(want));
		require(_vault != address(0), "!vault");
		IERC20(want).safeTransfer(_vault, balance);
	}

	function balanceOfWant() public view returns (uint256) {
		return IERC20(want).balanceOf(address(this));
	}

	function balanceOf() public view returns (uint256) {
		return balanceOfWant() + balanceOfPool();
	}

	function setWithdrawalFee(uint256 _withdrawalFee) external onlyGovernance {
		withdrawalFee = _withdrawalFee;
	}

	function setPerformanceFee(uint256 _performanceFee) external onlyGovernance {
		performanceFee = _performanceFee;
	}

	function setStrategist(address _strategist) external onlyGovernance {
		strategist = _strategist;
	}

	function setGovernance(address _governance) external onlyGovernance {
		governance = _governance;
	}

	function setController(address _controller) external onlyGovernance {
		controller = _controller;
	}

	/* Implemented by strategy */

	function name() external pure virtual returns (string memory);

	function balanceOfPool() public view virtual returns (uint256);

	function deposit() public virtual;

	function _withdrawSome(uint256 _amount) internal virtual;
}
