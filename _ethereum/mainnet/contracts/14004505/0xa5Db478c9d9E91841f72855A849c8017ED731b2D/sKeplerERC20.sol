// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./IStaking.sol";

contract sKeplerERC20 is ERC20 {

    using SafeMath for uint256;

    event StakingContractUpdated(address stakingContract);
    event LogSupply(uint256 indexed epoch, uint256 timestamp, uint256 totalSupply);
    event LogRebase(uint256 indexed epoch, uint256 rebase, uint256 index);

    address initializer;
    address public stakingContract; // balance used to calc rebase

    uint8 private constant _tokenDecimals = 9;
    uint INDEX; // Index Gons - tracks rebase growth
    uint _totalSupply;

    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 5000000 * 10**_tokenDecimals;

    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;
    mapping (address => mapping (address => uint256)) private _allowedValue;

    struct Rebase {
        uint epoch;
        uint rebase; // 18 decimals
        uint totalStakedBefore;
        uint totalStakedAfter;
        uint amountRebased;
        uint index;
        uint timeOccured;
    }

    Rebase[] public rebases; // past rebase data    

    modifier onlyStakingContract() {
        require(msg.sender == stakingContract);
        _;
    }

    constructor() ERC20("Staked Keeper", "TROVE") {
        _setupDecimals(_tokenDecimals);
        initializer = msg.sender;
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
    }

    function setIndex(uint _INDEX) external {
        require(msg.sender == initializer);
        require(INDEX == 0);
        require(_INDEX != 0);
        INDEX = gonsForBalance(_INDEX);
    }

    // do this last
    function initialize(address _stakingContract) external {
        require(msg.sender == initializer);
        require(_stakingContract != address(0));
        stakingContract = _stakingContract;
        _gonBalances[ stakingContract ] = TOTAL_GONS;

        emit Transfer(address(0x0), stakingContract, _totalSupply);
        emit StakingContractUpdated(_stakingContract);
        
        initializer = address(0);
    }

    /**
        @notice increases sKEEPER supply to increase staking balances relative to _profit
        @param _profit uint256
        @return uint256
    */
    function rebase(uint256 _profit, uint _epoch) public onlyStakingContract() returns (uint256) {
        uint256 rebaseAmount;
        uint256 _circulatingSupply = circulatingSupply();

        if (_profit == 0) {
            emit LogSupply(_epoch, block.timestamp, _totalSupply);
            emit LogRebase(_epoch, 0, index());
            return _totalSupply;
        }
        else if (_circulatingSupply > 0) {
            rebaseAmount = _profit.mul(_totalSupply).div(_circulatingSupply);
        }
        else {
            rebaseAmount = _profit;
        }

        _totalSupply = _totalSupply.add(rebaseAmount);
        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        _storeRebase(_circulatingSupply, _profit, _epoch);
        return _totalSupply;
    }

    /**
        @notice emits event with data about rebase
        @param _previousCirculating uint
        @param _profit uint
        @param _epoch uint
        @return bool
    */
    function _storeRebase(uint _previousCirculating, uint _profit, uint _epoch) internal returns (bool) {
        uint rebasePercent = _profit.mul(1e18).div(_previousCirculating);

        rebases.push(Rebase ({
            epoch: _epoch,
            rebase: rebasePercent, // 18 decimals
            totalStakedBefore: _previousCirculating,
            totalStakedAfter: circulatingSupply(),
            amountRebased: _profit,
            index: index(),
            timeOccured: uint32(block.timestamp)
        }));
        
        emit LogSupply(_epoch, block.timestamp, _totalSupply);
        emit LogRebase(_epoch, rebasePercent, index());
        return true;
    }

    /* =================================== VIEW FUNCTIONS ========================== */

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who) public view override returns (uint256) {
        return _gonBalances[ who ].div(_gonsPerFragment);
    }

    /**
     * @param who The address to query.
     * @return The gon balance of the specified address.
     */
    function scaledBalanceOf(address who) external view returns (uint256) {
        return _gonBalances[who];
    }

    function gonsForBalance(uint amount) public view returns (uint) {
        return amount * _gonsPerFragment;
    }

    function balanceForGons(uint gons) public view returns (uint) {
        return gons / _gonsPerFragment;
    }

    // Staking contract holds excess sKEEPER
    function circulatingSupply() public view returns (uint) {
        return _totalSupply.sub(balanceOf(stakingContract)).add(IStaking(stakingContract).supplyInWarmup());
    }

    function index() public view returns (uint) {
        return balanceForGons(INDEX);
    }

    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowedValue[ owner_ ][ spender ];
    }

    /* ================================= MUTATIVE FUNCTIONS ====================== */

    function transfer(address to, uint256 value) public override returns (bool) {
        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[ msg.sender ] = _gonBalances[ msg.sender ].sub(gonValue);
        _gonBalances[ to ] = _gonBalances[ to ].add(gonValue);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
       _allowedValue[ from ][ msg.sender ] = _allowedValue[ from ][ msg.sender ].sub(value);
       emit Approval(from, msg.sender,  _allowedValue[ from ][ msg.sender ]);

        uint256 gonValue = gonsForBalance(value);
        _gonBalances[ from ] = _gonBalances[from].sub(gonValue);
        _gonBalances[ to ] = _gonBalances[to].add(gonValue);
        emit Transfer(from, to, value);
        return true;
    }

    function _approve(address owner, address spender, uint256 value) internal override virtual {
        _allowedValue[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function approve(address spender, uint256 value) public override returns (bool) {
         _allowedValue[ msg.sender ][ spender ] = value;
         emit Approval(msg.sender, spender, value);
         return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
        _allowedValue[ msg.sender ][ spender ] = _allowedValue[ msg.sender ][ spender ].add(addedValue);
        emit Approval(msg.sender, spender, _allowedValue[ msg.sender ][ spender ]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
        uint256 oldValue = _allowedValue[ msg.sender ][ spender ];
        if (subtractedValue >= oldValue) {
            _allowedValue[ msg.sender ][ spender ] = 0;
        } else {
            _allowedValue[ msg.sender ][ spender ] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedValue[ msg.sender ][ spender ]);
        return true;
    }
}