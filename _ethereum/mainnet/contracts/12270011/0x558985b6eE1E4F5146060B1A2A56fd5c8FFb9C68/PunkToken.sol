// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";
import "./ERC1967Proxy.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

contract ERC20Initialize is ERC20, Initializable{

    function initialize( string memory name_, string memory symbol_, uint8 decimals_ ) public initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }
    
}

contract OwnableStorage {

    address public _admin;
    address public _governance;

    constructor() payable {
        _admin = msg.sender;
        _governance = msg.sender;
    }

    function setAdmin( address account ) public {
        require( isAdmin( msg.sender ), "Not a admin" );
        _admin = account;
    }

    function setGovernance( address account ) public {
        require( isAdmin( msg.sender ) || isGovernance( msg.sender ), "Not a admin or governance" );
        _admin = account;
    }

    function isAdmin( address account ) public view returns( bool ) {
        return account == _admin;
    }

    function isGovernance( address account ) public view returns( bool ) {
        return account == _admin;
    }

}

contract Ownable{

    OwnableStorage _storage;

    function initialize( address storage_ ) public {
        _storage = OwnableStorage(storage_);
    }

    modifier OnlyAdmin(){
        require( _storage.isAdmin(msg.sender), "Not a admin" );
        _;
    }

    modifier OnlyGovernance(){
        require( _storage.isGovernance( msg.sender ), "Not a Governance" );
        _;
    }

    modifier OnlyAdminOrGovernance(){
        require( _storage.isAdmin(msg.sender) || _storage.isGovernance( msg.sender ), "Not a Admin or Governance" );
        _;
    }

    function updateAdmin( address admin_ ) public OnlyAdmin {
        _storage.setAdmin(admin_);
    }

    function updateGovenance( address gov_ ) public OnlyAdminOrGovernance {
        _storage.setGovernance(gov_);
    }

}

contract InitializableProxy is Proxy, Initializable{

    function initialize( address implAddress, bytes memory initData ) public virtual initializer{
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(implAddress);
        if(initData.length > 0) {
            Address.functionDelegateCall(implAddress, initData);
        }  
    }

    event Upgraded(address indexed implementation);

    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967Proxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }

}

contract PunkRewardPoolProxy is InitializableProxy{

    function initialize( address implAddress, bytes memory initData ) public override initializer{
        require(msg.sender == address(0xd82348b97d8BADd471097AD60e37B1d34fAD4BE2), "Only 0xd82348b97d8BADd471097AD60e37B1d34fAD4BE2");
        super.initialize( implAddress, initData );
    }
    
    function upgrade( address addr ) public {
        require(msg.sender == address(0xd82348b97d8BADd471097AD60e37B1d34fAD4BE2), "Only 0xd82348b97d8BADd471097AD60e37B1d34fAD4BE2");
        _upgradeTo( addr );
    }

}

contract VestingPunk is Initializable{
    using SafeMath for uint;

    address _punkToken;
    address _holder;
    
    uint _lockPeriod = 2 * 365 * 24 * 60 * 60;
    uint _startTimestamp = 1622473200;
    uint _released = 0;
    
    function initialize( address punkToken_, address holder_ ) public initializer {
        _punkToken = punkToken_;
        _holder = holder_;
    }

    function release() public {
        require( _startTimestamp <= _currentTimestamp(), "not yet Jun 01, 2021" );
        uint ableAmount = releasable();
        if( ableAmount > _currentBalance() ){
            ableAmount = _currentBalance();
        }
        IERC20( _punkToken ).transfer( _holder, ableAmount );
        _released += ableAmount;
    }

    function released() public view returns ( uint ){
        return _released;
    }

    function releasable() public view returns( uint ){
        if( _startTimestamp > _currentTimestamp() ) return 0;
        if( _currentBalance() == 0 ) return 0;
        return ( ( _currentBalance().add( _released ) ).mul( _currentTimestamp() - _startTimestamp ).div( _lockPeriod ) ).sub( _released );
    }

    function _currentBalance() private view returns( uint ){
        return IERC20( _punkToken ).balanceOf( address( this ) );
    }

    function _currentTimestamp() private view returns( uint ){
        return block.timestamp;
    }

}

contract PunkToken is ERC20Initialize, Ownable{
    using Address for address;

    function initializePunk(
            address ownableStorage,
            address airdropControlAddress,
            address earlyContributorControlAddress,
            address devFundsVestingContract, 
            address rewardPoolForSaverContract,
            address rewardPoolForFutureProduct1Contract,
            address rewardPoolForFutureProduct2Contract
            ) public {

        require(Address.isContract(devFundsVestingContract), "devFundsVestingContract is not Contract address");
        require(Address.isContract(rewardPoolForSaverContract), "rewardPoolForSaverContract is not Contract address");
        require(Address.isContract(rewardPoolForFutureProduct1Contract), "rewardPoolForFutureProduct1Contract is not Contract address");
        require(Address.isContract(rewardPoolForFutureProduct2Contract), "rewardPoolForFutureProduct2Contract is not Contract address");

        Ownable.initialize( ownableStorage );

        ERC20Initialize.initialize(
            "Punk Token",
            "PUNK",
            18);
        
        _mint( airdropControlAddress, 2100000e18 );

        _mint( earlyContributorControlAddress, 2100000e18 );
        _mint( devFundsVestingContract, 2100000e18 );
        
        _mint( rewardPoolForSaverContract, 10500000e18 );
        _mint( rewardPoolForFutureProduct1Contract, 2100000e18 );
        _mint( rewardPoolForFutureProduct2Contract, 2100000e18 );

    }

    function setDecimals( uint8 decimals_ ) public OnlyAdmin {
        require(decimals_ != decimals(), "Equals Decimals");
        _decimals = decimals_;
    }
}

