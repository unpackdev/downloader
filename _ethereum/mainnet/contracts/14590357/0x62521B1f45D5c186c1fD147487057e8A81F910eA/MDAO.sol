// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

import "./IPermissions.sol";

contract MDAO is ERC20, Ownable {
    using SafeMath for uint256;

    modifier lockSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier liquidityAdd() {
        _inLiquidityAdd = true;
        _;
        _inLiquidityAdd = false;
    }

    uint256 public constant MAX_SUPPLY = 1_000_000_000 ether;
    uint256 public constant BPS_DENOMINATOR = 10_000;

    /// @notice Cooldown in seconds
    uint256 public cooldown = 60;
    /// @notice Maps each wallet to the last timestamp they bought
    mapping(address => uint256) public lastBuy;

    /// @notice Buy taxes in BPS
    uint256[3] public buyTaxes = [600, 500, 100];
    /// @notice Sell taxes in BPS
    uint256[3] public sellTaxes = [800, 600, 100];
    /// @notice Buy autoLiquidityTax in BPS
    uint256 public buyAutoLiquidityTax = 0;
    /// @notice Sell autoLiquidityTax in BPS
    uint256 public sellAutoLiquidityTax = 0;

    /// @notice Contract MDAO balance threshold before `_swap` is invoked
    uint256 public minTokenBalance = 1000 ether;
    bool public swapFees = true;

    /// @notice tokens that are allocated for each tax
    uint256[3] public totalTaxes;
    /// @notice tokens that are allocated for auto liquidity tax
    uint256 public totalAutoLiquidityTax;

    /// @notice addresses that each tax is sent to
    address payable[3] public taxWallets;

    /// @notice Mapping from address to tax exlcusion status
    mapping(address => bool) public taxExcluded;

    /// @notice Permissions module
    IPermissions public permissions;

    /// @notice Flag indicating whether buys/sells are permitted
    bool public tradingActive = false;

    uint256 internal _totalSupply = 0;
    mapping(address => uint256) private _balances;

    IUniswapV2Router02 internal immutable _router;
    address internal immutable _pair;

    bool internal _inSwap = false;
    bool internal _inLiquidityAdd = false;

    event TaxWalletsChanged(
        address payable[3] previousWallets,
        address payable[3] nextWallets
    );
    event BuyTaxesChanged(uint256[3] previousTaxes, uint256[3] nextTaxes);
    event SellTaxesChanged(uint256[3] previousTaxes, uint256[3] nextTaxes);
    event BuyAutoLiquidityTaxChanged(uint256 previousTax, uint256 nextTax);
    event SellAutoLiquidityTaxChanged(uint256 previousTax, uint256 nextTax);
    event MinTokenBalanceChanged(uint256 previousMin, uint256 nextMin);
    event TaxesRescued(uint256 index, uint256 amount);
    event AutoLiquidityTaxRescued(uint256 amount);
    event TradingActiveChanged(bool enabled);
    event TaxExclusionChanged(address user, bool taxExcluded);
    event SwapFeesChanged(bool enabled);
    event PermissionsChanged(
        address previousPermissions,
        address nextPermissions
    );
    event CooldownChanged(uint256 previousCooldown, uint256 nextCooldown);

    constructor(IUniswapV2Router02 _uniswapRouter)
        ERC20("Meme DAO", "MDAO")
        Ownable()
    {
        taxExcluded[owner()] = true;
        taxExcluded[address(0)] = true;
        taxExcluded[address(this)] = true;

        _router = _uniswapRouter;
        _pair = IUniswapV2Factory(_uniswapRouter.factory()).createPair(
            address(this),
            _uniswapRouter.WETH()
        );
    }

    /// @notice Change the address of the tax wallets
    /// @param _taxWallets The new address of the tax wallets
    function setTaxWallets(address payable[3] memory _taxWallets)
        external
        onlyOwner
    {
        emit TaxWalletsChanged(taxWallets, _taxWallets);
        taxWallets = _taxWallets;
    }

    /// @notice Change the buy tax rates
    /// @param _buyTaxes The new buy tax rates
    function setBuyTaxes(uint256[3] memory _buyTaxes) external onlyOwner {
        require(
            _buyTaxes[0] <= BPS_DENOMINATOR &&
                _buyTaxes[1] <= BPS_DENOMINATOR &&
                _buyTaxes[2] <= BPS_DENOMINATOR,
            "_buyTaxes cannot exceed BPS_DENOMINATOR"
        );
        emit BuyTaxesChanged(buyTaxes, _buyTaxes);
        buyTaxes = _buyTaxes;
    }

    /// @notice Change the sell tax rates
    /// @param _sellTaxes The new sell tax rates
    function setSellTaxes(uint256[3] memory _sellTaxes) external onlyOwner {
        require(
            _sellTaxes[0] <= BPS_DENOMINATOR &&
                _sellTaxes[1] <= BPS_DENOMINATOR &&
                _sellTaxes[2] <= BPS_DENOMINATOR,
            "_sellTaxes cannot exceed BPS_DENOMINATOR"
        );
        emit SellTaxesChanged(sellTaxes, _sellTaxes);
        sellTaxes = _sellTaxes;
    }

    /// @notice Change the buy autoLiquidityTax rate
    /// @param _buyAutoLiquidityTax The new buy autoLiquidityTax rate
    function setBuyAutoLiquidityTax(uint256 _buyAutoLiquidityTax)
        external
        onlyOwner
    {
        require(
            _buyAutoLiquidityTax <= BPS_DENOMINATOR,
            "_buyAutoLiquidityTax cannot exceed BPS_DENOMINATOR"
        );
        emit BuyAutoLiquidityTaxChanged(
            buyAutoLiquidityTax,
            _buyAutoLiquidityTax
        );
        buyAutoLiquidityTax = _buyAutoLiquidityTax;
    }

    /// @notice Change the sell autoLiquidityTax rate
    /// @param _sellAutoLiquidityTax The new sell autoLiquidityTax rate
    function setSellAutoLiquidityTax(uint256 _sellAutoLiquidityTax)
        external
        onlyOwner
    {
        require(
            _sellAutoLiquidityTax <= BPS_DENOMINATOR,
            "_sellAutoLiquidityTax cannot exceed BPS_DENOMINATOR"
        );
        emit SellAutoLiquidityTaxChanged(
            sellAutoLiquidityTax,
            _sellAutoLiquidityTax
        );
        sellAutoLiquidityTax = _sellAutoLiquidityTax;
    }

    /// @notice Change the minimum contract MDAO balance before `_swap` gets invoked
    /// @param _minTokenBalance The new minimum balance
    function setMinTokenBalance(uint256 _minTokenBalance) external onlyOwner {
        emit MinTokenBalanceChanged(minTokenBalance, _minTokenBalance);
        minTokenBalance = _minTokenBalance;
    }

    /// @notice Change the permissions
    /// @param _permissions The new permissions contract
    function setPermissions(IPermissions _permissions) external onlyOwner {
        emit PermissionsChanged(address(permissions), address(_permissions));
        permissions = _permissions;
    }

    /// @notice Change the cooldown for buys
    /// @param _cooldown The new cooldown in seconds
    function setCooldown(uint256 _cooldown) external onlyOwner {
        emit CooldownChanged(cooldown, _cooldown);
        cooldown = _cooldown;
    }

    /// @notice Rescue MDAO from the taxes
    /// @dev Should only be used in an emergency
    /// @param _index The tax allocation to rescue from
    /// @param _amount The amount of MDAO to rescue
    /// @param _recipient The recipient of the rescued MDAO
    function rescueTaxTokens(
        uint256 _index,
        uint256 _amount,
        address _recipient
    ) external onlyOwner {
        require(0 <= _index && _index < totalTaxes.length, "_index OOB");
        require(
            _amount <= totalTaxes[_index],
            "Amount cannot be greater than totalTax"
        );
        _rawTransfer(address(this), _recipient, _amount);
        emit TaxesRescued(_index, _amount);
        totalTaxes[_index] -= _amount;
    }

    /// @notice Rescue MDAO from the autoLiquidityTax amount
    /// @dev Should only be used in an emergency
    /// @param _amount The amount of BBI to rescue
    /// @param _recipient The recipient of the rescued BBI
    function rescueAutoLiquidityTaxTokens(uint256 _amount, address _recipient)
        external
        onlyOwner
    {
        require(
            _amount <= totalAutoLiquidityTax,
            "Amount cannot be greater than totalAutoLiquidityTax"
        );
        _rawTransfer(address(this), _recipient, _amount);
        emit AutoLiquidityTaxRescued(_amount);
        totalAutoLiquidityTax -= _amount;
    }

    function addLiquidity(uint256 tokens)
        external
        payable
        onlyOwner
        liquidityAdd
    {
        _mint(address(this), tokens);
        _approve(address(this), address(_router), tokens);

        _router.addLiquidityETH{value: msg.value}(
            address(this),
            tokens,
            0,
            0,
            owner(),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );
    }

    /// @notice Enables or disables trading on Uniswap
    function setTradingActive(bool _tradingActive) external onlyOwner {
        tradingActive = _tradingActive;
        emit TradingActiveChanged(_tradingActive);
    }

    /// @notice Updates tax exclusion status
    /// @param _account Account to update the tax exclusion status of
    /// @param _taxExcluded If true, exclude taxes for this user
    function setTaxExcluded(address _account, bool _taxExcluded)
        external
        onlyOwner
    {
        taxExcluded[_account] = _taxExcluded;
        emit TaxExclusionChanged(_account, _taxExcluded);
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function _addBalance(address account, uint256 amount) internal {
        _balances[account] = _balances[account] + amount;
    }

    function _subtractBalance(address account, uint256 amount) internal {
        _balances[account] = _balances[account] - amount;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (taxExcluded[sender] || taxExcluded[recipient]) {
            _rawTransfer(sender, recipient, amount);
            return;
        }

        uint256 swapAmount = totalTaxes[0].add(totalTaxes[1]).add(
            totalTaxes[2]
        );
        bool overMinTokenBalance = swapAmount >= minTokenBalance;

        if (overMinTokenBalance && !_inSwap && sender != _pair && swapFees) {
            _swap();
        }

        uint256 send = amount;
        uint256[3] memory taxes;
        uint256 autoLiquidityTax;
        if (sender == _pair) {
            if (address(permissions) != address(0)) {
                require(
                    permissions.isWhitelisted(recipient),
                    "User is not whitelisted to buy"
                );
                require(
                    amount <= permissions.buyLimit(recipient),
                    "User buying more than his/her buyLimit"
                );
            }
            // if (cooldown > 0) {
            //     require(
            //         lastBuy[recipient] + cooldown <= block.timestamp,
            //         "Cooldown still active"
            //     );
            //     lastBuy[recipient] = block.timestamp;
            // }
            require(tradingActive, "Trading is not yet active");
            (send, taxes, autoLiquidityTax) = _getTaxAmounts(amount, true);
        } else if (recipient == _pair) {
            require(tradingActive, "Trading is not yet active");
            if (address(permissions) != address(0)) {
                require(
                    permissions.isWhitelisted(sender),
                    "User is not whitelisted to sell"
                );
            }
            (send, taxes, autoLiquidityTax) = _getTaxAmounts(amount, false);
        }
        _rawTransfer(sender, recipient, send);
        _takeTaxes(sender, taxes, autoLiquidityTax);
    }

    /// @notice Perform a Uniswap v2 swap from MDAO to ETH and handle tax distribution
    function _swap() internal lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        uint256 autoLiquidityAmount = totalAutoLiquidityTax.div(2);
        uint256 walletTaxes = totalTaxes[0].add(totalTaxes[1]).add(
            totalTaxes[2]
        );
        uint256 totalSwapAmount = walletTaxes.add(autoLiquidityAmount);

        _approve(
            address(this),
            address(_router),
            totalAutoLiquidityTax.add(walletTaxes)
        );
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            totalSwapAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        uint256 contractEthBalance = address(this).balance;

        uint256 tax0Eth = contractEthBalance.mul(totalTaxes[0]).div(
            totalSwapAmount
        );
        uint256 tax1Eth = contractEthBalance.mul(totalTaxes[1]).div(
            totalSwapAmount
        );
        uint256 tax2Eth = contractEthBalance.mul(totalTaxes[2]).div(
            totalSwapAmount
        );
        uint256 autoLiquidityEth = contractEthBalance
            .mul(autoLiquidityAmount)
            .div(totalSwapAmount);
        totalTaxes = [0, 0, 0];
        totalAutoLiquidityTax = 0;

        if (tax0Eth > 0) {
            taxWallets[0].transfer(tax0Eth);
        }
        if (tax1Eth > 0) {
            taxWallets[1].transfer(tax1Eth);
        }
        if (tax2Eth > 0) {
            taxWallets[2].transfer(tax2Eth);
        }
        if (autoLiquidityEth > 0) {
            _router.addLiquidityETH{value: autoLiquidityEth}(
                address(this),
                autoLiquidityAmount,
                0,
                0,
                address(0),
                block.timestamp
            );
        }
    }

    function swapAll() external {
        if (!_inSwap) {
            _swap();
        }
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Transfers MDAO from an account to this contract for taxes
    /// @param _account The account to transfer MDAO from
    /// @param _taxAmounts The amount for each tax
    /// @param _autoLiquidityTaxAmount The amount of auto liquidity tax
    function _takeTaxes(
        address _account,
        uint256[3] memory _taxAmounts,
        uint256 _autoLiquidityTaxAmount
    ) internal {
        require(_account != address(0), "taxation from the zero address");

        uint256 totalAmount = _taxAmounts[0]
            .add(_taxAmounts[1])
            .add(_taxAmounts[2])
            .add(_autoLiquidityTaxAmount);
        _rawTransfer(_account, address(this), totalAmount);
        totalTaxes[0] += _taxAmounts[0];
        totalTaxes[1] += _taxAmounts[1];
        totalTaxes[2] += _taxAmounts[2];
        totalAutoLiquidityTax += _autoLiquidityTaxAmount;
    }

    /// @notice Get a breakdown of send and tax amounts
    /// @param amount The amount to tax in wei
    /// @return send The raw amount to send
    /// @return taxes The raw tax amounts
    /// @return autoLiquidityTax The raw auto liquidity tax amount
    function _getTaxAmounts(uint256 amount, bool buying)
        internal
        view
        returns (
            uint256 send,
            uint256[3] memory taxes,
            uint256 autoLiquidityTax
        )
    {
        if (buying) {
            taxes = [
                amount.mul(buyTaxes[0]).div(BPS_DENOMINATOR),
                amount.mul(buyTaxes[1]).div(BPS_DENOMINATOR),
                amount.mul(buyTaxes[2]).div(BPS_DENOMINATOR)
            ];
            autoLiquidityTax = amount.mul(buyAutoLiquidityTax).div(
                BPS_DENOMINATOR
            );
        } else {
            taxes = [
                amount.mul(sellTaxes[0]).div(BPS_DENOMINATOR),
                amount.mul(sellTaxes[1]).div(BPS_DENOMINATOR),
                amount.mul(sellTaxes[2]).div(BPS_DENOMINATOR)
            ];
            autoLiquidityTax = amount.mul(sellAutoLiquidityTax).div(
                BPS_DENOMINATOR
            );
        }
        send = amount.sub(taxes[0]).sub(taxes[1]).sub(taxes[2]).sub(
            autoLiquidityTax
        );
    }

    // modified from OpenZeppelin ERC20
    function _rawTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");

        uint256 senderBalance = balanceOf(sender);
        require(senderBalance >= amount, "transfer amount exceeds balance");
        unchecked {
            _subtractBalance(sender, amount);
        }
        _addBalance(recipient, amount);

        emit Transfer(sender, recipient, amount);
    }

    /// @notice Enable or disable whether swap occurs during `_transfer`
    /// @param _swapFees If true, enables swap during `_transfer`
    function setSwapFees(bool _swapFees) external onlyOwner {
        swapFees = _swapFees;
        emit SwapFeesChanged(_swapFees);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _mint(address account, uint256 amount) internal override {
        require(_totalSupply.add(amount) <= MAX_SUPPLY, "Max supply exceeded");
        _totalSupply += amount;
        _addBalance(account, amount);
        emit Transfer(address(0), account, amount);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function airdrop(address[] memory accounts, uint256[] memory amounts)
        external
        onlyOwner
    {
        require(accounts.length == amounts.length, "array lengths must match");

        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], amounts[i]);
        }
    }

    receive() external payable {}
}
