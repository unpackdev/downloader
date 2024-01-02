// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./ERC20PresetMinterPauserUpgradeable.sol";
import "./EnumerableSet.sol";

import "./IAddressProvider.sol";
import "./IPriceOracleAggregator.sol";
import "./IERC20MintableBurnable.sol";

contract OptionShezmu is ERC20PresetMinterPauserUpgradeable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev name
    string private constant NAME = 'Option Shezmu';

    /// @dev symbol
    string private constant SYMBOL = 'oSHEZMU';

    /// @notice percent multiplier (100%)
    uint256 public constant MULTIPLIER = 10000;

    /// @notice shezmu decimals
    uint256 public constant UNIT = 1e18;

    /// @notice dead address
    address public constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    /// @notice address provider
    IAddressProvider public addressProvider;

    /// @notice discount percent
    uint256 public discount;

    /// @dev tokens used to create bond
    EnumerableSet.AddressSet private principals;

    /* ======== EVENTS ======== */

    event Exercise(
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        address principal,
        uint256 paymentAmount
    );

    /* ======== ERRORS ======== */

    error INVALID_ADDRESS();
    error INVALID_PRINCIPAL();
    error PAST_DEADLINE();
    error SLIPPAGE_TOO_HIGH();

    /* ======== INITIALIZATION ======== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _addressProvider) external initializer {
        if (_addressProvider == address(0)) revert INVALID_ADDRESS();

        // address provider
        addressProvider = IAddressProvider(_addressProvider);

        // discount 10%
        discount = 1000;

        // init
        __ERC20PresetMinterPauser_init(NAME, SYMBOL);
    }

    /* ======== MODIFIER ======== */

    modifier onlyOwner() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    modifier onlyPrincipal(address _principal) {
        if (!principals.contains(_principal)) revert INVALID_PRINCIPAL();
        _;
    }

    /* ======== POLICY FUNCTIONS ======== */

    /**
     * @notice add principals
     * @param _principals address[]
     */
    function addPrincipals(address[] calldata _principals) external onlyOwner {
        uint256 length = _principals.length;

        for (uint256 i = 0; i < length; i++) {
            address principal = _principals[i];
            if (principal == address(0)) revert INVALID_PRINCIPAL();

            principals.add(principal);
        }
    }

    /**
     * @notice remove principals
     * @param _principals address[]
     */
    function removePrincipals(
        address[] calldata _principals
    ) external onlyOwner {
        uint256 length = _principals.length;

        for (uint256 i = 0; i < length; i++) {
            address principal = _principals[i];
            if (principal == address(0)) revert INVALID_PRINCIPAL();

            principals.remove(principal);
        }
    }

    /**
     * @notice set address provider
     * @param _addressProvider address
     */
    function setAddressProvider(address _addressProvider) external onlyOwner {
        if (_addressProvider == address(0)) revert INVALID_ADDRESS();
        addressProvider = IAddressProvider(_addressProvider);
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice show all tokens used to create bond
     *  @return principals_ address[]
     *  @return prices_ uint256[]
     */
    function allPrincipals()
        external
        view
        returns (address[] memory principals_, uint256[] memory prices_)
    {
        principals_ = principals.values();

        uint256 length = principals.length();
        prices_ = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            prices_[i] = _viewPriceInUSD(principals.at(i));
        }
    }

    function getShezmuAmount(
        address _principal,
        uint256 _paymentAmount
    ) external view onlyPrincipal(_principal) returns (uint256 amount) {
        address shezmu = addressProvider.getShezmu();

        amount =
            (_viewPriceInUSD(_principal) * _paymentAmount * UNIT) /
            (((_viewPriceInUSD(shezmu) * (MULTIPLIER - discount)) /
                MULTIPLIER) * 10 ** IERC20Metadata(_principal).decimals());
    }

    function getPrincipalAmount(
        address _principal,
        uint256 _amount
    ) public view onlyPrincipal(_principal) returns (uint256 paymentAmount) {
        address shezmu = addressProvider.getShezmu();

        paymentAmount =
            (((_amount * _viewPriceInUSD(shezmu) * (MULTIPLIER - discount)) /
                MULTIPLIER) * 10 ** IERC20Metadata(_principal).decimals()) /
            (_viewPriceInUSD(_principal) * UNIT);
    }

    /* ======== USER FUNCTIONS ======== */

    /// @notice Exercises options tokens to purchase the underlying tokens.
    /// @dev The options tokens are not burnt but sent to address(0) to avoid messing up the
    /// inflation schedule.
    /// The oracle may revert if it cannot give a secure result.
    /// @param _principal principal address
    /// @param _amount The amount of options tokens to exercise
    /// @param _maxPaymentAmount The maximum acceptable amount to pay. Used for slippage protection.
    /// @param _recipient The recipient of the purchased underlying tokens
    /// @return paymentAmount The amount paid to the treasury to purchase the underlying tokens
    function exercise(
        address _principal,
        uint256 _amount,
        uint256 _maxPaymentAmount,
        address _recipient
    )
        external
        virtual
        onlyPrincipal(_principal)
        returns (uint256 paymentAmount)
    {
        return _exercise(_principal, _amount, _maxPaymentAmount, _recipient);
    }

    /// @notice Exercises options tokens to purchase the underlying tokens.
    /// @dev The options tokens are not burnt but sent to address(0) to avoid messing up the
    /// inflation schedule.
    /// The oracle may revert if it cannot give a secure result.
    /// @param _principal principal address
    /// @param _amount The amount of options tokens to exercise
    /// @param _maxPaymentAmount The maximum acceptable amount to pay. Used for slippage protection.
    /// @param _recipient The recipient of the purchased underlying tokens
    /// @param _deadline The Unix timestamp (in seconds) after which the call will revert
    /// @return paymentAmount The amount paid to the treasury to purchase the underlying tokens
    function exercise(
        address _principal,
        uint256 _amount,
        uint256 _maxPaymentAmount,
        address _recipient,
        uint256 _deadline
    )
        external
        virtual
        onlyPrincipal(_principal)
        returns (uint256 paymentAmount)
    {
        if (block.timestamp > _deadline) revert PAST_DEADLINE();

        return _exercise(_principal, _amount, _maxPaymentAmount, _recipient);
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _viewPriceInUSD(address _token) internal view returns (uint256) {
        return
            IPriceOracleAggregator(addressProvider.getPriceOracleAggregator())
                .viewPriceInUSD(_token);
    }

    function _exercise(
        address _principal,
        uint256 _amount,
        uint256 _maxPaymentAmount,
        address _recipient
    ) internal virtual returns (uint256 paymentAmount) {
        // skip if amount is zero
        if (_amount == 0) return 0;

        // transfer options tokens from msg.sender to DEAD_ADDRESS
        // we transfer instead of burn because TokenAdmin cares about totalSupply
        // which we don't want to change in order to follow the emission schedule
        transfer(DEAD_ADDRESS, _amount);

        // transfer principal token from msg.sender to the treasury
        paymentAmount = getPrincipalAmount(_principal, _amount);
        if (paymentAmount > _maxPaymentAmount) revert SLIPPAGE_TOO_HIGH();
        IERC20(_principal).safeTransferFrom(
            msg.sender,
            addressProvider.getTreasury(),
            paymentAmount
        );

        // mint underlying tokens to recipient
        IERC20MintableBurnable(addressProvider.getShezmu()).mint(
            _recipient,
            _amount
        );

        emit Exercise(
            msg.sender,
            _recipient,
            _amount,
            _principal,
            paymentAmount
        );
    }
}
