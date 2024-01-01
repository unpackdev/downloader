// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./IERC20Metadata.sol";

/**
 * @title MOJI Token Contract
 */
contract MOJI is IERC20Metadata, Ownable, ERC20Burnable {
    /// @notice Emitted when a liquidity pool pair is updated.
    event LPPairSet(address indexed pair, bool enabled);

    /// @notice Emitted when an account is marked or unmarked as a liquidity holder (treasury, staking, etc).
    event LiquidityHolderSet(address indexed account, bool flag);

    /// @notice Emitted (once) when fees are locked forever.
    event FeesLockedForever();

    /// @notice Emitted (once) when sniper bot protection is disabled forever.
    event SniperBotProtectionDisabledForever();

    event BlacklistSet(address indexed account, bool flag);

    /// @notice Emitted (once) when blacklist add is restricted forever.
    event BlacklistAddRestrictedForever();

    event BuyFeeNumeratorSet(uint256 value);
    event SellFeeNumeratorSet(uint256 value);
    event TreasurySet(address[] treasuryList, uint256[] treasuryShares);
    event BuyFeePaid(address indexed from, uint256 amount);
    event SellFeePaid(address indexed from, uint256 amount);

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

    string constant private _name = "Meme2earN";
    string constant private _symbol = "MOJI";
    uint256 constant private TOTAL_SUPPLY = 100_000_000 * (10 ** 18);

    uint256 constant public DENOMINATOR = 10000;
    uint256 constant public MAX_BUY_FEE_NUMERATOR = 500;  // 5%
    uint256 constant public MAX_SELL_FEE_NUMERATOR = 500;  // 5%
    uint256 public buyFeeNumerator;
    uint256 public _sellFeeNumerator;
    uint256[] public treasuryShares;
    address[] public treasuryList;
    bool public feesAreLockedForever;
    bool public sniperBotProtectionDisabledForever;
    bool public blacklistAddRestrictedForever;
    uint256 public immutable deployTimestamp;

    constructor(
        address[] memory _treasuryList,
        uint256[] memory _treasuryShares,
        uint256 _buyFeeNumeratorValue,
        uint256 _sellFeeNumeratorValue
    ) Ownable() ERC20(_name, _symbol) {
        _mint(msg.sender, TOTAL_SUPPLY);
        setLiquidityHolder(msg.sender, true);
        setTreasury(_treasuryList, _treasuryShares);
        setBuyFeeNumerator(_buyFeeNumeratorValue);
        setSellFeeNumerator(_sellFeeNumeratorValue);
        deployTimestamp = block.timestamp;
    }

    function setTreasury(
        address[] memory _treasuryList,
        uint256[] memory _treasuryShares
    ) public onlyOwner {
        require(_treasuryShares.length == _treasuryList.length, "lengths mismatch");
        uint256 sumShares = 0;
        for (uint256 i=0; i<_treasuryShares.length; i++) {
            sumShares += _treasuryShares[i];
            require(_treasuryShares[i] != 0, "wrong share");
        }
        require(sumShares == DENOMINATOR, "wrong shares (sum != 10000)");
        treasuryList = _treasuryList;
        treasuryShares = _treasuryShares;
        emit TreasurySet(_treasuryList, _treasuryShares);
    }

    function lockFeesForever() external onlyOwner {
        require(!feesAreLockedForever, "already set");
        feesAreLockedForever = true;
        emit FeesLockedForever();
    }

    function restrictBlacklistAddForever() external onlyOwner {
        require(!blacklistAddRestrictedForever, "already set");
        blacklistAddRestrictedForever = true;
        emit BlacklistAddRestrictedForever();
    }

    function setLpPair(address pair, bool enabled) external onlyOwner {
        accountInfo[pair].isLPPool = enabled;
        emit LPPairSet(pair, enabled);
    }

    function setBlacklisted(address account, bool isBlacklisted) external onlyOwner {
        if (isBlacklisted) {
            require(!blacklistAddRestrictedForever, "Blacklist add restricted forever");
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
        return DENOMINATOR;  // 100% to prevent sniper bots from buying
    }

    function disableSniperBotProtectionForever() external onlyOwner {
        require(!sniperBotProtectionDisabledForever, "already set");
        sniperBotProtectionDisabledForever = true;
        emit SniperBotProtectionDisabledForever();
    }

    function setLiquidityHolder(address account, bool flag) public onlyOwner {
        accountInfo[account].isLiquidityHolder = flag;
        emit LiquidityHolderSet(account, flag);
    }

    function _hasLimits(AccountInfo memory fromInfo, AccountInfo memory toInfo) internal pure returns(bool) {
        return !fromInfo.isLiquidityHolder && !toInfo.isLiquidityHolder;
    }

    event TakenFee(address to, uint256 amount);

    function _distributeFees(address from, uint256 amount) internal {
        for (uint256 i=0; i<treasuryList.length; ++i) {
            address _treasury = treasuryList[i];
            uint256 _share = treasuryShares[i];
            uint256 amountShare = amount * _share / DENOMINATOR;
            if (_treasury == address(0)) {
                _burn(from, amountShare);
            } else {
                super._transfer(from, _treasury, amountShare);
            }
            emit TakenFee(_treasury, amountShare);
        }
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

        if (fromInfo.isLPPool) {
            // buy
            uint256 buyFeeAmount = amount * buyFeeNumerator / DENOMINATOR;
            _distributeFees(from, buyFeeAmount);
            emit BuyFeePaid(from, buyFeeAmount);
            unchecked {  // underflow is not possible
                amount -= buyFeeAmount;
            }
        } else if (toInfo.isLPPool) {
            // sell
            uint256 sellFeeAmount = amount * sellFeeNumerator() / DENOMINATOR;
            _distributeFees(from, sellFeeAmount);
            emit SellFeePaid(from, sellFeeAmount);
            unchecked {  // underflow is not possible
                amount -= sellFeeAmount;
            }
        } else {
            // no fees for usual transfers
        }

        super._transfer(from, to, amount);

        if (block.timestamp - deployTimestamp < 1 hours) {
            require(balanceOf(to) < 4_000_000 * 1e18 || toInfo.isLiquidityHolder, "wheel protection");
        }
    }
}