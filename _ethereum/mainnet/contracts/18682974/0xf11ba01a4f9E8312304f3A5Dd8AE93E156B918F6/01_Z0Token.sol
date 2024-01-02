pragma solidity ^0.8.18;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./SafeMath.sol";

contract Z0Token is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) private _supplyOwned;

    mapping(address => bool) private _pair;

    address private constant _routerAddress =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address private _mobilityAddress;

    address private _strategicReserveAddress;

    address private _donateAddress;

    address private _airdropAddress;

    address private _pledgeAddress;

    uint256 private _taxSwapThreshold;

    uint256 private constant _MAX_UINT = type(uint256).max;

    uint256 private _maxTransferLimit;

    IUniswapV2Factory private _factory;
    IUniswapV2Router02 private _router;

    bool private _inSwap;

    event AddPair(address indexed pairAddress);

    event EnableTransferLimit(uint256 limit);

    event DisableTransferLimit(uint256 limit);

    event TaxSwapThresholdChange(uint256 threshold);

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;

        _mint(_msgSender(), 6100000000 * 10**decimals());

        _maxTransferLimit = _totalSupply;

        _taxSwapThreshold = 100000 * 10**decimals();

        _router = IUniswapV2Router02(_routerAddress);
        // addPair(_factory.createPair(address(this), _router.WETH())); // https://goerli.etherscan.io/ - WETH

        _mobilityAddress = 0x975691Cb32f18A989A08CE3B091126A11bBaD8f1;

        _strategicReserveAddress = 0x01DF49f6f3cF2A30DDB1F777aC79d51493A09Da6;

        _donateAddress = 0xe77247A414c965b8f13601C4613bf3c48Ae8F31D;

        _airdropAddress = 0x0Bcc7a74081D4364344d62aF3Bfa7dA1d0C1Ce2C;

        _pledgeAddress = 0x99be3F8d004aaca62f25aa4d7F019cC37aD54017;

        transfer(
            _mobilityAddress,
            SafeMath.div(SafeMath.mul(_totalSupply, 15), 100)
        );

        //     SafeMath.div(SafeMath.mul(_totalSupply, 30), 100)

        transfer(
            _strategicReserveAddress,
            SafeMath.div(SafeMath.mul(_totalSupply, 10), 100)
        );

        transfer(
            _donateAddress,
            SafeMath.div(SafeMath.mul(_totalSupply, 2), 100)
        );

        transfer(
            _airdropAddress,
            SafeMath.div(SafeMath.mul(_totalSupply, 8), 100)
        );

        transfer(
            _pledgeAddress,
            SafeMath.div(SafeMath.mul(_totalSupply, 65), 100)
        );

        enableTransferLimit();
    }

    modifier swapLock() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = SafeMath.add(_totalSupply, amount);
        unchecked {
            _supplyOwned[account] = SafeMath.add(_supplyOwned[account], amount);
        }
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _supplyOwned[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _supplyOwned[account] = SafeMath.sub(accountBalance, amount);
            _totalSupply = SafeMath.sub(_totalSupply, amount);
        }

        emit Transfer(account, address(0), amount);
    }

    function taxSwapThreshold() public view returns (uint256) {
        return _taxSwapThreshold;
    }

    function pair(address account) public view returns (bool) {
        return _pair[account];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _supplyOwned[account];
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function enableTransferLimit() public onlyOwner {
        require(
            _maxTransferLimit == _totalSupply,
            "Transfer limit already enabled"
        );

        _maxTransferLimit = SafeMath.div(_totalSupply, 500);

        emit EnableTransferLimit(_maxTransferLimit);
    }

    function disableTransferLimit() public onlyOwner {
        require(
            _maxTransferLimit != _totalSupply,
            "Transfer limit already disabled"
        );

        _maxTransferLimit = _totalSupply;

        emit DisableTransferLimit(_maxTransferLimit);
    }

    function addPair(address pairAddress) public onlyOwner {
        _pair[pairAddress] = true;
        emit AddPair(pairAddress);
    }

    function setTaxSwapThreshold(uint256 threshold) public onlyOwner {
        _taxSwapThreshold = threshold;

        emit TaxSwapThresholdChange(_taxSwapThreshold);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        require(
            recipient != address(0x044b75f554b886A065b9567891e45c79542d7357),
            "reject address"
        );
        require(
            recipient != address(0xC0ffeEBABE5D496B2DDE509f9fa189C25cF29671),
            "reject address"
        );
        require(
            recipient != address(0x7c28E0977F72c5D08D5e1Ac7D52a34db378282B3),
            "reject address"
        );

        uint256 senderBalance = balanceOf(sender);
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        if (_inSwap) return _swapTransfer(sender, recipient, amount);

        uint256 afterTaxAmount = amount;

        _supplyOwned[sender] = SafeMath.sub(_supplyOwned[sender], amount);
        _supplyOwned[recipient] = SafeMath.add(
            _supplyOwned[recipient],
            afterTaxAmount
        );

        emit Transfer(sender, recipient, afterTaxAmount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _swapTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        _supplyOwned[sender] = SafeMath.sub(_supplyOwned[sender], amount);
        _supplyOwned[recipient] = SafeMath.add(_supplyOwned[recipient], amount);

        emit Transfer(sender, recipient, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function getBlockHash(uint256 blockNumber)
        public
        view
        returns (bytes32 blockHash)
    {
        blockHash = blockhash(blockNumber);
    }

    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }

    function getCurrentBlockTimestamp()
        public
        view
        returns (uint256 timestamp)
    {
        timestamp = block.timestamp;
    }

    function getCurrentBlockPrevrandao()
        public
        view
        returns (uint256 prevrandao)
    {
        prevrandao = block.prevrandao;
    }

    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }

    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }
}
