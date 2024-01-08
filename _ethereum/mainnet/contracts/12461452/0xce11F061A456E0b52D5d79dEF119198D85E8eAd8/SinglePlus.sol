// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./MathUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./ISinglePlus.sol";
import "./Plus.sol";

/**
 * @title Single plus token.
 *
 * A single plus token wraps an LP token, typically not value-pegged, into a value peg token.
 *
 * Note: LP token vs underlying token
 * - LP token is the token wrapped by single plus. It's typically not value peg, and it applies to
 *   single plus only;
 * - Underlying token is the peg token. It applies to both single plus and composite plus.
 * E.g. For renCrv+, the LP token is renCrv and underlying token is BTC.
 */
contract SinglePlus is ISinglePlus, Plus, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    event Minted(address indexed user, uint256 amount, uint256 mintShare, uint256 mintAmount);
    event Redeemed(address indexed user, uint256 amount, uint256 redeemShare, uint256 redeemAmount, uint256 fee);

    event Harvested(address indexed token, uint256 amount, uint256 feeAmount);
    event PerformanceFeeUpdated(uint256 oldPerformanceFee, uint256 newPerformanceFee);
    
    // LP token of the single plus toke. Typically a yield token and not value peg.
    address public override token;
    // Whether minting is paused for the single plus token.
    bool public mintPaused;
    uint256 public performanceFee;
    uint256 public constant PERCENT_MAX = 10000;    // 0.01%

    /**
     * @dev Initializes the single plus contract.
     * @param _token LP token of the single plus.
     * @param _nameOverride If empty, the single plus name will be `token_name Plus`
     * @param _symbolOverride If empty. the single plus name will be `token_symbol+`
     */
    function initialize(address _token, string memory _nameOverride, string memory _symbolOverride) public initializer {
        token = _token;

        string memory _name = _nameOverride;
        string memory _symbol = _symbolOverride;
        if (bytes(_name).length == 0) {
            _name = string(abi.encodePacked(ERC20Upgradeable(_token).name(), " Plus"));
        }
        if (bytes(_symbol).length == 0) {
            _symbol = string(abi.encodePacked(ERC20Upgradeable(_token).symbol(), "+"));
        }
        __PlusToken__init(_name, _symbol);
        __ReentrancyGuard_init();
    }

    /**
     * @dev Returns the amount of single plus tokens minted with the LP token provided.
     * @dev _amounts Amount of LP token used to mint the single plus token.
     */
    function getMintAmount(uint256 _amount) external view override returns(uint256) {
        // Conversion rate is the amount of single plus token per LP token, in WAD.
        return _amount.mul(_conversionRate()).div(WAD);
    }

    /**
     * @dev Mints the single plus token with the LP token.
     * @dev _amount Amount of the LP token used to mint single plus token.
     */
    function mint(uint256 _amount) external override nonReentrant {
        require(_amount > 0, "zero amount");
        require(!mintPaused, "mint paused");

        // Rebase first to make index up-to-date
        rebase();

        // Transfers the LP token in.
        IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), _amount);
        // Conversion rate is the amount of single plus token per LP token, in WAD.
        uint256 _newAmount = _amount.mul(_conversionRate()).div(WAD);
        // Index is in WAD
        uint256 _share = _amount.mul(_conversionRate()).div(index);

        uint256 _oldShare = userShare[msg.sender];
        uint256 _newShare = _oldShare.add(_share);
        uint256 _totalShares = totalShares.add(_share);
        totalShares = _totalShares;
        userShare[msg.sender] = _newShare;

        emit UserShareUpdated(msg.sender, _oldShare, _newShare, _totalShares);
        emit Minted(msg.sender, _amount, _share, _newAmount);

        emit Transfer(address(0x0), msg.sender, _newAmount);
    }

    /**
     * @dev Returns the amount of tokens received in redeeming the single plus token.
     * @param _amount Amounf of single plus to redeem.
     * @return Amount of LP token received as well as fee collected.
     */
    function getRedeemAmount(uint256 _amount) external view override returns (uint256, uint256) {
        // LP amount = Redeem amount * (1 - redeem fee) * liquidity ratio
        // Redeem fee is in 0.01%
        uint256 _fee = _amount.mul(redeemFee).div(MAX_PERCENT);
        // Both liquidity ratio and conversion rate is in WAD, so it cancels out
        uint256 _lpAmount = _amount.sub(_fee).mul(liquidityRatio()).div(_conversionRate());

        // Note: Fee is in plus token(18 decimals) but the received amount is in LP token!
        return (_lpAmount, _fee);
    }

    /**
     * @dev Redeems the single plus token.
     * @param _amount Amount of single plus token to redeem. -1 means redeeming all shares.
     */
    function redeem(uint256 _amount) external override nonReentrant {
        require(_amount > 0, "zero amount");

        // Rebase first to make index up-to-date
        rebase();

        // Special handling of -1 is required here in order to fully redeem all shares, since interest
        // will be accrued between the redeem transaction is signed and mined.
        uint256 _share;
        if (_amount == uint256(int256(-1))) {
            _share = userShare[msg.sender];
            _amount = _share.mul(index).div(WAD);
        } else {
            _share  = _amount.mul(WAD).div(index);
        }

        // LP amount = Redeem amount * (1 - redeem fee) * liquidity ratio
        // Redeem fee is in 0.01%
        uint256 _fee = _amount.mul(redeemFee).div(MAX_PERCENT);
        // Both liquidity ratio and conversion rate is in WAD, so it cancels out
        uint256 _lpAmount = _amount.sub(_fee).mul(liquidityRatio()).div(_conversionRate());

        // Update the treasury balance
        if (_fee > 0) {
            uint256 _feeShare = _fee.mul(WAD).div(index);
            // Transfers fee shares to treasury
            userShare[treasury] = userShare[treasury].add(_feeShare);
            totalShares = totalShares.add(_feeShare);
        }

        // Updates the caller balance
        uint256 _oldShare = userShare[msg.sender];
        uint256 _newShare = _oldShare.sub(_share);
        totalShares = totalShares.sub(_share);
        userShare[msg.sender] = _newShare;

        // Transfer LP tokens to users
        _withdraw(msg.sender, _lpAmount);

        emit UserShareUpdated(msg.sender, _oldShare, _newShare, totalShares);
        emit Redeemed(msg.sender, _lpAmount, _share, _amount, _fee);

        // Caller transfers _fee to treasury
        emit Transfer(msg.sender, treasury, _fee);
        // Caller burns _amount - _fee
        emit Transfer(msg.sender, address(0x0), _amount.sub(_fee));
    }

    /**
     * @dev Updates the mint paused state of the LP token.
     * @param _paused Whether minting with that token is paused.
     */
    function setMintPaused(bool _paused) external onlyStrategist {
        require(mintPaused != _paused, "no change");

        mintPaused = _paused;
        emit MintPausedUpdated(token, _paused);
    }

    /**
     * @dev Updates the performance fee. Only governance can update the performance fee.
     */
    function setPerformanceFee(uint256 _performanceFee) public onlyGovernance {
        require(_performanceFee <= PERCENT_MAX, "overflow");
        uint256 oldPerformanceFee = performanceFee;
        performanceFee = _performanceFee;

        emit PerformanceFeeUpdated(oldPerformanceFee, _performanceFee);
    }

    /**
     * @dev Retrive the LP token from the investment.
     */
    function divest() public virtual override {}

    /**
     * @dev Returns the amount that can be invested now. The invested token
     * does not have to be the LP token.
     * investable > 0 means it's time to call invest.
     */
    function investable() public view virtual override returns (uint256) {
        return 0;
    }

    /**
     * @dev Invest the LP token for additional yield.
     */
    function invest() public virtual override {}

    /**
     * @dev Returns the amount of reward that could be harvested now.
     * harvestable > 0 means it's time to call harvest.
     */
    function harvestable() public view virtual override returns (uint256) {
        return 0;
    }

    /**
     * @dev Harvest additional yield from the investment.
     */
    function harvest() public virtual override {}

    /**
     * @dev Checks whether a token can be salvaged via salvageToken().
     * @param _token Token to check salvageability.
     */
    function _salvageable(address _token) internal view virtual override returns (bool) {
        // For single plus, the only token that cannot salvage is the LP token!
        return _token != token;
    }

    /**
     * @dev Returns the amount of single plus token is worth for one LP token, expressed in WAD.
     * The default implmentation assumes that the single plus and LP tokens are both peg.
     */
    function _conversionRate() internal view virtual returns (uint256) {
        // 36 since the decimals for plus token is always 18, and conversion rate is in WAD.
        return uint256(10) ** (36 - ERC20Upgradeable(token).decimals());
    }

    /**
     * @dev Returns the total value of the LP token in terms of the underlying tokens, scaled to 18 decimals
     * and expressed in WAD.
     */
    function _totalUnderlyingInWad() internal view virtual override returns (uint256) {
        uint256 _balance = IERC20Upgradeable(token).balanceOf(address(this));
        // Conversion rate is the amount of single plus token per LP token, in WAD.
        return _balance.mul(_conversionRate());
    }

    /**
     * @dev Withdraws LP tokens.
     * @param _receiver Address to receive the token withdraw.
     * @param _amount Amount of LP token withdraw.
     */
    function _withdraw(address _receiver, uint256  _amount) internal virtual {
        IERC20Upgradeable(token).safeTransfer(_receiver, _amount);
    }

    uint256[50] private __gap;
}