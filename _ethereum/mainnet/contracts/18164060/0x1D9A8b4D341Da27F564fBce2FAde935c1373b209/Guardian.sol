// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC20Metadata.sol";
import "./ERC1155.sol";
import "./ERC1155PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./EnumerableSet.sol";
import "./Strings.sol";

import "./IRewardRecipient.sol";
import "./IUniswapV2Router02.sol";
import "./IERC20MintableBurnable.sol";

error INVALID_ADDRESS();
error INVALID_AMOUNT();
error INVALID_PARAM();
error INVALID_FEE_TOKEN();

contract Guardian is
    ERC1155PausableUpgradeable,
    OwnableUpgradeable,
    IRewardRecipient
{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Strings for uint256;

    /* ======== STORAGE ======== */
    struct RewardRate {
        uint256 rewardPerSec;
        uint256 numberOfGuardians;
    }

    struct RewardInfo {
        uint256 debt;
        uint256 pending;
    }

    /// @dev BASE URI
    string private constant BASE_URI = 'https://metadata.shezmu.io/guardian/';

    /// @notice name
    string public constant name = 'Shezmu Guardian';

    /// @notice percent multiplier (100%)
    uint256 public constant PRECISION = 10000;

    /// @notice SHEZMU
    IERC20MintableBurnable public constant SHEZMU =
        IERC20MintableBurnable(0x5fE72ed557d8a02FFf49B3B826792c765d5cE162);

    /// @notice Fee Token (USDC)
    IERC20 public constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    /// @notice Uniswap Router
    IUniswapV2Router02 public constant ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    /// @notice price per guardian
    uint256 public pricePerGuardian;

    /// @notice treasury wallet
    address public treasury;

    /// @notice txn fee (price)
    uint256 public txnFee;

    /// @notice claim fee (percentage)
    uint256 public claimFee;

    /// @notice mint limit in one txn
    uint256 public mintLimit;

    /// @notice mapping account => total balance
    mapping(address => uint256) public totalBalanceOf;

    /// @notice total supply
    uint256 public totalSupply;

    /// @notice reward rate
    RewardRate public rewardRate;

    /// @dev feeToken tokens (stable coin for txn fee payment)
    EnumerableSet.AddressSet private feeTokens;

    /// @dev TYPE
    uint8 private constant TYPE = 6;

    /// @dev SIZE for each TYPE
    uint8[6] private SIZES;

    /// @dev reward accTokenPerShare
    uint256 private accTokenPerShare;

    /// @dev reward lastUpdate
    uint256 private lastUpdate;

    /// @dev mapping account => reward info
    mapping(address => RewardInfo) private rewardInfoOf;

    /// @dev USDC dividendsPerShare
    uint256 private dividendsPerShare;

    /// @dev mapping account => dividends info
    mapping(address => RewardInfo) private dividendsInfoOf;

    /// @dev dividends multiplier
    uint256 private constant MULTIPLIER = 1e18;

    /* ======== EVENTS ======== */

    event MintLimit(uint256 limit);
    event Treasury(address treasury);
    event TxnFee(uint256 fee);
    event ClaimFee(uint256 fee);
    event AddFeeTokens(address[] tokens);
    event RemoveFeeTokens(address[] tokens);
    event Mint(address indexed from, address indexed to, uint256 amount);
    event Compound(address indexed from, address indexed to, uint256 amount);
    event Split(address indexed from, address indexed to, uint256 amount);
    event Claim(address indexed from, uint256 reward, uint256 dividends);

    /* ======== INITIALIZATION ======== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address treasury_) external initializer {
        if (treasury_ == address(0)) revert INVALID_ADDRESS();
        treasury = treasury_;

        // 1 Guardian: Craftsman
        // 5 Guardian: Scribe
        // 10 Guardian: High Priest
        // 25 Guardian: Nobles
        // 50 Guardians: Viziers
        // 100 Guardian: Pharaoh
        SIZES = [1, 5, 10, 25, 50, 100];

        // 12 Shezmu per Guardian
        pricePerGuardian = 12 ether;

        // txn fee $15
        txnFee = 15 ether;
        feeTokens.add(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USDC
        feeTokens.add(0xdAC17F958D2ee523a2206206994597C13D831ec7); // USDT
        feeTokens.add(0x6B175474E89094C44Da98b954EedeAC495271d0F); // DAI

        // claim fee 20%
        claimFee = 2000;

        // option how many can mint in one txn
        mintLimit = 100;

        // 0.1 Shezmu per day for first 250,000 guardians
        rewardRate.rewardPerSec = uint256(0.1 ether) / uint256(1 days);
        rewardRate.numberOfGuardians = 250000;

        // init
        __ERC1155Pausable_init();
        __ERC1155_init(BASE_URI);
        __Ownable_init();
    }

    function migrate(
        Guardian oldGuardian,
        address[] calldata accounts
    ) external onlyOwner {
        uint256 length = accounts.length;

        for (uint256 i = 0; i < length; i++) {
            address account = accounts[i];

            // claimable
            (uint256 reward, uint256 dividends) = oldGuardian.pendingReward(
                account
            );
            rewardInfoOf[account].pending = reward;
            dividendsInfoOf[account].pending = dividends;

            // mint
            for (uint256 j = 0; j < TYPE; j++) {
                uint256 amount = oldGuardian.balanceOf(account, j);

                if (amount > 0) {
                    super._mint(account, j, amount, '');
                }
            }

            totalBalanceOf[account] = oldGuardian.totalBalanceOf(account);
        }

        totalSupply = oldGuardian.totalSupply();
        lastUpdate = block.timestamp;
    }

    /* ======== MODIFIERS ======== */

    modifier update() {
        if (totalSupply > 0) {
            accTokenPerShare +=
                rewardRate.rewardPerSec *
                (block.timestamp - lastUpdate);
        }
        lastUpdate = block.timestamp;

        _;
    }

    /* ======== POLICY FUNCTIONS ======== */

    function setMintLimit(uint256 limit) external onlyOwner {
        if (limit == 0) revert INVALID_AMOUNT();

        mintLimit = limit;

        emit MintLimit(limit);
    }

    function setTreasury(address treasury_) external onlyOwner {
        if (treasury_ == address(0)) revert INVALID_ADDRESS();

        treasury = treasury_;

        emit Treasury(treasury_);
    }

    function setTxnFee(uint256 fee) external onlyOwner {
        if (fee == 0) revert INVALID_AMOUNT();

        txnFee = fee;

        emit TxnFee(fee);
    }

    function setClaimFee(uint256 fee) external onlyOwner {
        if (fee >= PRECISION / 2) revert INVALID_AMOUNT();

        claimFee = fee;

        emit ClaimFee(fee);
    }

    function addFeeTokens(address[] calldata tokens) external onlyOwner {
        uint256 length = tokens.length;

        for (uint256 i = 0; i < length; ) {
            feeTokens.add(tokens[i]);
            unchecked {
                ++i;
            }
        }

        emit AddFeeTokens(tokens);
    }

    function removeFeeTokens(address[] calldata tokens) external onlyOwner {
        uint256 length = tokens.length;

        for (uint256 i = 0; i < length; ) {
            feeTokens.remove(tokens[i]);
            unchecked {
                ++i;
            }
        }

        emit RemoveFeeTokens(tokens);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function recoverERC20(IERC20 token) external onlyOwner {
        token.safeTransfer(_msgSender(), token.balanceOf(address(this)));
    }

    function airdrop(
        address[] calldata tos,
        uint256[] calldata amounts
    ) external onlyOwner update {
        uint256 length = tos.length;
        if (length != amounts.length) revert INVALID_PARAM();

        for (uint256 i = 0; i < length; ) {
            _simpleMint(tos[i], amounts[i]);

            unchecked {
                ++i;
            }
        }
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _sync(address account) internal {
        uint256 totalBalance = totalBalanceOf[account];

        unchecked {
            for (uint256 i = 0; i < TYPE; i++) {
                uint256 index = TYPE - i - 1;
                uint256 newBalance = totalBalance / SIZES[index];
                uint256 oldBalance = balanceOf(account, index);

                if (newBalance > oldBalance) {
                    super._mint(account, index, newBalance - oldBalance, '');
                } else if (newBalance < oldBalance) {
                    super._burn(account, index, oldBalance - newBalance);
                }

                totalBalance = totalBalance % SIZES[index];
            }
        }
    }

    function _updateReward(
        address account
    )
        internal
        returns (
            RewardInfo storage rewardInfo,
            RewardInfo storage dividendsInfo
        )
    {
        uint256 totalBalance = totalBalanceOf[account];

        // Shezmu
        rewardInfo = rewardInfoOf[account];
        uint256 reward = accTokenPerShare * totalBalance - rewardInfo.debt;
        uint256 fee = (reward * claimFee) / PRECISION;
        rewardInfo.pending += reward - fee;
        if (fee > 0) {
            SHEZMU.mint(treasury, fee);
        }

        // USDC
        dividendsInfo = dividendsInfoOf[account];
        dividendsInfo.pending +=
            (dividendsPerShare * totalBalance) /
            MULTIPLIER -
            dividendsInfo.debt;
    }

    function _mint(address to, address feeToken, uint256 amount) internal {
        if (to == address(0)) revert INVALID_ADDRESS();
        if (amount == 0 || amount > mintLimit) revert INVALID_AMOUNT();
        if (!feeTokens.contains(feeToken)) revert INVALID_FEE_TOKEN();

        // pay txn fee
        RewardInfo storage dividendsInfo = dividendsInfoOf[to];
        uint256 usdcFee = (txnFee *
            10 ** IERC20Metadata(address(USDC)).decimals()) / MULTIPLIER;

        if (dividendsInfo.pending >= usdcFee) {
            dividendsInfo.pending -= usdcFee;
            USDC.safeTransfer(treasury, usdcFee);
        } else {
            IERC20(feeToken).safeTransferFrom(
                _msgSender(),
                treasury,
                (txnFee * 10 ** IERC20Metadata(feeToken).decimals()) /
                    MULTIPLIER
            );
        }

        _simpleMint(to, amount);
    }

    function _simpleMint(address to, uint256 amount) internal {
        // update reward
        (
            RewardInfo storage rewardInfo,
            RewardInfo storage dividendsInfo
        ) = _updateReward(to);

        // mint Guardian
        unchecked {
            totalBalanceOf[to] += amount;
            totalSupply += amount;
        }

        // update reward rate if exceeds the Guardians number
        if (totalSupply > rewardRate.numberOfGuardians) {
            rewardRate.rewardPerSec /= 2;
            rewardRate.numberOfGuardians *= 2;
        }

        // update reward debt
        rewardInfo.debt = accTokenPerShare * totalBalanceOf[to];
        dividendsInfo.debt =
            (dividendsPerShare * totalBalanceOf[to]) /
            MULTIPLIER;

        // sync Guardians
        _sync(to);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override update {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0) || to == address(0)) {
            return;
        }

        // update reward
        (
            RewardInfo storage fromRewardInfo,
            RewardInfo storage fromDividendsInfo
        ) = _updateReward(from);
        (
            RewardInfo storage toRewardInfo,
            RewardInfo storage toDividendsInfo
        ) = _updateReward(to);

        // calculate number of Guardians
        uint256 amount;
        unchecked {
            for (uint256 i = 0; i < ids.length; ++i) {
                amount += SIZES[ids[i]] * amounts[i];
            }
        }

        // update total balance
        unchecked {
            totalBalanceOf[from] -= amount;
            totalBalanceOf[to] += amount;
        }

        // update reward debt
        fromRewardInfo.debt = accTokenPerShare * totalBalanceOf[from];
        fromDividendsInfo.debt =
            (dividendsPerShare * totalBalanceOf[from]) /
            MULTIPLIER;
        toRewardInfo.debt = accTokenPerShare * totalBalanceOf[to];
        toDividendsInfo.debt =
            (dividendsPerShare * totalBalanceOf[to]) /
            MULTIPLIER;
    }

    /* ======== PUBLIC FUNCTIONS ======== */

    function mint(
        address to,
        address feeToken,
        uint256 amount
    ) external update {
        address account = _msgSender();

        // burn Shezmu
        SHEZMU.burnFrom(account, amount * pricePerGuardian);

        // update reward
        (
            RewardInfo storage rewardInfo,
            RewardInfo storage dividendsInfo
        ) = _updateReward(account);
        rewardInfo.debt = accTokenPerShare * totalBalanceOf[account];
        dividendsInfo.debt =
            (dividendsPerShare * totalBalanceOf[account]) /
            MULTIPLIER;

        // mint Guardian
        _mint(to, feeToken, amount);

        emit Mint(account, to, amount);
    }

    function compound(
        address to,
        address feeToken,
        uint256 amount
    ) external update {
        address account = _msgSender();

        // update reward
        (
            RewardInfo storage rewardInfo,
            RewardInfo storage dividendsInfo
        ) = _updateReward(account);
        rewardInfo.debt = accTokenPerShare * totalBalanceOf[account];
        dividendsInfo.debt =
            (dividendsPerShare * totalBalanceOf[account]) /
            MULTIPLIER;

        // burn Shezmu out of rewards
        if (amount > 0) {
            if (rewardInfo.pending < amount * pricePerGuardian)
                revert INVALID_AMOUNT();
            unchecked {
                rewardInfo.pending -= amount * pricePerGuardian;
            }
        } else {
            amount = rewardInfo.pending / pricePerGuardian;
            rewardInfo.pending %= pricePerGuardian;
        }

        // mint Guardian
        _mint(to, feeToken, amount);

        emit Compound(account, to, amount);
    }

    function split(address to, uint256 amount) external update {
        if (to == address(0)) revert INVALID_ADDRESS();
        address from = _msgSender();
        if (totalBalanceOf[from] < amount) revert INVALID_AMOUNT();

        // from
        {
            // update reward
            (
                RewardInfo storage rewardInfo,
                RewardInfo storage dividendsInfo
            ) = _updateReward(from);

            unchecked {
                totalBalanceOf[from] -= amount;
            }

            // update reward debt
            rewardInfo.debt = accTokenPerShare * totalBalanceOf[from];
            dividendsInfo.debt =
                (dividendsPerShare * totalBalanceOf[from]) /
                MULTIPLIER;

            // sync Guardians
            _sync(from);
        }

        // to
        {
            // update reward
            (
                RewardInfo storage rewardInfo,
                RewardInfo storage dividendsInfo
            ) = _updateReward(to);

            unchecked {
                totalBalanceOf[to] += amount;
            }

            // update reward debt
            rewardInfo.debt = accTokenPerShare * totalBalanceOf[to];
            dividendsInfo.debt =
                (dividendsPerShare * totalBalanceOf[to]) /
                MULTIPLIER;

            // sync Guardians
            _sync(to);
        }

        emit Split(from, to, amount);
    }

    function claim() external update {
        address account = _msgSender();
        uint256 totalBalance = totalBalanceOf[account];

        if (totalBalance == 0) return;

        // update reward
        (
            RewardInfo storage rewardInfo,
            RewardInfo storage dividendsInfo
        ) = _updateReward(account);

        rewardInfo.debt = accTokenPerShare * totalBalance;
        dividendsInfo.debt = (dividendsPerShare * totalBalance) / MULTIPLIER;

        // transfer pending (Shezmu)
        uint256 reward = rewardInfo.pending;
        if (reward > 0) {
            rewardInfo.pending = 0;
            SHEZMU.mint(account, reward);
        }

        // transfer pending (USDC)
        uint256 dividends = _min(
            dividendsInfo.pending,
            USDC.balanceOf(address(this))
        );
        if (dividends > 0) {
            unchecked {
                dividendsInfo.pending -= dividends;
            }
            USDC.safeTransfer(account, dividends);
        }

        emit Claim(account, reward, dividends);
    }

    function receiveReward() external payable override {
        if (msg.value == 0) return;

        address[] memory path = new address[](2);
        path[0] = ROUTER.WETH();
        path[1] = address(USDC);

        uint256 balanceBefore = USDC.balanceOf(address(this));
        ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(0, path, address(this), block.timestamp);

        uint256 rewardAmount = USDC.balanceOf(address(this)) - balanceBefore;

        if (totalSupply > 0 && rewardAmount > 0) {
            dividendsPerShare += (rewardAmount * MULTIPLIER) / totalSupply;
        }
    }

    /* ======== VIEW FUNCTIONS ======== */

    function uri(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return
            tokenId < TYPE
                ? string(
                    abi.encodePacked(BASE_URI, tokenId.toString(), '.json')
                )
                : super.uri(tokenId);
    }

    function allFeeTokens() external view returns (address[] memory) {
        return feeTokens.values();
    }

    function pendingReward(
        address account
    ) external view returns (uint256 reward, uint256 dividends) {
        uint256 totalBalance = totalBalanceOf[account];

        if (totalBalance > 0) {
            // Shezmu reward
            RewardInfo memory rewardInfo = rewardInfoOf[account];
            uint256 newAccTokenPerShare = accTokenPerShare +
                rewardRate.rewardPerSec *
                (block.timestamp - lastUpdate);
            uint256 newReward = newAccTokenPerShare *
                totalBalance -
                rewardInfoOf[account].debt;
            reward =
                rewardInfo.pending +
                newReward -
                (newReward * claimFee) /
                PRECISION;

            // USDC reward
            RewardInfo memory dividendsInfo = dividendsInfoOf[account];
            dividends =
                dividendsInfo.pending +
                (dividendsPerShare * totalBalance) /
                MULTIPLIER -
                dividendsInfo.debt;
        }
    }

    uint256[49] private __gap;
}
