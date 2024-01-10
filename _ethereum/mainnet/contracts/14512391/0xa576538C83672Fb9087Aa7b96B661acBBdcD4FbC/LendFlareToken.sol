// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "./SafeMath.sol";
import "./Initializable.sol";
import "./IERC20.sol";

contract LendFlareToken is Initializable, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 public constant YEAR = 1 days * 365;
    uint256 public constant INITIAL_RATE = (274815283 * 10**18) / YEAR; // leading to 43% premine
    uint256 public constant RATE_REDUCTION_TIME = YEAR;
    uint256 public constant RATE_REDUCTION_COEFFICIENT = 1189207115002721024; // 2 ** (1/4) * 1e18
    uint256 public constant RATE_DENOMINATOR = 10**18;

    uint256 public startEpochTime;
    uint256 public startEpochSupply;
    uint256 public miningEpoch;
    uint256 public rate;
    uint256 public version;

    address public multiSigUser;
    address public owner;
    address public minter;
    address public liquidityTransformer;

    bool public liquidity;

    event UpdateMiningParameters(uint256 time, uint256 rate, uint256 supply);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    event SetMinter(address minter);
    event SetOwner(address owner);
    event LiquidityTransformer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    // @custom:oz-upgrades-unsafe-allow constructor
    constructor() public initializer {}

    function initialize(address _owner, address _multiSigUser)
        public
        initializer
    {
        _name = "LendFlare DAO Token";
        _symbol = "LFT";
        _decimals = 18;
        version = 1;

        owner = _owner;
        multiSigUser = _multiSigUser;

        startEpochTime = block.timestamp.sub(RATE_REDUCTION_TIME);

        miningEpoch = 0;
        rate = 0;
        startEpochSupply = 0;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "LendFlareToken: caller is not the owner");
        _;
    }

    modifier onlyLiquidityTransformer() {
        require(
            liquidityTransformer == msg.sender,
            "LendFlareToken: caller is not the liquidityTransformer"
        );
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;

        emit SetOwner(_owner);
    }

    function setLiquidityTransformer(address _v) public onlyOwner {
        require(_v != address(0), "!_v");
        require(liquidityTransformer == address(0), "!liquidityTransformer");

        liquidityTransformer = _v;

        uint256 supply = 909090909 * 10**18;

        _balances[liquidityTransformer] = supply;
        _totalSupply = _totalSupply.add(supply);

        startEpochSupply = startEpochSupply.add(supply);

        emit LiquidityTransformer(address(0), multiSigUser, supply);
    }

    function setLiquidityFinish() external onlyLiquidityTransformer {
        require(!liquidity, "!liquidity");

        uint256 officialTeam = 90909090 * 10**18;
        uint256 merkleAirdrop = 30303030 * 10**18;
        uint256 earlyLiquidityReward = 151515151 * 10**18;
        uint256 community = 121212121 * 10**18;

        uint256 supply = officialTeam
            .add(merkleAirdrop)
            .add(earlyLiquidityReward)
            .add(community);

        _balances[multiSigUser] = supply;
        _totalSupply = _totalSupply.add(supply);

        startEpochSupply = startEpochSupply.add(supply);

        liquidity = true;

        emit Transfer(address(0), multiSigUser, officialTeam);
        emit Transfer(address(0), multiSigUser, merkleAirdrop);
        emit Transfer(address(0), multiSigUser, earlyLiquidityReward);
        emit Transfer(address(0), multiSigUser, community);
    }

    function _updateMiningParameters() internal {
        startEpochTime = startEpochTime.add(RATE_REDUCTION_TIME);

        miningEpoch++;

        if (rate == 0) {
            rate = INITIAL_RATE;
        } else {
            startEpochSupply = startEpochSupply.add(
                rate.mul(RATE_REDUCTION_TIME)
            );

            rate = rate.mul(RATE_DENOMINATOR).div(RATE_REDUCTION_COEFFICIENT);
        }

        emit UpdateMiningParameters(block.timestamp, rate, startEpochSupply);
    }

    function updateMiningParameters() external {
        require(
            block.timestamp >= startEpochTime.add(RATE_REDUCTION_TIME),
            "too soon!"
        );

        _updateMiningParameters();
    }

    function startEpochTimeWrite() external returns (uint256) {
        if (block.timestamp >= startEpochTime.add(RATE_REDUCTION_TIME)) {
            _updateMiningParameters();
        }

        return startEpochTime;
    }

    function futureEpochTimeWrite() external returns (uint256) {
        if (block.timestamp >= startEpochTime.add(RATE_REDUCTION_TIME)) {
            _updateMiningParameters();
        }

        return startEpochTime.add(RATE_REDUCTION_TIME);
    }

    function availableSupply() public view returns (uint256) {
        return
            startEpochSupply.add(block.timestamp.sub(startEpochTime).mul(rate));
    }

    function setMinter(address _minter) public onlyOwner {
        require(_minter != address(0), "!_minter");

        minter = _minter;

        emit SetMinter(_minter);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address user, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[user][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function mint(address account, uint256 amount) public returns (bool) {
        require(msg.sender == minter, "!minter");
        require(account != address(0), "mint to the zero address");
        require(liquidity, "!liquidity");

        if (block.timestamp >= startEpochTime.add(RATE_REDUCTION_TIME)) {
            _updateMiningParameters();
        }

        _totalSupply = _totalSupply.add(amount);

        require(
            _totalSupply <= availableSupply(),
            "exceeds allowable mint amount"
        );

        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) public returns (bool) {
        _balances[msg.sender] = _balances[msg.sender].sub(
            amount,
            "burn amount exceeds balance"
        );

        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(msg.sender, address(0), amount);
    }

    function _approve(
        address user,
        address spender,
        uint256 amount
    ) internal virtual {
        require(user != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[user][spender] = amount;
        emit Approval(user, spender, amount);
    }
}
