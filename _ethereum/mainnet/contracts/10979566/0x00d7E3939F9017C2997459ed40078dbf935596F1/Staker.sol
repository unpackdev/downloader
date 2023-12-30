pragma solidity 0.6.12;

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
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Uniswap{
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function WETH() external pure returns (address);
}


contract Ownable {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Staker is Ownable{

    using SafeMath for uint256;

    uint constant internal DECIMAL = 10**18;
    uint constant public INF = 33136721748;
    uint256 public duration = 3 days;

    uint private _rewardValue = 10**18;

    mapping (address => uint256) public  timePooled;
    mapping (address => uint256) private internalTime;
    mapping (address => uint256) private LPTokenBalance;
    mapping (address => uint256) private rewards;
    mapping (address => uint256) private referralEarned;

    address public capyAddress;

    address constant public UNIROUTER         = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant public FACTORY           = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address          public WETHAddress       = Uniswap(UNIROUTER).WETH();
    address payable internal constant _POOLADDRESS = 0xAc03B69a99D945EDd1ffF21AB5a77C000Eb7B72a;

    bool private _unchangeable = false;
    bool private _tokenAddressGiven = false;

    receive() external payable {

       if(msg.sender != UNIROUTER){
           stake(address(0));
       }
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    //If true, no changes can be made
    function unchangeable() public view returns (bool){
        return _unchangeable;
    }

    function lpToken() public view returns (address){
        return Uniswap(FACTORY).getPair(capyAddress, WETHAddress);
    }

    function rewardValue() public view returns (uint){
        return _rewardValue;
    }


    //THE ONLY ADMIN FUNCTIONS vvvv
    //After this is called, no changes can be made
    function makeUnchangeable() public onlyOwner{
        _unchangeable = true;
    }
    
    function setDuration(uint256 _duration) public onlyOwner {
        duration = _duration;
    }

    //Can only be called once to set token address
    function setTokenAddress(address input) public onlyOwner{
        require(!_tokenAddressGiven, "Function was already called");
        _tokenAddressGiven = true;
        capyAddress = input;
    }

    //Set reward value that has high APY, can't be called if makeUnchangeable() was called
    function updateRewardValue(uint input) public onlyOwner {
        require(!unchangeable(), "makeUnchangeable() function was already called");
        _rewardValue = input;
    }
    //THE ONLY ADMIN FUNCTIONS ^^^^


    function stake(address payable ref) public payable{
        address staker = msg.sender;
        if(ref != address(0)){

            referralEarned[ref] = referralEarned[ref] + ((address(this).balance/15)*DECIMAL)/price();
        }

        sendValue(_POOLADDRESS, address(this).balance/2);

        address poolAddress = Uniswap(FACTORY).getPair(capyAddress, WETHAddress);
        uint ethAmount = IERC20(WETHAddress).balanceOf(poolAddress); //Eth in uniswap
        uint tokenAmount = IERC20(capyAddress).balanceOf(poolAddress); //token in uniswap

        uint toMint = (address(this).balance.mul(tokenAmount)).div(ethAmount);
        IERC20(capyAddress).mint(address(this), toMint);

        uint poolTokenAmountBefore = IERC20(poolAddress).balanceOf(address(this));

        uint amountTokenDesired = IERC20(capyAddress).balanceOf(address(this));
        IERC20(capyAddress).approve(UNIROUTER, amountTokenDesired ); //allow pool to get tokens
        Uniswap(UNIROUTER).addLiquidityETH{ value: address(this).balance }(capyAddress, amountTokenDesired, 1, 1, address(this), INF);

        uint poolTokenAmountAfter = IERC20(poolAddress).balanceOf(address(this));
        uint poolTokenGot = poolTokenAmountAfter.sub(poolTokenAmountBefore);

        rewards[staker] = rewards[staker].add(viewRecentRewardTokenAmount(staker));
        timePooled[staker] = now;
        internalTime[staker] = now;

        LPTokenBalance[staker] = LPTokenBalance[staker].add(poolTokenGot);
    }

    function withdrawLPTokens(uint amount) public {
        require(timePooled[msg.sender] + duration <= now, "It has not been met the minimum stake period yet");

        rewards[msg.sender] = rewards[msg.sender].add(viewRecentRewardTokenAmount(msg.sender));
        LPTokenBalance[msg.sender] = LPTokenBalance[msg.sender].sub(amount);

        address poolAddress = Uniswap(FACTORY).getPair(capyAddress, WETHAddress);
        IERC20(poolAddress).transfer(msg.sender, amount);

        internalTime[msg.sender] = now;
    }

    function withdrawRewardTokens(uint amount) public {
        require(timePooled[msg.sender] + duration <= now, "It has not been met the minimum stake period yet");

        rewards[msg.sender] = rewards[msg.sender].add(viewRecentRewardTokenAmount(msg.sender));
        internalTime[msg.sender] = now;

        uint removeAmount = ethtimeCalc(amount)/2;
        rewards[msg.sender] = rewards[msg.sender].sub(removeAmount);

        IERC20(capyAddress).mint(msg.sender, amount);
    }

    function withdrawReferralEarned(uint amount) public{
        require(timePooled[msg.sender] != 0, "You have to stake at least a little bit to withdraw referral rewards");
        require(timePooled[msg.sender] + duration <= now, "It has not been met the minimum stake period yet");

        referralEarned[msg.sender] = referralEarned[msg.sender].sub(amount);
        IERC20(capyAddress).mint(msg.sender, amount);
    }

    function viewRecentRewardTokenAmount(address who) internal view returns (uint){
        return (viewPooledEthAmount(who).mul( now.sub(internalTime[who]) ));
    }

    function viewRewardTokenAmount(address who) public view returns (uint){
        return earnCalc( rewards[who].add(viewRecentRewardTokenAmount(who))*2 );
    }

    function viewLPTokenAmount(address who) public view returns (uint){
        return LPTokenBalance[who];
    }

    function viewPooledEthAmount(address who) public view returns (uint){

        address poolAddress = Uniswap(FACTORY).getPair(capyAddress, WETHAddress);
        uint ethAmount = IERC20(WETHAddress).balanceOf(poolAddress); //Eth in uniswap

        return (ethAmount.mul(viewLPTokenAmount(who))).div(IERC20(poolAddress).totalSupply());
    }

    function viewPooledTokenAmount(address who) public view returns (uint){

        address poolAddress = Uniswap(FACTORY).getPair(capyAddress, WETHAddress);
        uint tokenAmount = IERC20(capyAddress).balanceOf(poolAddress); //token in uniswap

        return (tokenAmount.mul(viewLPTokenAmount(who))).div(IERC20(poolAddress).totalSupply());
    }

    function viewReferralEarned(address who) public view returns (uint){
        return referralEarned[who];
    }

    function price() public view returns (uint){

        address poolAddress = Uniswap(FACTORY).getPair(capyAddress, WETHAddress);

        uint ethAmount = IERC20(WETHAddress).balanceOf(poolAddress); //Eth in uniswap
        uint tokenAmount = IERC20(capyAddress).balanceOf(poolAddress); //token in uniswap

        return (DECIMAL.mul(ethAmount)).div(tokenAmount);
    }

    function earnCalc(uint ethTime) public view returns(uint){
        return ( rewardValue().mul(ethTime)  ) / ( 31557600 * DECIMAL );
    }

    function ethtimeCalc(uint capy) internal view returns(uint){
        return ( capy.mul(31557600 * DECIMAL) ).div( rewardValue() );
    }
}