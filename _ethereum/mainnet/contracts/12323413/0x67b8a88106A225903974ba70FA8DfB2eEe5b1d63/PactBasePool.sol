// "SPDX-License-Identifier: MIT"
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Whitelist.sol";
import "./TxStorage.sol";
import "./IUniswapOracle.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./TransferHelper.sol";


contract PactBasePool is Whitelist, TxStorage {
    
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public _oracleAddress;
    address public _PACT;

    uint public _minBuy;
    uint public _price;

    event Deposit(uint amount, uint price);
    event Withdraw(uint tokensAmount, uint price);
    
    constructor (
        address governanceAddress,
        address oracleAddress,
        address PACT,
        uint minBuy

    ) public GovernanceOwnable(governanceAddress) {
        require (oracleAddress != address(0), "ORACLE ADDRESS SHOULD BE NOT NULL");
        require (PACT != address(0), "PACT ADDRESS SHOULD BE NOT NULL");

        _oracleAddress = oracleAddress;
        _PACT = PACT;
        
        _minBuy = minBuy == 0 ? 10000e18 : minBuy;
    }
    
    
    function buylimitsUpdate( uint minLimit) public onlyGovernance {
        _minBuy = minLimit;
    }
    
    
    function changeOracleAddress (address oracleAddress) 
      public 
      onlyGovernance {
        require (oracleAddress != address(0), "NEW ORACLE ADDRESS SHOULD BE NOT NULL");

        _oracleAddress = oracleAddress;
    }


	function calcPriceEthPact(uint amountInEth) public view returns (uint) {
        uint price = IUniswapOracle(_oracleAddress).consultAB(1e18);
        if (price > 1e18){
            return amountInEth.mul(price.div(1e18));
        }
        return amountInEth.mul(uint(1e18).div(price));
	}

	function calcPricePactEth(uint amountInPact) public view returns (uint) {
        uint price = IUniswapOracle(_oracleAddress).consultAB(1e18);
        if (price > 1e18){
            return amountInPact.div(price.div(1e18));
        }
        return amountInPact.div(uint(1e18).div(price));
	}


    function changeEthToToken() public onlyWhitelisted payable {
        uint amountIn = msg.value;
        IUniswapOracle(_oracleAddress).update();
        uint tokensAmount = calcPriceEthPact(amountIn);
        IERC20 PACT = IERC20(_PACT);

        require(tokensAmount >= _minBuy, "BUY LIMIT");
        require(tokensAmount <= PACT.balanceOf(address(this)), "NOT ENOUGH PACT TOKENS ON BASEPOOl CONTRACT BALANCE");

        PACT.safeTransfer(msg.sender, tokensAmount);
        transactionAdd(tokensAmount,amountIn);

        emit Deposit(tokensAmount, amountIn);
    }
    

    function returnToken(uint index) external onlyWhitelisted {
        IERC20 PACT = IERC20(_PACT);
        checkTrransaction(msg.sender , index);
        (uint amount, uint price,,,) = getTransaction(msg.sender , index);
        
        require(address(this).balance >= price, "NOT ENOUGH ETH ON BASEPOOl CONTRACT BALANCE");
        require(PACT.allowance(msg.sender, address(this)) >= amount, "NOT ENOUGH DELEGATED PACT TOKENS ON DESTINATION BALANCE");

        closedTransaction(msg.sender, index);
        PACT.safeTransferFrom(msg.sender, amount);
        TransferHelper.safeTransferETH(msg.sender, price);

        emit Withdraw(amount, price);
    }


    function withdrawEthForExpiredTransaction(address to) public onlyGovernance{
        uint actualBalanceOfTransactions = amountOfActualTransactions();
        uint balance = address(this).balance;
        require(balance > actualBalanceOfTransactions,"");
        TransferHelper.safeTransferETH(to,balance.sub(actualBalanceOfTransactions));   
    }
    
} 