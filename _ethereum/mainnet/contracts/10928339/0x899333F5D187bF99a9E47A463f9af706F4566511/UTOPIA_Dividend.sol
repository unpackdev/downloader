pragma solidity 0.5.16; 


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b, 'SafeMath mul failed');
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath sub failed');
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath add failed');
    return c;
    }
}


contract owned {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


interface UTOPIAInterface
{
    function userStakedAmount(address _token,address user) external view returns (uint) ;
    function totalStakedAmount(address _token) external view returns(uint);
    function authorisedToken(address _token) external view returns(bool);
    function updateUserData(address _token, address user, uint d_T, uint d_E, uint s_A, uint t_T, uint t_E) external returns(bool);
}

interface tokenInterface
{
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
}

contract UTOPIA_Dividend is owned 
{
    using SafeMath for uint256;

    struct userData
    {
        uint distCount_T;
        uint distCount_Direct;
        uint distCount_E;
        uint totalWhenWithdrawn_T;
        uint totalWhenWithdrawn_Direct;
        uint totalWhenWithdrawn_E;
    }

    // All first address in mapping is token 
    //  => user 
    mapping(address => mapping(address => userData)) public userDatas;

    mapping (address => uint) public lastDistributionTime;  // last time when distributed
    mapping (address => uint) public distributionInterval;  // Next distribution after this seconds

    mapping (address => uint) public totalDepositedDividend_T; // total deposited dividend for all time for token
    mapping (address => uint) public totalDepositedDividend_Direct; // total direct dividend for all time for token
    mapping (address => uint) public totalDepositedDividend_E; // total deposited dividend for all time for ether
    mapping (address => uint) public totalWithdrawnByUser_T; // sum of all withdrawn amount withdrawn by user in current distribution
    mapping (address => uint) public totalWithdrawnByUser_E; // sum of all withdrawn amount withdrawn by user in current distribution

    mapping (address => uint) public distributedTotalAmountTillNow_T; // total amount of contract when last distribution done
    mapping (address => uint) public distributedTotalAmountTillNow_E; // total amount of contract when last distribution done
    mapping (address => uint) public distributedTotalAmountTillNow_Direct;

    mapping (address => uint) public totalDistributionCount_T;
    mapping (address => uint) public totalDistributionCount_Direct;
    mapping (address => uint) public totalDistributionCount_E;

    uint public distributionPercent;

    address public stakingContractAddress;

    function adjustDistributionTime(address token, uint _delayInSeconds, bool _increase) public onlyOwner returns(bool)
    {
        require(UTOPIAInterface(stakingContractAddress).authorisedToken(token), "Invalid token");
        if(_increase)
        {
            lastDistributionTime[token] += _delayInSeconds;
        }
        else
        {
            lastDistributionTime[token] -= _delayInSeconds;
        }
        return true;
    }


    function setdistributionInterval(address token, uint _distributionInterval ) public onlyOwner returns(bool)
    {
        require(UTOPIAInterface(stakingContractAddress).authorisedToken(token), "Invalid token");
        distributionInterval[token] = _distributionInterval;
        return true;
    }


    function setStakingContractAddress(address _stakingContractAddress, uint _distributionPercent ) public onlyOwner returns(bool)
    {
        stakingContractAddress = _stakingContractAddress;
        distributionPercent = _distributionPercent;
        return true;
    }

    constructor() public
    {
        
    }


    event depositDividendEv(address token, address depositor, uint amount_E, uint amount_T);
    function depositDividend(address token, uint tokenAmount) public payable returns(bool)
    {
        require(UTOPIAInterface(stakingContractAddress).authorisedToken(token), "Invalid token");
        if(msg.value > 0) totalDepositedDividend_E[token] = totalDepositedDividend_E[token].add(msg.value);
        if(tokenAmount > 0 ) 
        {
            require(tokenInterface(token).transferFrom(msg.sender, address(this), tokenAmount),"token transfer failed");
            totalDepositedDividend_T[token] = totalDepositedDividend_T[token].add(tokenAmount);
        }
        emit depositDividendEv(token, msg.sender, msg.value, tokenAmount);
        return true;
    }


    event distributeDividendEv(address token, address user, uint amount_E, uint amount_T);
    function distributeDividend(address token) public onlyOwner returns(bool)
    {
        require(UTOPIAInterface(stakingContractAddress).authorisedToken(token), "Invalid token");
        require(lastDistributionTime[token] + distributionInterval[token] <= now, "please wait some more time" );
        uint amount_E = ( totalDepositedDividend_E[token]-distributedTotalAmountTillNow_E[token]) * distributionPercent / 100000000;
        uint amount_T = ( totalDepositedDividend_T[token]-distributedTotalAmountTillNow_T[token]) * distributionPercent / 100000000;
        require(amount_E > 0 || amount_T > 0 , "no amount to distribute next");
        if(amount_E > 0)
        {
            distributedTotalAmountTillNow_E[token] += amount_E;
            totalDistributionCount_E[token]++;
        }
        if(amount_T > 0)
        {
            distributedTotalAmountTillNow_T[token] += amount_T;
            totalDistributionCount_T[token]++;
        }
        lastDistributionTime[token] = now;
        emit distributeDividendEv(token,msg.sender, amount_E, amount_T);
        return true;
    }

    function directDistribute(address _token, uint _amount) public returns(bool)
    {
        require(msg.sender == stakingContractAddress || msg.sender == owner, "Invalid caller");
        require(UTOPIAInterface(stakingContractAddress).authorisedToken(_token), "Invalid token");
        require(_amount > 0 , "invalid amount to distribute direct");

        distributedTotalAmountTillNow_Direct[_token] += _amount;
        totalDepositedDividend_Direct[_token] += _amount;
        totalDistributionCount_Direct[_token]++;
        return true;
    }

    event withdrawMyDividendEv(address token, address user, uint amount_E, uint amount_T);
    // searchFrom = 0 means start searching from latest stake records of the user, and if >  0 then before latest
    function withdrawMyDividend(address _token) public returns (bool)
    {
        require(UTOPIAInterface(stakingContractAddress).authorisedToken(_token), "Invalid token");

        uint amount_E = distributedTotalAmountTillNow_E[_token].sub(userDatas[_token][tx.origin].totalWhenWithdrawn_E);
        uint amount_T = distributedTotalAmountTillNow_T[_token].sub(userDatas[_token][tx.origin].totalWhenWithdrawn_T);
        uint amount_Direct = distributedTotalAmountTillNow_Direct[_token].sub(userDatas[_token][tx.origin].totalWhenWithdrawn_Direct);
        uint userStaked = UTOPIAInterface(stakingContractAddress).userStakedAmount(_token, tx.origin);

        uint totalStaked = UTOPIAInterface(stakingContractAddress).totalStakedAmount(_token);
        if(totalStaked > 0)
        {
            uint gain_E = amount_E * ((userStaked * 100000000 / totalStaked) / 1000000);
            uint gain_T = amount_T * ((userStaked * 100000000 / totalStaked) / 1000000);
            gain_T += amount_Direct * ((userStaked * 100000000 / totalStaked) / 1000000);
            userDatas[_token][tx.origin].distCount_T = totalDistributionCount_T[_token];
            userDatas[_token][tx.origin].distCount_Direct = totalDistributionCount_Direct[_token];
            userDatas[_token][tx.origin].distCount_E = totalDistributionCount_E[_token];
            userDatas[_token][tx.origin].totalWhenWithdrawn_T = distributedTotalAmountTillNow_T[_token];
            userDatas[_token][tx.origin].totalWhenWithdrawn_Direct = distributedTotalAmountTillNow_Direct[_token];
            userDatas[_token][tx.origin].totalWhenWithdrawn_E = distributedTotalAmountTillNow_E[_token];

            if(gain_E > 0) tx.origin.transfer(gain_E);
            if(gain_T > 0) require(tokenInterface(_token).transfer(tx.origin, gain_T ), "token transfer failed");
            emit withdrawMyDividendEv(_token,tx.origin,gain_E, gain_T);
        }
        return true;
    }

    function viewMyWithdrawable(address _token, address _user) public view returns(uint amount_E,uint amount_T, uint amount_Direct)
    {
        uint userStaked = UTOPIAInterface(stakingContractAddress).userStakedAmount(_token, _user);
        amount_E = distributedTotalAmountTillNow_E[_token].sub(userDatas[_token][_user].totalWhenWithdrawn_E);
        amount_T = distributedTotalAmountTillNow_T[_token].sub(userDatas[_token][_user].totalWhenWithdrawn_T);
        amount_Direct= distributedTotalAmountTillNow_Direct[_token].sub(userDatas[_token][_user].totalWhenWithdrawn_Direct);

        uint totalStaked = UTOPIAInterface(stakingContractAddress).totalStakedAmount(_token);
        amount_E = amount_E * ((userStaked * 100000000 / totalStaked) / 1000000);
        amount_T = amount_T * ((userStaked * 100000000 / totalStaked) / 1000000);
        amount_Direct = amount_Direct * ((userStaked * 100000000 / totalStaked) / 1000000);
        return (amount_E,amount_T, amount_Direct);
    }

    function currentDepositedAmount(address _token) public view returns(uint amount_E, uint amount_T)
    {
        return (totalDepositedDividend_E[_token] - distributedTotalAmountTillNow_E[_token],totalDepositedDividend_T[_token] - distributedTotalAmountTillNow_T[_token]);
    }

    function viewDistributionAmount(address _token) public view returns (uint amount_E, uint amount_T)
    {
        return (totalDepositedDividend_E[_token] - distributedTotalAmountTillNow_E[_token],totalDepositedDividend_T[_token] - distributedTotalAmountTillNow_T[_token] );
    }    


}