// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";


contract ICO is ReentrancyGuard {
    

    /**
     * EVENTS 
     */
    event Bought(
        address indexed beneficiary,
        address stablecoinAddress,
        uint256 stablecoinAmount,
        uint256 _gldkrmAmount
    );

    event Withdrawal(
        address indexed beneficiary,
        address stablecoinAddress,
        uint256 stablecoinAmount
    );


    /**
     * STATE VARIABLES
     */
    mapping(address => bool) public admins;
    mapping(address => bool) public authorizedStablecoins;
    mapping(address => uint256) public stablecoinBalances;
    IERC20 public gldkrm20;
    uint256 public rate; // Conversion rate for buying gldkrm20 with Stablecoin
    bool public isActive;
    bool private isgldkrmAddressUpdated = false;
    

    constructor(uint256 _rate) {
        require(_rate > 0, "Rate must be greater than 0");
        rate = _rate;
        admins[msg.sender] = true;
        isActive = true;
    }


    /**
     *  SETTERS & MODIFIERS
     */
    modifier onlyAdmins() {
        require(admins[msg.sender] == true, "Not an admin");
        _;
    }


    modifier onlyIfActivated(){
        require(isActive == true, "Method is not active");
        _;
    }


    function addAdmin(address _admin) external onlyAdmins{
        require(_admin != address(0), "Invalid address");
        require(!admins[_admin], "Already an admin");
        admins[_admin] = true;
    }


    function setIsActivated(bool _activate) external onlyAdmins{
        isActive = _activate;
    }


    function setGldkrmAddress(address _gldkrmAddress) external onlyAdmins{
        require(_gldkrmAddress != address(0), "Invalid address");
        require(isgldkrmAddressUpdated == false, "gldkrm20 can be updated only once");
        gldkrm20 = IERC20(_gldkrmAddress);
        isgldkrmAddressUpdated = true;
    }


    function authorizeStablecoin(address _stablecoinAddress) external onlyAdmins{
        require(_stablecoinAddress != address(0), "Invalid address");
        authorizedStablecoins[_stablecoinAddress] = true;
        stablecoinBalances[_stablecoinAddress] = 0;
    }


    function removeStablecoin(address _stablecoinAddress) external onlyAdmins{
        require(_stablecoinAddress != address(0), "Invalid address");
        require(stablecoinBalances[_stablecoinAddress] == 0, "Stablecoin balance should be zero");
        authorizedStablecoins[_stablecoinAddress] = false;
    }


    /**
     *  FUNCTIONS
     */
    function buy(uint256 _amount, address _stablecoinAddress) public nonReentrant onlyIfActivated{
        require(isgldkrmAddressUpdated == true, "gldkrm20 address must be setted");
        require(authorizedStablecoins[_stablecoinAddress] == true, "Stablecoin not registered");
        require(_stablecoinAddress != address(0), "Invalid address");
        IERC20 stablecoin = IERC20(_stablecoinAddress);

        uint256 userStablecoinBalance = stablecoin.balanceOf(msg.sender);
        require(userStablecoinBalance >= _amount, "Insufficient amount");

        uint256 normalizedAmount = _amount * 1e12;
        uint256 gldkrmAmount = normalizedAmount * rate;

        uint256 gldkrm20Balance = gldkrm20.balanceOf(address(this));
        require(gldkrm20Balance >= gldkrmAmount, "Not enough GLDKRM available");
        
        stablecoin.transferFrom(msg.sender, address(this), _amount);
        stablecoinBalances[_stablecoinAddress] = stablecoinBalances[_stablecoinAddress] + _amount;
        gldkrm20.transfer(msg.sender, gldkrmAmount);

        emit Bought(msg.sender, _stablecoinAddress, _amount, gldkrmAmount);
    }


    function withdrawal(uint256 _amount, address _stablecoinAddress) external onlyAdmins nonReentrant{
        require(_stablecoinAddress != address(0), "Invalid address");
        require(stablecoinBalances[_stablecoinAddress] >= _amount, "Insufficient amount");
        IERC20 stablecoin = IERC20(_stablecoinAddress);
        
        stablecoinBalances[_stablecoinAddress] = stablecoinBalances[_stablecoinAddress] - _amount;
        stablecoin.transfer(msg.sender, _amount);

        emit Withdrawal(msg.sender, _stablecoinAddress, _amount);
    }


    function gldkarmaWithdrawal() external onlyAdmins(){
        uint256 gldkrm20Balance = gldkrm20.balanceOf(address(this));
        gldkrm20.transfer(msg.sender, gldkrm20Balance);
    }


}
