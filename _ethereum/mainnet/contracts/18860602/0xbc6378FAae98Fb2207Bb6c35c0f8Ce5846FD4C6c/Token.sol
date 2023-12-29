//SPDX-License-Identifier: MIT
/*
───────────────────────────────────────────────────────────
─██████████████─██████████████───██████████─██████████████─
─██░░░░░░░░░░██─██░░░░░░░░░░██───██░░░░░░██─██░░░░░░░░░░██─
─██░░██████░░██─██░░██████░░██───████░░████─██████░░██████─
─██░░██──██░░██─██░░██──██░░██─────██░░██───────██░░██─────
─██░░██████░░██─██░░██████░░████───██░░██───────██░░██─────
─██░░░░░░░░░░██─██░░░░░░░░░░░░██───██░░██───────██░░██─────
─██░░██████░░██─██░░████████░░██───██░░██───────██░░██─────
─██░░██──██░░██─██░░██────██░░██───██░░██───────██░░██─────
─██░░██████░░██─██░░████████░░██─████░░████─────██░░██─────
─██░░░░░░░░░░██─██░░░░░░░░░░░░██─██░░░░░░██─────██░░██─────
─██████████████─████████████████─██████████─────██████─────
───────────────────────────────────────────────────────────
 */
import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";

pragma solidity ^0.8.17;

interface DexFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface DexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract _8BitToken is ERC20, Ownable {
    struct Tax {
        uint256 marketingTax;
        uint256 DevelopmentTax;
    }

    uint256 private _totalSupply = 0;

    //Router
    DexRouter public immutable uniswapRouter;
    address public immutable pairAddress;

    //Taxes
    Tax public buyTaxes = Tax(3, 2);
    Tax public sellTaxes = Tax(3, 2);
    uint256 public totalBuyFees = 5;
    uint256 public totalSellFees = 5;

    //Whitelisting from taxes/maxwallet/txlimit/etc
    mapping(address => bool) private whitelisted;

    //Swapping
    uint256 public swapTokensAtAmount = _totalSupply / 10000; //after 0.001% of total supply, swap them
    bool public swapAndLiquifyEnabled = true;
    bool public isSwapping = false;

    //Wallets
    address public marketingWallet = 0x7bA6E2fF8888BF229E7A70C1DC519BeE5612d0Fb;
    address public DevelopmentWallet =
        0x0d32047C93116ad5684B8Dae76cdaA89b97831A8;
    address public bridgeContract; //set bridge wallet

    //Events
    event marketingWalletChanged(address indexed _trWallet);
    event BuyFeesUpdated(uint256 indexed _trFee);
    event SellFeesUpdated(uint256 indexed _trFee);
    event TransferFeesUpdated(uint256 indexed _trFee);
    event SwapThresholdUpdated(uint256 indexed _newThreshold);
    event InternalSwapStatusUpdated(bool indexed _status);
    event Whitelist(address indexed _target, bool indexed _status);
    event BridgeWalletUpdated(address indexed _bridge, bool indexed _status);

    constructor() ERC20("8Bit Chain", "w8Bit") {
        address newOwner = msg.sender;
        uniswapRouter = DexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pairAddress = DexFactory(uniswapRouter.factory()).createPair(
            address(this),
            uniswapRouter.WETH()
        );
        whitelisted[msg.sender] = true;
        whitelisted[address(uniswapRouter)] = true;
        whitelisted[address(this)] = true;
        whitelisted[newOwner] = true;

        _mint(newOwner, _totalSupply);
        _approve(address(this), address(this), ~uint256(0));
        transferOwnership(newOwner);
    }

    function setMrketingWallet(address _newMarketing) external onlyOwner {
        require(
            _newMarketing != address(0),
            "8bit : can not set marketing to dead wallet"
        );
        marketingWallet = _newMarketing;
    }

    function setDevelopmentWallet(address _newDevelopment) external onlyOwner {
        require(
            _newDevelopment != address(0),
            "8bit : can not set Development to dead wallet"
        );
        DevelopmentWallet = _newDevelopment;
    }

    function setBridgeContract(address _newBridge) external onlyOwner {
        require(
            _newBridge != address(0),
            "8bit : can not set Development to dead wallet"
        );
        _approve(address(this), _newBridge, ~uint256(0));
        bridgeContract = _newBridge;
    }

    function setBuyTaxes(
        uint256 _marketingTax,
        uint256 _DevelopmentTax
    ) external onlyOwner {
        buyTaxes.marketingTax = _marketingTax;
        buyTaxes.DevelopmentTax = _DevelopmentTax;
        totalBuyFees = _marketingTax + _DevelopmentTax;
        require(
            _marketingTax + _DevelopmentTax <= 10,
            "8bit : can not set buy fees higher than 10"
        );
    }

