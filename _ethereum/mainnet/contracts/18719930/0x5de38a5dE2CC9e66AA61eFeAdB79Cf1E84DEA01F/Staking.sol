// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
            address from,
            address to,
            uint256 amount
        ) external returns (bool);
}

contract Staking {        
        uint256 internal daySeconds = 24*60*60;        
        uint256 public yieldPeriod1 = 14 * daySeconds;
        uint256 public yieldPeriod2 = 30 * daySeconds;
        uint256 public yieldPeriod3 = 60 * daySeconds;

        uint256 public yieldRate1 =  3;
        uint256 public yieldRate2 =  7;
        uint256 public yieldRate3 = 15;
        uint256 public stakeTokenDecimals = 10**18;
        uint256 public minDepositAmount = 344*stakeTokenDecimals;
        uint256 public yieldFund;
        address public stakeToken;
        address internal _owner;
        bool public stakeEnable;        

        struct Farmers {
           uint256 money;
           uint256 reward;
           uint256 timestamp;
        }
        mapping(address => Farmers) public farmers_1;
        mapping(address => Farmers) public farmers_2;
        mapping(address => Farmers) public farmers_3;
        
        constructor(address _stakeToken){
            _owner = msg.sender;
            stakeToken = _stakeToken;
        }
        modifier onlyOwner() {
            require(_owner == msg.sender, "Ownable: caller is not the owner");
            _;
        }
        function depositFund(uint256 _amount) public {  
            uint256 amount = _amount * stakeTokenDecimals;
            IERC20(stakeToken).transferFrom(msg.sender, address(this), amount);
            yieldFund = yieldFund + amount;
        }
        function deposit_1(uint256 amount) public {
            address user = msg.sender;
            require(amount>= minDepositAmount || farmers_1[user].money>= minDepositAmount, "Deposit is less than the minimum allowable");
            require(stakeEnable, "Staking disabled");
            IERC20(stakeToken).transferFrom(msg.sender, address(this), amount);
            farmers_1[user].money += amount;
            farmers_1[user].reward += amount * yieldRate1 / 100;
            farmers_1[user].timestamp = block.timestamp;
        }    
        function unstake_1() public {
            address user = msg.sender;
            require(block.timestamp  >= farmers_1[user].timestamp + yieldPeriod1, "too early for unstaking");            
            uint256 amount = farmers_1[user].money + farmers_1[user].reward;
            yieldFund = yieldFund - farmers_1[user].reward;
            farmers_1[user].money = 0;
            farmers_1[msg.sender].reward = 0;
            IERC20(stakeToken).transfer(user, amount);
        }
        function deposit_2(uint256 amount) public {
            address user = msg.sender;
            require(amount>= minDepositAmount || farmers_2[user].money>= minDepositAmount, "Deposit is less than the minimum allowable");
            require(stakeEnable, "Staking disabled");
            IERC20(stakeToken).transferFrom(msg.sender, address(this), amount);
            farmers_2[user].money += amount;
            farmers_2[user].reward += amount * yieldRate2 / 100;
            farmers_2[user].timestamp = block.timestamp;
        }    
        function unstake_2() public {
            address user = msg.sender;
            require(block.timestamp  >= farmers_2[user].timestamp + yieldPeriod2, "too early for unstaking");
            uint256 amount = farmers_2[user].money + farmers_2[user].reward;
            yieldFund = yieldFund - farmers_2[user].reward;
            farmers_2[user].money = 0;
            farmers_2[msg.sender].reward = 0;
            IERC20(stakeToken).transfer(user, amount);
        }
        function deposit_3(uint256 amount) public {
            address user = msg.sender;
            require(amount>= minDepositAmount || farmers_3[user].money>= minDepositAmount, "Deposit is less than the minimum allowable");
            require(stakeEnable, "Staking disabled");
            IERC20(stakeToken).transferFrom(msg.sender, address(this), amount);
            farmers_3[user].money += amount;
            farmers_3[user].reward += amount * yieldRate3 / 100;
            farmers_3[user].timestamp = block.timestamp;
        }    
        function unstake_3() public {
            address user = msg.sender;
            require(block.timestamp  >= farmers_3[user].timestamp + yieldPeriod3, "too early for unstaking");
            uint256 amount = farmers_3[user].money + farmers_3[user].reward;
            yieldFund = yieldFund - farmers_3[user].reward;
            farmers_3[user].money = 0;
            farmers_3[msg.sender].reward = 0;
            IERC20(stakeToken).transfer(user, amount);
        }        
        function whitelisted(address[] memory _to, uint256[] memory _amount, uint256 _type ) public onlyOwner  returns(bool) {
            require( 1 <= _type && _type <= 3, "incorrect type");           
                for(uint i = 0; i < _to.length; i++){   
                    address user = _to[i];     
                     if(_type == 1){ 
                        farmers_1[user].reward = _amount[i] * stakeTokenDecimals;
                        farmers_1[user].timestamp = block.timestamp;
                     } else if(_type == 2){
                        farmers_2[user].reward = _amount[i] * stakeTokenDecimals;
                        farmers_2[user].timestamp = block.timestamp;
                     } else if(_type == 3){
                        farmers_3[user].reward = _amount[i] * stakeTokenDecimals;
                        farmers_3[user].timestamp = block.timestamp;
                     }
                }
            return true;
        }
        function getSummStake() public view returns (uint256) {
            return IERC20(stakeToken).balanceOf(address(this)) - yieldFund;
        }
        function flipStakeEnable() public onlyOwner {
            stakeEnable = !stakeEnable;
        }
        function setYieldRates(uint256  _yieldRate1, uint256  _yieldRate2, uint256  _yieldRate3) public onlyOwner {
            yieldRate1 = _yieldRate1;
            yieldRate2 = _yieldRate2;
            yieldRate3 = _yieldRate3;
        }
        function setYieldPeriods(uint256  _yieldPeriod1, uint256  _yieldPeriod2, uint256  _yieldPeriod3) public onlyOwner {
            require(_yieldPeriod1 < 14 * daySeconds && _yieldPeriod2 < 30 * daySeconds && _yieldPeriod3 < 60 * daySeconds, "MaxDayLimit" );
            yieldPeriod1 = _yieldPeriod1;
            yieldPeriod2 = _yieldPeriod2;
            yieldPeriod3 = _yieldPeriod3;
        }
        function setMinDepositAmount(uint256  _minDepositAmount) public onlyOwner {
            minDepositAmount = _minDepositAmount * stakeTokenDecimals;
        }
        function setStakeToken(address  _stakeToken) public onlyOwner {
            stakeToken = _stakeToken;
        }
        function withdraw() external onlyOwner {
            IERC20(stakeToken).transfer(msg.sender, yieldFund);
            yieldFund = 0;
        }
        function clearETH() public onlyOwner{
            payable(msg.sender).transfer(address(this).balance);
        }
}