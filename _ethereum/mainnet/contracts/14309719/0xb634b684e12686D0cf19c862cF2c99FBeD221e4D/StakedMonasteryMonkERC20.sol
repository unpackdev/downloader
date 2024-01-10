// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./ERC20.sol";
import "./Ownable.sol";

contract StakedMonasteryERC20 is ERC20Permit, Ownable {

    using SafeMath for uint256;

    modifier onlyStakingContract() {
        require( msg.sender == stakingContract );
        _;
    }

    address public stakingContract;
    address public initializer;

    event LogSupply(uint256 indexed epoch, uint256 timestamp, uint256 totalSupply );
    event LogRebase( uint256 indexed epoch, uint256 rebase, uint256 index );
    event LogStakingContractUpdated( address stakingContract );

    struct Rebase {
        uint epoch;
        uint rebase; // 18 decimals
        uint totalStakedBefore;
        uint totalStakedAfter;
        uint amountRebased;
        uint index;
        uint blockNumberOccured;
    }
    Rebase[] public rebases;

    uint public INDEX;

    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 5000000 * 10**9;

    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private constant MAX_SUPPLY = ~uint128(0);

    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    uint256 internal _NtotalSupply;
    uint256 private _NgonsPerFragment;
    mapping(address => bool) public _isN;

    uint256 internal BASIS_POINTS = 10_000;
    uint256 public pValue; // IN Bps

    uint256 public NTG;
    uint256 private lossSupply;

    mapping ( address => mapping ( address => uint256 ) ) private _allowedValue;

    constructor(uint256 pVal) ERC20("Staked Monastery", "ZEN", 9) ERC20Permit() {
        initializer = msg.sender;

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        _NtotalSupply = _totalSupply;
        _NgonsPerFragment = _gonsPerFragment;
        pValue = pVal;
    }

    function initialize( address stakingContract_ ) external returns ( bool ) {
        require( msg.sender == initializer );
        require( stakingContract_ != address(0) );
        stakingContract = stakingContract_;
        _gonBalances[ stakingContract ] = TOTAL_GONS;

        emit Transfer( address(0x0), stakingContract, _totalSupply );
        emit LogStakingContractUpdated( stakingContract_ );

        initializer = address(0);
        return true;
    }

    function setIndex( uint _INDEX ) external onlyOwner() returns ( bool ) {
        require( INDEX == 0 );
        INDEX = gonsForBalance( _INDEX );
        return true;
    }

    function setPValue( uint256 pVal ) external onlyOwner() {
        require( pVal > 0 && pVal < BASIS_POINTS );
        pValue = pVal;
    }

    function rebase( uint256 profit_, uint epoch_ ) public onlyStakingContract() returns ( uint256 ) {
        uint256 rebaseAmount;
        uint256 circulatingSupply_ = circulatingSupply();

        if ( profit_ == 0 ) {
            emit LogSupply( epoch_, block.timestamp, totalSupply() );
            emit LogRebase( epoch_, 0, index() );
            return totalSupply();
        } else if ( circulatingSupply_ > 0 ){
            rebaseAmount = profit_.mul( totalSupply() ).div( circulatingSupply_ );
        } else {
            rebaseAmount = profit_;
        }

        uint256 reducedRebaseAmount = rebaseAmount.mul(pValue).div(BASIS_POINTS);
        uint256 extraRebaseAmount = rebaseAmount.sub(reducedRebaseAmount);

        _NtotalSupply = _NtotalSupply.add(rebaseAmount);
        _totalSupply = _totalSupply.add( reducedRebaseAmount );

        if ( _NtotalSupply > MAX_SUPPLY ) {
            _NtotalSupply = MAX_SUPPLY;
            lossSupply = 0;
            extraRebaseAmount = 0;
        }

        if ( _totalSupply > MAX_SUPPLY ) {
            _totalSupply = MAX_SUPPLY;
        }

        updateGons();
        if (extraRebaseAmount > 0) {
            manage(extraRebaseAmount);
        }

        _storeRebase( circulatingSupply_, profit_, epoch_ );

        return totalSupply();
    }

    function manage(uint256 extraRebaseAmount) private {
        uint256 value = _NtotalSupply.sub(NbalanceForGons(NTG)).mul(extraRebaseAmount).div(_NtotalSupply);
        lossSupply = lossSupply.add(value);
    }

    function _storeRebase( uint previousCirculating_, uint profit_, uint epoch_ ) internal returns ( bool ) {
        uint rebasePercent = profit_.mul( 1e18 ).div( previousCirculating_ );

        rebases.push( Rebase ( {
            epoch: epoch_,
            rebase: rebasePercent, // 18 decimals
            totalStakedBefore: previousCirculating_,
            totalStakedAfter: circulatingSupply(),
            amountRebased: profit_,
            index: index(),
            blockNumberOccured: block.number
        }));

        emit LogSupply( epoch_, block.timestamp, totalSupply() );
        emit LogRebase( epoch_, rebasePercent, index() );

        return true;
    }

    function updateGons() private {
        _NgonsPerFragment = TOTAL_GONS.div( _NtotalSupply );
        _gonsPerFragment = TOTAL_GONS.div( _totalSupply );
    }

    function boost(address who) public onlyStakingContract() {
        require(!_isN[who], "Already boosted");
        _gonBalances[who] = NgonsForBalance(balanceOf(who));
        NTG = NTG.add(_gonBalances[who]);
        _isN[who] = true;
    }

    function unboost(address who) public onlyStakingContract() {
        require(_isN[who], "Not boosted");
        NTG = NTG.sub(_gonBalances[who]);
        _gonBalances[who] = gonsForBalance(balanceOf(who));
        _isN[who] = false;
    }

    function balanceOf( address who ) public view override returns ( uint256 ) {
        if (_isN[who]) {
            return NbalanceForGons(_gonBalances[ who ]);
        }
        return balanceForGons(_gonBalances[ who ]);
    }

    function gonsForBalance( uint amount ) public view returns ( uint ) {
        return amount.mul( _gonsPerFragment );
    }

    function balanceForGons( uint gons ) public view returns ( uint ) {
        return gons.div( _gonsPerFragment );
    }

    function NgonsForBalance( uint amount ) public view returns ( uint ) {
        return amount.mul( _NgonsPerFragment );
    }

    function NbalanceForGons( uint gons ) public view returns ( uint ) {
        return gons.div( _NgonsPerFragment );
    }

    function totalSupply() public view override returns (uint256) {
        return _NtotalSupply.sub(lossSupply);
    }

    function circulatingSupply() public view returns ( uint ) {
        return totalSupply().sub( balanceOf( stakingContract ) );
    }

    function index() public view returns ( uint ) {
        return NbalanceForGons( INDEX );
    }

    function transferToN(address from, address to, uint256 value ) private {
        _gonBalances[ from ] = _gonBalances[from].sub(gonsForBalance(value), "ERC20: transfer amount exceeds balance");
        _gonBalances[ to ] = _gonBalances[to].add(NgonsForBalance(value));
        NTG = NTG.add(NgonsForBalance(value));
    }

    function transferFromN(address from, address to, uint256 value ) private {
        _gonBalances[ from ] = _gonBalances[ from ].sub(NgonsForBalance(value), "ERC20: transfer amount exceeds balance");
        _gonBalances[ to ] =  _gonBalances[ to ].add(gonsForBalance(value));
        NTG = NTG.sub(NgonsForBalance(value));
    }

    function transferSimpleN(address from, address to, uint256 value ) private{
        uint256 gonValue = NgonsForBalance(value);
        _gonBalances[ from ] = _gonBalances[ from ].sub(gonValue, "ERC20: transfer amount exceeds balance");
        _gonBalances[ to ] = _gonBalances[ to ].add(gonValue);
    }

    function transferSimple(address from, address to, uint256 value ) private {
        uint256 gonValue = gonsForBalance(value);
        _gonBalances[ from ] = _gonBalances[ from ].sub(gonValue, "ERC20: transfer amount exceeds balance");
        _gonBalances[ to ] = _gonBalances[ to ].add( gonValue );
    }

    function _transfer(address from, address to, uint256 value) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        bool isNFrom = _isN[from];
        bool isNTo = _isN[to];
        if (!isNFrom && isNTo) {
            transferToN(from, to, value);
        } else if (isNFrom && !isNTo) {
            transferFromN(from, to, value);
        } else if (!isNFrom && !isNTo) {
            transferSimple(from, to, value);
        } else if (isNFrom && isNTo) {
            transferSimpleN(from, to, value);
        }
    }

    function transfer( address to, uint256 value ) public override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function allowance( address owner_, address spender ) public view override returns ( uint256 ) {
        return _allowedValue[ owner_ ][ spender ];
    }

    function transferFrom( address from, address to, uint256 value ) public override returns ( bool ) {
        _allowedValue[ from ][ msg.sender ] = _allowedValue[ from ][ msg.sender ].sub( value, "ERC20: decreased allowance below zero" );
        emit Approval( from, msg.sender,  _allowedValue[ from ][ msg.sender ] );

        _transfer(from, to, value);

        emit Transfer( from, to, value );

        return true;
    }

    function approve( address spender, uint256 value ) public override returns (bool) {
         _allowedValue[ msg.sender ][ spender ] = value;
         emit Approval( msg.sender, spender, value );
         return true;
    }

    function _approve( address owner, address spender, uint256 value ) internal override virtual {
        _allowedValue[owner][spender] = value;
        emit Approval( owner, spender, value );
    }

    function increaseAllowance( address spender, uint256 addedValue ) public override returns (bool) {
        _allowedValue[ msg.sender ][ spender ] = _allowedValue[ msg.sender ][ spender ].add( addedValue );
        emit Approval( msg.sender, spender, _allowedValue[ msg.sender ][ spender ] );
        return true;
    }

    function decreaseAllowance( address spender, uint256 subtractedValue ) public override returns (bool) {
        uint256 oldValue = _allowedValue[ msg.sender ][ spender ];
        if (subtractedValue >= oldValue) {
            _allowedValue[ msg.sender ][ spender ] = 0;
        } else {
            _allowedValue[ msg.sender ][ spender ] = oldValue.sub( subtractedValue );
        }
        emit Approval( msg.sender, spender, _allowedValue[ msg.sender ][ spender ] );
        return true;
    }
}