    function setSellTaxes(
        uint256 _marketingTax,
        uint256 _DevelopmentTax
    ) external onlyOwner {
        sellTaxes.marketingTax = _marketingTax;
        sellTaxes.DevelopmentTax = _DevelopmentTax;
        totalSellFees = _marketingTax + _DevelopmentTax;
        require(
            _marketingTax + _DevelopmentTax <= 10,
            "8bit : can not set buy fees higher than 10%"
        );
    }

    function setSwapTokensAtAmount(uint256 _newAmount) external onlyOwner {
        require(
            _newAmount > 0 && _newAmount <= (_totalSupply * 1) / 100,
            "8bit : minimum swap amount must be greater than 0 and less than 1% of total supply!"
        );
        swapTokensAtAmount = _newAmount;
        emit SwapThresholdUpdated(swapTokensAtAmount);
    }

    function toggleSwapping() external onlyOwner {
        swapAndLiquifyEnabled = (swapAndLiquifyEnabled) ? false : true;
    }

    function setWhitelistStatus(
        address _wallet,
        bool _status
    ) external onlyOwner {
        whitelisted[_wallet] = _status;
        emit Whitelist(_wallet, _status);
    }

    function checkWhitelist(address _wallet) external view returns (bool) {
        return whitelisted[_wallet];
    }

    // this function is reponsible for managing tax, if _from or _to is whitelisted, we simply return _amount and skip all the limitations
    function _takeTax(
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        if (whitelisted[_from] || whitelisted[_to]) {
            return _amount;
        }
        uint256 totalTax = 0;

        if (_to == pairAddress) {
            totalTax = totalSellFees;
        } else if (_from == pairAddress) {
            totalTax = totalBuyFees;
        }

        uint256 tax = 0;
        if (totalTax > 0) {
            tax = (_amount * totalTax) / 100;
            super._transfer(_from, address(this), tax);
        }
        return (_amount - tax);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        require(_from != address(0), "transfer from address zero");
        require(_to != address(0), "transfer to address zero");
        uint256 toTransfer = _takeTax(_from, _to, _amount);

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
        if (
            swapAndLiquifyEnabled &&
            pairAddress == _to &&
            canSwap &&
            !whitelisted[_from] &&
            !whitelisted[_to] &&
            !isSwapping
        ) {
            isSwapping = true;
            internalSwap();
            isSwapping = false;
        }
        super._transfer(_from, _to, toTransfer);
    }

    function internalSwap() internal {
        uint256 taxAmount = balanceOf(address(this));
        if (taxAmount == 0) {
            return;
        }

        swapToETH(taxAmount);

        uint256 received = address(this).balance;
        uint256 totalShares = totalBuyFees + totalSellFees;

        if (totalShares == 0 || received == 0) return;

        uint256 totalMarketingFee = buyTaxes.marketingTax +
            sellTaxes.marketingTax;
        uint256 totalDevelopmentFee = buyTaxes.DevelopmentTax +
            sellTaxes.DevelopmentTax;

        if (totalMarketingFee > 0) {
            //ignoring success, we dont need it, if an error happened we dont want an external contract to affect our trades
            (bool success, ) = marketingWallet.call{
                value: (totalMarketingFee * received) / totalShares
            }("");
        }

        if (totalDevelopmentFee > 0) {
            //ignoring success, we dont need it, if an error happened we dont want an external contract to affect our trades
            (bool success, ) = DevelopmentWallet.call{
                value: address(this).balance
            }("");
        }
    }

    function swapToETH(uint256 _amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), _amount);

        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == bridgeContract, "8bit : only bridge");
        _mint(to, amount);
        require(
            _totalSupply <= 140_000_000 ether,
            "8bit : max supply is 140_000_000"
        );
    }

    function burn(address from, uint256 amount) public {
        require(msg.sender == bridgeContract, "8bit : only bridge");
        require(
            allowance(from, msg.sender) >= amount,
            "8bit : not enough allowance for bridge action"
        );
        _burn(from, amount);
    }

    function withdrawStuckETH() external onlyOwner {
        (bool success, ) = address(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "transferring ETH failed");
    }

    function withdrawStuckTokens(address ERC20_token) external onlyOwner {
        bool success = IERC20(ERC20_token).transfer(
            msg.sender,
            IERC20(ERC20_token).balanceOf(address(this))
        );
        require(success, "trasfering tokens failed!");
    }

    receive() external payable {}
}
