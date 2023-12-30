pragma solidity 0.6.12;

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
}


interface IYFKA {
    function mint(address to, uint256 amount) external;
    function transferOwnership(address newOwner) external;
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
}

interface IYFKAController {
    function getEmissionRate() external view returns (uint256);
}

contract Stake is Ownable {
    using SafeMath for uint256;
    
    IERC20 public YFKA = IERC20(0x4086692D53262b2Be0b13909D804F0491FF6Ec3e);
    IERC20 public POOL = IERC20(0x34d0448A79F853d6E1f7ac117368C87BB7bEeA6B); // UNISWAP LP
    IYFKAController public CONTROLLER; // YFKA Controller
    
    mapping(address => uint256) lastWithdraw;
    mapping(address => uint256) stakes;
    mapping(address => uint256) emissions;
    
    uint256 public blocks_per_year = 2372500;
    uint precision = 1000000;
    
    // constructor(address _pool, address _controller) public {
    //     POOL = IERC20(_pool);
    //     CONTROLLER = IYFKAController(_controller);
    // }
    
    function setController(address _addr) public onlyOwner {
        CONTROLLER = IYFKAController(_addr);
    }
    
    function setPool(address _addr) public onlyOwner {
        POOL = IERC20(_addr);
    }
    
    function blockDelta() public view returns(uint256) {
        if (lastWithdraw[msg.sender] == 0) {
            return 0;
        }
        return block.number.sub(lastWithdraw[msg.sender]);
    }
    
    function stake(uint256 amount) internal {
        amount = amount.sub(10**3);

        mint();
        
        POOL.transferFrom(msg.sender, address(this), amount);
        stakes[msg.sender] = stakes[msg.sender].add(amount);
    }
    
    function unstake(uint256 amount) internal {
        amount = amount.sub(10**3);
        
        mint();
        resetPersonalRate();

        stakes[msg.sender] = stakes[msg.sender].sub(amount);

        POOL.transfer(msg.sender, amount);
    }
    
    function redeem() public {
        mint();
        resetPersonalRate();
    }
    
    function mint() internal {
        // MINT IT
        lastWithdraw[msg.sender] = block.number;
    }
    
    function resetPersonalRate() internal {
        emissions[msg.sender] = CONTROLLER.getEmissionRate();
    }
    
    function totalYFKAStaked() public view returns(uint256) {
        uint256 stakedLPTokens = POOL.balanceOf(address(this));
        uint256 totalLPTokens = POOL.totalSupply();
        
        uint256 totalYFKAInLP = YFKA.balanceOf(address(POOL));
    }
    
    function personalYFKAStaked() public view returns(uint256) {
        uint percentOfLPStaked = stakes[msg.sender].mul(precision).div(POOL.totalSupply());
        uint256 _yfkaStake = YFKA.balanceOf(address(POOL)).mul(percentOfLPStaked).div(precision);

        return _yfkaStake;
    }
    
    function currentReward() public view returns(uint256) {
        return personalYFKAStaked().mul(emissions[msg.sender]).mul(blockDelta()).div(blocks_per_year);
    }
}