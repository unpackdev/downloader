// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./UniwarRecoverable.sol";
import "./IUniwarConfig.sol";


contract UniwarConfigImpl is UniwarRecoverable, IUniwarConfig {
    address public treasury; /// @dev Uniwar DAO Treasury
    address public controller; /// @dev Uniwar Controller (Disbursements)
    address public lp; /// @dev Uniwar LP Holder
    address public router; /// @dev uniswapV2Router
    address public pair; /// @dev uniV2Pair
    address public unibot; /// @dev Unibot Token
    address public uniwar; /// @dev Uniwar Token
    address public forge; /// @dev Uniwar Forge

    uint8 public phase; /// @dev Controls the phases of the war starting at ground zero.
    uint16 public swapThreshold; /// @dev Swap threshold amount (%uint.10000) of Uniwar in the current phase to swap at.

    mapping (address => bool) public glacialBind; /// @dev glacialBind for bad actors, let us pray, in this time of war, we don't need to use it.
    mapping (address => bool) public highElves; /// @dev high elves administration upon thy

    mapping (uint8 => SwapLimits) public buyLimits; /// @dev block snipers from buying too much in a single tx or wallet in the current phase.
    mapping (uint8 => SwapTaxRates) public buyTaxRates; /// @dev Buy tax rates (%uint.10000) of Uniwar in the current phase.
    mapping (uint8 => SwapTaxRates) public sellTaxRates; /// @dev Sell tax rates (%uint.10000) of Uniwar in the current phase.
    mapping (uint8 => ForgeWeights) public forgeWeights; /// @dev Forge weights of Uniwar in the current phase.
    mapping (uint8 => ForgeRates) public forgeStakingRates; /// @dev Forge staking tax amount (%uint.10000) of Uniwar in the current phase.
    mapping (uint8 => ForgeRates) public forgeInstantWithdrawRates; /// @dev Forge staking tax amount (%uint.10000) of Uniwar in the current phase.
    mapping (uint8 => ForgeVaultLockPeriod) public forgeVaultLockPeriods; /// @dev Forge vault lock periods (seconds) of Uniwar in the current phase.

    event UpdateTreasury(address indexed _oldTreasury, address indexed _newTreasury);
    event UpdateController(address indexed _oldController, address indexed _newController);
    event UpdateLp(address indexed _oldLp, address indexed _newLp);
    event UpdateRouter(address indexed _oldRouter, address indexed _newRouter);
    event UpdatePair(address indexed _oldPair, address indexed _newPair);
    event UpdateUnibot(address indexed _oldAddress, address indexed _newAddress);
    event UpdateUniwar(address indexed _oldAddress, address indexed _newAddress);
    event UpdateForge(address indexed _oldAddress, address indexed _newAddress);
    event UpdatePhase(uint8 _oldPhase, uint8 _newPhase);
    event UpdateSwapThreshold(uint8 _phase, uint16 _oldThreshold, uint16 _newThreshold);
    event UpdateSwapEnabled(uint8 _phase, bool _enabled);
    event UpdateGlacialBind(address indexed _elf, bool _bind);
    event UpdateHighElves(address indexed _elf, bool _appoint);
    event UpdateBuyLimits(uint8 _phase, uint16 _txMax, uint16 _walletMax);
    event UpdateBuyTaxRates(uint8 _phase, uint16 _unibot, uint16 _liquidity, uint16 _treasury, uint16 _burn);
    event UpdateSellTaxRates(uint8 _phase, uint16 _unibot, uint16 _liquidity, uint16 _treasury, uint16 _burn);
    event UpdateForgeWeights(uint8 _phase, uint8 _x, uint8 _y, uint8 _z);
    event UpdateForgeStakingRates(uint8 _phase, uint16 _x, uint16 _y, uint16 _z);
    event UpdateForgeInstantWithdrawRates(uint8 _phase, uint16 _x, uint16 _y, uint16 _z);
    event UpdateForgeVaultLockPeriods(uint8 _phase, uint256 _x, uint256 _y, uint256 _z);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _treasury, address _controller, address _lp, address _router, address _unibot) initializer external {
        __UniwarRecoverable_init();
        _updateTreasury(_treasury);
        _updateController(_controller);
        _updateLp(_lp);
        _updateRouter(_router);
        _updateUnibot(_unibot);
    }

    /// @dev Update the treasury address
    /// @param _treasury The new treasury address
    /// @return True if the update is successful
    function updateTreasury(address _treasury) external onlyOwner returns (bool) {
        return _updateTreasury(_treasury);
    }

    function _updateTreasury(address _treasury) internal returns (bool) {
        require(_treasury != address(0), "UniwarConfig: treasury cannot be zero address");
        address _oldTreasury = treasury;
        treasury = _treasury;
        emit UpdateTreasury(_oldTreasury, _treasury);
        return true;
    }

    /// @dev Update the controller address
    /// @param _controller The new controller address
    /// @return True if the update is successful
    function updateController(address _controller) external onlyOwner returns (bool) {
        return _updateController(_controller);
    }

    function _updateController(address _controller) internal returns (bool) {
        require(_controller != address(0), "UniwarConfig: controller cannot be zero address");
        address _oldController = controller;
        controller = _controller;
        emit UpdateController(_oldController, _controller);
        return true;
    }

    /// @dev Update the lp address
    /// @param _lp The new lp address
    /// @return True if the update is successful
    function updateLp(address _lp) external onlyOwner returns (bool) {
        return _updateLp(_lp);
    }

    function _updateLp(address _lp) internal returns (bool) {
        require(_lp != address(0), "UniwarConfig: lp cannot be zero address");
        address _oldLp = lp;
        lp = _lp;
        emit UpdateLp(_oldLp, _lp);
        return true;
    }

    /// @dev Update the router address
    /// @param _router The new router address
    /// @return True if the update is successful
    function updateRouter(address _router) external onlyOwner returns (bool) {
        return _updateRouter(_router);
    }

    function _updateRouter(address _router) internal returns (bool) {
        require(_router != address(0), "UniwarConfig: router cannot be zero address");
        address _oldRouter = router;
        router = _router;
        emit UpdateRouter(_oldRouter, _router);
        return true;
    }

    /// @dev Update the pair address
    /// @param _pair The new pair address
    /// @return True if the update is successful
    function updatePair(address _pair) external onlyOwner returns (bool) {
        return _updatePair(_pair);
    }

    function _updatePair(address _pair) internal returns (bool) {
        require(_pair != address(0), "UniwarConfig: pair cannot be zero address");
        address _oldPair = pair;
        pair = _pair;
        emit UpdatePair(_oldPair, _pair);
        return true;
    }

    /// @dev Update the unibot address
    /// @param _unibot The new unibot address
    /// @return True if the update is successful
    function updateUnibot(address _unibot) external onlyOwner returns (bool) {
        return _updateUnibot(_unibot);
    }

    function _updateUnibot(address _unibot) internal returns (bool) {
        require(_unibot != address(0), "UniwarConfig: unibot cannot be zero address");
        address _oldAddress = address(unibot);
        unibot = _unibot;
        emit UpdateUnibot(_oldAddress, _unibot);
        return true;
    }

    /// @dev Update the uniwar address
    /// @param _uniwar The new uniwar address
    /// @return True if the update is successful
    function updateUniwar(address _uniwar) external onlyOwner returns (bool) {
        return _updateUniwar(_uniwar);
    }

    function _updateUniwar(address _uniwar) internal returns (bool) {
        require(_uniwar != address(0), "UniwarConfig: uniwar cannot be zero address");
        address _oldAddress = address(uniwar);
        uniwar = _uniwar;
        emit UpdateUniwar(_oldAddress, _uniwar);
        return true;
    }

    /// @dev Update the forge address
    /// @param _forge The new forge address
    /// @return True if the update is successful
    function updateForge(address _forge) external onlyOwner returns (bool) {
        return _updateForge(_forge);
    }

    function _updateForge(address _forge) internal returns (bool) {
        require(_forge != address(0), "UniwarConfig: forge cannot be zero address");
        address _oldAddress = forge;
        forge = _forge;
        emit UpdateForge(_oldAddress, _forge);
        return true;
    }

    /// @dev Update the phase
    /// @param _phase The new phase
    /// @return True if the update is successful
    function updatePhase(uint8 _phase) external onlyOwner returns (bool) {
        return _updatePhase(_phase);
    }

    function _updatePhase(uint8 _phase) internal returns (bool) {
        require(_phase != phase, "UniwarConfig: same phase");
        uint8 _oldPhase = phase;
        phase = _phase;
        emit UpdatePhase(_oldPhase, _phase);
        return true;
    }

    /// @dev Update the swap threshold
    /// @param _threshold The new swap threshold
    /// @return True if the update is successful
    function updateSwapThreshold(uint16 _threshold) external onlyOwner returns (bool) {
        return _updateSwapThreshold(_threshold);
    }

    function _updateSwapThreshold(uint16 _threshold) internal returns (bool) {
        require(_threshold != swapThreshold, "UniwarConfig: same threshold");
        uint16 _oldThreshold = swapThreshold;
        swapThreshold = _threshold;
        emit UpdateSwapThreshold(phase, _oldThreshold, _threshold);
        return true;
    }

    /// @dev Update the glacial bind
    /// @param _elf The elf address
    /// @param _bind The new glacial bind
    /// @return True if the update is successful
    function updateGlacialBind(address _elf, bool _bind) external onlyOwner returns (bool) {
        return _updateGlacialBind(_elf, _bind);
    }

    function _updateGlacialBind(address _elf, bool _bind) internal returns (bool) {
        require(_elf != address(0), "UniwarConfig: elf cannot be zero address");
        require(_bind != glacialBind[_elf], "UniwarConfig: same bind");
        glacialBind[_elf] = _bind;
        emit UpdateGlacialBind(_elf, _bind);
        return true;
    }

    /// @dev Update the high elves
    /// @param _elf The elf address
    /// @param _appoint The new high elves
    /// @return True if the update is successful
    function updateHighElves(address _elf, bool _appoint) external onlyOwner returns (bool) {
        return _updateHighElves(_elf, _appoint);
    }

    function _updateHighElves(address _elf, bool _appoint) internal returns (bool) {
        require(_elf != address(0), "UniwarConfig: elf cannot be zero address");
        require(_appoint != highElves[_elf], "UniwarConfig: same appoint");
        highElves[_elf] = _appoint;
        emit UpdateHighElves(_elf, _appoint);
        return true;
    }

    function appointHighElves(address[] calldata _elf) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < _elf.length; i++) {
            _updateHighElves(_elf[i], true);
        }
        return true;
    }

    /// @dev Update the buy limits
    /// @param _phase The phase to update
    /// @param _txMax The new buy tx max
    /// @param _walletMax The new buy wallet max
    /// @return True if the update is successful
    function updateBuyLimits(uint8 _phase, uint16 _txMax, uint16 _walletMax) external onlyOwner returns (bool) {
        return _updateBuyLimits(_phase, _txMax, _walletMax);
    }

    function _updateBuyLimits(uint8 _phase, uint16 _txMax, uint16 _walletMax) internal returns (bool) {
        buyLimits[_phase] = SwapLimits(_txMax, _walletMax);
        emit UpdateBuyLimits(_phase, _txMax, _walletMax);
        return true;
    }

    /// @dev Update the buy tax rates
    /// @param _phase The phase to update
    /// @param _unibot The new buy unibot tax
    /// @param _liquidity The new buy liquidity tax
    /// @param _treasury The new buy treasury tax
    /// @param _burn The new buy burn tax
    /// @return True if the update is successful
    function updateBuyTaxRates(uint8 _phase, uint16 _unibot, uint16 _liquidity, uint16 _treasury, uint16 _burn) external onlyOwner returns (bool) {
        return _updateBuyTaxRates(_phase, _unibot, _liquidity, _treasury, _burn);
    }

    function _updateBuyTaxRates(uint8 _phase, uint16 _unibot, uint16 _liquidity, uint16 _treasury, uint16 _burn) internal returns (bool) {
        buyTaxRates[_phase] = SwapTaxRates(_unibot, _liquidity, _treasury, _burn);
        emit UpdateBuyTaxRates(_phase, _unibot, _liquidity, _treasury, _burn);
        return true;
    }

    /// @dev Update the sell tax rates
    /// @param _phase The phase to update
    /// @param _unibot The new sell unibot tax
    /// @param _liquidity The new sell liquidity tax
    /// @param _treasury The new sell treasury tax
    /// @param _burn The new sell burn tax
    /// @return True if the update is successful
    function updateSellTaxRates(uint8 _phase, uint16 _unibot, uint16 _liquidity, uint16 _treasury, uint16 _burn) external onlyOwner returns (bool) {
        return _updateSellTaxRates(_phase, _unibot, _liquidity, _treasury, _burn);
    }

    function _updateSellTaxRates(uint8 _phase, uint16 _unibot, uint16 _liquidity, uint16 _treasury, uint16 _burn) internal returns (bool) {
        sellTaxRates[_phase] = SwapTaxRates(_unibot, _liquidity, _treasury, _burn);
        emit UpdateSellTaxRates(_phase, _unibot, _liquidity, _treasury, _burn);
        return true;
    }

    /// @dev Update the forge weights
    /// @param _phase The phase to update
    /// @param _x The new forge x weight
    /// @param _y The new forge y weight
    /// @param _z The new forge z weight
    /// @return True if the update is successful
    function updateForgeWeights(uint8 _phase, uint8 _x, uint8 _y, uint8 _z) external onlyOwner returns (bool) {
        return _updateForgeWeights(_phase, _x, _y, _z);
    }

    function _updateForgeWeights(uint8 _phase, uint8 _x, uint8 _y, uint8 _z) internal returns (bool) {
        forgeWeights[_phase] = ForgeWeights(_x, _y, _z);
        emit UpdateForgeWeights(_phase, _x, _y, _z);
        return true;
    }

    /// @dev Update the forge staking rates
    /// @param _phase The phase to update
    /// @param _x The new forge x tax
    /// @param _y The new forge y tax
    /// @param _z The new forge z tax
    /// @return True if the update is successful
    function updateForgeStakingRates(uint8 _phase, uint16 _x, uint16 _y, uint16 _z) external onlyOwner returns (bool) {
        return _updateForgeStakingRates(_phase, _x, _y, _z);
    }

    function _updateForgeStakingRates(uint8 _phase, uint16 _x, uint16 _y, uint16 _z) internal returns (bool) {
        forgeStakingRates[_phase] = ForgeRates(_x, _y, _z);
        emit UpdateForgeStakingRates(_phase, _x, _y, _z);
        return true;
    }

    /// @dev Update the forge instant withdraw rates
    /// @param _phase The phase to update
    /// @param _x The new forge x tax
    /// @param _y The new forge y tax
    /// @param _z The new forge z tax
    /// @return True if the update is successful
    function updateForgeInstantWithdrawRates(uint8 _phase, uint16 _x, uint16 _y, uint16 _z) external onlyOwner returns (bool) {
        return _updateForgeInstantWithdrawRates(_phase, _x, _y, _z);
    }

    function _updateForgeInstantWithdrawRates(uint8 _phase, uint16 _x, uint16 _y, uint16 _z) internal returns (bool) {
        forgeInstantWithdrawRates[_phase] = ForgeRates(_x, _y, _z);
        emit UpdateForgeInstantWithdrawRates(_phase, _x, _y, _z);
        return true;
    }

    /// @dev Update the forge vault lock periods
    /// @param _phase The phase to update
    /// @param _x The new forge x take lock
    /// @param _y The new forge y take lock
    /// @param _z The new forge z take lock
    /// @return True if the update is successful
    function updateForgeVaultLockPeriods(uint8 _phase, uint256 _x, uint256 _y, uint256 _z) external onlyOwner returns (bool) {
        return _updateForgeVaultLockPeriods(_phase, _x, _y, _z);
    }

    function _updateForgeVaultLockPeriods(uint8 _phase, uint256 _x, uint256 _y, uint256 _z) internal returns (bool) {
        forgeVaultLockPeriods[_phase] = ForgeVaultLockPeriod(_x, _y, _z);
        emit UpdateForgeVaultLockPeriods(_phase, _x, _y, _z);
        return true;
    }

    function _authorizeUpgrade(address _newImplementation)
    internal
    onlyOwner
    override
    {}

    /// @dev v0.0.2
    mapping (uint8 => SwapLimits) public sellLimits; /// @dev block snipers from selling too much in a single tx or wallet in the current phase.
    event UpdateSellLimits(uint8 _phase, uint16 _txMax, uint16 _walletMax);

    function updateSellLimits(uint8 _phase, uint16 _txMax, uint16 _walletMax) external onlyOwner returns (bool) {
        return _updateSellLimits(_phase, _txMax, _walletMax);
    }

    function _updateSellLimits(uint8 _phase, uint16 _txMax, uint16 _walletMax) internal returns (bool) {
        sellLimits[_phase] = SwapLimits(_txMax, _walletMax);
        emit UpdateSellLimits(_phase, _txMax, _walletMax);
        return true;
    }
}
