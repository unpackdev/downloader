// SPDX-License-Identifier: MIT

// Web: https://blockcrafteth.com/
// Twitter: https://twitter.com/BlockCraftETH
// Tg: https://t.me/BlockCraftETH

pragma solidity 0.8.17;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC20PresetMinterPauser.sol";

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IRewardRecipient.sol";
import "./SafeMath.sol";

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


error INVALID_ADDRESS();
error INVALID_FEE();
error PAUSED();

contract BlockCraft is ERC20PresetMinterPauser {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /// @dev name
    string private constant NAME = 'BlockCraft';

    /// @dev symbol
    string private constant SYMBOL = 'BC';

    /// @dev initial supply
    uint256 private constant INITIAL_SUPPLY = 10000000 ether;

    /// @notice percent multiplier (100%)
    uint256 public constant MULTIPLIER = 10000;

    /// @notice Uniswap Router
    IUniswapV2Router02 public immutable ROUTER;

    /// @notice Uniswap Factory
    IUniswapV2Factory public immutable FACTORY;

    /// @notice Uniswap Pair
    address public immutable PAIR;

    /// @notice tax info
    struct TaxInfo {
        uint256 materialFee;
        uint256 operationFee;
        uint256 rewardFee;
    }
    TaxInfo public taxInfo;
    uint256 public totalFee;
    uint256 public uniswapFee;

    /// @notice anti bot deets
    uint256 public maxWalletPercent = 2;
    uint256 public maxTxPercent = 2; 
    bool private _anitbotenabled = true;

    /// @notice material
    address public materialFeeReceiver;

    /// @notice liquidity wallet
    address public rewardFeeReceiver;

    /// @notice marketing wallet
    address public operationFeeReceiver;

    /// @notice whether a wallet excludes fees
    mapping(address => bool) public isExcludedFromFee;

    /// @notice wheter to include a wallet in antibot or not
    mapping(address => bool) public isExcludedFromAntiBot;

    /// @notice pending tax
    uint256 public pendingTax;

    /// @notice swap enabled
    bool public swapEnabled = false;

    /// @notice swap threshold
    uint256 public swapThreshold = INITIAL_SUPPLY / 20000; // 0.005%

    /// @dev in swap
    bool private inSwap;


    /* ======== EVENTS ======== */

    event MaterialFeeReceiver(address receiver);
    event RewardFeeReceiver(address receiver);
    event OperationFeeReceiver(address receiver);
    event TaxFee(
        uint256 materialFee,
        uint256 operationFee,
        uint256 rewardFee
    );
    event UniswapFee(uint256 uniswapFee);
    event ExcludeFromFee(address account);
    event IncludeFromFee(address account);
    event AntiBotConfig(uint256 maxWallet, uint256 maxTx);
    event AntiBotEnabled(bool enabled);
    event AnitBotExclusion(address account, bool excluded);
    /* ======== INITIALIZATION ======== */

    constructor(
        IUniswapV2Router02 router
    ) ERC20PresetMinterPauser(NAME, SYMBOL) {
        _mint(_msgSender(), INITIAL_SUPPLY);

        ROUTER = router;
        FACTORY = IUniswapV2Factory(router.factory());
        PAIR = FACTORY.createPair(address(this), router.WETH());

        _approve(address(this), address(ROUTER), type(uint256).max);

        taxInfo.materialFee = 200; // 2%
        taxInfo.operationFee = 200; // 2%
        taxInfo.rewardFee = 200; // 2%
        totalFee = 600; // 6%
        uniswapFee = 3; // 0.3% (1000 = 100%)

        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromAntiBot[_msgSender()] = true;
        isExcludedFromAntiBot[address(this)] = true;
        isExcludedFromAntiBot[address(PAIR)] = true;
    }

    receive() external payable {}

    /* ======== MODIFIERS ======== */

    modifier onlyOwner() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    modifier swapping() {
        inSwap = true;

        _;

        inSwap = false;
    }

    /* ======== POLICY FUNCTIONS ======== */

    function setMaterialFeeReceiver(address receiver) external onlyOwner {
        if (receiver == address(0)) revert INVALID_ADDRESS();

        materialFeeReceiver = receiver;

        emit MaterialFeeReceiver(receiver);
    }

    function setRewardFeeReceiver(address receiver) external onlyOwner {
        if (receiver == address(0)) revert INVALID_ADDRESS();

        rewardFeeReceiver = receiver;

        emit RewardFeeReceiver(receiver);
    }

    function setOperationFeeReceiver(address receiver) external onlyOwner {
        if (receiver == address(0)) revert INVALID_ADDRESS();

        operationFeeReceiver = receiver;

        emit OperationFeeReceiver(receiver);
    }

    function setTaxFee(
        uint256 materialFee,
        uint256 operationFee,
        uint256 rewardFee
    ) external onlyOwner {
        totalFee = materialFee + operationFee + rewardFee;
        if (totalFee == 0 || totalFee >= MULTIPLIER) revert INVALID_FEE();

        taxInfo.materialFee = materialFee;
        taxInfo.operationFee = operationFee;
        taxInfo.rewardFee = rewardFee;

        emit TaxFee(materialFee, operationFee, rewardFee);
    }

    function setAntiBotConfig(uint256 _maxwallet,uint256 _maxtx) external onlyOwner {
        maxWalletPercent = _maxwallet;
        maxTxPercent = _maxtx;
        emit AntiBotConfig(_maxwallet,_maxtx);
    }

    function setAntiBot(bool _enabled) external onlyOwner {
        _anitbotenabled = _enabled;
        emit AntiBotEnabled(_enabled);
    }

    function setUniswapFee(uint256 fee) external onlyOwner {
        uniswapFee = fee;

        emit UniswapFee(fee);
    }

    function excludeFromFee(address account) external onlyOwner {
        isExcludedFromFee[account] = true;

        emit ExcludeFromFee(account);
    }

    function includeFromFee(address account) external onlyOwner {
        isExcludedFromFee[account] = false;

        emit IncludeFromFee(account);
    }

    function setAntiBotExclusion(address account,bool _isexcluded) external onlyOwner{
        isExcludedFromAntiBot[account] = _isexcluded;

        emit AnitBotExclusion(account,_isexcluded);
    }

    function enableSwap() external onlyOwner {
        swapEnabled = true;
    }

    function recoverERC20(IERC20 token) external onlyOwner {
        if (address(token) == address(this)) {
            token.safeTransfer(
                _msgSender(),
                token.balanceOf(address(this)) - pendingTax
            );
        } else {
            token.safeTransfer(_msgSender(), token.balanceOf(address(this)));
        }
    }

    /* ======== PUBLIC FUNCTIONS ======== */

    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        
        _anitbotcheck(to,amount);
        _transferWithTax(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();
        _anitbotcheck(to,amount);
        _spendAllowance(from, spender, amount);
        _transferWithTax(from, to, amount);
        return true;
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if (from != address(0) && paused()) revert PAUSED();
    }

    function _getPoolToken(
        address pool,
        string memory signature,
        function() external view returns (address) getter
    ) internal returns (address) {
        (bool success, ) = pool.call(abi.encodeWithSignature(signature));

        if (success) {
            uint32 size;
            assembly {
                size := extcodesize(pool)
            }
            if (size > 0) {
                return getter();
            }
        }

        return address(0);
    }

    function _shouldTakeTax(address from, address to) internal returns (bool) {
        if (isExcludedFromFee[from] || isExcludedFromFee[to]) return false;

        address token0 = _getPoolToken(
            to,
            'token0()',
            IUniswapV2Pair(to).token0
        );
        address token1 = _getPoolToken(
            to,
            'token1()',
            IUniswapV2Pair(to).token1
        );

        return token0 == address(this) || token1 == address(this);
    }

    function _shouldSwapTax() internal view returns (bool) {
        return !inSwap && swapEnabled && pendingTax >= swapThreshold;
    }

    function _swapTax() internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = ROUTER.WETH();

        uint256 balance = pendingTax;
        uint256 noSwap = (balance * taxInfo.rewardFee) / totalFee;

        delete pendingTax;
        // distribute tax (materials, operations, rewards)
        {
            uint256 swapAmount = balance - noSwap;
            uint256 balanceBefore = address(this).balance;
            if (swapAmount>0){
                ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
                swapAmount,
                0,
                path,
                address(this),
                block.timestamp
                );

                uint256 amountETH = address(this).balance - balanceBefore;
                uint256 materialETH = (amountETH * taxInfo.materialFee) /
                    (taxInfo.materialFee + taxInfo.operationFee);
                uint256 operationETH = amountETH - materialETH;

                try
                    IRewardRecipient(materialFeeReceiver).receiveReward{
                        value: materialETH
                    }()
                {} catch {}

                payable(operationFeeReceiver).call{value: operationETH}('');
            }
        }

        // transfer reward to reward wallet
        if (noSwap>0){
            _transfer(address(this), rewardFeeReceiver, noSwap);
        }
    }

    function _calculateSwapInAmount(
        uint256 reserveIn,
        uint256 userIn
    ) internal view returns (uint256) {
        return
            (Babylonian.sqrt(
                reserveIn *
                    ((userIn * (uint256(4000) - (4 * uniswapFee)) * 1000) +
                        (reserveIn *
                            ((uint256(4000) - (4 * uniswapFee)) *
                                1000 +
                                uniswapFee *
                                uniswapFee)))
            ) - (reserveIn * (2000 - uniswapFee))) / (2000 - 2 * uniswapFee);
    }

    function _checkMaxWallet(address recipient, uint256 amount) internal view {
        uint256 maxWalletBalance = totalSupply().mul(maxWalletPercent).div(100);
        require(balanceOf(recipient).add(amount) <= maxWalletBalance, "Exceeds maximum wallet balance");
    }

    function _checkMaxTx(uint256 amount) internal view {
        uint256 maxTransactionSize = totalSupply().mul(maxTxPercent).div(100);
        require(amount <= maxTransactionSize, "Exceeds maximum transaction size");
    }

    function _anitbotcheck(address to, uint256 amount) internal view{
        if (!_anitbotenabled){return;}
        if (isExcludedFromAntiBot[to]){
            return ;
        }
        require(swapEnabled,"Swap not enabled");
        _checkMaxWallet(to,amount);
        _checkMaxTx(amount);
        return ;
    }

    function _transferWithTax(
        address from,
        address to,
        uint256 amount
    ) internal {
        if (inSwap) {
            _transfer(from, to, amount);
            return;
        }

        if (_shouldTakeTax(from, to)) {
            uint256 tax = (amount * totalFee) / MULTIPLIER;
            unchecked {
                amount -= tax;
                pendingTax += tax;
            }
            _transfer(from, address(this), tax);
        }

        if (_shouldSwapTax()) {
            _swapTax();
        }

        _transfer(from, to, amount);
    }

}