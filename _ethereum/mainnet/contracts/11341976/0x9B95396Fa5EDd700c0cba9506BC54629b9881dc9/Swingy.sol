pragma solidity =0.6.6;

/*  ____                            
 / ___|_      _(_)_ __   __ _ _   _ 
 \___ \ \ /\ / / | '_ \ / _` | | | |
  ___) \ V  V /| | | | | (_| | |_| |
 |____/ \_/\_/ |_|_| |_|\__, |\__, |
                        |___/ |___/   
                        
 A price adaptive cryptocurrency designed for traders*/


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
    }

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
   
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

library Address {
 
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
       
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
         } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
         } else {
                revert(errorMessage);
    }
    }
    }
    }

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
        require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
    }
    }

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }
   
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
   
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
   
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    }
    
// 
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    }
    
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
    }

library FixedPoint {
   
    struct uq112x112 {
        uint224 _x;
    }
   
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }
   
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
    }

library UniswapV2OracleLibrary {
    using FixedPoint for *;

    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
    }
    }
    }

library UniswapV2Library {
    using SafeMath for uint;

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    }

contract SwingySeesaw {
   
   function SwingyRewardsTransfer(uint256 amount, uint256 durationSec) external {}
 
    }
    
contract Swingy is ERC20, Ownable, Pausable {
    using SafeMath for uint256;
   
    uint256 private constant abcdefg01000110 = 15;
    
    uint256 private constant abcdefghi01010101 = 6 * 1e4;
   
    uint256 private constant abcdefgh01001110 = 26 * 1e4;

    uint256 private constant abcdefghij01101000 = 45;
   
    uint256 private constant abcdefghijk01100001 = 11 * 1e2;
   
    uint256 private constant minburn = 22 * 1e3;
   
    uint256 private constant minmint = 36560;
   
    uint256 private constant maxmint = 9 * 1e4;
    
    uint256 private constant maxtransfer = 5 * 1e21;
    
    uint32 public blockTimestampLast;
   
    uint256 public TransferLast;

    uint256 public priceCumulativeLast;

    uint256 public priceAverageLast;

    uint256 public PriceUpdateInterval;
   
    uint256 public TransferInterval;
   
    uint256 public SeesawReleaseDuration;
    
    address private SwingyToken = address(this);
   
    address public constant WETH = address(0xd0A1E359811322d97991E03f863a0C30C2cF029C);

    address public constant uniswapV2Factory = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    
    address public immutable InitialSwingyAddress;  
    
    address public uniswapPair;
   
    mapping(address => bool) public whitelistedSenders;
   
    bool public isThisToken0;
    
    bool public TransferVariables; 

    event TwapUpdated(uint256 priceCumulativeLast, uint256 blockTimestampLast, uint256 priceAverageLast);
   
    event updateTransfer(uint256 TransferLast);
    
    SwingySeesaw _Seesaw;
   
 
    constructor(address _InitialSwingyAddress, uint256 _PriceUpdateInterval, uint256 _SeesawReleaseDuration)
    public
    Ownable()
    ERC20("Swingy", "SWING")
    {
        setPriceUpdateInterval(_PriceUpdateInterval);
        setSeesawReleaseDuration(_SeesawReleaseDuration);
        CalcTransferInterval();
        InitialSwingyAddress = _InitialSwingyAddress;
        _distributeSwing(_InitialSwingyAddress);
        _initializeSwingxETHPair();
        TransferVariables = true;
        _pause();
    
       
    }
    
    /*Modifier to be used with transfer function for initial launch to prevent early liquidity adds */
    modifier whenNotPausedOrWhitelisted(address sender) {
        require(!paused() || _isWhitelisted(sender), "SwingyToken is paused or you are not whitelisted");
        _;
    }
    
    /*unpause, unpauses SwingyToken to be tradeable after initial liquidity add */
     function unpause() external virtual onlyOwner {
        super._unpause();
    }
    
    /*SeesawReleaseDuration, the time in seconds for the transferred Swingy rewards to linearly release.*/
    function setSeesawReleaseDuration(uint256 _SeesawReleaseDuration) public onlyOwner {
        SeesawReleaseDuration = _SeesawReleaseDuration;
    }

    
    /*PriceUpdateInterval, the time in seconds of how often the SWINGETH pair price is updated.*/
    function setPriceUpdateInterval(uint256 _PriceUpdateInterval) public onlyOwner {
        PriceUpdateInterval = _PriceUpdateInterval;
    }
    
    /*initializePriceUpdates, initializes price tracking*/
    function initializePriceUpdates() external onlyOwner {
        require(blockTimestampLast == 0, "Price tracking already initialized");
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(uniswapPair);

        uint256 priceCumulative = isThisToken0 ? price1Cumulative : price0Cumulative;
       
        blockTimestampLast = blockTimestamp;
        priceCumulativeLast = priceCumulative;
        priceAverageLast = abcdefg01000110; 
    }
    
    /*setwhitelisted, immune to transfer variables, Uniswap pools + Seesaw pools.*/
    function setWhitelistedSender(address _address, bool _whitelisted) public onlyOwner {
        whitelistedSenders[_address] = _whitelisted;
    }
    
    /*EnableDisableTransferVariables, enable or disable transfer variables (mints/burns).*/
    function EnableDisableTransferVariables(bool _status) external onlyOwner {
        TransferVariables  = _status;
    }
    
    /*_distributeSwing, distributes SWING to the Initial Swingy Address for further distribution.*/
    function _distributeSwing(address _InitialSwingyAddress) internal {  
        _mint(address(_InitialSwingyAddress), 26 * 1e4 * 1e18);
        setWhitelistedSender(msg.sender, true);
        setWhitelistedSender(address(this), true);
    }
    
    /*_initializeSwingxETHPair, initializes the SWING/ETH uniswapPair.*/
    function _initializeSwingxETHPair() internal {
        (address token0, address token1) = UniswapV2Library.sortTokens(address(this), address(WETH));
        isThisToken0 = (token0 == address(this));
        uniswapPair = UniswapV2Library.pairFor(uniswapV2Factory, token0, token1);
        
    }
    
    /*_isWhitelisted, returns a bool (true/false) as of which an address is whitelisted or not.*/
    function _isWhitelisted(address _sender) internal view returns (bool) {
        return whitelistedSenders[_sender];
    }
    
    /*_TheSeesaw, sets the Seesaw Address*/
    function _TheSeesaw(address TheSeesaw) external onlyOwner {
        _Seesaw = SwingySeesaw(TheSeesaw);
        setWhitelistedSender(TheSeesaw, true);

    }
    
    /*approveSeesaw, SwingyToken contract approves the Seesaw address to spend SWING for _TransferSwingyRewards().*/
    function approveSeesaw() external onlyOwner returns (bool) {
        _approve(address(this), address(_Seesaw), 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        return true;
    }
    
     /*CalcTransferInterval, the randomly generated time in seconds of how often tranfers to the Seesaw can occur with a range of 1-3 hours*/
    function CalcTransferInterval() internal returns(uint256) {
    uint256 seed = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty +
        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) +
        block.gaslimit + 
        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)) +
        block.number
    )));
    
            TransferInterval = (seed - ((seed / 7200) * 7200)) +3600;
            return TransferInterval;
    }
    
    /*_TransferSwingyRewards, transfers minted Swingy Rewards to the Seesaw with release according to SeesawReleaseDuration. Cap of 5k SWING per interval, leaves .1%*/       
    function _TransferSwingyRewards() internal {
        uint256 LastTransfer = now - TransferLast;
        
        if (LastTransfer > TransferInterval) {
            ERC20 _SwingyToken = ERC20(SwingyToken);
            uint256 InitialRewardstoTransfer = _SwingyToken.balanceOf(address(this));
            uint256 abc01101011011001010110101100001010 = InitialRewardstoTransfer.div(1e3);
            uint256 abc01100110 = InitialRewardstoTransfer - abc01101011011001010110101100001010;
            uint256 zxy01110101 = abc01100110;
            uint256 fuk01101110 = abc01100110;
            uint256 RewardstoBurn;
        
           
        if (abc01100110 > maxtransfer) {
            abc01100110 = maxtransfer; 
            fuk01101110 = abc01100110;
            RewardstoBurn = zxy01110101 - fuk01101110;
            _Seesaw.SwingyRewardsTransfer(fuk01101110, SeesawReleaseDuration);
            super._burn(address(this), RewardstoBurn);
            TransferLast = now;
            CalcTransferInterval();
            
    }
    
        if (abc01100110 < maxtransfer) {
            _Seesaw.SwingyRewardsTransfer(fuk01101110, SeesawReleaseDuration);
            TransferLast = now;
            CalcTransferInterval();
       

    }
            emit updateTransfer(TransferLast);
    }
           
    }  
    
    /*_updateSwingyPrice, updates the current tracked SWING/ETH uniswapPair price according to PriceUpdateInterval.*/  
    function _updateSwingyPrice() internal virtual returns (uint256) {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(uniswapPair);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;

        if (timeElapsed > PriceUpdateInterval) {
            uint256 priceCumulative = isThisToken0 ? price1Cumulative : price0Cumulative;

            FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
                uint224((priceCumulative - priceCumulativeLast) / timeElapsed)
            );

            priceCumulativeLast = priceCumulative;
            blockTimestampLast = blockTimestamp;

            priceAverageLast = FixedPoint.decode144(FixedPoint.mul(priceAverage, 1 ether));

            emit TwapUpdated(priceCumulativeLast, blockTimestampLast, priceAverageLast);
    }

            return priceAverageLast;
       
    }
    
    /*_transfer, the general transfer function with variable mint/burns based on current SWING/ETH uniswapPair price. 
     * Mints can only occur when routing through Uniswap, but burns can and will take place outside.
     * Have fun with the rest.
     */ 
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override whenNotPausedOrWhitelisted(sender) {  
        
        if (!TransferVariables == false) {
             
        if (!_isWhitelisted(sender)) {
        uint256 a01010011 = _updateSwingyPrice();
        uint256 ab01010111 = abcdefgh01001110.mul(1e18);
        uint256 abc01001001 = ab01010111.mul(abcdefghij01101000).div(a01010011);
        uint256 abcd01001110 = abcdefg01000110;
        uint256 abcde01000111 = abcdefghi01010101;
        uint256 abcdef01011001 = abc01001001;
           
        if (abc01001001 >= maxmint) {
            abc01001001 = maxmint;
    }
       
        if (_isWhitelisted(recipient) == false) {
            abc01001001 = 1;
            abcd01001110 = 1;
            abcde01000111 = 1;
           
    }  
    
        uint256 abcdefghijklmnopqrstuvwxy0101001101010111010000010100111001000111 = amount.div(abcdef01011001).mul(abcdefghijk01100001);
        uint256 abcdefghijklmnopqrstuvwxyz0101001101010111010010010100111001000111 = amount.mul(abc01001001).div(abcd01001110).div(abcde01000111);
       
        if (abc01001001 >= minmint) {
            super._mint(address(this), abcdefghijklmnopqrstuvwxyz0101001101010111010010010100111001000111);
            _TransferSwingyRewards();
    }

        if (abc01001001 <= minburn) {
           super._burn(sender, abcdefghijklmnopqrstuvwxy0101001101010111010000010100111001000111);
           amount = amount.sub(abcdefghijklmnopqrstuvwxy0101001101010111010000010100111001000111);
           _totalSupply = _totalSupply.sub(abcdefghijklmnopqrstuvwxy0101001101010111010000010100111001000111);
           
    }    
   
    }  
    
    }
        super._transfer(sender, recipient, amount);
        
    }
    
    /*getCurrentSwingPerEth, grabs the current SWING per ETH.*/  
    function getCurrentSwingPerEth() public view returns (uint256) {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(uniswapPair);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;

        uint256 priceCumulative = isThisToken0 ? price1Cumulative : price0Cumulative;

        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
            uint224((priceCumulative - priceCumulativeLast) / timeElapsed)
        );

        return FixedPoint.decode144(FixedPoint.mul(priceAverage, 1 ether));
    }
    
    /*getLastSwingPerEth, grabs the last SWING per ETH.*/ 
    function getLastSwingPerEth() public view returns (uint256) {
        return priceAverageLast;
    }
   
    }