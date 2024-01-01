// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC20Upgradeable.sol";
import "./Initializable.sol";
import "./ERC4626Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./MathUpgradeable.sol";

import "./AuthorityAware.sol";
import "./LendingPool.sol";
import "./PoolFactory.sol";

contract TrancheVault is Initializable, ERC4626Upgradeable, PausableUpgradeable, AuthorityAware {
    using MathUpgradeable for uint256;

    /*////////////////////////////////////////////////
      State
    ////////////////////////////////////////////////*/

    mapping(address => mapping(address => uint256)) approvedRollovers;

    /* id */
    uint8 private s_id;
    event ChangeId(uint8 oldValue, uint8 newValue);

    function id() public view returns (uint8) {
        return s_id;
    }

    function _setId(uint8 newValue) internal {
        uint8 oldValue = s_id;
        s_id = newValue;
        emit ChangeId(oldValue, newValue);
    }

    /* poolAddress */
    address private s_poolAddress;
    event ChangePoolAddress(address oldValue, address newValue);

    function poolAddress() public view returns (address) {
        return s_poolAddress;
    }

    function _setPoolAddress(address newValue) internal {
        address oldValue = s_poolAddress;
        s_poolAddress = newValue;
        emit ChangePoolAddress(oldValue, newValue);
    }

    /* minFundingCapacity */
    uint256 private s_minFundingCapacity;
    event ChangeMinFundingCapacity(uint256 oldValue, uint256 newValue);

    function minFundingCapacity() public view returns (uint256) {
        return s_minFundingCapacity;
    }

    function _setMinFundingCapacity(uint256 newValue) internal {
        uint256 oldValue = s_minFundingCapacity;
        s_minFundingCapacity = newValue;
        emit ChangeMinFundingCapacity(oldValue, newValue);
    }

    /* maxFundingCapacity */
    uint256 private s_maxFundingCapacity;
    event ChangeMaxFundingCapacity(uint256 oldValue, uint256 newValue);

    function maxFundingCapacity() public view returns (uint256) {
        return s_maxFundingCapacity;
    }

    function _setMaxFundingCapacity(uint256 newValue) internal {
        uint256 oldValue = s_maxFundingCapacity;
        s_maxFundingCapacity = newValue;
        emit ChangeMaxFundingCapacity(oldValue, newValue);
    }

    /* withdrawEnabled */
    bool private s_withdrawEnabled;
    event ChangeWithdrawEnabled(address indexed actor, bool oldValue, bool newValue);

    function withdrawEnabled() public view returns (bool) {
        return s_withdrawEnabled;
    }

    function _setWithdrawEnabled(bool newValue) internal {
        bool oldValue = s_withdrawEnabled;
        s_withdrawEnabled = newValue;
        emit ChangeWithdrawEnabled(msg.sender, oldValue, newValue);
    }

    /* depositEnabled */
    bool private s_depositEnabled;
    event ChangeDepositEnabled(address indexed actor, bool oldValue, bool newValue);

    function depositEnabled() public view returns (bool) {
        return s_depositEnabled;
    }

    function _setDepositEnabled(bool newValue) internal {
        bool oldValue = s_depositEnabled;
        s_depositEnabled = newValue;
        emit ChangeDepositEnabled(msg.sender, oldValue, newValue);
    }

    /* transferEnabled */
    bool private s_transferEnabled;
    event ChangeTransferEnabled(address indexed actor, bool oldValue, bool newValue);

    function transferEnabled() public view returns (bool) {
        return s_transferEnabled;
    }

    function _setTransferEnabled(bool newValue) internal {
        bool oldValue = s_transferEnabled;
        s_transferEnabled = newValue;
        emit ChangeTransferEnabled(msg.sender, oldValue, newValue);
    }

    /* defaultRatio */
    uint private s_defaultRatioWad;
    event ChangeDefaultRatio(address indexed actor, uint oldValue, uint newValue);

    function defaultRatioWad() public view returns (uint) {
        return s_defaultRatioWad;
    }

    function isDefaulted() public view returns (bool) {
        return s_defaultRatioWad != 0;
    }

    function _setDefaultRatioWad(uint newValue) internal {
        uint oldValue = s_defaultRatioWad;
        s_defaultRatioWad = newValue;
        emit ChangeDefaultRatio(msg.sender, oldValue, newValue);
    }

    function setDefaultRatioWad(uint newValue) external onlyPool {
        _setDefaultRatioWad(newValue);
    }

    /*////////////////////////////////////////////////
      Modifiers
    ////////////////////////////////////////////////*/
    modifier onlyPool() {
        require(_msgSender() == poolAddress(), "Vault: onlyPool");
        _;
    }

    modifier onlyDeadTranche() {
        LendingPool pool = LendingPool(s_poolAddress);
        PoolFactory factory = PoolFactory(pool.poolFactoryAddress());
        require(factory.prevDeployedTranche(msg.sender), "Vault: onlyDeadTranche");
        _;
    }

    modifier onlyOwnerOrPool() {
        require(_msgSender() == poolAddress() || _msgSender() == owner(), "Vault: onlyOwnerOrPool");
        _;
    }

    modifier whenWithdrawEnabled() {
        require(withdrawEnabled(), "Vault: withdraw disabled");
        _;
    }

    modifier whenDepositEnabled() {
        require(depositEnabled(), "Vault: deposit disabled");
        _;
    }

    modifier whenTransferEnabled() {
        require(transferEnabled(), "Vault: transfer disabled");
        _;
    }

    function _isWhitelisted(address) internal virtual returns (bool) {
        return true;
    }

    /*////////////////////////////////////////////////
      CONSTRUCTOR
    ////////////////////////////////////////////////*/
    function initialize(
        address _poolAddress,
        uint8 _trancheId,
        uint _minCapacity,
        uint _maxCapacity,
        string memory _tokenName,
        string memory _symbol,
        address _underlying,
        address _authority
    ) external initializer {
        if (_minCapacity > _maxCapacity) {
            uint256 tmpMin = _minCapacity;
            _minCapacity = _maxCapacity;
            _maxCapacity = tmpMin;
        }
        require(_minCapacity <= _maxCapacity, "Vault: min > max");
        _setPoolAddress(_poolAddress);
        _setId(_trancheId);
        _setMinFundingCapacity(_minCapacity);
        _setMaxFundingCapacity(_maxCapacity);
        __ERC20_init(_tokenName, _symbol);
        __Pausable_init();
        __Ownable_init();
        __ERC4626_init(IERC20Upgradeable(_underlying));
        __AuthorityAware__init(_authority);
    }

    /*////////////////////////////////////////////////
        ADMIN METHODS
    ////////////////////////////////////////////////*/

    /** @dev enables deposits to the vault */
    function enableDeposits() external onlyOwnerOrPool {
        _setDepositEnabled(true);
    }

    /** @dev disables deposits to the vault */
    function disableDeposits() external onlyOwnerOrPool {
        _setDepositEnabled(false);
    }

    /** @dev enables withdrawals from the vault*/
    function enableWithdrawals() external onlyOwnerOrPool {
        _setWithdrawEnabled(true);
    }

    /** @dev disables withdrawals from the vault*/
    function disableWithdrawals() external onlyOwnerOrPool {
        _setWithdrawEnabled(false);
    }

    /** @dev enables vault token transfers */
    function enableTransfers() external onlyOwnerOrPool {
        _setTransferEnabled(true);
    }

    /** @dev disables vault token transfers */
    function disableTransfers() external onlyOwnerOrPool {
        _setTransferEnabled(false);
    }

    /** @dev Pauses the pool */
    function pause() external onlyOwnerOrAdmin {
        _pause();
    }

    /** @dev Unpauses the pool */
    function unpause() external onlyOwnerOrAdmin {
        _unpause();
    }

    /** @dev called by the pool in order to send assets*/
    function sendAssetsToPool(uint assets) external onlyPool whenNotPaused {
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(asset()), poolAddress(), assets);
    }

    /**@dev used to approve the process of the rollover to deployments that do not yet exist (executed with older tranche before creation of next tranche) */
    function approveRollover(address lender, uint256 assets) external onlyOwnerOrPool {
        LendingPool pool = LendingPool(poolAddress());
        PoolFactory factory = PoolFactory(pool.poolFactoryAddress());

        address[8] memory futureTranches = factory.nextTranches();
        for (uint256 i = 0; i < futureTranches.length; i++) {
            //super.approve(futureTranches[i], convertToShares(amount));
            approvedRollovers[lender][futureTranches[i]] = assets;
        }
    }

    function executeRolloverAndBurn(address lender, uint256 rewards) external onlyDeadTranche whenNotPaused returns (uint256) {
        TrancheVault newTranche = TrancheVault(_msgSender());
        uint256 assets = approvedRollovers[lender][address(newTranche)] + rewards;
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(asset()), address(newTranche), assets);
        uint256 shares = convertToAssets(assets - rewards);
        _burn(lender, shares);
        return assets;
    }

    /**@dev used to process the rollover (executed with newer tranche on deploy) */
    function rollover(address lender, address deadTrancheAddr, uint256 rewards) external onlyPool {
        TrancheVault deadTranche = TrancheVault(deadTrancheAddr);
        require(deadTranche.asset() == asset(), "Incompatible asset types");
        // transfer in capital from prev tranche
        uint256 assetsRolled = deadTranche.executeRolloverAndBurn(lender, rewards);
        IERC20Upgradeable(asset()).approve(address(this), assetsRolled);
        uint256 shares = previewDeposit(assetsRolled);
        _deposit(address(this), lender, assetsRolled, shares);
    }

    /*////////////////////////////////////////////////
        ERC-4626 Overrides
    ////////////////////////////////////////////////*/
    /** @dev Deposit asset to the pool
     *      See {IERC4626-deposit}.
     * @param assets amount of underlying asset to deposit
     * @param receiver receiver address (just set it to msg sender)
     * @return amount of pool tokens minted for the deposit
     */
    function deposit(
        uint256 assets,
        address receiver
    ) public virtual override whenNotPaused onlyLender whenDepositEnabled returns (uint256) {
        return super.deposit(assets, receiver);
    }

    /** @dev See {IERC4626-mint} */
    function mint(
        uint256 shares,
        address receiver
    ) public virtual override whenNotPaused onlyLender whenDepositEnabled returns (uint256) {
        return super.mint(shares, receiver);
    }

    /** @dev Withdraw principal from the pool
     * See {IERC4626-withdraw}.
     * @param assets amount of underlying asset to withdraw
     * @param receiver address to which the underlying assets should be sent
     * @param owner owner of the principal (just use msg sender)
     * @return amount of pool tokens burned after withdrawal
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override onlyLender whenNotPaused whenWithdrawEnabled returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override onlyLender whenNotPaused whenWithdrawEnabled returns (uint256) {
        return super.redeem(shares, receiver, owner);
    }

    /** @dev Maximum amount of assets that the vault will accept
     *  See {IERC4626-maxDeposit}.
     *  @param . lender address (just set it to msg sender)
     *  @return maximum amount of assets that can be deposited to the pool
     */
    function maxDeposit(address) public view override returns (uint256) {
        if (paused() || !depositEnabled()) {
            return 0;
        }
        if (totalAssets() >= maxFundingCapacity()) {
            return 0;
        }
        return maxFundingCapacity() - totalAssets();
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view override returns (uint256) {
        return convertToAssets(totalSupply());
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view override returns (uint256) {
        return convertToShares(maxDeposit(msg.sender));
    }

    /** @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(address owner) public view override returns (uint256) {
        if (paused() || !withdrawEnabled()) {
            return 0;
        }
        return _convertToAssets(balanceOf(owner), MathUpgradeable.Rounding.Down);
    }

    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view override returns (uint256) {
        if (paused() || !withdrawEnabled()) {
            return 0;
        }
        return balanceOf(owner);
    }

    /** @dev will return 1:1 */
    function _convertToShares(
        uint256 assets,
        MathUpgradeable.Rounding rounding
    ) internal view override returns (uint256 shares) {
        if (isDefaulted()) {
            return assets.mulDiv(10 ** 18, s_defaultRatioWad, rounding);
        }
        return _initialConvertToShares(assets, rounding);
    }

    /** @dev will return 1:1 */
    function _convertToAssets(
        uint256 shares,
        MathUpgradeable.Rounding rounding
    ) internal view override returns (uint256 assets) {
        if (isDefaulted()) {
            return shares.mulDiv(s_defaultRatioWad, 10 ** 18, rounding);
        }
        return _initialConvertToAssets(shares, rounding); // 1:1
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal whenNotPaused override {
        // If _asset is ERC777, `transferFrom` can trigger a reenterancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(asset()), caller, address(this), assets);
        _mint(receiver, shares);
        LendingPool(poolAddress()).onTrancheDeposit(id(), receiver, assets);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override whenNotPaused {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        _burn(owner, shares);
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(asset()), receiver, assets);
        LendingPool(poolAddress()).onTrancheWithdraw(id(), owner, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    /*////////////////////////////////////////////////
        ERC20Upgradeable overrides
    ////////////////////////////////////////////////*/
    function _transfer(address, address, uint256) internal override whenNotPaused whenTransferEnabled {
        revert("Transfers are not implemented");
    }
}
