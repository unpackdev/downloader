// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity 0.8.11;
import "./OwnableUpgradeable.sol";
import "./Counters.sol";
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
contract DepositeContract is OwnableUpgradeable {
    address public _fundReceiver;
    
    mapping(address => bool) public _supportTokens;
    mapping(address => bool) public _manager;
    
    // ERC20 token -> user -> amount 
    mapping(address => mapping(address => uint256)) public _tokenDepositeRecord;
    // ERC20 token -> amount 
    mapping(address => uint256) public _totalDeposite;

    // ERC20 token ->  user ->  orderid 
    mapping(address => mapping(uint256 => address)) public _userByOrderIDs;


    event managerRoleGranded(address indexed newManagerAddress, address indexed authorizer);
    event managerRoleRevoked(address indexed rovokedManagerAddress, address indexed authorizer);
    event supportTokenGranded(address indexed newToken, address indexed authorizer);
    event supportTokenRevoked(address indexed rovokedToken, address indexed authorizer);
    event userDeposite(address indexed depositeMaker,address depositeToken, uint256 indexed depositeAmount, uint256 indexed orderID);
    event managerWithdraw(address indexed manager,address indexed withdrawToken, uint256 indexed withdrawAmount);
    event fundsTransfered(address indexed fundReceiver, address indexed fundToken, uint256 indexed fundAmount);

    function grantManagerRole(address addr_) public onlyOwner {
        require(addr_ != address(0), 'invalid address');
        _manager[addr_] = true;
        emit managerRoleGranded(addr_, msg.sender);
    }

    function revokeManagerRole(address addr_) public onlyOwner {
        require(addr_ != address(0), 'invalid address');
        _manager[addr_] = false;
        emit managerRoleRevoked(addr_, msg.sender);
    }

    function grantSupportToken(address addr_) public {
        require(addr_ != address(0), 'invalid address');
        require(_manager[msg.sender], "Only Manager allowed");
        _supportTokens[addr_] = true;
        emit supportTokenGranded(addr_, msg.sender);
    } 

    function revokeSupportToken(address addr_) public {
        require(addr_ != address(0), 'invalid address');
        require(_manager[msg.sender], "Only Manager allowed");
        _supportTokens[addr_] = false;
        emit supportTokenRevoked(addr_, msg.sender);
    }

    function changeFundsReceiver(address newAddress) public onlyOwner {
        require(newAddress != address(0), 'invalid address');
        _fundReceiver = newAddress;
    }

    function initialize(address fundReceiver, address usdtAddress) public virtual initializer {
        require(fundReceiver != address(0), "fund receiver can not be 0");
        _fundReceiver = fundReceiver;
        __Ownable_init();
        grantManagerRole(_msgSender());
        grantSupportToken(usdtAddress);
    }




    function deposite(uint256 amount, address _supportToken, uint256 _orderid) external {

        require(_supportTokens[_supportToken], "Only SupportTokens allowed");
        IERC20(_supportToken).transferFrom(msg.sender, address(this), amount);
        // token -> user -> amount
        _tokenDepositeRecord[_supportToken][msg.sender] += amount;
        _totalDeposite[_supportToken] += amount;

        _userByOrderIDs[_supportToken][_orderid] =  msg.sender;
        // user -> orderid
        emit userDeposite(msg.sender, _supportToken, amount, _orderid);
    }


    function withdraw(address _withdrawToken, uint256 _withdrawAmount) external {
        require(_manager[msg.sender], "Only Manager allowed");
        require(_supportTokens[_withdrawToken], "Only SupportTokens allowed");
        require(_totalDeposite[_withdrawToken] >= _withdrawAmount, "Insufficient balance");

        // to manager
        IERC20(_withdrawToken).transfer(msg.sender, _withdrawAmount);

        emit managerWithdraw(msg.sender, _withdrawToken, _withdrawAmount);
        _totalDeposite[_withdrawToken] -= _withdrawAmount;
    }


    function transferFunds(address _transferToken, uint256 _transferAmount) external {
        require(_manager[msg.sender], "Only Manager allowed");
        require(_supportTokens[_transferToken], "Only SupportTokens allowed");
        require(_totalDeposite[_transferToken] >= _transferAmount, "Insufficient balance");

        // to fundReceiver
        IERC20(_transferToken).transfer(_fundReceiver, _transferAmount);

        emit fundsTransfered(_fundReceiver, _transferToken, _transferAmount);
        _totalDeposite[_transferToken] -= _transferAmount;
    }


    function checkDepositeAmount(address _supportToken) external view returns (uint256){
        return _tokenDepositeRecord[_supportToken][msg.sender];
    }


    function checkIsManager(address addr_) external view returns (bool){
        return _manager[addr_];
    }

    function getVersion() pure external returns (uint256){
        return 1;
    }
}
