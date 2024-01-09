// SPDX-License-Identifier: MIT

// /$$$$$$$   /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$  /$$     /$$
//| $$__  $$ /$$__  $$ /$$__  $$| $$__  $$ /$$__  $$|  $$   /$$/
//| $$  \ $$| $$  \ $$| $$  \ $$| $$  \ $$| $$  \ $$ \  $$ /$$/
//| $$$$$$$/| $$  | $$| $$  | $$| $$$$$$$/| $$$$$$$$  \  $$$$/
//| $$____/ | $$  | $$| $$  | $$| $$____/ | $$__  $$   \  $$/
//| $$      | $$  | $$| $$  | $$| $$      | $$  | $$    | $$
//| $$      |  $$$$$$/|  $$$$$$/| $$      | $$  | $$    | $$
//|__/       \______/  \______/ |__/      |__/  |__/    |__/

pragma solidity =0.8.9;

import "IERC20.sol";
import "Context.sol";
import "Ownable.sol";
import "Address.sol";
import "SafeMath.sol";
import "IUniswapV2Factory.sol";
import "IUniswapV2Router01.sol";
import "IUniswapV2Router02.sol";

contract PooPay is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExemptFromFee;

    string private constant _name = "PooPay";
    string private constant _symbol = "POO";
    uint8 private constant _decimals = 18;

    uint256 private constant _totalSupply = 10000000000 * 10**18;

    address public burnWallet = 0x000000000000000000000000000000000000dEaD;
    address public marketingWallet;
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;

    uint256 public _marketingFee = 3;
    uint256 private _previousMarketingFee = _marketingFee;

    uint256 public _burnFee = 2;
    uint256 private _previousBurnFee = _burnFee;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event UpdateMarketingWallet(
        address indexed newAddress,
        address indexed oldAddress
    );

    event SetBurnFeePercent(
        uint256 indexed newBurnFee,
        uint256 indexed oldBurnFee
    );

    event SetMarketingFeePercent(
        uint256 indexed newMarketingFee,
        uint256 indexed oldMarketingFee
    );

    constructor() public {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        marketingWallet = 0x5807a0E82D575EE8681a02e815c651D3d75A3ee2;
        // Owner, contract & marketingwallet are exempt from fees \\
        _isExemptFromFee[owner()] = true;
        _isExemptFromFee[address(this)] = true;
        _isExemptFromFee[marketingWallet] = true;

        // Distribute token to sender addr \\
        _balances[_msgSender()] = _totalSupply;

        emit Transfer(address(0), _msgSender(), _totalSupply);
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

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
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
                "ERC20: transfer amount exceeds allowance"
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
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    receive() external payable {}

    function isExemptFromFee(address account) public view returns (bool) {
        return _isExemptFromFee[account];
    }

    function exemptFromFee(address account) public onlyOwner {
        _isExemptFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExemptFromFee[account] = false;
    }

    function setBurnFeePercent(uint256 burnFee) external onlyOwner {
        emit SetBurnFeePercent(burnFee, uint256(_burnFee));
        _burnFee = burnFee;
    }

    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner {
        emit SetMarketingFeePercent(marketingFee, uint256(_marketingFee));
        _marketingFee = marketingFee;
    }

    function updateMarketingWallet(address account) public onlyOwner {
        emit UpdateMarketingWallet(account, address(marketingWallet));
        marketingWallet = account;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "ERC20: Unable to use existing address"
        );
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function calculateFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee + _marketingFee).div(100);
    }

    function removeAllFee() private {
        if (_burnFee == 0 && _marketingFee == 0) return;

        _previousBurnFee = _burnFee;
        _previousMarketingFee = _marketingFee;

        _burnFee = 0;
        _marketingFee = 0;
    }

    function restoreAllFee() private {
        _burnFee = _previousBurnFee;
        _marketingFee = _previousMarketingFee;
    }

    // Distribute fee to marketing & burn addr \\
    function _distributeFee(uint256 totalFee, address sender) private {
        if (_marketingFee + _burnFee > 0) {
            uint256 totalMarketing = totalFee.mul(_marketingFee).div(
                _marketingFee + _burnFee
            );
            uint256 totalBurn = totalFee.sub(totalMarketing);

            _balances[burnWallet] = _balances[burnWallet].add(totalBurn);
            emit Transfer(sender, burnWallet, totalBurn);

            _balances[marketingWallet] = _balances[marketingWallet].add(
                totalMarketing
            );
            emit Transfer(sender, marketingWallet, totalMarketing);
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // Determine fee exemption \\
        bool takeFee = true;
        if (_isExemptFromFee[sender] || _isExemptFromFee[recipient]) {
            takeFee = false;
        }

        if (!takeFee) removeAllFee();

        _transferActual(sender, recipient, amount);

        if (!takeFee) restoreAllFee();
    }

    // Deduct fees and amend balances \\
    function _transferActual(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 totalFee = calculateFee(amount);
        uint256 transferAmount = amount.sub(totalFee);

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(transferAmount);
        _distributeFee(totalFee, sender);
        emit Transfer(sender, recipient, transferAmount);
    }
}