// Not Ready
contract PunkRewardPool is Ownable, Initializable{
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 _punkToken;

    uint startBlock;
    uint blockYear = 4 * 60 * 24 * 365;
    
    uint initialEvent = 4 * 60 * 24 * 7 * 4;
    uint eventWeight = 2;
    uint normalWeight = 3;

    uint _weightSum;
    uint released;

    address [] _products;
    mapping ( address => bool ) _checkProducts;
    mapping ( address => uint ) _totalSupply;
    mapping ( address => uint ) _weight;
    
    mapping ( address => mapping( address=>uint ) ) _balances;
    mapping ( address => mapping( address=>uint ) ) _updateTimes;
    mapping ( address => mapping( address=>uint ) ) _perBlock;

    mapping ( address => mapping( address=>uint ) ) _released_per_products;


    modifier checkProduct( address productAddr ){
        require(_checkProducts[productAddr]);
        _;
    }

    function initializeRewardPool( address punkToken_ ) public initializer{
        _punkToken = IERC20(punkToken_);
        blockYear = 4 * 60 * 24 * 365;
        initialEvent = 4 * 60 * 24 * 7 * 4;
        eventWeight = 2;
        normalWeight = 3;
        _weightSum = 0;
        released = 0;
    }
    
    function enterRewardPool( address productAddr, uint amounts ) public checkProduct( productAddr ){
        IERC20( productAddr ).safeTransferFrom( msg.sender, address(this), amounts );
        _totalSupply[productAddr] = _totalSupply[productAddr].add( amounts );
        _balances[productAddr][msg.sender] = _balances[productAddr][msg.sender].add( amounts );
    }

    function exitRewardPool( address productAddr, uint amounts ) public checkProduct( productAddr ){
        IERC20( productAddr ).safeTransfer( msg.sender, amounts );
        _totalSupply[productAddr] = _totalSupply[productAddr].sub( amounts );
        _balances[productAddr][msg.sender] = _balances[productAddr][msg.sender].sub( amounts );
    }

    function addProduct( address productAddr ) public {
        require(!_checkProducts[productAddr], "Already adding product");
        require(IERC20(productAddr).totalSupply() > 0, "is Empty token");

        if( _products.length == 0 ) startBlock = block.number;
        
        _products.push( productAddr );
        _checkProducts[productAddr] = true;
    }

    function getStartBlock(  ) public view returns ( uint ){
        return startBlock;
    }

    function products() public view returns( address [] memory  ){
        return _products;
    }

    function updateWeights( address [] calldata productAddrs, uint [] calldata weights ) public {
        require( productAddrs.length == weights.length );
        require( productAddrs.length == _products.length );

        _weightSum = 0;
        for( uint i = 0 ; i < productAddrs.length ; i++ ){
            _weight[productAddrs[i]] = weights[i];
            _weightSum += weights[i];
        }
    }

    function getRewardFromBlock( ) public view returns( uint ){
        if( block.number.sub(startBlock) < initialEvent ){
            // Events
            uint totalDistribution =_punkToken.balanceOf(address(this)).add( released ).mul( eventWeight ).div( eventWeight.add( normalWeight ) );
            
            return totalDistribution;
            
        }else{

            uint totalDistribution =_punkToken.balanceOf(address(this)).add( released ).mul( normalWeight ).div( eventWeight.add( normalWeight ) );
            uint period = block.number.sub( startBlock.add( initialEvent ) ).div( blockYear.mul(4) ).add( 1 );

            return totalDistribution.div( period.mul( 2 ) );
        }

        // return block.number.sub( fromBlock ).mul(origin).div( getPeriod().mul( 2 ) ).div( 4 ).div( blockYear );
    }
    
    function getPeriod( ) public view returns ( uint ){
        return block.number.sub( startBlock ).div( blockYear.mul(4) ).add( 1 );
    }

    function getRewardFromBlockEvent( uint fromBlock ) public view returns( uint ){
        uint period = block.number.sub(startBlock).div( blockYear.mul(4) ).add( 1 ).mul( 2 );
        uint origin = _punkToken.balanceOf(address(this)).add( released );
        return block.number.sub( fromBlock ).mul(origin).div( period ).div( 4 ).div( blockYear );
    }

    function transfer( address to, uint amount ) public returns(bool){
        _punkToken.safeTransfer(to, amount);
        return true;
    }

    function balanceOf( address addr ) public view returns( uint ) {
        return _punkToken.balanceOf(addr);
    }

    function totalSupply( address addr, address addr2 ) public view returns( uint ){
        return _perBlock[addr][addr2];
    }

}
