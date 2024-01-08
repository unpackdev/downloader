// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";

contract DVDUniBot is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    struct Token {
        bool allowed;
        uint256 decimals;
    }

    IERC20 public dvd; 
    IERC20 public xdvd; 
    IUniswapV2Router02 public router;
    address public wallet;
    uint256 public minAmount = 500; 
    uint256 public amount = minAmount;
    mapping(IERC20 => Token) public token; 

    event BuyDVD(address indexed user, IERC20 indexed token, uint256 dvdAmount);
    event SetWallet(address indexed who, address indexed newWallet);
    event SetAmount(uint256 minAmount, uint256 amount);
    event SetToken(address indexed who, IERC20 indexed token, bool allowed, uint256 decimals);

    /// @dev Require that the caller must be an EOA account to avoid flash loans
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Not EOA");
        _;
    }

    constructor (
        IERC20 _dvd, 
        IERC20 _xdvd, 
        IUniswapV2Router02 _router, 
        address _wallet
    ) {        
        dvd = _dvd;
        xdvd = _xdvd;
        router = _router;
        wallet = _wallet;
    }

    receive() external payable {}

    // Ask this smart contract to buy more DVDs on Uniswap, using funds in wallet     
    function buyDVD(IERC20 _token) public payable onlyEOA nonReentrant returns(uint256 dvdAmount) {
        require(token[_token].allowed, "Token not allowed");
        require(_token.balanceOf(wallet) >= minAmount.mul(token[_token].decimals), "Token balance of wallet not enough");

        uint256 amount_ = amount.mul(token[_token].decimals);
        address weth = router.WETH();

        _token.safeTransferFrom(wallet, address(this), amount_); 

        address[] memory path = new address[](2);
        path[0] = address(_token);
        path[1] = weth;

        uint[] memory amounts = router.swapExactTokensForETH(amount_, 0, path, address(this), block.timestamp);

        path[0] = weth;
        path[1] = address(dvd);
        amounts = router.swapExactETHForTokens{value:amounts[amounts.length - 1]}(0, path, address(xdvd), block.timestamp);

        dvdAmount = amounts[1];

        emit BuyDVD(msg.sender, _token, dvdAmount);
    }

    function setWallet(address _wallet) external onlyOwner {
        wallet = _wallet;

        emit SetWallet(msg.sender, _wallet);
    }

    function setAmount(uint256 _minAmount, uint256 _amount) external onlyOwner {
        minAmount = _minAmount;
        amount = _amount;

        emit SetAmount(minAmount, amount);
    }

    function setToken(IERC20 _token, bool _allowed, uint256 _decimals) external onlyOwner {
        require(address(_token).isContract(), "Token address should be the smart contract address");
        token[_token] = Token(_allowed, _decimals);
        
        if (_token.allowance(address(this), address(router)) == 0) {
            _token.safeApprove(address(router), type(uint256).max);
        }

        emit SetToken(msg.sender, _token, _allowed, _decimals);
    }
}