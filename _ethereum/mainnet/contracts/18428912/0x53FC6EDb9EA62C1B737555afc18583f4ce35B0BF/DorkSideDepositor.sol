// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


abstract contract ReentrancyGuard {
 
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}


interface IWETH {
    function deposit() external payable;
    function withdraw(uint amount) external;
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint256 value) external returns (bool);

}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract DorkSideDepositor is ReentrancyGuard {
    IWETH public WETH_TOKEN;
    address public STAR;
    address public ALT;
    address public STABLE;
    uint256 public starPercentage = 100; // in basis points, out of 1000
    uint256 public altPercentage = 300;
    uint256 public stablePercentage = 600;
    address public owner;
    bool public allowDeposits = true;

    uint256 public totalDeposited;// Total ETH deposited
    uint256 public totalDepositedPlusBonus; // Total ETH deposited + Bonus amount
    uint256 public totalReceivedWETH; // Total WETH received
    uint256 public totalClaimedWETH; // Total WETH claimed by all users

    uint256 public bonusPercent = 10; // Bonus percent (e.g., 10 for 10%)
    uint256 public lastClaimTime; // Last time claim was executed
    uint256 public claimInterval = 1 minutes; // 1 min interval


    mapping(address => uint256) public userTotalClaimedWETH; // Last WETH claimed by user
    mapping(address => uint256) public lastUserClaimTime; // Last time user claimed

    mapping(address => uint256)public UserTotalDepositAndBonus; //Total user depoist and bonus
    mapping(address => uint256)public UserTotalDeposited; //Total user deposit
    mapping(address => uint256) public UserUnclaimedBalances; //Total amount a user has left to claim


    constructor(address _wethToken) {
        WETH_TOKEN = IWETH(_wethToken);
        owner = msg.sender;
        STAR = msg.sender;
        ALT = msg.sender;
        STABLE = msg.sender;
        lastClaimTime = block.timestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    receive() external payable {
        depositAndWrapETH();
    }

    function setPercentages(uint256 _starPercentage, uint256 _altPercentage, uint256 _stablePercentage) external onlyOwner {
        require(_starPercentage + _altPercentage + _stablePercentage == 1000, "Total must be 1000 basis points.");
        starPercentage = _starPercentage;
        altPercentage = _altPercentage;
        stablePercentage = _stablePercentage;
    }

    function setAddresses(address _STAR, address _ALT, address _STABLE) external onlyOwner {
        STAR = _STAR;
        ALT = _ALT;
        STABLE = _STABLE;
    }

    function toggleDeposits() external onlyOwner {
        allowDeposits = !allowDeposits;
    }

    function setBonusPercent(uint256 _bonusPercent) external onlyOwner {
        bonusPercent = _bonusPercent;
    }

    function depositAndWrapETH() public payable nonReentrant{
        require(allowDeposits, "Deposits are currently disabled.");

        uint256 depositAmount = msg.value;

        uint256 bonusAmount = (depositAmount * bonusPercent) / 100;

        uint256 totalDeposit = depositAmount;

        uint256 totalDepositAndBonus = bonusAmount + totalDeposit;

        UserTotalDepositAndBonus[msg.sender] += totalDepositAndBonus; 
        UserTotalDeposited[msg.sender] += depositAmount;
        UserUnclaimedBalances[msg.sender] += totalDepositAndBonus;

        totalDeposited += totalDeposit;
        totalDepositedPlusBonus += totalDepositAndBonus;

        WETH_TOKEN.deposit{value: depositAmount}();

        uint256 starAmount = (depositAmount * starPercentage) / 1000;
        uint256 altAmount = (depositAmount * altPercentage) / 1000;
        uint256 stableAmount = (depositAmount * stablePercentage) / 1000;

        WETH_TOKEN.transfer(STAR, starAmount);
        WETH_TOKEN.transfer(ALT, altAmount);
        WETH_TOKEN.transfer(STABLE, stableAmount);
    }   


    function getTotalDeposited() public view returns (uint256) {
        return totalDeposited;
    }

    function getTotalClaimedWETH() public view returns (uint256) {
        return totalClaimedWETH;
    }

    function getUserDeposit(address user) public view returns (uint256) {
        return UserTotalDeposited[user];
    }

    function getUserLastClaimedWETH(address user) public view returns (uint256) {
        return userTotalClaimedWETH[user];
    }

    function getTotalReceivedWeth() public view returns (uint256) {
        return WETH_TOKEN.balanceOf(address(this)) + totalClaimedWETH;
    }

    function getCurrentBalanceWETH() public view returns (uint256) {
        return WETH_TOKEN.balanceOf(address(this));
    }
   
    function computeClaimableAmount(address user) public view returns(uint256) {
        uint256 currentTotalReceivedWETH = WETH_TOKEN.balanceOf(address(this)) + totalClaimedWETH;  //10
        uint256 userBalance = UserTotalDepositAndBonus[user];  //Total of all deposits of a user
        uint256 userProportion = (userBalance * 1e18) / totalDepositedPlusBonus; //"ratio" of a user deposit to total deposits
        uint256 userShouldHaveClaimed = (userProportion * currentTotalReceivedWETH) / 1e18;
        uint256 claimable;
    

        if (userShouldHaveClaimed >= userTotalClaimedWETH[user]) {
            claimable = userShouldHaveClaimed - userTotalClaimedWETH[user];
        } else {
            claimable = 0;
        }

        uint256 remainingUnclaimed = UserUnclaimedBalances[user]; 
        if (claimable >= remainingUnclaimed) {
        claimable = remainingUnclaimed;
        }
    
        return claimable;
   }

    function claim() public nonReentrant {
        require(lastUserClaimTime[msg.sender] == 0 || block.timestamp >= lastUserClaimTime[msg.sender] + claimInterval, "You can only claim once in the allowed interval.");

        uint256 claimable = computeClaimableAmount(msg.sender); 
        require(claimable > 0, "Nothing to claim.");

        uint256 contractWETHBalance = WETH_TOKEN.balanceOf(address(this));
        require(contractWETHBalance >= claimable, "Insufficient WETH balance.");

        UserUnclaimedBalances[msg.sender] -= claimable;

        userTotalClaimedWETH[msg.sender] += claimable;

        totalClaimedWETH += claimable;

        lastUserClaimTime[msg.sender] = block.timestamp;

        WETH_TOKEN.transfer(msg.sender, claimable);
       

        totalReceivedWETH = WETH_TOKEN.balanceOf(address(this)) + totalClaimedWETH;

    }

    function withdrawERC20Balance(IERC20 _token) external onlyOwner {
        require(address(_token) != address(WETH_TOKEN), "Cannot withdraw WETH through this function");

        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw.");
        
        _token.transfer(msg.sender, balance);
    }

    

    
}