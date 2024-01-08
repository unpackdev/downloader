// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./SignedSafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IUniMexFactory.sol";

contract UniMexPool {
	using SignedSafeMath for int256;
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	uint256 private constant FLOAT_SCALAR = 2**64;
	IERC20 public WETH;

	struct User {
		uint256 balance;
		int256 scaledPayout;
		int256 balanceCorrection;
	}

	mapping(address => User) public users;

	IERC20 public token;
	address public factory;
	uint256 public divPerShare;
	uint256 public outstandingLoans;
	uint256 public corrPerShare;

	event OnDeposit(address indexed from, uint256 amount);
	event OnWithdraw(address indexed from, uint256 amount);
	event OnClaim(address indexed from, uint256 amount);
	event OnForceCorrection(address indexed from, uint256 amount);
	event OnTransfer(address indexed from, address indexed to, uint256 amount);
	event OnDistribute(address indexed from, uint256 amount);
	event OnBalanceCorrection(address indexed from, uint256 amount);
	event OnBorrow(address indexed from, uint256 amount);
	event OnRepay(address indexed from, uint256 amount);

	modifier onlyMargin() {
		require(IUniMexFactory(factory).allowedMargins(msg.sender), "ONLY_MARGIN_CONTRACT");
		_;
	}

	constructor() public {
		factory = msg.sender;
	}

	function totalSupply() private view returns (uint256) {
		return token.balanceOf(address(this)).add(outstandingLoans);
	}

	function initialize(address _token, address _WETH) external returns (bool) {
		require(msg.sender == factory, "ONLY_FACTORY_CONTRACT");
		token = IERC20(_token);
		WETH = IERC20(_WETH);
		return true;
	}

	/**
	 * @notice division by zero is avoided, since with an empty pool there can be no loans
	 * @notice restricted calling to margin contract
	 */
	function distribute(uint256 _amount) external onlyMargin returns (bool) {
		WETH.safeTransferFrom(address(msg.sender), address(this), _amount);
		divPerShare = divPerShare.add(
			(_amount.mul(FLOAT_SCALAR)).div(totalSupply())
		);
		emit OnDistribute(msg.sender, _amount);
		return true;
	}

	function distributeCorrection(uint256 _amount) external onlyMargin returns (bool) {
		corrPerShare = corrPerShare.add(_amount.mul(FLOAT_SCALAR).div(totalSupply()));
		emit OnBalanceCorrection(msg.sender, _amount);
		return true;
	}

	function deposit(uint256 _amount) external returns (bool) {
		token.safeTransferFrom(msg.sender, address(this), _amount);
		users[msg.sender].balance = users[msg.sender].balance.add(_amount);
		users[msg.sender].scaledPayout = users[msg.sender].scaledPayout.add(
			int256(_amount.mul(divPerShare))
		);
		users[msg.sender].balanceCorrection = users[msg.sender].balanceCorrection.add(int256(_amount.mul(corrPerShare)));
		emit OnDeposit(msg.sender, _amount);
		return true;
	}

	function withdraw(uint256 _amount) external returns (bool) {
		uint256 _balance = correctedBalanceOf(msg.sender);
		require(_balance >= _amount, "WRONG AMOUNT: CHECK CORRECTED BALANCE");
		if (outstandingLoans > 0) {
			uint256 currentUtilization =
				(outstandingLoans.mul(FLOAT_SCALAR)).div(
					(totalSupply().sub(_amount)).add(outstandingLoans)
				);
			require(
				(currentUtilization <=
					IUniMexFactory(factory).utilizationScaled(address(token))),
				"NO_LIQUIDITY"
			);
		}
		users[msg.sender].balance = users[msg.sender].balance.sub(_amount);
		users[msg.sender].scaledPayout = users[msg.sender].scaledPayout.sub(
			int256(_amount.mul(divPerShare))
		);
		users[msg.sender].balanceCorrection = users[msg.sender].balanceCorrection.sub(int256(_amount.mul(corrPerShare)));
		token.safeTransfer(msg.sender, _amount);
		emit OnWithdraw(msg.sender, _amount);
		return true;
	}

	function claim() external returns (bool) {
		uint256 _dividends = dividendsOf(msg.sender);
		require(_dividends > 0);
		users[msg.sender].scaledPayout = users[msg.sender].scaledPayout.add(
			int256(_dividends.mul(FLOAT_SCALAR))
		);
		WETH.safeTransfer(address(msg.sender), _dividends);
		emit OnClaim(msg.sender, _dividends);
		return true;
	}

/*	function correctMyBalance() external returns (bool) {
		require(balanceOf(msg.sender) > 0);
		uint256 _newBalance = correctedBalanceOf(msg.sender);
		users[msg.sender].balance = _newBalance;
		users[msg.sender].balanceCorrection = 0;
		emit OnForceCorrection(msg.sender, _newBalance);
		return true;
	}*/

	function transfer(address _to, uint256 _amount) external returns (bool) {
		return _transfer(msg.sender, _to, _amount);
	}

	function borrow(uint256 _amount) external onlyMargin returns (bool) {
		uint256 currentUtilization =
			(outstandingLoans.add(_amount).mul(FLOAT_SCALAR)).div(
				totalSupply().add(outstandingLoans)
			);
		require(
			currentUtilization <=
				IUniMexFactory(factory).utilizationScaled(address(token)),
			"POOL:NO_LIQUIDITY"
		);
		outstandingLoans = outstandingLoans.add(_amount);
		token.safeTransfer(msg.sender, _amount);
		emit OnBorrow(msg.sender, _amount);
		return true;
	}

	function repay(uint256 _amount) external onlyMargin returns (bool) {
		token.safeTransferFrom(msg.sender, address(this), _amount);
		outstandingLoans = outstandingLoans.sub(_amount);
		emit OnRepay(msg.sender, _amount);
		return true;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return users[_user].balance;
	}

	function dividendsOf(address _user) public view returns (uint256) {
		return
			uint256(
				int256(divPerShare.mul(balanceOf(_user))).sub(
					users[_user].scaledPayout
				)
			)
				.div(FLOAT_SCALAR);
	}

	function correctedBalanceOf(address _user) public view returns (uint256) {
		uint256 _balance = balanceOf(_user);
		return _balance.sub(uint256(int256(corrPerShare.mul(_balance)).sub(users[_user].balanceCorrection))
					.div(FLOAT_SCALAR));
	}

	function _transfer(address _from, address _to, uint256 _amount) internal returns (bool) {
		require(users[_from].balance >= _amount);
		users[_from].balance = users[_from].balance.sub(_amount);
		users[_from].scaledPayout = users[_from].scaledPayout.sub(
			int256(_amount.mul(divPerShare))
		);
		users[_from].balanceCorrection = users[_from].balanceCorrection.sub(
			int256(_amount.mul(corrPerShare))
		);
		users[_to].balance = users[_to].balance.add(_amount);
		users[_to].scaledPayout = users[_to].scaledPayout.add(
			int256(_amount.mul(divPerShare))
		);
		users[_to].balanceCorrection = users[_to].balanceCorrection.add(
			int256(_amount.mul(corrPerShare))
		);
		emit OnTransfer(msg.sender, _to, _amount);
		return true;
	}
}
