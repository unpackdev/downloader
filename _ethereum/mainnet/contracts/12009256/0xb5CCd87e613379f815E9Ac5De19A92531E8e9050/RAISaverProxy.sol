pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./DefisaverLogger.sol";
import "./Discount.sol";

import "./IOracleRelayer.sol";
import "./ITaxCollector.sol";
import "./ICoinJoin.sol";

import "./RAISaverProxyHelper.sol";
import "./BotRegistry.sol";
import "./DFSExchangeCore.sol";

/// @title Implements Boost and Repay for Reflexer Safes
contract RAISaverProxy is DFSExchangeCore, RAISaverProxyHelper {

    uint public constant MANUAL_SERVICE_FEE = 400; // 0.25% Fee
    uint public constant AUTOMATIC_SERVICE_FEE = 333; // 0.3% Fee

    bytes32 public constant ETH_COLL_TYPE = 0x4554482d41000000000000000000000000000000000000000000000000000000;

    address public constant SAFE_ENGINE_ADDRESS = 0xCC88a9d330da1133Df3A7bD823B95e52511A6962;
    address public constant ORACLE_RELAYER_ADDRESS = 0x4ed9C0dCa0479bC64d8f4EB3007126D5791f7851;
    address public constant RAI_JOIN_ADDRESS = 0x0A5653CCa4DB1B6E265F47CAf6969e64f1CFdC45;
    address public constant TAX_COLLECTOR_ADDRESS = 0xcDB05aEda142a1B0D6044C09C64e4226c1a281EB;
    address public constant RAI_ADDRESS = 0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919;

    address public constant BOT_REGISTRY_ADDRESS = 0x637726f8b08a7ABE3aE3aCaB01A80E2d8ddeF77B;

    ISAFEEngine public constant safeEngine = ISAFEEngine(SAFE_ENGINE_ADDRESS);
    ICoinJoin public constant raiJoin = ICoinJoin(RAI_JOIN_ADDRESS);
    IOracleRelayer public constant oracleRelayer = IOracleRelayer(ORACLE_RELAYER_ADDRESS);

    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    /// @notice Repay - draws collateral, converts to Rai and repays the debt
    /// @dev Must be called by the DSProxy contract that owns the Safe
    function repay(
        ExchangeData memory _exchangeData,
        uint _safeId,
        uint _gasCost,
        address _joinAddr,
        ManagerType _managerType
    ) public payable {

        address managerAddr = getManagerAddr(_managerType);

        address user = getOwner(ISAFEManager(managerAddr), _safeId);
        bytes32 ilk = ISAFEManager(managerAddr).collateralTypes(_safeId);

        drawCollateral(managerAddr, _safeId, _joinAddr, _exchangeData.srcAmount, true);

        _exchangeData.user = user;
        _exchangeData.dfsFeeDivider = isAutomation() ? AUTOMATIC_SERVICE_FEE : MANUAL_SERVICE_FEE;
        (, uint raiAmount) = _sell(_exchangeData);

        raiAmount -= takeFee(_gasCost, raiAmount);

        paybackDebt(managerAddr, _safeId, ilk, raiAmount, user);

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }

        logger.Log(address(this), msg.sender, "RAIRepay", abi.encode(_safeId, user, _exchangeData.srcAmount, raiAmount));

    }

    /// @notice Boost - draws Rai, converts to collateral and adds to Safe
    /// @dev Must be called by the DSProxy contract that owns the Safe
    function boost(
        ExchangeData memory _exchangeData,
        uint _safeId,
        uint _gasCost,
        address _joinAddr,
        ManagerType _managerType
    ) public payable {

        address managerAddr = getManagerAddr(_managerType);

        address user = getOwner(ISAFEManager(managerAddr), _safeId);
        bytes32 ilk = ISAFEManager(managerAddr).collateralTypes(_safeId);

        uint raiDrawn = drawRai(managerAddr, _safeId, ilk, _exchangeData.srcAmount);

        _exchangeData.user = user;
        _exchangeData.dfsFeeDivider = isAutomation() ? AUTOMATIC_SERVICE_FEE : MANUAL_SERVICE_FEE;
        _exchangeData.srcAmount = raiDrawn - takeFee(_gasCost, raiDrawn);
        (, uint swapedColl) = _sell(_exchangeData);

        addCollateral(managerAddr, _safeId, _joinAddr, swapedColl, true);

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }

        logger.Log(address(this), msg.sender, "RAIBoost", abi.encode(_safeId, user, _exchangeData.srcAmount, swapedColl));
    }

    /// @notice Draws Rai from the Safe
    /// @dev If _raiAmount is bigger than max available we'll draw max
    /// @param _managerAddr Address of the Safe Manager
    /// @param _safeId Id of the Safe
    /// @param _collType Coll type of the Safe
    /// @param _raiAmount Amount of Rai to draw
    function drawRai(address _managerAddr, uint _safeId, bytes32 _collType, uint _raiAmount) internal returns (uint) {
        uint rate = ITaxCollector(TAX_COLLECTOR_ADDRESS).taxSingle(_collType);
        uint raiVatBalance = safeEngine.coinBalance(ISAFEManager(_managerAddr).safes(_safeId));

        uint maxAmount = getMaxDebt(_managerAddr, _safeId, _collType);

        if (_raiAmount >= maxAmount) {
            _raiAmount = sub(maxAmount, 1);
        }

        ISAFEManager(_managerAddr).modifySAFECollateralization(_safeId, int(0), normalizeDrawAmount(_raiAmount, rate, raiVatBalance));
        ISAFEManager(_managerAddr).transferInternalCoins(_safeId, address(this), toRad(_raiAmount));

        if (safeEngine.safeRights(address(this), address(RAI_JOIN_ADDRESS)) == 0) {
            safeEngine.approveSAFEModification(RAI_JOIN_ADDRESS);
        }

        ICoinJoin(RAI_JOIN_ADDRESS).exit(address(this), _raiAmount);

        return _raiAmount;
    }

    /// @notice Adds collateral to the Safe
    /// @param _managerAddr Address of the Safe Manager
    /// @param _safeId Id of the Safe
    /// @param _joinAddr Address of the join contract for the Safe collateral
    /// @param _amount Amount of collateral to add
    /// @param _toWeth Should we convert to Weth
    function addCollateral(address _managerAddr, uint _safeId, address _joinAddr, uint _amount, bool _toWeth) internal {
        int convertAmount = 0;

        if (isEthJoinAddr(_joinAddr) && _toWeth) {
            TokenInterface(IBasicTokenAdapters(_joinAddr).collateral()).deposit{value: _amount}();
            convertAmount = toPositiveInt(_amount);
        } else {
            convertAmount = toPositiveInt(convertTo18(_joinAddr, _amount));
        }

        ERC20(address(IBasicTokenAdapters(_joinAddr).collateral())).safeApprove(_joinAddr, _amount);

        IBasicTokenAdapters(_joinAddr).join(address(this), _amount);

        safeEngine.modifySAFECollateralization(
            ISAFEManager(_managerAddr).collateralTypes(_safeId),
            ISAFEManager(_managerAddr).safes(_safeId),
            address(this),
            address(this),
            convertAmount,
            0
        );

    }

    /// @notice Draws collateral and returns it to DSProxy
    /// @param _managerAddr Address of the Safe Manager
    /// @dev If _amount is bigger than max available we'll draw max
    /// @param _safeId Id of the Safe
    /// @param _joinAddr Address of the join contract for the Safe collateral
    /// @param _amount Amount of collateral to draw
    /// @param _toEth Boolean if we should unwrap Ether
    function drawCollateral(address _managerAddr, uint _safeId, address _joinAddr, uint _amount, bool _toEth) internal returns (uint) {
        uint frobAmount = _amount;

        if (IBasicTokenAdapters(_joinAddr).decimals() != 18) {
            frobAmount = _amount * (10 ** (18 - IBasicTokenAdapters(_joinAddr).decimals()));
        }

        ISAFEManager(_managerAddr).modifySAFECollateralization(_safeId, -toPositiveInt(frobAmount), 0);
        ISAFEManager(_managerAddr).transferCollateral(_safeId, address(this), frobAmount);

        IBasicTokenAdapters(_joinAddr).exit(address(this), _amount);

        if (isEthJoinAddr(_joinAddr) && _toEth) {
            TokenInterface(IBasicTokenAdapters(_joinAddr).collateral()).withdraw(_amount); // Weth -> Eth
        }

        return _amount;
    }

    /// @notice Paybacks Rai debt
    /// @param _managerAddr Address of the Safe Manager
    /// @dev If the _raiAmount is bigger than the whole debt, returns extra Rai
    /// @param _safeId Id of the Safe
    /// @param _collType Coll type of the Safe
    /// @param _raiAmount Amount of Rai to payback
    /// @param _owner Address that owns the DSProxy that owns the Safe
    function paybackDebt(address _managerAddr, uint _safeId, bytes32 _collType, uint _raiAmount, address _owner) internal {
        address urn = ISAFEManager(_managerAddr).safes(_safeId);

        uint wholeDebt = getAllDebt(SAFE_ENGINE_ADDRESS, urn, urn, _collType);

        if (_raiAmount > wholeDebt) {
            ERC20(RAI_ADDRESS).transfer(_owner, sub(_raiAmount, wholeDebt));
            _raiAmount = wholeDebt;
        }

        if (ERC20(RAI_ADDRESS).allowance(address(this), RAI_JOIN_ADDRESS) == 0) {
            ERC20(RAI_ADDRESS).approve(RAI_JOIN_ADDRESS, uint(-1));
        }

        raiJoin.join(urn, _raiAmount);

        int paybackAmnt = _getRepaidDeltaDebt(SAFE_ENGINE_ADDRESS, ISAFEEngine(safeEngine).coinBalance(urn), urn, _collType);

        ISAFEManager(_managerAddr).modifySAFECollateralization(_safeId, 0, paybackAmnt);
    }

    /// @notice Gets the maximum amount of collateral available to draw
    /// @param _managerAddr Address of the Safe Manager
    /// @param _safeId Id of the Safe
    /// @param _collType Coll type of the Safe
    /// @param _joinAddr Joind address of collateral
    /// @dev Substracts 1% to aviod rounding error later on
    function getMaxCollateral(address _managerAddr, uint _safeId, bytes32 _collType, address _joinAddr) public view returns (uint) {
        (uint collateral, uint debt) = getSafeInfo(ISAFEManager(_managerAddr), _safeId, _collType);

        (, , uint256 safetyPrice, , , ) =
            ISAFEEngine(SAFE_ENGINE_ADDRESS).collateralTypes(_collType);

        uint maxCollateral = sub(collateral, wmul(wdiv(RAY, safetyPrice), debt));

        uint normalizeMaxCollateral = maxCollateral / (10 ** (18 - IBasicTokenAdapters(_joinAddr).decimals()));

        // take one percent due to precision issues
        return normalizeMaxCollateral * 99 / 100;
    }

    /// @notice Gets the maximum amount of debt available to generate
    /// @param _managerAddr Address of the Safe Manager
    /// @param _safeId Id of the Safe
    /// @param _collType Coll type of the Safe
    /// @dev Substracts 10 wei to aviod rounding error later on
    function getMaxDebt(
        address _managerAddr,
        uint256 _safeId,
        bytes32 _collType
    ) public view virtual returns (uint256) {
        (uint256 collateral, uint256 debt) =
            getSafeInfo(ISAFEManager(_managerAddr), _safeId, _collType);

        (, , uint256 safetyPrice, , , ) =
            ISAFEEngine(SAFE_ENGINE_ADDRESS).collateralTypes(_collType);

        return sub(sub(rmul(collateral, safetyPrice), debt), 10);
    }

    function getPrice(bytes32 _collType) public returns (uint256) {
        (, uint256 safetyCRatio) =
            IOracleRelayer(ORACLE_RELAYER_ADDRESS).collateralTypes(_collType);
        (, , uint256 safetyPrice, , , ) =
            ISAFEEngine(SAFE_ENGINE_ADDRESS).collateralTypes(_collType);

        uint256 redemptionPrice = IOracleRelayer(ORACLE_RELAYER_ADDRESS).redemptionPrice();

        return rmul(rmul(safetyPrice, redemptionPrice), safetyCRatio);
    }

    function isAutomation() internal view returns(bool) {
        return BotRegistry(BOT_REGISTRY_ADDRESS).botList(tx.origin);
    }

    function takeFee(uint256 _gasCost, uint _amount) internal returns(uint) {
        if (_gasCost > 0) {
            uint ethRaiPrice = getPrice(ETH_COLL_TYPE);
            uint feeAmount = rmul(_gasCost, ethRaiPrice);

            if (feeAmount > _amount / 5) {
                feeAmount = _amount / 5;
            }

            address walletAddr = _feeRecipient.getFeeAddr();

            ERC20(RAI_ADDRESS).transfer(walletAddr, feeAmount);

            return feeAmount;
        }

        return 0;
    }
}
