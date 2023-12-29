// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./IUniswapV3Factory.sol";
import "./ISwapRouter.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

interface IUniswapV3Router is ISwapRouter {
    function factory() external pure returns (address);
}

contract OrdiswapToken is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    IUniswapV3Router public immutable uniswapV3Router;
    address public uniswapV2Pair;
    address public uniswapV3Pool10000;
    address public uniswapV3Pool3000;
    address public uniswapV3Pool500;
    address public uniswapV3Pool100;
    address public constant ZERO_ADDRESS = address(0);
    address public constant DEAD_ADDRESS = address(0xdead);

    bool private _swapping;
    bool private _v3LPProtectionEnabled;
    bool public swapEnabled;
    bool public taxesEnabled;
    bool public launched;

    address public operationsWallet;

    uint256 public launchBlock;
    uint256 public launchTime;

    uint256 public swapTokensAtAmount;

    uint256 public buyFees;

    uint256 public sellFees;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _automatedMarketMakerPairsV2;
    mapping(address => bool) private _automatedMarketMakerPairsV3;
    mapping(address => bool) private _isBot;

    event Airdrop(address account, uint256 amount);
    event Launch(uint256 blockNumber, uint256 timestamp);
    event PrepareForMigration(uint256 blockNumber, uint256 timestamp);
    event SetSwapEnabled(bool status);
    event SetTaxesEnabled(bool status);
    event SetSwapTokensAtAmount(uint256 oldValue, uint256 newValue);
    event SetBuyFees(uint256 oldValue, uint256 newValue);
    event SetSellFees(uint256 oldValue, uint256 newValue);
    event SetOperationsWallet(
        address indexed oldWallet,
        address indexed newWallet
    );
    event WithdrawStuckTokens(address token, uint256 amount);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetBots(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPairV2(
        address indexed pair,
        bool indexed value
    );
    event SetAutomatedMarketMakerPairV3(
        address indexed pair,
        bool indexed value
    );

    modifier lockSwapping() {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor() ERC20("Ordiswap", "ORDS") {
        uint256 totalSupply = 1_000_000_000 ether;

        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV3Router = IUniswapV3Router(
            0xE592427A0AEce92De3Edee1F18E0157C05861564
        );

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        swapTokensAtAmount = totalSupply.mul(1).div(100000);

        operationsWallet = owner();

        _excludeFromFees(owner(), true);
        _excludeFromFees(address(this), true);
        _excludeFromFees(DEAD_ADDRESS, true);
        _excludeFromFees(operationsWallet, true);

        _mint(owner(), totalSupply);
    }

    receive() external payable {}

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function airdrop(address[] memory accounts, uint256[] memory amounts)
        public
        onlyOwner
    {
        require(
            accounts.length == amounts.length,
            "arrays must be the same length"
        );
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 amount = amounts[i];
            _transfer(_msgSender(), account, amount);
            emit Airdrop(account, amount);
        }
    }

    function launch() public onlyOwner {
        require(!launched, "ERC20: Already launched.");
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(
            address(this),
            uniswapV2Router.WETH()
        );
        if (uniswapV2Pair == ZERO_ADDRESS) {
            uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(address(this), uniswapV2Router.WETH());
        }
        uniswapV3Pool10000 = IUniswapV3Factory(uniswapV3Router.factory())
            .getPool(address(this), uniswapV2Router.WETH(), 10000);
        uniswapV3Pool3000 = IUniswapV3Factory(uniswapV3Router.factory())
            .getPool(address(this), uniswapV2Router.WETH(), 3000);
        uniswapV3Pool500 = IUniswapV3Factory(uniswapV3Router.factory()).getPool(
            address(this),
            uniswapV2Router.WETH(),
            500
        );
        uniswapV3Pool100 = IUniswapV3Factory(uniswapV3Router.factory()).getPool(
            address(this),
            uniswapV2Router.WETH(),
            100
        );
        if (uniswapV3Pool10000 == ZERO_ADDRESS) {
            uniswapV3Pool10000 = IUniswapV3Factory(uniswapV3Router.factory())
                .createPool(address(this), uniswapV2Router.WETH(), 10000);
        }
        if (uniswapV3Pool3000 == ZERO_ADDRESS) {
            uniswapV3Pool3000 = IUniswapV3Factory(uniswapV3Router.factory())
                .createPool(address(this), uniswapV2Router.WETH(), 3000);
        }
        if (uniswapV3Pool500 == ZERO_ADDRESS) {
            uniswapV3Pool500 = IUniswapV3Factory(uniswapV3Router.factory())
                .createPool(address(this), uniswapV2Router.WETH(), 500);
        }
        if (uniswapV3Pool100 == ZERO_ADDRESS) {
            uniswapV3Pool100 = IUniswapV3Factory(uniswapV3Router.factory())
                .createPool(address(this), uniswapV2Router.WETH(), 100);
        }

        _approve(address(this), address(uniswapV2Pair), type(uint256).max);
        _approve(address(this), address(uniswapV3Pool10000), type(uint256).max);
        _approve(address(this), address(uniswapV3Pool3000), type(uint256).max);
        _approve(address(this), address(uniswapV3Pool500), type(uint256).max);
        _approve(address(this), address(uniswapV3Pool100), type(uint256).max);

        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        _setAutomatedMarketMakerPairV2(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPairV3(address(uniswapV3Pool10000), true);
        _setAutomatedMarketMakerPairV3(address(uniswapV3Pool3000), true);
        _setAutomatedMarketMakerPairV3(address(uniswapV3Pool500), true);
        _setAutomatedMarketMakerPairV3(address(uniswapV3Pool100), true);

        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );

        _v3LPProtectionEnabled = true;
        launched = true;
        launchBlock = block.number;
        launchTime = block.timestamp;
        emit Launch(launchBlock, launchTime);
    }

    function prepareForMigration() public onlyOwner {
        _v3LPProtectionEnabled = false;
        swapEnabled = false;
        taxesEnabled = false;
        buyFees = 0;
        sellFees = 0;
        swapTokensAtAmount = totalSupply();
        if (balanceOf(address(this)) > 0) {
            super._transfer(
                address(this),
                msg.sender,
                balanceOf(address(this))
            );
        }

        emit PrepareForMigration(block.number, block.timestamp);
    }

    function setSwapEnabled(bool value) public onlyOwner {
        swapEnabled = value;
        emit SetSwapEnabled(swapEnabled);
    }

    function setTaxesEnabled(bool value) public onlyOwner {
        taxesEnabled = value;
        emit SetTaxesEnabled(taxesEnabled);
    }

    function setSwapTokensAtAmount(uint256 _swapTokensAtAmount)
        public
        onlyOwner
    {
        require(
            _swapTokensAtAmount >= totalSupply().mul(1).div(1000000),
            "ERC20: Swap amount cannot be lower than 0.0001% total supply."
        );
        require(
            _swapTokensAtAmount <= totalSupply().mul(1).div(1000),
            "ERC20: Swap amount cannot be higher than 0.1% total supply."
        );
        uint256 oldValue = swapTokensAtAmount;
        swapTokensAtAmount = _swapTokensAtAmount;
        emit SetSwapTokensAtAmount(oldValue, swapTokensAtAmount);
    }

    function setBuyFees(uint256 _buyFees) public onlyOwner {
        require(_buyFees <= 5, "ERC20: Must keep fees at 5% or less");
        uint256 oldValue = buyFees;
        buyFees = _buyFees;
        emit SetBuyFees(oldValue, buyFees);
    }

    function setSellFees(uint256 _sellFees) public onlyOwner {
        require(_sellFees <= 5, "ERC20: Must keep fees at 5% or less");
        uint256 oldValue = sellFees;
        sellFees = _sellFees;
        emit SetSellFees(oldValue, sellFees);
    }

    function setOperationsWallet(address _operationsWallet) public onlyOwner {
        require(_operationsWallet != ZERO_ADDRESS, "ERC20: Address 0");
        address oldWallet = operationsWallet;
        operationsWallet = _operationsWallet;
        _excludeFromFees(operationsWallet, true);
        emit SetOperationsWallet(oldWallet, operationsWallet);
    }

    function withdrawStuckTokens(address tkn) public onlyOwner {
        uint256 amount;
        if (tkn == ZERO_ADDRESS) {
            bool success;
            amount = address(this).balance;
            (success, ) = address(msg.sender).call{value: amount}("");
        } else {
            require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
            amount = IERC20(tkn).balanceOf(address(this));
            IERC20(tkn).transfer(msg.sender, amount);
        }
        emit WithdrawStuckTokens(tkn, amount);
    }

    function excludeFromFees(address[] calldata accounts, bool value)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            _excludeFromFees(accounts[i], value);
        }
    }

    function setAutomatedMarketMakerPairV2(address account, bool value)
        internal
        virtual
    {
        _setAutomatedMarketMakerPairV2(account, value);
    }

    function setAutomatedMarketMakerPairV3(address account, bool value)
        internal
        virtual
    {
        _setAutomatedMarketMakerPairV3(account, value);
    }

    function setBots(address[] calldata accounts, bool value) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (
                (accounts[i] != uniswapV2Pair) &&
                (accounts[i] != uniswapV3Pool10000) &&
                (accounts[i] != uniswapV3Pool3000) &&
                (accounts[i] != uniswapV3Pool500) &&
                (accounts[i] != uniswapV3Pool100) &&
                (accounts[i] != address(uniswapV2Router)) &&
                (accounts[i] != address(uniswapV3Router)) &&
                (accounts[i] != address(this))
            ) _setBots(accounts[i], value);
        }
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from != ZERO_ADDRESS, "ERC20: transfer from the zero address");
        require(to != ZERO_ADDRESS, "ERC20: transfer to the zero address");

        require(!_isBot[from], "ERC20: bot detected");
        require(!_isBot[msg.sender], "ERC20: bot detected");
        require(!_isBot[tx.origin], "ERC20: bot detected");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (
            _v3LPProtectionEnabled &&
            (_automatedMarketMakerPairsV3[from] ||
                _automatedMarketMakerPairsV3[to])
        ) {
            require(
                _isExcludedFromFees[from] || _isExcludedFromFees[to],
                "ERC20: Not authorized to add LP to Uniswap V3 Pool"
            );
        }

        if (
            from != owner() &&
            to != owner() &&
            to != ZERO_ADDRESS &&
            to != DEAD_ADDRESS &&
            !_swapping
        ) {
            if (!launched) {
                require(
                    _isExcludedFromFees[from] || _isExcludedFromFees[to],
                    "ERC20: Not launched."
                );
            }
        }

        if (swapEnabled) {
            uint256 contractTokenBalance = balanceOf(address(this));

            bool canSwap = contractTokenBalance >= swapTokensAtAmount;

            if (
                canSwap &&
                !_swapping &&
                !_automatedMarketMakerPairsV2[from] &&
                !_isExcludedFromFees[from] &&
                !_isExcludedFromFees[to]
            ) {
                _swapBack(contractTokenBalance);
            }
        }

        if (taxesEnabled) {
            bool takeFee = !_swapping;

            if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
                takeFee = false;
            }

            uint256 fees = 0;

            if (takeFee) {
                if (_automatedMarketMakerPairsV2[to] && sellFees > 0) {
                    fees = amount.mul(sellFees).div(100);
                } else if (_automatedMarketMakerPairsV2[from] && buyFees > 0) {
                    fees = amount.mul(buyFees).div(100);
                }

                if (fees > 0) {
                    super._transfer(from, address(this), fees);
                }

                amount -= fees;
            }
        }

        super._transfer(from, to, amount);
    }

    function _swapTokensForETH(uint256 tokenAmount) internal virtual {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _swapBack(uint256 contractTokenBalance)
        internal
        virtual
        lockSwapping
    {
        bool success;

        if (contractTokenBalance == 0) {
            return;
        }

        if (contractTokenBalance > swapTokensAtAmount.mul(10)) {
            contractTokenBalance = swapTokensAtAmount.mul(10);
        }

        _swapTokensForETH(contractTokenBalance);

        (success, ) = address(operationsWallet).call{
            value: address(this).balance
        }("");
    }

    function _excludeFromFees(address account, bool value) internal virtual {
        _isExcludedFromFees[account] = value;
        emit ExcludeFromFees(account, value);
    }

    function _setBots(address account, bool value) internal virtual {
        _isBot[account] = value;
        emit SetBots(account, value);
    }

    function _setAutomatedMarketMakerPairV2(address account, bool value)
        internal
        virtual
    {
        _automatedMarketMakerPairsV2[account] = value;
        emit SetAutomatedMarketMakerPairV2(account, value);
    }

    function _setAutomatedMarketMakerPairV3(address account, bool value)
        internal
        virtual
    {
        _automatedMarketMakerPairsV3[account] = value;
        emit SetAutomatedMarketMakerPairV3(account, value);
    }
}
