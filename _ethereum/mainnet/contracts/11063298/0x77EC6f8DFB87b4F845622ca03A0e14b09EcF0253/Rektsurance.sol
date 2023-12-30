pragma solidity >=0.6.2;


library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;}

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;}

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;}

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;}

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");}

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;}
}


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


contract Rektsurance {
	using SafeMath for uint256;
	
	address internal immutable REKT;
	address payable immutable ADMIN_ADDRESS;
	
	constructor(address _REKT) public {
        REKT = _REKT;
        ADMIN_ADDRESS = msg.sender;
    }
	
	uint public stakingStartTime = 1611736098;
	uint private fundAmount;
	uint public fundCloseTime = 1611736098;
	
	bool public fundOpen = false;
	bool private claimLocked = false;
	
	
	receive() external payable {
    }
	
	address private STAKERADDRESS;
	bool private StakerAddressGiven = false;
	
	//Admin function to define address of staking contract
    //Can only be called once to set staker address
    function setStakerAddress(address _STAKERADDRESS) public {
		require(msg.sender == ADMIN_ADDRESS, "Caller is not admin.");
        require(!StakerAddressGiven, "Staker Address already defined.");
        StakerAddressGiven = true;
        STAKERADDRESS = _STAKERADDRESS;
    }
	
	//take snapshot of time when staking started
	function startTimer() public {
		require(msg.sender == STAKERADDRESS, "Caller is not Staker");
		stakingStartTime = block.timestamp;
	}
	
	//allow fund opening 2.718281828459045235 weeks after staking start
	//allow withdrawals for 2.71828 days after opening
	function openFund() public {
		require(stakingStartTime + 19 days + 40 minutes + 16 seconds <= block.timestamp, "Fund cannot be opened yet.");
		require(!fundOpen, "Fund is already open.");
		fundOpen = true;
		fundAmount = address(this).balance;
		fundCloseTime = block.timestamp + 234859;
	}
	
	//function to send ETH
	function sendValue(address payable recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
	
	//claim refund based on share of REKT tokens
	function claimRefund(uint amount) public {
		require(fundOpen, "Fund is not open yet.");
		require(block.timestamp < fundCloseTime, "Fund is closed. Claims are not possible anymore.");
		require(!claimLocked, "Reentrant call, nice try!");
		claimLocked = true;
		
		//transfer tokens
		require(IERC20(REKT).transferFrom(msg.sender, address(this), amount), "Token transfer failed.");
		
		//get amount of eth to send back
		uint ethRefund = fundAmount.mul(amount).div(IERC20(REKT).totalSupply());
		//send refund
		sendValue(msg.sender, ethRefund);
		claimLocked = false;
	}
	
	//claim dev payment after claiming period has ended
	function claimAdminPayment() public {
		require(msg.sender == ADMIN_ADDRESS, "Caller is not admin.");
		require(fundCloseTime <= block.timestamp, "Fund has not been closed yet.");
		
		//send all remaining eth to admin address
		sendValue(ADMIN_ADDRESS, address(this).balance);
	}
	
	//get fund amount
	function viewFundAmount() public view returns (uint){
        return address(this).balance;
    }
}