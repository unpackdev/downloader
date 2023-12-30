pragma solidity ^0.6.0;

import "./ExchangeInterface.sol";

import "./SaverLogger.sol";
import "./Discount.sol";

import "./Spotter.sol";
import "./Jug.sol";
import "./DaiJoin.sol";
import "./Join.sol";

import "./ExchangeHelper.sol";
import "./SaverProxyHelper.sol";


/// @title Implements Boost and Repay for MCD CDPs
contract MCDSaverProxy is SaverProxyHelper, ExchangeHelper {

    uint public constant SERVICE_FEE = 400; // 0.25% Fee
    bytes32 public constant ETH_ILK = 0x4554482d41000000000000000000000000000000000000000000000000000000;
    bytes32 public constant USDC_ILK = 0x555344432d410000000000000000000000000000000000000000000000000000;

    Manager public constant manager = Manager(MANAGER_ADDRESS);
    Vat public constant vat = Vat(VAT_ADDRESS);
    DaiJoin public constant daiJoin = DaiJoin(DAI_JOIN_ADDRESS);
    Spotter public constant spotter = Spotter(SPOTTER_ADDRESS);

    /// @notice Checks if the collateral amount is increased after boost
    /// @param _cdpId The Id of the CDP
    modifier boostCheck(uint _cdpId) {
        bytes32 ilk = manager.ilks(_cdpId);
        address urn = manager.urns(_cdpId);

        (uint collateralBefore, ) = vat.urns(ilk, urn);

        _;

        (uint collateralAfter, ) = vat.urns(ilk, urn);

        require(collateralAfter > collateralBefore);
    }

    /// @notice Checks if ratio is increased after repay
    /// @param _cdpId The Id of the CDP
    modifier repayCheck(uint _cdpId) {
        bytes32 ilk = manager.ilks(_cdpId);

        uint beforeRatio = getRatio(_cdpId, ilk);

        _;

        uint afterRatio = getRatio(_cdpId, ilk);

        require(afterRatio > beforeRatio || afterRatio == 0);
    }

    /// @notice Repay - draws collateral, converts to Dai and repays the debt
    /// @dev Must be called by the DSProxy contract that owns the CDP
    /// @param _data Uint array [cdpId, amount, minPrice, exchangeType, gasCost, 0xPrice]
    /// @param _joinAddr Address of the join contract for the CDP collateral
    /// @param _exchangeAddress Address of 0x exchange that should be called
    /// @param _callData data to call 0x exchange with
    function repay(
        // cdpId, amount, minPrice, exchangeType, gasCost, 0xPrice
        uint[6] memory _data,
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData
    ) public payable repayCheck(_data[0]) {

        address owner = getOwner(manager, _data[0]);
        bytes32 ilk = manager.ilks(_data[0]);

        // uint collDrawn;
        // uint daiAmount;
        // uint daiAfterFee;
        uint[3] memory temp;

        temp[0] = drawCollateral(_data[0], ilk, _joinAddr, _data[1]);

                                // collDrawn, minPrice, exchangeType, 0xPrice
        uint[4] memory swapData = [temp[0], _data[2], _data[3], _data[5]];
        temp[1] = swap(swapData, getCollateralAddr(_joinAddr), DAI_ADDRESS, _exchangeAddress, _callData);
        temp[2] = sub(temp[1], getFee(temp[1], _data[4], owner));

        paybackDebt(_data[0], ilk, temp[2], owner);

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }

        SaverLogger(LOGGER_ADDRESS).LogRepay(_data[0], owner, temp[0], temp[1]);
    }

    /// @notice Boost - draws Dai, converts to collateral and adds to CDP
    /// @dev Must be called by the DSProxy contract that owns the CDP
    /// @param _data Uint array [cdpId, daiAmount, minPrice, exchangeType, gasCost, 0xPrice]
    /// @param _joinAddr Address of the join contract for the CDP collateral
    /// @param _exchangeAddress Address of 0x exchange that should be called
    /// @param _callData data to call 0x exchange with
    function boost(
        // cdpId, daiAmount, minPrice, exchangeType, gasCost, 0xPrice
        uint[6] memory _data,
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData
    ) public payable boostCheck(_data[0]) {
        address owner = getOwner(manager, _data[0]);
        bytes32 ilk = manager.ilks(_data[0]);

        // uint daiDrawn;
        // uint daiAfterFee;
        // uint collateralAmount;
        uint[3] memory temp;

        temp[0] = drawDai(_data[0], ilk, _data[1]);
        temp[1] = sub(temp[0], getFee(temp[0], _data[4], owner));
                                // daiAfterFee, minPrice, exchangeType, 0xPrice
        uint[4] memory swapData = [temp[1], _data[2], _data[3], _data[5]];
        temp[2] = swap(swapData, DAI_ADDRESS, getCollateralAddr(_joinAddr), _exchangeAddress, _callData);

        addCollateral(_data[0], _joinAddr, temp[2]);

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }

        SaverLogger(LOGGER_ADDRESS).LogBoost(_data[0], owner, temp[0], temp[2]);
    }

    /// @notice Draws Dai from the CDP
    /// @dev If _daiAmount is bigger than max available we'll draw max
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    /// @param _daiAmount Amount of Dai to draw
    function drawDai(uint _cdpId, bytes32 _ilk, uint _daiAmount) internal returns (uint) {
        uint rate = Jug(JUG_ADDRESS).drip(_ilk);
        uint daiVatBalance = vat.dai(manager.urns(_cdpId));

        uint maxAmount = getMaxDebt(_cdpId, _ilk);

        if (_daiAmount >= maxAmount) {
            _daiAmount = sub(maxAmount, 1);
        }

        manager.frob(_cdpId, int(0), normalizeDrawAmount(_daiAmount, rate, daiVatBalance));
        manager.move(_cdpId, address(this), toRad(_daiAmount));

        if (vat.can(address(this), address(DAI_JOIN_ADDRESS)) == 0) {
            vat.hope(DAI_JOIN_ADDRESS);
        }

        DaiJoin(DAI_JOIN_ADDRESS).exit(address(this), _daiAmount);

        return _daiAmount;
    }

    /// @notice Adds collateral to the CDP
    /// @param _cdpId Id of the CDP
    /// @param _joinAddr Address of the join contract for the CDP collateral
    /// @param _amount Amount of collateral to add
    function addCollateral(uint _cdpId, address _joinAddr, uint _amount) internal {
        int convertAmount = 0;

        if (_joinAddr == ETH_JOIN_ADDRESS) {
            Join(_joinAddr).gem().deposit{value: _amount}();
            convertAmount = toPositiveInt(_amount);
        } else {
            convertAmount = toPositiveInt(convertTo18(_joinAddr, _amount));
        }

        Join(_joinAddr).gem().approve(_joinAddr, _amount);
        Join(_joinAddr).join(address(this), _amount);

        vat.frob(
            manager.ilks(_cdpId),
            manager.urns(_cdpId),
            address(this),
            address(this),
            convertAmount,
            0
        );

    }

    /// @notice Draws collateral and returns it to DSProxy
    /// @dev If _amount is bigger than max available we'll draw max
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    /// @param _joinAddr Address of the join contract for the CDP collateral
    /// @param _amount Amount of collateral to draw
    function drawCollateral(uint _cdpId, bytes32 _ilk, address _joinAddr, uint _amount) internal returns (uint) {
        uint maxCollateral = getMaxCollateral(_cdpId, _ilk, _joinAddr);

        if (_amount >= maxCollateral) {
            _amount = sub(maxCollateral, 1);
        }

        uint frobAmount = _amount;

        if (Join(_joinAddr).dec() != 18) {
            frobAmount = _amount * (10 ** (18 - Join(_joinAddr).dec()));
        }

        manager.frob(_cdpId, -toPositiveInt(frobAmount), 0);
        manager.flux(_cdpId, address(this), frobAmount);

        Join(_joinAddr).exit(address(this), _amount);

        if (_joinAddr == ETH_JOIN_ADDRESS) {
            Join(_joinAddr).gem().withdraw(_amount); // Weth -> Eth
        }

        return _amount;
    }

    /// @notice Paybacks Dai debt
    /// @dev If the _daiAmount is bigger than the whole debt, returns extra Dai
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    /// @param _daiAmount Amount of Dai to payback
    /// @param _owner Address that owns the DSProxy that owns the CDP
    function paybackDebt(uint _cdpId, bytes32 _ilk, uint _daiAmount, address _owner) internal {
        address urn = manager.urns(_cdpId);

        uint wholeDebt = getAllDebt(VAT_ADDRESS, urn, urn, _ilk);

        if (_daiAmount > wholeDebt) {
            ERC20(DAI_ADDRESS).transfer(_owner, sub(_daiAmount, wholeDebt));
            _daiAmount = wholeDebt;
        }

        daiJoin.dai().approve(DAI_JOIN_ADDRESS, _daiAmount);
        daiJoin.join(urn, _daiAmount);

        manager.frob(_cdpId, 0, normalizePaybackAmount(VAT_ADDRESS, urn, _ilk));
    }

    /// @notice Calculates the fee amount
    /// @param _amount Dai amount that is converted
    /// @param _gasCost Used for Monitor, estimated gas cost of tx
    /// @param _owner The address that controlls the DSProxy that owns the CDP
    function getFee(uint _amount, uint _gasCost, address _owner) internal returns (uint feeAmount) {
        uint fee = SERVICE_FEE;

        if (Discount(DISCOUNT_ADDRESS).isCustomFeeSet(_owner)) {
            fee = Discount(DISCOUNT_ADDRESS).getCustomServiceFee(_owner);
        }

        feeAmount = (fee == 0) ? 0 : (_amount / fee);

        if (_gasCost != 0) {
            uint ethDaiPrice = getPrice(ETH_ILK);
            _gasCost = rmul(_gasCost, ethDaiPrice);

            feeAmount = add(feeAmount, _gasCost);
        }

        // fee can't go over 20% of the whole amount
        if (feeAmount > (_amount / 5)) {
            feeAmount = _amount / 5;
        }

        ERC20(DAI_ADDRESS).transfer(WALLET_ID, feeAmount);
    }

    /// @notice Gets the maximum amount of collateral available to draw
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    /// @param _joinAddr Joind address of collateral
    /// @dev Substracts 10 wei to aviod rounding error later on
    function getMaxCollateral(uint _cdpId, bytes32 _ilk, address _joinAddr) public view returns (uint) {
        uint price = getPrice(_ilk);

        (uint collateral, uint debt) = getCdpInfo(manager, _cdpId, _ilk);

        (, uint mat) = Spotter(SPOTTER_ADDRESS).ilks(_ilk);

        uint maxCollateral = sub(sub(collateral, (div(mul(mat, debt), price))), 10);

        uint normalizeMaxCollateral = maxCollateral;

        if (Join(_joinAddr).dec() != 18) {
            normalizeMaxCollateral = maxCollateral / (10 ** (18 - Join(_joinAddr).dec()));
        }

        return normalizeMaxCollateral;
    }

    /// @notice Gets the maximum amount of debt available to generate
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    /// @dev Substracts 10 wei to aviod rounding error later on
    function getMaxDebt(uint _cdpId, bytes32 _ilk) public virtual view returns (uint) {
        uint price = getPrice(_ilk);

        (, uint mat) = spotter.ilks(_ilk);
        (uint collateral, uint debt) = getCdpInfo(manager, _cdpId, _ilk);

        return sub(sub(div(mul(collateral, price), mat), debt), 10);
    }

    /// @notice Gets a price of the asset
    /// @param _ilk Ilk of the CDP
    function getPrice(bytes32 _ilk) public view returns (uint) {
        (, uint mat) = spotter.ilks(_ilk);
        (,,uint spot,,) = vat.ilks(_ilk);

        return rmul(rmul(spot, spotter.par()), mat);
    }

    /// @notice Gets CDP ratio
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    function getRatio(uint _cdpId, bytes32 _ilk) public view returns (uint) {
        uint price = getPrice( _ilk);

        (uint collateral, uint debt) = getCdpInfo(manager, _cdpId, _ilk);

        if (debt == 0) return 0;

        return rdiv(wmul(collateral, price), debt);
    }

    /// @notice Gets CDP info (collateral, debt, price, ilk)
    /// @param _cdpId Id of the CDP
    function getCdpDetailedInfo(uint _cdpId) public view returns (uint collateral, uint debt, uint price, bytes32 ilk) {
        address urn = manager.urns(_cdpId);
        ilk = manager.ilks(_cdpId);

        (collateral, debt) = vat.urns(ilk, urn);
        (,uint rate,,,) = vat.ilks(ilk);

        debt = rmul(debt, rate);
        price = getPrice(ilk);
    }

}
