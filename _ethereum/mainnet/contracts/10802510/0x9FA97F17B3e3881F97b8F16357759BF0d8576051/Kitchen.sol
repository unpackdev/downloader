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
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

interface UniswapExchangeInterface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

struct FullPoolInfo {
    string logo;
    string name;
    UniswapExchangeInterface lpToken;           // Address of LP token contract.
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

interface IMasterChef {
    function poolLength() external view returns (uint256);
    function poolInfo(uint256 nr) external view returns (address, uint256, uint256, uint256);
}

contract Kitchen is Ownable {
    IMasterChef masterChef = IMasterChef(0xFF281cEF43111A83f09C656734Fa03E6375d432A);
    
    mapping(uint256 => string) public logos;
    mapping(uint256 => string) public names;
    
    constructor() public {
        logos[0] = '🐢'; names[0] = 'Tether Turtle';
        logos[1] = '🐌'; names[1] = 'Circle Snail';
        logos[2] = '🦆'; names[2] = 'Donald DAI';
        logos[3] = '🦍'; names[3] = 'Spartan Dollar';
        logos[4] = '🍄'; names[4] = 'Compound Truffle';
        logos[5] = '🐗'; names[5] = 'Aave Boar';
        logos[6] = '🐍'; names[6] = 'Synthetic Snake';
        logos[7] = '🦑'; names[7] = 'Umami Squid';
        logos[8] = '🐸'; names[8] = 'Toadie Marine';
        logos[9] = '🦖'; names[9] = 'Band-osaurus';
        logos[10] = '🐥'; names[10] = 'Ample Chicks';
        logos[11] = '🐋'; names[11] = 'YFI Whale';
        logos[12] = '🍣'; names[12] = 'Sushi Party!';
        logos[13] = '🦏'; names[13] = 'REN Rhino';
        logos[14] = '🐂'; names[14] = 'BASED Bull';
        logos[15] = '🦈'; names[15] = 'SRM Shark';
        logos[16] = '🍠'; names[16] = 'YAMv2 Yam';
        logos[17] = '🐊'; names[17] = 'CRV Crocodile';
    }
    
    function setPoolInfo(uint256 pid, string memory logo, string memory name) public onlyOwner {
        logos[pid] = logo;
        names[pid] = name;
    }

    function getPoolsInfo() public view returns(FullPoolInfo[] memory) {
        uint256 poolLength = masterChef.poolLength();
        FullPoolInfo[] memory pools = new FullPoolInfo[](poolLength);
        for (uint256 i = 0; i < poolLength; i++) {
            (address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accSushiPerShare) = masterChef.poolInfo(i);
            UniswapExchangeInterface uniV2 = UniswapExchangeInterface(lpToken);
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
            
            pools[i].logo = logos[i];
            pools[i].name = names[i];
        }
        return pools;
    }
}