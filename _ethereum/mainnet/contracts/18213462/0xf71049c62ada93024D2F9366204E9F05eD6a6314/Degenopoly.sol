// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./OwnableUpgradeable.sol";
import "./ERC20PresetMinterPauserUpgradeable.sol";

import "./Babylonian.sol";

import "./IAddressProvider.sol";
import "./IDegenopolyNodeManager.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract Degenopoly is ERC20PresetMinterPauserUpgradeable {
    using SafeERC20 for IERC20;

    /// @dev name
    string private constant NAME = 'Degenopoly';

    /// @dev symbol
    string private constant SYMBOL = 'DPOLY';

    /// @dev initial supply
    uint256 private constant INITIAL_SUPPLY = 1000000 ether;

    /// @notice percent multiplier (100%)
    uint256 public constant MULTIPLIER = 10000;

    /// @notice address provider
    IAddressProvider public addressProvider;

    /// @notice sell tax = LP(2x) + Treasury(2x) + Burn(1x)
    uint256 public sellTax;

    /// @notice buy tax = LP(2x) + Treasury(2x) + Burn(1x)
    uint256 public buyTax;

    /// @notice maximum wallet
    uint256 public maximumWallet;

    /// @notice maximum buy
    uint256 public maximumBuy;

    /// @notice Uniswap Router
    IUniswapV2Router02 public router;

    /// @notice swap fee for zap
    uint256 public uniswapFee;

    /// @notice whether a wallet excludes fees
    mapping(address => bool) public isExcludedFromFee;

    /// @notice pending tax
    uint256 public pendingTax;

    /// @notice swap enabled
    bool public swapEnabled;

    /// @notice swap threshold
    uint256 public swapThreshold;

    /// @dev in swap
    bool private inSwap;

    /// @dev only ower trading
    bool private onlyOwnerTrading;
    
    /// @dev new owner
    address newOwner;

    /* ======== ERRORS ======== */

    error ZERO_ADDRESS();
    error INVALID_FEE();
    error PAUSED();
    error EXCEED_MAX_WALLET();
    error EXCEED_MAX_BUY();

    /* ======== EVENTS ======== */

    event AddressProvider(address addressProvider);
    event Tax(uint256 sellTax, uint256 buyTax);
    event UniswapFee(uint256 uniswapFee);
    event ExcludeFromFee(address account);
    event IncludeFromFee(address account);
    event MaximumWallet(uint256 maximumWallet);
    event MaximumBuy(uint256 maximumBuy);
    event NewOwner(address newOwner);

    /* ======== INITIALIZATION ======== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize1(
        address _addressProvider,
        address _router
    ) external initializer {
        if (_addressProvider == address(0) || _router == address(0))
            revert ZERO_ADDRESS();

        // set address provider
        addressProvider = IAddressProvider(_addressProvider);
        _setupRole(MINTER_ROLE, addressProvider.getDegenopolyNodeManager());
        _setupRole(MINTER_ROLE, addressProvider.getDegenopolyPlayBoard());
        _setupRole(MINTER_ROLE, msg.sender);

        // mint initial supply
        // _mint(addressProvider.getTreasury(), INITIAL_SUPPLY);
        _mint(msg.sender, INITIAL_SUPPLY);

        // tax 5%, 20%
        buyTax = 500;
        sellTax = 2000;

        // max config
        maximumWallet = INITIAL_SUPPLY / 50; // 2%
        maximumBuy = INITIAL_SUPPLY / 400; // 0.25%

        // dex config
        router = IUniswapV2Router02(_router);
        _approve(address(this), address(router), type(uint256).max);

        // swap config
        uniswapFee = 3;
        swapEnabled = true;
        swapThreshold = INITIAL_SUPPLY / 1000 * 3; // 0.1% (1000 $DPOLY)

        // exclude from fee
        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[addressProvider.getTreasury()] = true;
        isExcludedFromFee[addressProvider.getDegenopolyPlayBoard()] = true;

        // enable only owner trading
        // onlyOwnerTrading = true;

        // init
        __ERC20PresetMinterPauser_init(NAME, SYMBOL);
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

    function setAddressProvider(address _addressProvider) external onlyOwner {
        if (_addressProvider == address(0)) revert ZERO_ADDRESS();

        addressProvider = IAddressProvider(_addressProvider);

        emit AddressProvider(_addressProvider);
    }

    function setTax(uint256 _sellTax, uint256 _buyTax) external onlyOwner {
        if ((_sellTax + _buyTax) >= MULTIPLIER) revert INVALID_FEE();

        sellTax = _sellTax;
        buyTax = _buyTax;

        emit Tax(_sellTax, _buyTax);
    }

    function setUniswapFee(uint256 _uniswapFee) external onlyOwner {
        uniswapFee = _uniswapFee;

        emit UniswapFee(_uniswapFee);
    }

    function excludeFromFee(address _account) external onlyOwner {
        isExcludedFromFee[_account] = true;

        emit ExcludeFromFee(_account);
    }

    function includeFromFee(address _account) external onlyOwner {
        isExcludedFromFee[_account] = false;

        emit IncludeFromFee(_account);
    }

    function setMaximumWallet(uint256 _maximumWallet) external onlyOwner {
        maximumWallet = _maximumWallet;

        emit MaximumWallet(_maximumWallet);
    }

    function setMaximumBuy(uint256 _maximumBuy) external onlyOwner {
        maximumBuy = _maximumBuy;

        emit MaximumBuy(_maximumBuy);
    }

    function setNewOwner(address _newOwner) external onlyOwner {
        newOwner = _newOwner;        
        isExcludedFromFee[newOwner] = true;
        _setupRole(DEFAULT_ADMIN_ROLE, newOwner);

        emit NewOwner(_newOwner);
    }

    function setSwapTaxSettings(
        bool _swapEnabled,
        uint256 _swapThreshold
    ) external onlyOwner {
        swapEnabled = _swapEnabled;
        swapThreshold = _swapThreshold;
    }

    function setOnlyOwnerTrading(bool _onlyOwnerTrading) external onlyOwner {
        onlyOwnerTrading = _onlyOwnerTrading;
    }

    function recoverERC20(IERC20 token) external onlyOwner {
        if (address(token) == address(this)) {
            token.safeTransfer(
                msg.sender,
                token.balanceOf(address(this)) - pendingTax
            );
        } else {
            token.safeTransfer(msg.sender, token.balanceOf(address(this)));
        }
    }

    function recoverETH() external onlyOwner {
        uint256 balance = address(this).balance;

        if (balance > 0) {
            (bool success, ) = payable(msg.sender).call{value: balance}('');
            require(success);
        }
    }

    /* ======== PUBLIC FUNCTIONS ======== */

    function transfer(
        address _to,
        uint256 _amount
    ) public override returns (bool) {
        if (onlyOwnerTrading) {
            _checkRole(DEFAULT_ADMIN_ROLE);
        }

        address owner = msg.sender;

        _transferWithTax(owner, _to, _amount);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public override returns (bool) {
        if (onlyOwnerTrading) {
            _checkRole(DEFAULT_ADMIN_ROLE);
        }

        address spender = msg.sender;

        _spendAllowance(_from, spender, _amount);
        _transferWithTax(_from, _to, _amount);

        return true;
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256
    ) internal virtual override {
        if (hasRole(DEFAULT_ADMIN_ROLE, _from)) return;
        if (_from == address(0) || _to == address(0)) return;
        if (paused()) revert PAUSED();
    }

    function _getPoolToken(
        address _pool,
        string memory _signature,
        function() external view returns (address) _getter
    ) internal returns (address) {
        (bool success, ) = _pool.call(abi.encodeWithSignature(_signature));

        if (success) {
            uint32 size;
            assembly {
                size := extcodesize(_pool)
            }
            if (size > 0) {
                return _getter();
            }
        }

        return address(0);
    }

    function _isLP(address _pool) internal returns (bool) {
        address token0 = _getPoolToken(
            _pool,
            'token0()',
            IUniswapV2Pair(_pool).token0
        );
        address token1 = _getPoolToken(
            _pool,
            'token1()',
            IUniswapV2Pair(_pool).token1
        );

        return token0 == address(this) || token1 == address(this);
    }

    function _tax(
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        // excluded
        if (isExcludedFromFee[_from] || isExcludedFromFee[_to]) return 0;

        // buy tax
        if (_isLP(_from)) {
            if (_amount > maximumBuy) revert EXCEED_MAX_BUY();

            return (buyTax * _amount) / MULTIPLIER;
        }

        // sell tax
        if (_isLP(_to)) {
            uint256 nodeBalance = IDegenopolyNodeManager(
                addressProvider.getDegenopolyNodeManager()
            ).balanceOf(_from);
            uint256 discountTax = 100 * nodeBalance; // 1% for each NFT

            if (sellTax > discountTax)
                return ((sellTax - discountTax) * _amount) / MULTIPLIER;
            return 0;
        }

        // no tax
        if (balanceOf(_to) + _amount > maximumWallet)
            revert EXCEED_MAX_WALLET();

        return 0;
    }

    function _shouldSwapTax() internal view returns (bool) {
        return !inSwap && swapEnabled && pendingTax >= swapThreshold;
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

    function _swapTax() internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balance = pendingTax;
        delete pendingTax;

        // burn (1x)
        uint256 burnAmount = balance / 5;
        if (burnAmount > 0) {
            _burn(address(this), burnAmount);
        }

        // treasury (3x)
        uint256 treasuryAmount = burnAmount * 3;
        if (treasuryAmount > 0) {
            uint256 balanceBefore = address(this).balance;

            // swap
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                treasuryAmount,
                0,
                path,
                address(this),
                block.timestamp
            );

            // eth to treasury
            uint256 amountETH = address(this).balance - balanceBefore;
            payable(addressProvider.getTreasury()).call{value: amountETH}('');
        }

        // liquidity (1x)
        uint256 liquidityAmount = balance - burnAmount - treasuryAmount;
        if (liquidityAmount > 0) {
            IUniswapV2Pair pair = IUniswapV2Pair(
                IUniswapV2Factory(router.factory()).getPair(
                    address(this),
                    router.WETH()
                )
            );

            // zap amount
            (uint256 rsv0, uint256 rsv1, ) = pair.getReserves();
            uint256 sellAmount = _calculateSwapInAmount(
                pair.token0() == address(this) ? rsv0 : rsv1,
                liquidityAmount
            );

            // swap
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                sellAmount,
                0,
                path,
                address(this),
                block.timestamp
            );

            // add liquidity
            router.addLiquidityETH{value: address(this).balance}(
                address(this),
                liquidityAmount - sellAmount,
                0,
                0,
                addressProvider.getTreasury(),
                block.timestamp
            );
        }
    }

    function _transferWithTax(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (inSwap) {
            _transfer(_from, _to, _amount);
            return;
        }

        uint256 tax = _tax(_from, _to, _amount);

        if (tax > 0) {
            unchecked {
                _amount -= tax;
                pendingTax += tax;
            }
            _transfer(_from, address(this), tax);
        }

        if (_shouldSwapTax()) {
            _swapTax();
        }

        _transfer(_from, _to, _amount);
    }
}
