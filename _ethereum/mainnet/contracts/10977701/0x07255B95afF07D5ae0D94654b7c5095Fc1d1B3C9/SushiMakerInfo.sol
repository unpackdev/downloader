pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function owner() external view returns (address);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISushiSwapPoolNames {
    function logos(uint256) external view returns(string memory);
    function names(uint256) external view returns(string memory);
    function setPoolInfo(uint256 pid, string memory logo, string memory name) external;
}

interface ISushiToken is IERC20{
    function delegates(address who) external view returns(address);
    function getCurrentVotes(address who) external view returns(uint256);
    function nonces(address who) external view returns(uint256);
}

interface IMasterChef {
    function BONUS_MULTIPLIER() external view returns (uint256);
    function bonusEndBlock() external view returns (uint256);
    function devaddr() external view returns (address);
    function migrator() external view returns (address);
    function owner() external view returns (address);
    function startBlock() external view returns (uint256);
    function sushi() external view returns (address);
    function sushiPerBlock() external view returns (uint256);
    function totalAllocPoint() external view returns (uint256);

    function poolLength() external view returns (uint256);
    function poolInfo(uint256 nr) external view returns (address, uint256, uint256, uint256);
    function userInfo(uint256 nr, address who) external view returns (uint256, uint256);
    function pendingSushi(uint256 nr, address who) external view returns (uint256);
}

interface IFactory {
    function getPair(address token0, address token1) external view returns (address);
}

interface IPair is IERC20 {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Underflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "Mul Overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Div by 0");
        uint256 c = a / b;

        return c;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

struct BaseInfo {
    uint256 BONUS_MULTIPLIER;
    uint256 bonusEndBlock;
    address devaddr;
    address migrator;
    address owner;
    uint256 startBlock;
    address sushi;
    uint256 sushiPerBlock;
    uint256 totalAllocPoint;
    
    uint256 sushiTotalSupply;
    address sushiOwner;
}

struct PoolInfo {
    string logo;
    string name;
    IPair lpToken;           // Address of LP token contract.
    uint256 allocPoint;       // How many allocation points assigned to this pool. SUSHIs to distribute per block.
    uint256 lastRewardBlock;  // Last block number that SUSHIs distribution occurs.
    uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
    IERC20 token0;
    IERC20 token1;
    string token0name;
    string token1name;
    string token0symbol;
    string token1symbol;
    uint256 token0decimals;
    uint256 token1decimals;
}

struct UserInfo {
    uint256 block;
    uint256 timestamp;
    uint256 eth_rate;
    uint256 sushiBalance;
    address delegates;
    uint256 currentVotes;
    uint256 nonces;
}

struct UserPoolInfo {
    uint256 lastRewardBlock;  // Last block number that SUSHIs distribution occurs.
    uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
    uint256 balance; // Balance of pool tokens
    uint256 totalSupply; // Token staked lp tokens
    uint256 uniBalance; // Balance of uniswap lp tokens not staked
    uint256 uniTotalSupply; // TotalSupply of uniswap lp tokens
    uint256 uniAllowance; // UniSwap LP tokens approved for masterchef
    uint256 reserve0;
    uint256 reserve1;
    uint256 token0rate;
    uint256 token1rate;
    uint256 rewardDebt;
    uint256 pending; // Pending SUSHI
}

contract SushiSwapBaseInfo is Ownable {
    // Mainnet
    //ISushiSwapPoolNames names = ISushiSwapPoolNames(0xb373a5def62A907696C0bBd22Dc512e2Fc8cfC7E);
    //IMasterChef masterChef = IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    
    // Ropsten
    ISushiSwapPoolNames names = ISushiSwapPoolNames(0x7685f4c573cE27C94F6aF70B330C29b9c41B8290);
    IMasterChef masterChef = IMasterChef(0xFF281cEF43111A83f09C656734Fa03E6375d432A);
    
    function setContracts(address names_, address masterChef_) public onlyOwner {
        names = ISushiSwapPoolNames(names_);
        masterChef = IMasterChef(masterChef_);
    }

    function getInfo() public view returns(BaseInfo memory, PoolInfo[] memory) {
        BaseInfo memory info;
        info.BONUS_MULTIPLIER = masterChef.BONUS_MULTIPLIER();
        info.bonusEndBlock = masterChef.bonusEndBlock();
        info.devaddr = masterChef.devaddr();
        info.migrator = masterChef.migrator();
        info.owner = masterChef.owner();
        info.startBlock = masterChef.startBlock();
        info.sushi = masterChef.sushi();
        info.sushiPerBlock = masterChef.sushiPerBlock();
        info.totalAllocPoint = masterChef.totalAllocPoint();
        
        info.sushiTotalSupply = IERC20(info.sushi).totalSupply();
        info.sushiOwner = IERC20(info.sushi).owner();

        uint256 poolLength = masterChef.poolLength();
        PoolInfo[] memory pools = new PoolInfo[](poolLength);
        for (uint256 i = 0; i < poolLength; i++) {
            (address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accSushiPerShare) = masterChef.poolInfo(i);
            IPair uniV2 = IPair(lpToken);
            pools[i].lpToken = uniV2;
            pools[i].allocPoint = allocPoint;
            pools[i].lastRewardBlock = lastRewardBlock;
            pools[i].accSushiPerShare = accSushiPerShare;
            
            IERC20 token0 = IERC20(uniV2.token0());
            pools[i].token0 = token0;
            IERC20 token1 = IERC20(uniV2.token1());
            pools[i].token1 = token1;
            
            pools[i].token0name = token0.name();
            pools[i].token0symbol = token0.symbol();
            pools[i].token0decimals = token0.decimals();
            
            pools[i].token1name = token1.name();
            pools[i].token1symbol = token1.symbol();
            pools[i].token1decimals = token1.decimals();
            
            pools[i].logo = names.logos(i);
            pools[i].name = names.names(i);
        }
        return (info, pools);
    }
}

