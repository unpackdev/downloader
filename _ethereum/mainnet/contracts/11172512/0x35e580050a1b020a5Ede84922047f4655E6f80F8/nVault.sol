pragma solidity ^0.5.16;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./Ownable.sol";

import "./IController.sol";
import "./IUniswapV2Router02.sol";

contract nVault is ERC20, ERC20Detailed {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IERC20 public token;

    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public nami = address(0x7EB4DB4dDDB16A329c5aDE17a8a0178331267E28);
    address public constant BURN_ADDRESS = address(0x000000000000000000000000000000000000dEaD);

    uint256 public min = 9500;
    uint256 public constant max = 10000;

    address public governance;
    address public controller;

    bool buyBackNamiEnabled = true;
    uint256 public buyBackNamiMin = 50;  // 0.5%
    uint256 public constant buyBackNamiMax = 10000;
    bool enableDepositEarn = true;

    constructor(address _token, address _controller)
        public
        ERC20Detailed(
            string(abi.encodePacked("Nami ", ERC20Detailed(_token).name())),
            string(abi.encodePacked("n", ERC20Detailed(_token).symbol())),
            ERC20Detailed(_token).decimals()
        )
    {
        token = IERC20(_token);
        governance = msg.sender;
        controller = _controller;
    }

    function balance() public view returns (uint256) {
        return token.balanceOf(address(this)).add(IController(controller).balanceOf(address(token)));
    }

    function setMin(uint256 _min) external {
        require(msg.sender == governance, "!governance");
        min = _min;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) public {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    // Custom logic in here for how much the vault allows to be borrowed
    // Sets minimum required on-hand to keep small withdrawals cheap
    function available() public view returns (uint256) {
        return token.balanceOf(address(this)).mul(min).div(max);
    }

    // Called by Keeper to put deposited token into strategy
    function earn() public {
        uint256 _bal = available();
        token.safeTransfer(controller, _bal);
        IController(controller).earn(address(token), _bal);
    }

    function depositAll() external {
        deposit(token.balanceOf(msg.sender));
    }

    function deposit(uint256 _amount) public {
        uint256 _pool = balance();
        uint256 _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = token.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalSupply())).div(_pool);
        }
        _mint(msg.sender, shares);

        if (enableDepositEarn) {
            earn();
        }
    }

    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    // Used to swap any borrowed reserve over the debt limit to liquidate to 'token'
    function harvest(address reserve, uint256 amount) external {
        require(msg.sender == controller, "!controller");
        require(reserve != address(token), "token");
        IERC20(reserve).safeTransfer(controller, amount);
    }

    // No rebalance implementation for lower fees and faster swaps
    function withdraw(uint256 _shares) public {
        uint256 r = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

        // Check balance
        uint256 b = token.balanceOf(address(this));
        if (b < r) {
            uint256 _withdraw = r.sub(b);
            IController(controller).withdraw(address(token), _withdraw);
            uint256 _after = token.balanceOf(address(this));
            uint256 _diff = _after.sub(b);
            if (_diff < _withdraw) {
                r = b.add(_diff);
            }
        }

        if (!buyBackNamiEnabled) {
            token.safeTransfer(msg.sender, r);
        } else {
            // Send back token
            uint256 tokenToBuyNamiAmount = r.mul(buyBackNamiMin).div(buyBackNamiMax);
            r = r.sub(tokenToBuyNamiAmount);
            token.safeTransfer(msg.sender, r);

            token.approve(address(uniswapRouter), tokenToBuyNamiAmount);

            uint256 amountOutMin = 0;
            address[] memory path = new address[](3);
            path[0] = address(token);
            path[1] = uniswapRouter.WETH();
            path[2] = address(nami);

            // Market buy and burn
            uniswapRouter.swapExactTokensForTokens(
                tokenToBuyNamiAmount, // amountIn
                amountOutMin, // amountOutMin
                path, // path
                BURN_ADDRESS, // address(this), // to
                block.timestamp + 20 minutes
            );
        }
    }

    function getPricePerFullShare() public view returns (uint256) {
        return balance().mul(1e18).div(totalSupply());
    }

    // -- Added functions --

    function setBuyBackNamiMin(uint256 _min) external {
        require(msg.sender == governance, "!governance");
        buyBackNamiMin = _min;
    }

    function setBuyBackNamiEnabled(bool _enabled) external {
        require(msg.sender == governance, "!governance");
        buyBackNamiEnabled = _enabled;
    }

    function setDepositEarnEnabled(bool _enabled) public {
        require(msg.sender == governance, "!governance");
        enableDepositEarn = _enabled;
    }

}
