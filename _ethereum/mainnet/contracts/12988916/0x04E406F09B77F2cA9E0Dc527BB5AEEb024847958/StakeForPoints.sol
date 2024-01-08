pragma solidity ^0.8.0;

import "./IToken.sol";
import "./AccessControlUpgradeable.sol";
import "./IERC721Upgradeable.sol";

import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";

// Stake to get points
contract StakeForPoints is Initializable, AccessControlUpgradeable {
    using SafeMathUpgradeable for uint256;

    IToken public museLp;
    IToken public cudlLp;
    IToken public cudl;

    bool public gameStopped;

    bytes32 public OPERATOR_ROLE;

    mapping(uint256 => mapping(address => uint256)) public balanceByPool;
    mapping(address => uint256) public lastUpdateTime;

    mapping(address => uint256) public points;

    address[] public lpTokens;

    // This is a percentage to determine for each token on how much CUDL they contain to achieve 5 muse per day per token
    mapping(uint256 => uint256) public lpTokenMultiplayer;

    event Staked(address who, uint256 amount, uint256 poolId);
    event Withdrawal(address who, uint256 amount, uint256 poolId);

    constructor() {}

    modifier onlyOperator() {
        require(
            hasRole(OPERATOR_ROLE, _msgSender()),
            "Roles: caller does not have the OPERATOR role"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Roles: caller does not have the OPERATOR role"
        );
        _;
    }

    // function initialize() public initializer {
    //     museLp = IToken(0x94036F9A13Cc4312Ce29c6Ca364774EA97191215);
    //     cudlLp = IToken(0x6E5eC6403EDc2E9FA0759ba3a77a85B4462d8E2a);
    //     cudl = IToken(0xeCD20F0EBC3dA5E514b4454E3dc396E7dA18cA6A);

    //     gameStopped = false;
    //     OPERATOR_ROLE = keccak256("OPERATOR");

    //     lpTokens.push(0x6E5eC6403EDc2E9FA0759ba3a77a85B4462d8E2a); //cudl-eth
    //     lpTokenMultiplayer[0] = 100;

    //     lpTokens.push(0x9Cfc1d1A45F79246e8E074Cfdfc3f4AacddE8d9a); //SMUSE single staking
    //     lpTokenMultiplayer[1] = 200;

    //     // lpTokens.push(0x94036F9A13Cc4312Ce29c6Ca364774EA97191215); //muse-eth
    //     // lpTokenMultiplayer[1] = 100;

    //     // lpTokens.push(0xeCD20F0EBC3dA5E514b4454E3dc396E7dA18cA6A); //CUDL single staking
    //     // lpTokenMultiplayer[2] = 100;

    //     _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    // }

    modifier notPaused() {
        require(!gameStopped, "Contract is paused");
        _;
    }

    function setLpTokens(
        address coin,
        uint256 percentage,
        uint256 _index,
        bool isNew
    ) external onlyAdmin {
        if (isNew) {
            lpTokens.push(coin);

            lpTokenMultiplayer[lpTokens.length - 1] = percentage;
        } else {
            lpTokens[_index] = coin;
            lpTokenMultiplayer[_index] = percentage;
        }
    }

    // in case a bug happens or we upgrade to another smart contract
    function pauseGame(bool _pause) external onlyOperator {
        gameStopped = _pause;
    }

    function changeMultiplier(uint256 poolId, uint256 multiplier)
        external
        onlyAdmin
    {
        lpTokenMultiplayer[poolId] = multiplier;
    }

    modifier updateReward(address account) {
        if (account != address(0)) {
            points[account] = earned(account);
            lastUpdateTime[account] = block.timestamp;
        }
        _;
    }

    function earned(address account) public view returns (uint256) {
        uint256 timeElapsed = lastUpdateTime[account] == 0
            ? 0
            : block.timestamp - lastUpdateTime[account];

        uint256 _earned;

        for (uint256 i; i < lpTokens.length; i++) {
            _earned += balanceByPool[i][account]
                .mul(
                    timeElapsed.mul(2314814814814).mul(100).div(
                        lpTokenMultiplayer[i]
                    )
                )
                .div(1e18);
        }
        return _earned + points[account]; //add the previous earned points
    }

    function stake(uint256 poolId, uint256 _amount)
        external
        updateReward(msg.sender)
        notPaused
    {
        IToken token = IToken(lpTokens[poolId]);
        // transfer tokens to this address to stake them
        balanceByPool[poolId][msg.sender] = balanceByPool[poolId][msg.sender]
            .add(_amount);
        token.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount, poolId);
    }

    // withdraw part of your stake
    function withdraw(uint256 poolId, uint256 amount)
        public
        updateReward(msg.sender) ////TODO do we need this? Yes this reset pints/reawad for all pools
    {
        require(amount > 0, "Amount can't be 0");

        IToken token = IToken(lpTokens[poolId]);

        balanceByPool[poolId][msg.sender] = balanceByPool[poolId][msg.sender]
            .sub(amount);

        // transfer erc20 back from the contract to the user
        token.transfer(msg.sender, amount);
        emit Withdrawal(msg.sender, amount, poolId);
    }

    // withdraw all your amount staked in all pools
    function exit() external {
        for (uint256 i; i <= lpTokens.length; i++) {
            if (balanceByPool[i][msg.sender] > 0) {
                withdraw(i, balanceByPool[i][msg.sender]);
            }
        }
        points[msg.sender] = 0; // Added second line
        lastUpdateTime[msg.sender] = block.timestamp;
    }

    function burnPoints(address _user, uint256 amount)
        external
        updateReward(_user)
        onlyOperator
    {
        require(points[_user] > amount, "!forbidden");
        points[_user] -= amount;
    }
}
