pragma solidity ^0.6.2;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";

contract Roles is AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());
    }

    modifier onlyMinter() {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Roles: caller does not have the MINTER role"
        );
        _;
    }

    modifier onlyOperator() {
        require(
            hasRole(OPERATOR_ROLE, _msgSender()),
            "Roles: caller does not have the OPERATOR role"
        );
        _;
    }
}

// Interface for fight erc20 token
interface IFightToken {
    function totalSupply() external view returns (uint256);

    function cap() external view returns (uint256);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    function mintingFinished() external view returns (bool);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// Stake to get vnfts
contract StakingContract is Roles {
    using SafeMath for uint256;

    IERC20 public warToken;
    IFightToken public fightToken;

    // min $war amount required to stake
    uint256 public minStake = 5 * 10**18;

    // amount of points needed to redeem a vnft, roughly 1 point is given each day;
    uint256 public totalStaked;
    uint256 public rate = 86400; // 1 day
    bool public gameStopped = false;

    mapping(address => uint256) public balance;
    mapping(address => uint256) public lastUpdateTime;
    mapping(address => uint256) public points;

    event Staked(address who, uint256 amount);
    event Withdrawal(address who, uint256 amount);
    event StakeReqChanged(uint256 newAmount);
    event Redeemed(address who, uint256 amount);
    event RateChanged(uint256 newRate);

    constructor(address _fightToken, address _warToken) public {
        fightToken = IFightToken(_fightToken);
        warToken = IERC20(_warToken);
    }

    modifier notPaused() {
        require(!gameStopped, "Contract is paused");
        _;
    }

    // in case a bug happens or we upgrade to another smart contract
    function pauseGame(bool _pause) external onlyOperator {
        gameStopped = _pause;
    }

    // changes stake requirement
    function changeStakeReq(uint256 _newAmount) external onlyOperator {
        minStake = _newAmount;
        emit StakeReqChanged(_newAmount);
    }

    function updateRate(uint256 _newRate) external onlyOperator {
        rate = _newRate;
        emit RateChanged(_newRate);
    }

    modifier updateReward(address account) {
        if (account != address(0)) {
            points[account] = earned(account);
            lastUpdateTime[account] = block.timestamp;
        }
        _;
    }

    //calculate how many points earned so far, this needs to give roughly 1 point a day per 5 tokens staked?.
    function earned(address account) public view returns (uint256) {
        uint256 blockTime = block.timestamp;
        return
            balance[account] // decimals are baked into this
                .mul(blockTime
                    .sub(lastUpdateTime[account])
                    .div(rate)
                    )
                .add(
                    points[account]
                    );
                //.div(1e18)
    }

    function stake(uint256 _amount)
        external
        updateReward(msg.sender)
        notPaused
    {
        require(
            _amount >= minStake,
            "You need to stake at least the min war"
        );

        // transfer tokens to this address to stake them
        totalStaked = totalStaked.add(_amount);
        balance[msg.sender] = balance[msg.sender].add(_amount);
        warToken.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    // withdraw part of your stake
    function withdraw(uint256 amount) internal updateReward(msg.sender) {
        require(amount > 0, "Amount can't be 0");
        require(totalStaked >= amount);
        points[msg.sender] = 0;
        lastUpdateTime[msg.sender] = 0;
        balance[msg.sender] = balance[msg.sender].sub(amount);
        totalStaked = totalStaked.sub(amount);
        // transfer erc20 back from the contract to the user
        warToken.transfer(msg.sender, amount);
        emit Withdrawal(msg.sender, amount);
    }

    // withdraw all your amount staked
    function exit() external notPaused {
        redeem();
        withdraw(balance[msg.sender]);
    }

    //todo: redeem should redeem all credits
    function redeem() public updateReward(msg.sender) notPaused {
        uint256 redeeming;
        if ( fightToken.cap() - fightToken.totalSupply() < points[msg.sender]) {
            redeeming = fightToken.cap() - fightToken.totalSupply();
        } else { 
            redeeming = points[msg.sender]; 
        }
        points[msg.sender] = 0;
        lastUpdateTime[msg.sender] = block.timestamp;
        fightToken.mint(msg.sender, redeeming);
        emit Redeemed(msg.sender,redeeming);   
    }
}
