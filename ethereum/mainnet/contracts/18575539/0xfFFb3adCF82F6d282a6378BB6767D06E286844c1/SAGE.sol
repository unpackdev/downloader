// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./ERC20Votes.sol";
import "./IERC20Metadata.sol";
import "./IERC165.sol";
import "./IVotes.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

import "./ITreasury.sol";

/**
 * @title SAGE Token Contract
 */
contract SAGE is IERC165, IERC20Metadata, Ownable, ERC20Burnable, ERC20Votes {
    /// @notice Emitted when a liquidity pool pair is updated.
    event LPPairSet(address indexed pair, bool enabled);

    /// @notice Emitted when an account is marked or unmarked as a liquidity holder (treasury, staking, etc).
    event LiquidityHolderSet(address indexed account, bool flag);

    /// @notice Emitted (once) when fees are locked forever.
    event FeesLockedForever();

    /// @notice Emitted (once) when sniper bot protection is disabled forever.
    event SniperBotProtectionDisabledForever();

    event BlacklistSet(address indexed account, bool flag);

    /// @notice Emitted (once) when blacklist add is disabled forever.
    event BlacklistAddDisabledForever();

    /// @notice Emitted (once) when whale protection is disabled forever.
    event whaleProtectionDisabledForever();

    event BuyFeeNumeratorSet(uint256 value);
    event SellFeeNumeratorSet(uint256 value);
    event TreasurySet(
        address treasuryBuy,
        address treasurySell,
        bool doCallback
    );
    event BuyFeePaid(address indexed from, uint256 amount);
    event SellFeePaid(address indexed from, uint256 amount);
    event IsWhitelisted(address indexed account, uint256 whitelistedAllowance);

    /**
     * @dev Struct to group account-specific flags to optimize storage usage.
     *
     * For a deeper understanding of storage packing and its benefits, you can refer to:
     * - https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html
     * - https://dev.to/web3_ruud/advance-soliditymastering-storage-slot-c38
     */
    struct AccountInfo {
        bool isLPPool;
        bool isLiquidityHolder;
        bool isBlackListed;
    }
    mapping (address => AccountInfo) public accountInfo;

    string constant private _name = "SAGE";
    string constant private _symbol = "SAGE";
    uint256 constant private TOTAL_SUPPLY = 100_000_000 * (10 ** 18);

    uint256 constant public DENOMINATOR = 10000;
    uint256 constant public MAX_BUY_FEE_NUMERATOR = 500;  // 5%
    uint256 constant public MAX_SELL_FEE_NUMERATOR = 500;  // 5%
    uint256 public buyFeeNumerator;
    uint256 public _sellFeeNumerator;

    address public treasuryBuy;
    address public treasurySell;
    bool public treasuryDoCallback;

    bool public feesAreLockedForever;
    bool public sniperBotProtectionDisabledForever;
    bool public blacklistAddDisabledForever;

    // note: whitelist is active only during the first 10 minutes to prevent sniper bots from buying
    mapping (address => uint256) public whitelistedAllowance;  // amount how much tokens can he buy
    uint256 public presaleStartTime;
    uint256 public presaleEndTime;

    constructor(
        address _treasuryBuy,
        address _treasurySell,
        bool _treasuryDoCallback,
        uint256 _buyFeeNumeratorValue,
        uint256 _sellFeeNumeratorValue
    ) Ownable() ERC20(_name, _symbol) ERC20Permit(_name) payable {
        _setLiquidityHolder(msg.sender, true);

        _setTreasury(_treasuryBuy, _treasurySell, _treasuryDoCallback);
        setBuyFeeNumerator(_buyFeeNumeratorValue);
        setSellFeeNumerator(_sellFeeNumeratorValue);

        _setSupportedInterface(type(IERC165).interfaceId, true);
        _setSupportedInterface(type(IVotes).interfaceId, true);

        _mint(address(this), TOTAL_SUPPLY);
        _setLiquidityHolder(address(this), true);
        _setWhitelistedAllowance(msg.sender, type(uint256).max);
    }

    function createLP(
        IUniswapV2Factory _uniswapV2Factory,
        IUniswapV2Router02 _uniswapV2Router
    ) public onlyOwner payable {
        _approve(address(this), address(_uniswapV2Router), TOTAL_SUPPLY);
        address WETH = _uniswapV2Router.WETH();
        address pair = IUniswapV2Factory(_uniswapV2Factory).createPair(address(this), WETH);
        _setLpPair(pair, true);
        IUniswapV2Router02(_uniswapV2Router).addLiquidityETH{value: msg.value}({
            token: address(this),
            amountTokenDesired: TOTAL_SUPPLY,
            amountTokenMin: 0,
            amountETHMin: 0,
            to: msg.sender,
            deadline: block.timestamp
        });
    }

    function setPresaleTime(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(presaleStartTime == 0, "Can be set only once");
        require(_startTime < _endTime, "Invalid time");
        require(_startTime > block.timestamp, "Invalid time");
        presaleStartTime = _startTime;
        presaleEndTime = _endTime;
    }

    function setWhitelistedAllowance(address account, uint256 _whitelistedAllowance) external onlyOwner {
        _setWhitelistedAllowance(account, _whitelistedAllowance);
    }

    function whitelistAllowanceMany(address[] calldata accounts, uint256 _whitelistedAllowance) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _setWhitelistedAllowance(accounts[i], _whitelistedAllowance);
        }
    }

    function _setWhitelistedAllowance(address account, uint256 _whitelistedAllowance) internal {
        whitelistedAllowance[account] = _whitelistedAllowance;
        emit IsWhitelisted(account, _whitelistedAllowance);
    }

    function _checkWhitelistedAllowance(uint256 amount) internal {
        require(presaleStartTime != 0, "Presale time is not set");
        require(block.timestamp >= presaleStartTime, "Sales are not active yet");
        if (block.timestamp > presaleEndTime) {
            // no restrictions after the presale
            return;
        }
        // during the presale only whitelisted accounts can buy
        uint256 allowance = whitelistedAllowance[tx.origin];  // note: tx.origin is used
        require(allowance >= amount, "Whitelisted allowance exceeded");
        _setWhitelistedAllowance(tx.origin, allowance - amount);
    }

    function setTreasury(
        address _treasuryBuy,
        address _treasurySell,
        bool _treasuryDoCallback
    ) public onlyOwner {
        _setTreasury(_treasuryBuy, _treasurySell, _treasuryDoCallback);
    }

    function _setTreasury(
        address _treasuryBuy,
        address _treasurySell,
        bool _treasuryDoCallback
    ) internal {
        require(_treasuryBuy != address(0), "Treasury address cannot be zero");
        require(_treasurySell != address(0), "Treasury address cannot be zero");
        treasuryBuy = _treasuryBuy;
        treasurySell = _treasurySell;
        treasuryDoCallback = _treasuryDoCallback;
        emit TreasurySet(_treasuryBuy, _treasurySell, _treasuryDoCallback);
        _setLiquidityHolder(_treasuryBuy, true);
        _setLiquidityHolder(_treasurySell, true);
    }

    function lockFeesForever() external onlyOwner {
        require(!feesAreLockedForever, "already set");
        feesAreLockedForever = true;
        emit FeesLockedForever();
    }

    function disableBlacklistAddForever() external onlyOwner {
        require(!blacklistAddDisabledForever, "already set");
        blacklistAddDisabledForever = true;
        emit BlacklistAddDisabledForever();
    }

    function setLpPair(address pair, bool enabled) external onlyOwner {
        _setLpPair(pair, enabled);
    }

    function _setLpPair(address pair, bool enabled) internal {
        accountInfo[pair].isLPPool = enabled;
        emit LPPairSet(pair, enabled);
    }

    function setBlacklisted(address account, bool isBlacklisted) external onlyOwner {
        if (isBlacklisted) {
            require(!blacklistAddDisabledForever, "Blacklist add disabled forever");
        }
        accountInfo[account].isBlackListed = isBlacklisted;
        emit BlacklistSet(account, isBlacklisted);
    }

    function setBuyFeeNumerator(uint256 value) public onlyOwner {
        require(!feesAreLockedForever, "Fees are locked forever");
        require(value <= MAX_BUY_FEE_NUMERATOR, "Exceeds maximum buy fee");
        buyFeeNumerator = value;
        emit BuyFeeNumeratorSet(value);
    }

    function setSellFeeNumerator(uint256 value) public onlyOwner {
        require(!feesAreLockedForever, "Fees are locked forever");
        require(value <= MAX_SELL_FEE_NUMERATOR, "Exceeds maximum buy fee");
        _sellFeeNumerator = value;
        emit SellFeeNumeratorSet(value);
    }

    function sellFeeNumerator() public view returns(uint256) {
        if (sniperBotProtectionDisabledForever) {
            return _sellFeeNumerator;
        }
        return DENOMINATOR;  // during the first 15minutes after the launch it's 100% to prevent sniper bots from buying
    }

    function disableSniperBotProtectionForever() external onlyOwner {
        require(!sniperBotProtectionDisabledForever, "already set");
        sniperBotProtectionDisabledForever = true;
        emit SniperBotProtectionDisabledForever();
    }

    function setLiquidityHolder(address account, bool flag) public onlyOwner {
        _setLiquidityHolder(account, flag);
    }

    function _setLiquidityHolder(address account, bool flag) internal {
        accountInfo[account].isLiquidityHolder = flag;
        emit LiquidityHolderSet(account, flag);
    }

    function _hasLimits(AccountInfo memory fromInfo, AccountInfo memory toInfo) internal pure returns(bool) {
        return !fromInfo.isLiquidityHolder && !toInfo.isLiquidityHolder;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        AccountInfo memory fromInfo = accountInfo[from];
        AccountInfo memory toInfo = accountInfo[to];

        require(!fromInfo.isBlackListed && !toInfo.isBlackListed, "Blacklisted");

        if (!_hasLimits(fromInfo, toInfo) ||
            (fromInfo.isLPPool && toInfo.isLPPool)  // no fee for transferring between pools
        ) {
            super._transfer(from, to, amount);
            return;
        }

        uint256 buyFeeAmount = 0;
        uint256 sellFeeAmount = 0;
        if (fromInfo.isLPPool) {
            // buy
            buyFeeAmount = amount * buyFeeNumerator / DENOMINATOR;
            super._transfer(from, treasuryBuy, buyFeeAmount);
            emit BuyFeePaid(from, buyFeeAmount);
            unchecked {  // underflow is not possible
                amount -= buyFeeAmount;
            }
            _checkWhitelistedAllowance(amount);
        } else if (toInfo.isLPPool) {
            // sell
            sellFeeAmount = amount * sellFeeNumerator() / DENOMINATOR;
            super._transfer(from, treasurySell, sellFeeAmount);
            emit SellFeePaid(from, sellFeeAmount);
            unchecked {  // underflow is not possible
                amount -= sellFeeAmount;
            }
        } else {
            // no fees for usual transfers
        }

        super._transfer(from, to, amount);

        if (treasuryDoCallback) {
            if (buyFeeAmount > 0) {
                ITreasury(treasuryBuy).onBuyFeePaid(from, buyFeeAmount);
            }
            if (sellFeeAmount > 0) {
                ITreasury(treasurySell).onSellFeePaid(from, sellFeeAmount);
            }
        }
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(account, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }

    mapping (bytes4 => bool) private _supportedInterfaces;
    event InterfaceSupported(bytes4 indexed interfaceId, bool value);

    function setSupportedInterface(bytes4 interfaceId, bool value) external onlyOwner {
        _setSupportedInterface(interfaceId, value);
    }

    function _setSupportedInterface(bytes4 interfaceId, bool value) internal {
        _supportedInterfaces[interfaceId] = value;
        emit InterfaceSupported(interfaceId, value);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }
}