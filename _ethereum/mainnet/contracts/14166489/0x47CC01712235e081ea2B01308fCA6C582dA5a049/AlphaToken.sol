// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC20.sol";
import "./Ownable.sol";
import "./Math.sol";

/**
 * @title AlphaToken
 * @dev Implementation of the LP Token "ALPHA".
 */

contract AlphaToken is ERC20, Ownable {

    // Proxy address
    address alphaStrategy;
    address admin;

    // Deposit Mapping
    mapping(address => uint256[]) public  amountDepositPerAddress;
    mapping(address => uint256[]) public  timeDepositPerAddress; 
    constructor() ERC20("Formation Fi: ALPHA TOKEN", "ALPHA") {}

    // Modifiers 
    modifier onlyProxy() {
        require(
            (alphaStrategy != address(0)) && (admin != address(0)),
            "Formation.Fi: proxy is the zero address"
        );

        require(
            (msg.sender == alphaStrategy) || (msg.sender == admin),
             "Formation.Fi: Caller is not the proxy"
        );
        _;
    }
    modifier onlyAlphaStrategy() {
        require(alphaStrategy != address(0),
            "Formation.Fi: alphaStrategy is the zero address"
        );

        require(msg.sender == alphaStrategy,
             "Formation.Fi: Caller is not the alphaStrategy"
        );
        _;
    }

    // Setter functions
    function setAlphaStrategy(address _alphaStrategy) external onlyOwner {
        require(
            _alphaStrategy!= address(0),
            "Formation.Fi: alphaStrategy is the zero address"
        );
         alphaStrategy = _alphaStrategy;
    } 
    function setAdmin(address _admin) external onlyOwner {
        require(
            _admin!= address(0),
            "Formation.Fi: admin is the zero address"
        );
         admin = _admin;
    } 

    function addTimeDeposit(address _account, uint256 _time) external onlyAlphaStrategy {
         require(
            _account!= address(0),
            "Formation.Fi: account is the zero address"
        );
         require(
            _time!= 0,
            "Formation.Fi: deposit time is zero"
        );
        timeDepositPerAddress[_account].push(_time);
    } 

    function addAmountDeposit(address _account, uint256 _amount) external onlyAlphaStrategy {
        require(
            _account!= address(0),
            "Formation.Fi: account is the zero address"
        );
        require(
            _amount!= 0,
            "Formation.Fi: deposit amount is zero"
        );
        amountDepositPerAddress[_account].push(_amount);

    } 
    
    // functions "mint" and "burn"
   function mint(address _account, uint256 _amount) external onlyProxy {
       require(
          _account!= address(0),
           "Formation.Fi: account is the zero address"
        );
         require(
            _amount!= 0,
            "Formation.Fi: amount is zero"
        );
       _mint(_account,  _amount);
   }

    function burn(address _account, uint256 _amount) external onlyProxy {
        require(
            _account!= address(0),
            "Formation.Fi: account is the zero address"
        );
         require(
            _amount!= 0,
            "Formation.Fi: amount is zero"
        );
        _burn( _account, _amount);
    }
    
    // Check the user lock up condition for his withdrawal request

    function ChecklWithdrawalRequest(address _account, uint256 _amount, uint256 _period) 
     external view returns (bool){

        require(
            _account!= address(0),
            "Formation.Fi: account is the zero address"
        );
        require(
           _amount!= 0,
            "Formation.Fi: amount is zero"
        );
        uint256 [] memory _amountDeposit = amountDepositPerAddress[_account];
        uint256 [] memory _timeDeposit = timeDepositPerAddress[_account];
        uint256 _amountTotal = 0;
        for (uint256 i = 0; i < _amountDeposit.length; i++) {
            require ((block.timestamp - _timeDeposit[i]) >= _period, 
            "Formation.Fi: user position locked");
            if (_amount<= (_amountTotal + _amountDeposit[i])){
                break; 
            }
            _amountTotal = _amountTotal + _amountDeposit[i];
        }
        return true;
    }

    // Functions to update  users deposit data 
    function updateDepositDataExternal( address _account,  uint256 _amount) 
        external onlyAlphaStrategy {
         updateDepositData(_account,  _amount);
    }
    function updateDepositData( address _account,  uint256 _amount) internal {
        require(
            _account!= address(0),
            "Formation.Fi: account is the zero address"
        );
        require(
            _amount!= 0,
            "Formation.Fi: amount is zero"
        );
        uint256 [] memory _amountDeposit = amountDepositPerAddress[ _account];
        uint256 _amountlocal = 0;
        uint256 _amountTotal = 0;
        uint256 _newAmount;
        for (uint256 i = 0; i < _amountDeposit.length; i++) {
            _amountlocal  = Math.min(_amountDeposit[i], _amount- _amountTotal);
            _amountTotal = _amountTotal +  _amountlocal;
            _newAmount = _amountDeposit[i] - _amountlocal;
            amountDepositPerAddress[_account][i] = _newAmount;
            if (_newAmount==0){
               deleteDepositData(_account, i);
            }
            if (_amountTotal == _amount){
               break; 
            }
        }
    }
    // Delete deposit data 
    function deleteDepositData(address _account, uint256 _ind) internal {
        require(
            _account!= address(0),
            "Formation.Fi: account is the zero address"
        );
        uint256 size = amountDepositPerAddress[_account].length-1;
        
        require( _ind <= size,
            "Formation.Fi: index is out of the range"
        );
        for (uint256 i = _ind; i< size; i++){
            amountDepositPerAddress[ _account][i] = amountDepositPerAddress[ _account][i+1];
            timeDepositPerAddress[ _account][i] = timeDepositPerAddress[ _account][i+1];
        }
        amountDepositPerAddress[ _account].pop();
        timeDepositPerAddress[ _account].pop();
       
    }
   
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
      ) internal virtual override{
      
       if ((to != address(0)) && (to != alphaStrategy) 
       && (to != admin) && (from != address(0)) )
       {
          updateDepositData(from, amount);
          amountDepositPerAddress[to].push(amount);
          timeDepositPerAddress[to].push(block.timestamp);
        }
    }

}
