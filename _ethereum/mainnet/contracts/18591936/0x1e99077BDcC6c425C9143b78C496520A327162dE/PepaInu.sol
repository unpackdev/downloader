// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./ERC20.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20UniswapV2InternalSwaps.sol";

contract PepaInu is ERC20, ERC20Permit, Ownable, ERC20UniswapV2InternalSwaps {
    /** @notice The presale states. */
    enum PresaleState {
        NONE,
        OPEN_FOR_WHITELIST,
        OPEN_FOR_PUBLIC,
        CLOSED,
        COMPLETED
    }

    /** @notice Percentage of supply to burn (50%). */
    uint256 public constant SHARE_BURN = 50_00;
    /** @notice Percentage of supply allocated for presale participants (33.22%). */
    uint256 public constant SHARE_PRESALE = 33_22;
    /** @notice Percentage of supply allocated for initial liquidity (13.28%).*/
    uint256 public constant SHARE_LIQUIDITY = 13_28;
    /** @notice Percentage of supply allocated for team, marketing, cex listings, etc. (3.5%). */
    uint256 public constant SHARE_OTHER = 3_50;
    /** @notice Hardcap in ETH for presale (75 ETH). */
    uint256 public constant PRESALE_HARDCAP = 75 ether;
    /** @notice Per account limit in ETH for presale (0.15 ETH). */
    uint256 public constant PRESALE_ACCOUNT_LIMIT = 0.15 ether;
    /** @notice Minimum threshold in ETH to trigger #_swapTokens. */
    uint256 public constant SWAP_THRESHOLD_ETH_MIN = 0.005 ether;
    /** @notice Maximum threshold in ETH to trigger #_swapTokens. */
    uint256 public constant SWAP_THRESHOLD_ETH_MAX = 50 ether;
    /** @notice Transfer tax in BPS (2%), not changeable. */
    uint256 public constant TAX_BPS = 2_00;

    uint8 private constant _DECIMALS = 9;
    uint256 private constant _MAX_SUPPLY =
        420_000_000_000_000_000 * (10 ** _DECIMALS);
    uint256 private constant _SUPPLY_PRESALE =
        (_MAX_SUPPLY * SHARE_PRESALE) / 100_00;
    uint256 private constant _SUPPLY_LIQUIDITY =
        (_MAX_SUPPLY * SHARE_LIQUIDITY) / 100_00;
    uint256 private constant _SUPPLY_BURN = (_MAX_SUPPLY * SHARE_BURN) / 100_00;
    uint256 private constant _SUPPLY_OTHER =
        _MAX_SUPPLY - _SUPPLY_PRESALE - _SUPPLY_LIQUIDITY - _SUPPLY_BURN;

    /** @notice Tax recipient wallet. */
    address public taxRecipient;
    /** @notice Whether address is extempt from transfer tax. */
    mapping(address => bool) public taxFreeAccount;
    /** @notice Whether address is an exchange pool. */
    mapping(address => bool) public isExchangePool;
    /** @notice Threshold in ETH of tokens to collect before triggering #_swapTokens. */
    uint256 public swapThresholdEth = 0.1 ether;
    /** @notice Tax manager. */
    address public taxManager;
    /** @notice Presale commitment in ETH per address. */
    mapping(address => uint256) public commitment;
    /** @notice Presale amount of claimed tokens per address. */
    mapping(address => uint256) public claimedTokens;
    /** @notice Whether address is whitelisted for early presale access. */
    mapping(address => bool) public presaleWhitelist;
    /** @notice Presale total commitment in ETH. */
    uint256 public totalCommitments;
    /** @notice Presale total amount of claimed tokens. */
    uint256 public totalClaimed;
    /** @notice Current presale state. */
    PresaleState public presaleState;

    uint256 private _launchTaxEndsAt = type(uint256).max;

    event CommitedToPresale(address indexed account, uint256 amount);
    event PresaleOpened();
    event PublicPresaleOpened();
    event PresaleClosed(uint256 totalCommitments);
    event PresaleCompleted(uint256 totalCommitments);
    event PresaleClaimed(address indexed account, uint256 amount);
    event TaxRecipientChanged(address indexed taxRecipient);
    event SwapThresholdChanged(uint256 swapThresholdEth);
    event TaxFreeStateChanged(address indexed account, bool indexed taxFree);
    event ExchangePoolStateChanged(
        address indexed account,
        bool indexed isExchangePool
    );
    event TaxManagerChanged(address indexed taxManager);
    event TaxesWithdrawn(uint256 amount);

    error MaxAccountLimitExceeded();
    error HardcapExceeded();
    error PresaleIsClosed();
    error PresaleNotCompleted();
    error AlreadyClaimed();
    error NoCommittments();
    error NothingCommitted();
    error Unauthorized();
    error InvalidParameters();
    error InvalidSwapThreshold();
    error InvalidTax();
    error NoContract();
    error InvalidState();
    error NotWhitelistedForPresale();

    modifier onlyTaxManager() {
        if (msg.sender != taxManager) {
            revert Unauthorized();
        }
        _;
    }

    constructor(
        address _owner,
        address _taxRecipient,
        address _taxManager,
        address _router
    )
        ERC20("Pepa Inu", "PEPA")
        ERC20Permit("Pepa Inu")
        ERC20UniswapV2InternalSwaps(_router)
    {
        _transferOwnership(_owner);

        taxManager = _taxManager;
        emit TaxManagerChanged(_taxManager);
        taxRecipient = _taxRecipient;
        emit TaxRecipientChanged(_taxRecipient);

        taxFreeAccount[address(0)] = true;
        emit TaxFreeStateChanged(address(0), true);
        taxFreeAccount[_taxRecipient] = true;
        emit TaxFreeStateChanged(_taxRecipient, true);
        taxFreeAccount[address(this)] = true;
        emit TaxFreeStateChanged(address(this), true);
        isExchangePool[pair] = true;
        emit ExchangePoolStateChanged(pair, true);

        _mint(address(this), _SUPPLY_PRESALE + _SUPPLY_LIQUIDITY);
        _mint(address(0xdead), _SUPPLY_BURN);
        _mint(_taxRecipient, _SUPPLY_OTHER);
    }

    /** @dev Users can send ETH directly to **this** contract to participate */
    receive() external payable {
        commitToPresale();
    }

    // *** User Interface ***

    /**
     * @notice Commit ETH to presale.
     * Presale supply is claimable proportionally for all presale participants.
     * Presale has no hardcap and 1 ETH per wallet limit.
     * Users can also send ETH directly to **this** contract to participate.
     * @dev Callable once presaleOpen.
     */
    function commitToPresale() public payable {
        address account = msg.sender;
        if (_isContract(account)) {
            revert NoContract();
        }
        if (
            presaleState == PresaleState.OPEN_FOR_WHITELIST &&
            !presaleWhitelist[account]
        ) {
            revert NotWhitelistedForPresale();
        }
        if (
            presaleState != PresaleState.OPEN_FOR_WHITELIST &&
            presaleState != PresaleState.OPEN_FOR_PUBLIC
        ) {
            revert PresaleIsClosed();
        }

        commitment[account] += msg.value;
        totalCommitments += msg.value;

        if (totalCommitments > PRESALE_HARDCAP) {
            revert HardcapExceeded();
        }
        if (commitment[account] > PRESALE_ACCOUNT_LIMIT) {
            revert MaxAccountLimitExceeded();
        }

        emit CommitedToPresale(account, msg.value);
    }

    /**
     * @notice Claim callers presale tokens.
     * @dev Callable once presaleCompleted.
     */
    function claimPresale() external {
        address account = msg.sender;

        if (_isContract(account)) {
            revert NoContract();
        }
        if (presaleState != PresaleState.COMPLETED) {
            revert PresaleNotCompleted();
        }
        if (commitment[account] == 0) {
            revert NothingCommitted();
        }
        if (claimedTokens[account] != 0) {
            revert AlreadyClaimed();
        }

        uint256 amountTokens = (_SUPPLY_PRESALE * commitment[account]) /
            totalCommitments;
        claimedTokens[account] = amountTokens;
        totalClaimed += amountTokens;

        _transferFromContractBalance(account, amountTokens);

        emit PresaleClaimed(account, amountTokens);
    }

    /** @notice Returns amount of tokens to be claimed by presale participants. */
    function unclaimedSupply() external view returns (uint256) {
        return _SUPPLY_PRESALE - totalClaimed;
    }

    // *** Owner Interface ***

    /**
     * @notice Whitelist wallet addresses for ealry presale access.
     * @param accounts accounts to whitelist
     */
    function whitelistForPresale(
        address[] calldata accounts
    ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; ++i) {
            presaleWhitelist[accounts[i]] = true;
        }
    }

    /**
     * @notice Open presale for all users.
     */
    function openPresale() external onlyOwner {
        if (presaleState != PresaleState.NONE) {
            revert InvalidState();
        }
        presaleState = PresaleState.OPEN_FOR_WHITELIST;
        emit PresaleOpened();
    }

    /**
     * @notice Open presale for all users.
     * Called after #openPresale.
     */
    function openPublicPresale() external onlyOwner {
        if (presaleState != PresaleState.OPEN_FOR_WHITELIST) {
            revert InvalidState();
        }
        presaleState = PresaleState.OPEN_FOR_PUBLIC;
        emit PublicPresaleOpened();
    }

    /**
     * @notice Close the presale.
     * Called after #openPublicPresale.
     */
    function closePresale() external onlyOwner {
        if (presaleState != PresaleState.OPEN_FOR_PUBLIC) {
            revert InvalidState();
        }
        if (totalCommitments == 0) {
            revert NoCommittments();
        }

        presaleState = PresaleState.CLOSED;

        emit PresaleClosed(totalCommitments);
    }

    /**
     * @notice Complete the presale.
     * @dev Adds 47.5% of collected ETH with 28.5% of totalSupply to Liquidity.
     * Sends the remaining 52.5% of collected ETH to current owner.
     * Renounces ownership.
     * Called after #closePresale.
     */
    function completePresale() external onlyOwner {
        if (presaleState != PresaleState.CLOSED) {
            revert InvalidState();
        }

        uint256 amountEthForLiquidity = (totalCommitments * _SUPPLY_LIQUIDITY) /
            _SUPPLY_PRESALE;
        _addInitialLiquidityEth(
            _SUPPLY_LIQUIDITY,
            amountEthForLiquidity,
            taxRecipient
        );

        _sweepEth(taxRecipient);

        renounceOwnership();

        presaleState = PresaleState.COMPLETED;

        emit PresaleCompleted(totalCommitments);
    }

    // *** Tax Manager Interface ***

    /**
     * @notice Set `taxFree` state of `account`.
     * @param account account
     * @param taxFree true if `account` should be extempt from transfer taxes.
     * @dev Only callable by taxManager.
     */
    function setTaxFreeAccount(
        address account,
        bool taxFree
    ) external onlyTaxManager {
        if (taxFreeAccount[account] == taxFree) {
            revert InvalidParameters();
        }
        taxFreeAccount[account] = taxFree;
        emit TaxFreeStateChanged(account, taxFree);
    }

    /**
     * @notice Set `exchangePool` state of `account`
     * @param account account
     * @param exchangePool whether `account` is an exchangePool
     * @dev ExchangePool state is used to decide if transfer is a swap
     * and should trigger #_swapTokens.
     */
    function setExchangePool(
        address account,
        bool exchangePool
    ) external onlyTaxManager {
        if (isExchangePool[account] == exchangePool) {
            revert InvalidParameters();
        }
        isExchangePool[account] = exchangePool;
        emit ExchangePoolStateChanged(account, exchangePool);
    }

    /**
     * @notice Transfer taxManager role to `newTaxManager`.
     * @param newTaxManager new taxManager
     * @dev Only callable by taxManager.
     */
    function transferTaxManager(address newTaxManager) external onlyTaxManager {
        if (newTaxManager == taxManager) {
            revert InvalidParameters();
        }
        taxManager = newTaxManager;
        emit TaxManagerChanged(newTaxManager);
    }

    /**
     * @notice Set taxRecipient address to `newTaxRecipient`.
     * @param newTaxRecipient new taxRecipient
     * @dev Only callable by taxManager.
     */
    function setTaxRecipient(address newTaxRecipient) external onlyTaxManager {
        if (newTaxRecipient == taxRecipient) {
            revert InvalidParameters();
        }
        taxRecipient = newTaxRecipient;
        emit TaxRecipientChanged(newTaxRecipient);
    }

    /**
     * @notice Withdraw tax collected (which would usually be automatically swapped to weth) to taxRecipient
     * @dev Only callable by taxManager.
     */
    function withdrawTaxes() external onlyTaxManager {
        uint256 balance = balanceOf(address(this));
        if (balance > 0) {
            super._transfer(address(this), taxRecipient, balance);
            emit TaxesWithdrawn(balance);
        }
    }

    /**
     * @notice Change the amount of tokens collected via tax before a swap is triggered.
     * @param newSwapThresholdEth new threshold received in ETH
     * @dev Only callable by taxManager
     */
    function setSwapThresholdEth(
        uint256 newSwapThresholdEth
    ) external onlyTaxManager {
        if (
            newSwapThresholdEth < SWAP_THRESHOLD_ETH_MIN ||
            newSwapThresholdEth > SWAP_THRESHOLD_ETH_MAX ||
            newSwapThresholdEth == swapThresholdEth
        ) {
            revert InvalidSwapThreshold();
        }
        swapThresholdEth = newSwapThresholdEth;
        emit SwapThresholdChanged(newSwapThresholdEth);
    }

    /**
     * @notice Threshold of how many tokens to collect from tax before calling #swapTokens.
     * @dev Depends on swapThresholdEth which can be configured by taxManager.
     * Restricted to 5% of liquidity.
     */
    function swapThresholdToken() public view returns (uint256) {
        (uint reserveToken, uint reserveWeth) = _getReserve();
        uint256 maxSwapEth = (reserveWeth * 5) / 100;
        return
            _getAmountToken(
                swapThresholdEth > maxSwapEth ? maxSwapEth : swapThresholdEth,
                reserveToken,
                reserveWeth
            );
    }

    // *** Internal Interface ***

    /** @notice IERC20#_transfer */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (
            !taxFreeAccount[from] &&
            !taxFreeAccount[to] &&
            !taxFreeAccount[msg.sender]
        ) {
            uint256 fee = (amount * TAX_BPS) / 100_00;
            super._transfer(from, address(this), fee);
            unchecked {
                amount -= fee;
            }

            if (isExchangePool[to]) /* selling */ {
                _swapTokens(swapThresholdToken());
            }
        }
        super._transfer(from, to, amount);
    }

    /** @dev Transfer `amount` tokens from contract balance to `to`. */
    function _transferFromContractBalance(
        address to,
        uint256 amount
    ) internal override {
        super._transfer(address(this), to, amount);
    }

    /**
     * @notice Swap `amountToken` collected from tax to WETH to add to send to taxRecipient.
     */
    function _swapTokens(uint256 amountToken) internal {
        if (
            balanceOf(address(this)) + totalClaimed <
            amountToken + _SUPPLY_PRESALE
        ) {
            return;
        }

        _swapForWETH(amountToken, taxRecipient);
    }

    function decimals() public view virtual override returns (uint8) {
        return _DECIMALS;
    }
}
