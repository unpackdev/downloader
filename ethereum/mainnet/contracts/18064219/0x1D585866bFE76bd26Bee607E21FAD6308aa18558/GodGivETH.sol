// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract GodGivETH {
    using SafeMath for uint256;
    IERC20 token;
    address public owner;
    address public god;
    uint counter = 1;
    uint public ETHfund = 0;
    uint public minPercent = 0;
    uint public maxPercent = 30;
    uint public ETHLockDays = 1;
    uint public prayerCost  = 10000 * 10** 9;
    mapping(address => uint) public WorshipperToEth;
    mapping(address => uint) public WorshipperToTime;
    address[] public prayers;
    event Funding(uint value);
    event Pray(address worshipper, uint value);
    event Withdrawal(address worshipper, uint value);
    event Judgement(address worshipper, uint decision, uint value);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    modifier onlyGod() {
        require(msg.sender == god, "not authorized");
        _;
    }

    receive() external payable {
    }

    function fund_god() external payable
    {
        ETHfund = ETHfund + msg.value;
        emit Funding(ETHfund);
    }

    function withdrawETH() external 
    {
        require(WorshipperToEth[msg.sender] > 0,"No ETH has been giveth");
        require(WorshipperToTime[msg.sender] + (ETHLockDays * 1 days)  > block.timestamp,"ETH is still locked and might be taketh away");
        uint amount = WorshipperToEth[msg.sender];
        WorshipperToEth[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    function pray(uint amount) external
    {
        uint dec_amount = amount * 10** 9;
        require(dec_amount >= prayerCost,"Not enough to pray");
        require(token.balanceOf(msg.sender) >= dec_amount,"Not enough balance");

        bool success = token.transferFrom(msg.sender, address(this), dec_amount);
        require(success, "Could not transfer token. Missing approval");
        uint prayers_amount = dec_amount / prayerCost;
        
        for(uint i = 0; i < prayers_amount; i++){
            prayers.push(msg.sender);
        }
        emit Pray(msg.sender, prayers_amount);
    }

    function getPrayers() external view returns (address[] memory)
    {
        return prayers;
    }

    function playerAllowance(address worshipper) external view returns (uint)
    {
        return token.allowance(worshipper, address(this));
    }
    

    function unPray(uint index) external
    {
        require(prayers[index] == msg.sender,"Not your prayer");
        prayers[index] = prayers[prayers.length - 1];
        prayers.pop();
        token.transfer(msg.sender, prayerCost);
    }


    function judge() external onlyGod()
    {
        uint index = randomBetween(0,prayers.length);
        uint decision_index = randomBetween(0,4);

        address chosen = prayers[index];

        uint random_amount = 0;

        // GivETH
        if(decision_index == 0)
        {
            random_amount = randomBetween(minPercent,ETHfund.mul(maxPercent).div(100));

            if(random_amount > 0)
            {
                ETHfund -= random_amount;
                WorshipperToEth[chosen] += random_amount;
                WorshipperToTime[chosen] = block.timestamp;
            }
        }
        // Burn Prayer
        if(decision_index == 1)
        {
            prayers[index] = prayers[prayers.length - 1];
            prayers.pop();

            token.transfer(address(0x0000dead), prayerCost);
        }
        // TakETH away
        if(decision_index == 2)
        {
            if(WorshipperToEth[chosen] > 0)
            {
                random_amount = randomBetween(minPercent,WorshipperToEth[chosen].mul(maxPercent).div(100));

                WorshipperToEth[chosen] -= random_amount;
                ETHfund += random_amount;
            }
        }
        // Sleep

        emit Judgement(chosen, decision_index, random_amount);
    }

    function setTokenAddress(address payable _tokenAddress) external onlyOwner() {
       token = IERC20(address(_tokenAddress));
    }

    function setLockDays(uint _days) external onlyOwner() {
       ETHLockDays = _days;
    }
    
    function setMinPercent(uint percent) external onlyOwner() {
       minPercent = percent;
    }

    function setMaxPercent(uint percent) external onlyOwner() {
       maxPercent = percent;
    }
    function setGodAddress(address _godAddress) external onlyOwner() {
       god = _godAddress;
    }

    function withdrawStuckETH() external onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance } ("");
        require(success, "Transfer failed.");
    }

    function withdrawStuckToken() external onlyOwner {
        uint balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function randomBetween(uint min, uint max) internal returns (uint) 
    {
        counter++;
        uint random = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty, counter, gasleft()))) % (max - min);
        return random + min;
    }

}