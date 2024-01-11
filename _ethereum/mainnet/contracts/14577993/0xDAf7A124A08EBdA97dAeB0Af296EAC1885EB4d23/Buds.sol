// SPDX-License-Identifier: MIT


pragma solidity ^0.8.7;



import "./ERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";
  


interface IBudsSource {
  function getAccumulatedAmount(address staker) external view returns (uint256);
  function getTax( uint amount) external;
}


contract Buds is Initializable, ERC20Upgradeable,  ReentrancyGuardUpgradeable {
    IBudsSource public BudsSource;
    uint256 public constant MAX_TAX_VALUE = 100;
    uint256 public withdrawTaxAmount;
    bool public withdrawTaxCollectionStopped;
    address public owner;
    bool public isPaused;
    bool public isDepositPaused;
    bool public isWithdrawPaused;
    bool public isTransferPaused;

    mapping (address => bool) private _isAuthorised;
    address[] public authorisedLog;

    mapping(address => uint256) public depositedAmount;
    mapping(address => uint256) public spentAmount;

    modifier onlyAuthorised {
      require(_isAuthorised[_msgSender()], "Not Authorised");
      _;
    }

    modifier whenNotPaused {
      require(!isPaused, "Transfers paused!");
      _;
    }

    modifier onlyOwner(){
      require(_msgSender() == owner);
      _;
    }

    event Withdraw(address indexed userAddress, uint256 amount, uint256 tax);
    event Deposit(address indexed userAddress, uint256 amount);
    event DepositFor(address indexed caller, address indexed userAddress, uint256 amount);
    event Spend(address indexed caller, address indexed userAddress, uint256 amount);
    event InternalTransfer(address indexed from, address indexed to, uint256 amount);

    function initialize(address _source,address _owner)  public initializer {
      __ERC20_init("BUDS", "BUDS");
      _isAuthorised[_msgSender()] = true;
      
      isWithdrawPaused = true;
      _mint(_owner, 1000000 * 10 **18);
      owner=_owner;
      withdrawTaxAmount = 25;
      BudsSource = IBudsSource(_source);
    }

   
    function getUserBalance(address user) public view returns (uint256) {

      uint num=BudsSource.getAccumulatedAmount(user)  + depositedAmount[user];
      if(num > spentAmount[user]){
        return num - spentAmount[user];
      }
      else {
        return 0;
      }
      
    }

  
    function depositBuds(uint256 amount) public nonReentrant whenNotPaused {
      require(!isDepositPaused, "Deposit Paused");
      require(balanceOf(_msgSender()) >= amount, "Insufficient balance");

      _burn(_msgSender(), amount);
      depositedAmount[_msgSender()] += amount;

      emit Deposit(
        _msgSender(),
        amount
      );
    }

   
    function withdrawBuds(uint256 amount) public nonReentrant whenNotPaused {
      require(!isWithdrawPaused, "Withdraw Paused");
      
      require(getUserBalance(_msgSender()) >= amount, "Insufficient balance");
      uint256 tax = withdrawTaxCollectionStopped ? 0 : (amount * withdrawTaxAmount) / 100;
      BudsSource.getTax(tax);
      spentAmount[_msgSender()] += amount;
      
      _mint(_msgSender(), (amount - tax));

       BudsSource.getTax(tax);
      emit Withdraw(
        _msgSender(),
        amount,
        tax
      );
    }

   
    function transferBuds(address to, uint256 amount) public nonReentrant whenNotPaused {
      require(!isTransferPaused, "Transfer Paused");
      require(getUserBalance(_msgSender()) >= amount, "Insufficient balance");

      spentAmount[_msgSender()] += amount;
      depositedAmount[to] += amount;

      emit InternalTransfer(
        _msgSender(),
        to,
        amount
      );
    }

   
    function spendBuds(address user, uint256 amount) external onlyAuthorised nonReentrant {
      require(getUserBalance(user) >= amount, "Insufficient balance");
      

      spentAmount[user] += amount;
      

      emit Spend(
        _msgSender(),
        user,
        amount
      );
    }

    function depositBudsFor(address user, uint256 amount) public onlyAuthorised nonReentrant {
      _depositBudsFor(user, amount);
    }

    function distributeBuds(address[] memory user, uint256[] memory amount) public onlyAuthorised nonReentrant {
      require(user.length == amount.length, "Wrong arrays passed");

      for (uint256 i; i < user.length; i++) {
        _depositBudsFor(user[i], amount[i]);
      }
    }

    function _depositBudsFor(address user, uint256 amount) internal {
      require(user != address(0), "Deposit to 0 address");
      depositedAmount[user] += amount;

      emit DepositFor(
        _msgSender(),
        user,
        amount
      );
    }

  
    function mintFor(address user, uint256 amount) external onlyAuthorised nonReentrant {
     
      _mint(user, amount);
    }

    function authorise(address addressToAuth) public onlyOwner {
      _isAuthorised[addressToAuth] = true;
      authorisedLog.push(addressToAuth);
    }

    function unauthorise(address addressToUnAuth) public onlyOwner {
      _isAuthorised[addressToUnAuth] = false;
    }


    function changeBudsSourceContract(address _source) public onlyOwner {
      BudsSource = IBudsSource(_source);
      authorise(_source);
    }

    function updateWithdrawTaxAmount(uint256 _taxAmount) public onlyOwner {
      require(_taxAmount < MAX_TAX_VALUE, "Wrong value passed");
      withdrawTaxAmount = _taxAmount;
    }

    function stopTaxCollectionOnWithdraw(bool _stop) public onlyOwner {
      withdrawTaxCollectionStopped = _stop;
    }

    function pauseGameBuds(bool _pause) public onlyOwner {
      isPaused = _pause;
    }

    function pauseTransfers(bool _pause) public onlyOwner {
      isTransferPaused = _pause;
    }

    function pauseWithdraw(bool _pause) public onlyOwner {
      isWithdrawPaused = _pause;
    }

    function pauseDeposits(bool _pause) public onlyOwner {
      isDepositPaused = _pause;
    }

    function rescue() external onlyOwner {
      payable(owner).transfer(address(this).balance);
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
       
        owner = newOwner;
        
    }
}

