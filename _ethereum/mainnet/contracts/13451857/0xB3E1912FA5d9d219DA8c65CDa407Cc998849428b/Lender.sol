// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC20.sol";
import { ECDSA } from  "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IwETH.sol";

interface IBorrower {
	function feePaid(address) external view returns(uint256);
	function getFee(address lender, uint256 amount) external returns(uint256);
}

contract Lender is Ownable, ReentrancyGuard, ERC20 {

	IwETH public wETH;
	uint256 public borrowCoefficient;
	uint256 public liquidationCoefficient;
	uint256 public liquidationBonusCoefficient;
	address public feeSigner;

	event Deposit(address indexed lender, uint256 amount);
	event Withdraw(address indexed lender, uint256 amount);
	event FeePaid(address indexed lender, address indexed borrower, uint256 amount);

	modifier onlyAmountGreaterThanZero(uint256 amount_) {
		require(amount_ != 0, "amount must be greater than 0");
		_;
	}

	constructor(
		string memory name_, 
		string memory symbol_,
		address wETH_,
		uint256 borrowCoefficient_,
		uint256 liquidationCoefficient_,
		uint256 liquidationBonusCoefficient_,
		address feeSigner_
	) 
		ERC20(name_, symbol_)
	{
		wETH = IwETH(wETH_);
		borrowCoefficient = borrowCoefficient_;
		liquidationCoefficient = liquidationCoefficient_;
		liquidationBonusCoefficient = liquidationBonusCoefficient_;
		feeSigner = feeSigner_;
	}

	// for wETH withdraw
	receive() external payable {
	}
	
	/***************************************
					ADMIN
	****************************************/

	function setBorrowCoefficient(uint256 borrowCoefficient_)
		external
		onlyOwner
	{
		borrowCoefficient = borrowCoefficient_;
	}

	function setLiquidationCoefficient(uint256 liquidationCoefficient_)
		external
		onlyOwner
	{
		liquidationCoefficient = liquidationCoefficient_;
	}

	function setLiquidationBonusCoefficient(uint256 liquidationBonusCoefficient_)
		external
		onlyOwner
	{
		liquidationBonusCoefficient = liquidationBonusCoefficient_;
	}

	function setFeeSigner(address feeSigner_)
		external
		onlyOwner
	{
		feeSigner = feeSigner_;
	}

	function approveBorrower(address borrower_, uint256 amount_)
		external
		onlyOwner
	{
		wETH.approve(borrower_, amount_);
	}

	/***************************************
					ACTIONS
	****************************************/
	
	function deposit(uint256 amount_, bool wrap_)
		external
		payable
		nonReentrant
		onlyAmountGreaterThanZero(amount_)
	{		
		if(wrap_){
			require(amount_ == msg.value, "wrong amount");
			wETH.deposit{value: msg.value}();
		}else{
			require(msg.value == 0, "non-zero msg.value");
			wETH.transferFrom(msg.sender, address(this), amount_);
		}
		_mint(msg.sender, amount_);
		emit Deposit(msg.sender, amount_);
	}

	function withdraw(uint256 amount_, bool unwrap_)
		external
		nonReentrant
		onlyAmountGreaterThanZero(amount_)
	{
		require(amount_ <= wETH.balanceOf(address(this)), "not enough weth balance on contract");
		_burn(msg.sender, amount_);
		if(unwrap_){
			wETH.withdraw(amount_);
			(bool _success, ) = msg.sender.call{value: amount_}("");
			require(_success, "transfer failed");
		}else{
			wETH.transfer(msg.sender, amount_);
		}
		emit Withdraw(msg.sender, amount_);
	}

	function getFee(address lender_, address borrower_, uint256 amount_, bytes calldata signature_)
		external
		nonReentrant
	{
		bytes32 _hash = keccak256(abi.encodePacked(lender_, borrower_, amount_));
		require(ECDSA.recover(_hash, signature_) == feeSigner, "wrong signature");
		uint256 _feePaid = IBorrower(borrower_).getFee(lender_, amount_);
		emit FeePaid(lender_, borrower_, _feePaid);
	}

	/***************************************
					GETTERS
	****************************************/

	function getFeePaid(address lender_, address borrower_)
		external
		view
		returns(uint256)
	{
		return IBorrower(borrower_).feePaid(lender_);
	}	

}