contract SushiSwapUserInfo is Ownable
{
    using SafeMath for uint256;

    IFactory factory = IFactory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);
    IMasterChef masterChef = IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    ISushiToken sushi = ISushiToken(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function setContracts(address factory_, address masterChef_, address sushi_, address WETH_) public onlyOwner {
        factory = IFactory(factory_);
        masterChef = IMasterChef(masterChef_);
        sushi = ISushiToken(sushi_);
        WETH = WETH_;
    }

    function getETHRate(address token) public view returns(uint256) {
        uint256 eth_rate = 1e18;
        if (token != WETH)
        {
            IPair pair = IPair(factory.getPair(token, WETH));
            (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
            if (pair.token0() == WETH) {
                eth_rate = uint256(reserve1).mul(1e18).div(reserve0);
            } else {
                eth_rate = uint256(reserve0).mul(1e18).div(reserve1);
            }
        }
        return eth_rate;
    }
    
    function _getUserInfo(address who, address currency) private view returns(UserInfo memory) {
        UserInfo memory user;
        
        user.block = block.number;
        user.timestamp = block.timestamp;
        user.sushiBalance = sushi.balanceOf(who);
        user.delegates = sushi.delegates(who);
        user.currentVotes = sushi.getCurrentVotes(who);
        user.nonces = sushi.nonces(who);
        user.eth_rate = getETHRate(currency);
        
        return user;
    }
    
    function getUserInfo(address who, address currency) public view returns(UserInfo memory, UserPoolInfo[] memory) {
        uint256 poolLength = masterChef.poolLength();
        UserPoolInfo[] memory pools = new UserPoolInfo[](poolLength);

        for (uint256 i = 0; i < poolLength; i++) {
            (uint256 amount, uint256 rewardDebt) = masterChef.userInfo(i, who);
            pools[i].balance = amount;
            pools[i].rewardDebt = rewardDebt;
            pools[i].pending = masterChef.pendingSushi(i, who);

            (address lpToken, , uint256 lastRewardBlock, uint256 accSushiPerShare) = masterChef.poolInfo(i);
            IPair uniV2 = IPair(lpToken);
            pools[i].totalSupply = uniV2.balanceOf(address(masterChef));
            pools[i].uniAllowance = uniV2.allowance(who, address(masterChef));
            pools[i].lastRewardBlock = lastRewardBlock;
            pools[i].accSushiPerShare = accSushiPerShare;
            pools[i].uniBalance = uniV2.balanceOf(who);
            pools[i].uniTotalSupply = uniV2.totalSupply();
            pools[i].token0rate = getETHRate(uniV2.token0());
            pools[i].token1rate = getETHRate(uniV2.token1());
            
            (uint112 reserve0, uint112 reserve1,) = uniV2.getReserves();
            pools[i].reserve0 = reserve0;
            pools[i].reserve1 = reserve1;
        }
        return (_getUserInfo(who, currency), pools);
    }
    
    function getMyInfoInUSDT() public view returns(UserInfo memory, UserPoolInfo[] memory) {
        return getUserInfo(msg.sender, 0x292c703A980fbFce4708864Ae6E8C40584DAF323);
    }
}

struct PairInfo {
    string logo;
    string name;
    IPair lpToken;           // Address of LP token contract.
    uint256 allocPoint;       // How many allocation points assigned to this pool. SUSHIs to distribute per block.
    uint256 lastRewardBlock;  // Last block number that SUSHIs distribution occurs.
    uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
    IERC20 token0;
    IERC20 token1;
    string token0name;
    string token1name;
    string token0symbol;
    string token1symbol;
    uint256 token0decimals;
    uint256 token1decimals;
    
    uint256 makerBalance;
    uint256 totalSupply;
    uint256 reserve0;
    uint256 reserve1;
    uint256 token0rate;
    uint256 token1rate;
}

contract SushiMakerInfo is Ownable
{
    using SafeMath for uint256;

    address sushiMaker = 0x54844afe358Ca98E4D09AAe869f25bfe072E1B1a;
    IFactory factory = IFactory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);
    IFactory factory_backup = IFactory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    ISushiToken sushi = ISushiToken(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    IMasterChef masterChef = IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    ISushiSwapPoolNames names = ISushiSwapPoolNames(0xb373a5def62A907696C0bBd22Dc512e2Fc8cfC7E);
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    mapping(uint256 => bool) public skipPID;
    uint256 public skipCount;
    
    constructor() public {
        setSkipPID(29, true);
        setSkipPID(30, true);
    }

    function setContracts(address sushiMaker_, address factory_, address factory_backup_, address sushi_, address masterChef_, address names_, address WETH_) public onlyOwner {
        sushiMaker = sushiMaker_;
        factory = IFactory(factory_);
        factory_backup = IFactory(factory_backup_);
        sushi = ISushiToken(sushi_);
        masterChef = IMasterChef(masterChef_);
        names = ISushiSwapPoolNames(names_);
        WETH = WETH_;
    }
    
    function setSkipPID(uint pid, bool skip) public onlyOwner {
        skipPID[pid] = skip;
        if (skip) {
            skipCount++;
        } else {
            skipCount--;
        }
    }

    function getETHRate(address token) public view returns(uint256) {
        uint256 eth_rate = 1e18;
        if (token != WETH)
        {
            IPair pair;
            pair = IPair(factory.getPair(token, WETH));
            if (address(pair) == address(0)) {
                pair = IPair(factory_backup.getPair(token, WETH));
                if (address(pair) == address(0)) {
                    return 0;
                }
            }
            (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
            if (pair.token0() == WETH) {
                eth_rate = uint256(reserve1).mul(1e18).div(reserve0);
            } else {
                eth_rate = uint256(reserve0).mul(1e18).div(reserve1);
            }
        }
        return eth_rate;
    }
    
    function getPair(uint256 pid) public view returns(PairInfo memory) {
        PairInfo memory info;

        (address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accSushiPerShare) = masterChef.poolInfo(pid);
        IPair pair = IPair(lpToken);
        info.lpToken = pair;
        info.allocPoint = allocPoint;
        info.lastRewardBlock = lastRewardBlock;
        info.accSushiPerShare = accSushiPerShare;
        
        IERC20 token0 = IERC20(pair.token0());
        info.token0 = token0;
        IERC20 token1 = IERC20(pair.token1());
        info.token1 = token1;
        
        info.token0name = token0.name();
        info.token0symbol = token0.symbol();
        info.token0decimals = token0.decimals();
        
        info.token1name = token1.name();
        info.token1symbol = token1.symbol();
        info.token1decimals = token1.decimals();
        
        info.logo = names.logos(pid);
        info.name = names.names(pid);

        info.makerBalance = pair.balanceOf(sushiMaker);
        info.totalSupply = pair.totalSupply();
        
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        info.reserve0 = reserve0;
        info.reserve1 = reserve1;

        info.token0rate = getETHRate(address(token0));
        info.token1rate = getETHRate(address(token1));

        return info;
    }    
    
    function getPairs(address currency) public view returns(uint256, PairInfo[] memory) {
        uint pairCount = masterChef.poolLength();
        PairInfo[] memory infos = new PairInfo[](pairCount.sub(skipCount));

        uint256 currentPair;
        for (uint256 i = 0; i < pairCount; i++) {
            if (!skipPID[i]) {
                (address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accSushiPerShare) = masterChef.poolInfo(i);
                IPair pair = IPair(lpToken);
                infos[currentPair].lpToken = pair;
                infos[currentPair].allocPoint = allocPoint;
                infos[currentPair].lastRewardBlock = lastRewardBlock;
                infos[currentPair].accSushiPerShare = accSushiPerShare;
                
                IERC20 token0 = IERC20(pair.token0());
                infos[currentPair].token0 = token0;
                IERC20 token1 = IERC20(pair.token1());
                infos[currentPair].token1 = token1;
                
                infos[currentPair].token0name = token0.name();
                infos[currentPair].token0symbol = token0.symbol();
                infos[currentPair].token0decimals = token0.decimals();
                
                infos[currentPair].token1name = token1.name();
                infos[currentPair].token1symbol = token1.symbol();
                infos[currentPair].token1decimals = token1.decimals();
                
                infos[currentPair].logo = names.logos(i);
                infos[currentPair].name = names.names(i);
    
                infos[currentPair].makerBalance = pair.balanceOf(sushiMaker);
                infos[currentPair].totalSupply = pair.totalSupply();
                
                (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
                infos[currentPair].reserve0 = reserve0;
                infos[currentPair].reserve1 = reserve1;
    
                infos[currentPair].token0rate = getETHRate(address(token0));
                infos[currentPair].token1rate = getETHRate(address(token1));
                
                currentPair++;
            }
        }
        return (getETHRate(currency), infos);
    }
}


