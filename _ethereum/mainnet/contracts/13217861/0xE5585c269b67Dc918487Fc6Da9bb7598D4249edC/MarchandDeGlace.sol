// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Proxied.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ProxyAdminFunctions.sol";
import "./CheckerFunctions.sol";
import "./SignatureFunctions.sol";
import "./DSMath.sol";

// BE CAREFUL: DOT NOT CHANGE THE ORDER OF INHERITED CONTRACT
// solhint-disable-next-line max-states-count
contract MarchandDeGlace is
    Initializable,
    Proxied,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;

    struct Whale {
        address addr;
        bytes[2] signatures;
    }

    struct Dolphin {
        address addr;
        bytes signature;
    }

    struct MultiIsCreatureResult {
        address creature;
        bool isCreature;
    }

    // solhint-disable-next-line max-line-length
    ////////////////////////////////////////// CONSTANTS AND IMMUTABLES ///////////////////////////////////

    ///@dev GEL_TOTAL_SUPPLY 420,690,000.00
    /// TOTAL_GEL_CAP = GEL_TOTAL_SUPPLY * 4%
    uint256 public immutable TOTAL_GEL_CAP; // solhint-disable-line var-name-mixedcase

    ///@dev POOL_ONE_GEL_CAP = TOTAL_GEL_CAP * (3/5);
    uint256 public immutable POOL_ONE_GEL_CAP; // solhint-disable-line var-name-mixedcase

    ///@dev GELUSD = 0.2971309 $ and WHALE_MIN_USD = 5000 $
    /// WHALE_POOL_USD_PRICE = POOL_ONE_GEL_CAP * GELUSD
    /// we know that WHALE_MIN_USD / WHALE_POOL_USD_PRICE = WHALE_MIN_GEL / POOL_ONE_GEL_CAP
    /// so WHALE_MIN_GEL = ( WHALE_MIN_USD / WHALE_POOL_USD_PRICE ) * POOL_ONE_GEL_CAP
    uint256 public constant WHALE_MIN_GEL = 16827600226028326236012;

    ///@dev WHALE_MAX_USD = 20000 $, with same reasoning
    /// we know that WHALE_MAX_USD / WHALE_POOL_USD_PRICE = WHALE_MAX_GEL / POOL_ONE_GEL_CAP
    /// so WHALE_MAX_GEL = ( WHALE_MAX_USD / WHALE_POOL_USD_PRICE ) * POOL_ONE_GEL_CAP
    uint256 public constant WHALE_MAX_GEL = 67310400904113304944050;

    ///@dev DOLPHIN_MIN_USD = 1000 $ and DOLPHIN_POOL_GEL = 6731040
    /// DOLPHIN_POOL_USD_PRICE = DOLPHIN_POOL_GEL * GELUSD
    /// we know that DOLPHIN_MIN_USD / DOLPHIN_POOL_USD_PRICE = DOLPHIN_MIN_GEL / DOLPHIN_POOL_GEL
    /// so DOLPHIN_MIN_GEL = ( DOLPHIN_MIN_USD / DOLPHIN_POOL_USD_PRICE ) * DOLPHIN_POOL_GEL
    uint256 public constant DOLPHIN_MIN_GEL = 3365520045205665247202;

    ///@dev DOLPHIN_MAX_USD = 4000 $, with same reasoning
    /// we know that DOLPHIN_MAX_USD / DOLPHIN_POOL_USD_PRICE = DOLPHIN_MAX_GEL / DOLPHIN_POOL_GEL
    /// so DOLPHIN_MAX_GEL = ( DOLPHIN_MAX_USD / DOLPHIN_POOL_USD_PRICE ) * DOLPHIN_POOL_GEL
    uint256 public constant DOLPHIN_MAX_GEL = 13462080180822660988810;

    // Token that Marchand De Glace Sell.
    IERC20 public immutable GEL; // solhint-disable-line var-name-mixedcase

    // Address signing user signature.
    address public immutable SIGNER; // solhint-disable-line var-name-mixedcase

    // solhint-disable-next-line max-line-length
    /////////////////////////////////////////// STORAGE DATA //////////////////////////////////////////////////

    // !!!!!!!!!!!!!!!!!!!!!!!! DO NOT CHANGE ORDER !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    // Only settable by the Admin
    uint256 public gelPerEth;
    uint256 public poolOneStartTime;
    uint256 public poolTwoStartTime;
    uint256 public poolOneEndTime;
    uint256 public poolTwoEndTime;
    uint256 public lockUpEndTime;

    mapping(address => uint256) public gelLockedByWhale;
    mapping(address => uint256) public gelBoughtByDolphin;
    uint256 public totalGelLocked;

    // !!!!!!!! ADD NEW PROPERTIES HERE !!!!!!!

    event LogBuyWhale(
        address indexed whale,
        uint256 ethPaid,
        uint256 gelBought,
        uint256 gelLocked,
        uint256 gelUnlocked
    );
    event LogBuyDolphin(
        address indexed dolphin,
        uint256 ethPaid,
        uint256 gelBought
    );
    event LogWithdrawLockedGEL(
        address indexed whale,
        address indexed to,
        uint256 gelWithdrawn
    );

    constructor(
        uint256 _totalGelCap,
        uint256 _poolOneGelCap,
        IERC20 _gel,
        address _signer
    ) {
        TOTAL_GEL_CAP = _totalGelCap;
        POOL_ONE_GEL_CAP = _poolOneGelCap;
        GEL = _gel;
        SIGNER = _signer;
    }

    function initialize(
        uint256 _gelPerEth,
        uint256 _poolOneStartTime,
        uint256 _poolTwoStartTime,
        uint256 _poolOneEndTime,
        uint256 _poolTwoEndTime,
        uint256 _lockUpEndTime
    ) external initializer {
        require(_gelPerEth > 0, "Ether to Gel price cannot be settable to 0");
        require(
            _poolOneStartTime <= _poolOneEndTime,
            "Pool One phase cannot end before the start"
        );
        require(
            _poolOneEndTime <= _poolTwoStartTime,
            "Pool One phase should be closed for starting pool two"
        );
        require(
            _poolTwoStartTime <= _poolTwoEndTime,
            "Pool Two phase cannot end before the start"
        );
        require(
            _poolOneEndTime + 182 days <= _lockUpEndTime,
            "Lockup should end at least 6 months after pool one phase 1 ending"
        );
        __ReentrancyGuard_init();
        __Pausable_init();
        gelPerEth = _gelPerEth;
        poolOneStartTime = _poolOneStartTime;
        poolTwoStartTime = _poolTwoStartTime;
        poolOneEndTime = _poolOneEndTime;
        poolTwoEndTime = _poolTwoEndTime;
        lockUpEndTime = _lockUpEndTime;
    }

    // We are using onlyProxyAdmin, because admin = owner,
    // Proxied get admin from storage position
    // 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
    // and EIP173Proxy store owner at same position.
    // https://github.com/wighawag/hardhat-deploy/blob/master/solc_0.7/proxy/EIP173Proxy.sol
    function setGelPerEth(uint256 _gelPerEth) external onlyProxyAdmin {
        gelPerEth = _gelPerEth;
    }

    function setPhaseOneStartTime(uint256 _poolOneStartTime)
        external
        onlyProxyAdmin
    {
        poolOneStartTime = _poolOneStartTime;
    }

    function setPhaseTwoStartTime(uint256 _poolTwoStartTime)
        external
        onlyProxyAdmin
    {
        poolTwoStartTime = _poolTwoStartTime;
    }

    function setPhaseOneEndTime(uint256 _poolOneEndTime)
        external
        onlyProxyAdmin
    {
        poolOneEndTime = _poolOneEndTime;
    }

    function setPhaseTwoEndTime(uint256 _poolTwoEndTime)
        external
        onlyProxyAdmin
    {
        poolTwoEndTime = _poolTwoEndTime;
    }

    function setLockUpEndTime(uint256 _lockUpEndTime) external onlyProxyAdmin {
        lockUpEndTime = _lockUpEndTime;
    }

    function pause() external onlyProxyAdmin {
        _pause();
    }

    function unpause() external onlyProxyAdmin {
        _unpause();
    }

    function withdrawETH() external onlyProxyAdmin {
        _withdrawETH(_proxyAdmin(), address(this).balance);
    }

    function withdrawUnlockedGEL() external onlyProxyAdmin {
        _withdrawUnlockedGEL(
            GEL,
            _proxyAdmin(),
            GEL.balanceOf(address(this)),
            totalGelLocked
        );
    }

    function withdrawAllGEL() external onlyProxyAdmin whenPaused {
        _withdrawAllGEL(GEL, _proxyAdmin(), GEL.balanceOf(address(this)));
    }

    // !!!!!!!!!!!!!!!!!!!!! FUNCTIONS CALLABLE BY WHALES AND DOLPHINS !!!!!!!!!!!!!!!!!!!!!!!!!

    function buyWhale(bytes calldata _signature)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        _requirePoolOneIsOpen(poolOneStartTime, poolOneEndTime);
        _requireWhale(_signature, SIGNER);
        _requireWhaleNeverBought(gelLockedByWhale[msg.sender]);

        // Amount of gel bought
        // TODO check precision issue here.
        uint256 gelBought = _wmul(msg.value, gelPerEth);

        _requireBoughtWithinWhaleCaps(gelBought, WHALE_MIN_GEL, WHALE_MAX_GEL);
        _requirePoolOneCapNotExceeded(
            TOTAL_GEL_CAP,
            GEL.balanceOf(address(this)),
            totalGelLocked,
            gelBought,
            POOL_ONE_GEL_CAP
        );

        uint256 gelLocked = _wmul(gelBought, 7 * 1e17); // 70% locked.
        totalGelLocked = totalGelLocked + gelLocked;
        gelLockedByWhale[msg.sender] = gelLocked;

        GEL.safeTransfer(msg.sender, gelBought - gelLocked);

        emit LogBuyWhale(
            msg.sender,
            msg.value,
            gelBought,
            gelLocked,
            gelBought - gelLocked
        );
    }

    // solhint-disable-next-line function-max-lines
    function buyDolphin(bytes calldata _signature)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        _requirePoolTwoIsOpen(poolTwoStartTime, poolTwoEndTime);
        _requireDolphin(_signature, SIGNER);
        _requireWhaleNeverBought(gelLockedByWhale[msg.sender]);
        _requireDolphinNeverBought(gelBoughtByDolphin[msg.sender]);

        // Amount of gel bought
        // TODO check precision issue here.
        uint256 gelBought = _wmul(msg.value, gelPerEth);

        _requireBoughtLteDolphinMax(gelBought, DOLPHIN_MAX_GEL);
        uint256 remainingGel = _getRemainingGel(
            GEL.balanceOf(address(this)),
            totalGelLocked
        );

        uint256 buyableRemainingGel = _getBuyableRemainingGel(
            remainingGel,
            gelPerEth
        ); // buyableRemainingGel <= remainingGel

        if (_isSaleClosing(buyableRemainingGel, DOLPHIN_MIN_GEL))
            _requireBoughtEqBuyableRemaining(gelBought, buyableRemainingGel);
        else {
            _requireBoughtGteDolphinMin(gelBought, DOLPHIN_MIN_GEL);
            _requireBoughtLteRemaining(gelBought, remainingGel);
        }

        gelBoughtByDolphin[msg.sender] = gelBought;

        GEL.safeTransfer(msg.sender, gelBought);

        emit LogBuyDolphin(msg.sender, msg.value, gelBought);
    }

    function withdrawLockedGEL(address _to)
        external
        whenNotPaused
        nonReentrant
    {
        _requireNotAddressZero(_to);
        _requireNotLocked(lockUpEndTime);
        _requireHasGELToUnlock(gelLockedByWhale[msg.sender]);

        uint256 gelWithdrawn = gelLockedByWhale[msg.sender];
        delete gelLockedByWhale[msg.sender];

        totalGelLocked = totalGelLocked - gelWithdrawn;

        GEL.safeTransfer(_to, gelWithdrawn);

        emit LogWithdrawLockedGEL(msg.sender, _to, gelWithdrawn);
    }

    // ======== HELPERS =======

    function canBuyWhale(
        address _whale,
        bytes calldata _signature,
        uint256 _ethToSell
    ) external view returns (bool) {
        uint256 gelToBuy = getGELToBuy(_ethToSell);
        return
            !paused() &&
            isPoolOneOpen() &&
            isWhale(_whale, _signature) &&
            hasWhaleNeverBought(_whale) &&
            isBoughtWithinWhaleCaps(gelToBuy) &&
            !isPoolOneCapExceeded(gelToBuy);
    }

    function canBuyDolphin(
        address _dolphin,
        bytes calldata _signature,
        uint256 _ethToSell
    ) external view returns (bool) {
        uint256 gelToBuy = getGELToBuy(_ethToSell);
        return
            !paused() &&
            isPoolTwoOpen() &&
            isDolphin(_dolphin, _signature) &&
            hasWhaleNeverBought(_dolphin) &&
            hasDolphinNeverBought(_dolphin) &&
            isBoughtLteDolphinMax(gelToBuy) &&
            (
                isSaleClosing()
                    ? isBoughtEqBuyableRemaining(gelToBuy)
                    : isBoughtGteDolphinMin(gelToBuy) &&
                        isBoughtLteRemaining(gelToBuy)
            );
    }

    function getGELToBuy(uint256 _ethToSell) public view returns (uint256) {
        return _wmul(_ethToSell, gelPerEth);
    }

    function isPoolOneOpen() public view returns (bool) {
        return _isPoolOneOpen(poolOneStartTime, poolOneEndTime);
    }

    function isWhale(address _whale, bytes calldata _signature)
        public
        view
        returns (bool)
    {
        return _isWhale(_whale, _signature, SIGNER);
    }

    function multiIsWhale(Whale[] calldata _whales)
        public
        view
        returns (MultiIsCreatureResult[] memory results)
    {
        results = new MultiIsCreatureResult[](_whales.length);

        for (uint256 i; i < _whales.length; i++) {
            MultiIsCreatureResult memory result = MultiIsCreatureResult({
                creature: _whales[i].addr,
                isCreature: isWhale(
                    _whales[i].addr,
                    _whales[i].signatures[0]
                ) && isDolphin(_whales[i].addr, _whales[i].signatures[1])
            });
            results[i] = result;
        }
    }

    function hasWhaleNeverBought(address _whale) public view returns (bool) {
        return _hasWhaleNeverBought(gelLockedByWhale[_whale]);
    }

    function isPoolOneCapExceeded(uint256 _gelToBuy)
        public
        view
        returns (bool)
    {
        return
            _isPoolOneCapExceeded(
                TOTAL_GEL_CAP,
                GEL.balanceOf((address(this))),
                totalGelLocked,
                _gelToBuy,
                POOL_ONE_GEL_CAP
            );
    }

    function getRemainingGelPoolOne() public view returns (uint256) {
        return
            block.timestamp < poolOneEndTime // solhint-disable-line not-rely-on-time
                ? POOL_ONE_GEL_CAP -
                    (TOTAL_GEL_CAP -
                        GEL.balanceOf(address(this)) +
                        totalGelLocked)
                : 0;
    }

    function isPoolTwoOpen() public view returns (bool) {
        return _isPoolTwoOpen(poolTwoStartTime, poolTwoEndTime);
    }

    function isDolphin(address _dolphin, bytes calldata _signature)
        public
        view
        returns (bool)
    {
        return _isDolphin(_dolphin, _signature, SIGNER);
    }

    function multiIsDolphin(Dolphin[] calldata _dolphins)
        public
        view
        returns (MultiIsCreatureResult[] memory results)
    {
        results = new MultiIsCreatureResult[](_dolphins.length);

        for (uint256 i; i < _dolphins.length; i++) {
            MultiIsCreatureResult memory result = MultiIsCreatureResult({
                creature: _dolphins[i].addr,
                isCreature: isDolphin(_dolphins[i].addr, _dolphins[i].signature)
            });
            results[i] = result;
        }
    }

    function hasDolphinNeverBought(address _dolphin)
        public
        view
        returns (bool)
    {
        return _hasDolphinNeverBought(gelBoughtByDolphin[_dolphin]);
    }

    function isSaleClosing() public view returns (bool) {
        return _isSaleClosing(getBuyableRemainingGel(), DOLPHIN_MIN_GEL);
    }

    function isBoughtEqBuyableRemaining(uint256 _gelToBuy)
        public
        view
        returns (bool)
    {
        return _isBoughtEqBuyableRemaining(_gelToBuy, getBuyableRemainingGel());
    }

    function isBoughtLteRemaining(uint256 _gelBought)
        public
        view
        returns (bool)
    {
        return _isBoughtLteRemaining(_gelBought, getRemainingGel());
    }

    function getBuyableRemainingGel() public view returns (uint256) {
        return _getBuyableRemainingGel(getRemainingGel(), gelPerEth);
    }

    function getRemainingGel() public view returns (uint256) {
        return _getRemainingGel(GEL.balanceOf(address(this)), totalGelLocked);
    }

    function isBoughtWithinWhaleCaps(uint256 _gelBought)
        public
        pure
        returns (bool)
    {
        return
            _isBoughtWithinWhaleCaps(_gelBought, WHALE_MIN_GEL, WHALE_MAX_GEL);
    }

    function isBoughtLteDolphinMax(uint256 _gelBought)
        public
        pure
        returns (bool)
    {
        return _isBoughtLteDolphinMax(_gelBought, DOLPHIN_MAX_GEL);
    }

    function isBoughtGteDolphinMin(uint256 _gelToBuy)
        public
        pure
        returns (bool)
    {
        return _isBoughtGteDolphinMin(_gelToBuy, DOLPHIN_MIN_GEL);
    }
}
