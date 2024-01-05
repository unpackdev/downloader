pragma solidity ^0.6.0;

import "./DSMath.sol";
import "./DSProxy.sol";
import "./IBasicTokenAdapters.sol";
import "./ISAFEManager.sol";
import "./ISAFEEngine.sol";
import "./ITaxCollector.sol";

/// @title Helper methods for RAISaverProxy
contract RAISaverProxyHelper is DSMath {

    enum ManagerType { RAI }

    /// @notice Returns a normalized debt _amount based on the current rate
    /// @param _amount Amount of dai to be normalized
    /// @param _rate Current rate of the stability fee
    /// @param _daiVatBalance Balance od Dai in the Vat for that Safe
    function normalizeDrawAmount(uint _amount, uint _rate, uint _daiVatBalance) internal pure returns (int dart) {
        if (_daiVatBalance < mul(_amount, RAY)) {
            dart = toPositiveInt(sub(mul(_amount, RAY), _daiVatBalance) / _rate);
            dart = mul(uint(dart), _rate) < mul(_amount, RAY) ? dart + 1 : dart;
        }
    }

    /// @notice Converts a number to Rad percision
    /// @param _wad The input number in wad percision
    function toRad(uint _wad) internal pure returns (uint) {
        return mul(_wad, 10 ** 27);
    }

    /// @notice Converts a number to 18 decimal percision
    /// @param _joinAddr Join address of the collateral
    /// @param _amount Number to be converted
    function convertTo18(address _joinAddr, uint256 _amount) internal view returns (uint256) {
        return mul(_amount, 10 ** (18 - IBasicTokenAdapters(_joinAddr).decimals()));
    }

    /// @notice Converts a uint to int and checks if positive
    /// @param _x Number to be converted
    function toPositiveInt(uint _x) internal pure returns (int y) {
        y = int(_x);
        require(y >= 0, "int-overflow");
    }

    /// @notice Gets Dai amount in Vat which can be added to Safe
    /// @param _safeEngine Address of Vat contract
    /// @param _urn Urn of the Safe
    /// @param _collType CollType of the Safe
    function normalizePaybackAmount(address _safeEngine, address _urn, bytes32 _collType) internal view returns (int amount) {
        uint dai = ISAFEEngine(_safeEngine).coinBalance(_urn);

        (, uint rate,,,,) = ISAFEEngine(_safeEngine).collateralTypes(_collType);
        (, uint art) = ISAFEEngine(_safeEngine).safes(_collType, _urn);

        amount = toPositiveInt(dai / rate);
        amount = uint(amount) <= art ? - amount : - toPositiveInt(art);
    }

    /// @notice Gets delta debt generated (Total Safe debt minus available safeHandler COIN balance)
    /// @param safeEngine address
    /// @param taxCollector address
    /// @param safeHandler address
    /// @param collateralType bytes32
    /// @return deltaDebt
    function _getGeneratedDeltaDebt(
        address safeEngine,
        address taxCollector,
        address safeHandler,
        bytes32 collateralType,
        uint wad
    ) internal returns (int deltaDebt) {
        // Updates stability fee rate
        uint rate = ITaxCollector(taxCollector).taxSingle(collateralType);
        require(rate > 0, "invalid-collateral-type");

        // Gets COIN balance of the handler in the safeEngine
        uint coin = ISAFEEngine(safeEngine).coinBalance(safeHandler);

        // If there was already enough COIN in the safeEngine balance, just exits it without adding more debt
        if (coin < mul(wad, RAY)) {
            // Calculates the needed deltaDebt so together with the existing coins in the safeEngine is enough to exit wad amount of COIN tokens
            deltaDebt = toPositiveInt(sub(mul(wad, RAY), coin) / rate);
            // This is neeeded due lack of precision. It might need to sum an extra deltaDebt wei (for the given COIN wad amount)
            deltaDebt = mul(uint(deltaDebt), rate) < mul(wad, RAY) ? deltaDebt + 1 : deltaDebt;
        }
    }

    function _getRepaidDeltaDebt(
        address safeEngine,
        uint coin,
        address safe,
        bytes32 collateralType
    ) internal view returns (int deltaDebt) {
        // Gets actual rate from the safeEngine
        (, uint rate,,,,) = ISAFEEngine(safeEngine).collateralTypes(collateralType);
        require(rate > 0, "invalid-collateral-type");

        // Gets actual generatedDebt value of the safe
        (, uint generatedDebt) = ISAFEEngine(safeEngine).safes(collateralType, safe);

        // Uses the whole coin balance in the safeEngine to reduce the debt
        deltaDebt = toPositiveInt(coin / rate);
        // Checks the calculated deltaDebt is not higher than safe.generatedDebt (total debt), otherwise uses its value
        deltaDebt = uint(deltaDebt) <= generatedDebt ? - deltaDebt : - toPositiveInt(generatedDebt);
    }

    /// @notice Gets the whole debt of the Safe
    /// @param _safeEngine Address of Vat contract
    /// @param _usr Address of the Dai holder
    /// @param _urn Urn of the Safe
    /// @param _collType CollType of the Safe
    function getAllDebt(address _safeEngine, address _usr, address _urn, bytes32 _collType) internal view returns (uint daiAmount) {
        (, uint rate,,,,) = ISAFEEngine(_safeEngine).collateralTypes(_collType);
        (, uint art) = ISAFEEngine(_safeEngine).safes(_collType, _urn);
        uint dai = ISAFEEngine(_safeEngine).coinBalance(_usr);

        uint rad = sub(mul(art, rate), dai);
        daiAmount = rad / RAY;

        daiAmount = mul(daiAmount, RAY) < rad ? daiAmount + 1 : daiAmount;
    }

    /// @notice Gets the token address from the Join contract
    /// @param _joinAddr Address of the Join contract
    function getCollateralAddr(address _joinAddr) internal view returns (address) {
        return address(IBasicTokenAdapters(_joinAddr).collateral());
    }

    /// @notice Checks if the join address is one of the Ether coll. types
    /// @param _joinAddr Join address to check
    function isEthJoinAddr(address _joinAddr) internal view returns (bool) {
        // if it's dai_join_addr don't check gem() it will fail
        if (_joinAddr == 0x0A5653CCa4DB1B6E265F47CAf6969e64f1CFdC45) return false;

        // if coll is weth it's and eth type coll
        if (address(IBasicTokenAdapters(_joinAddr).collateral()) == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) {
            return true;
        }

        return false;
    }

    /// @notice Gets Safe info (collateral, debt)
    /// @param _manager Manager contract
    /// @param _safeId Id of the Safe
    /// @param _collType CollType of the Safe
    function getSafeInfo(ISAFEManager _manager, uint _safeId, bytes32 _collType) public view returns (uint, uint) {
        address vat = _manager.safeEngine();
        address urn = _manager.safes(_safeId);

        (uint collateral, uint debt) = ISAFEEngine(vat).safes(_collType, urn);
        (,uint rate,,,,) = ISAFEEngine(vat).collateralTypes(_collType);

        return (collateral, rmul(debt, rate));
    }

    /// @notice Address that owns the DSProxy that owns the Safe
    /// @param _manager Manager contract
    /// @param _safeId Id of the Safe
    function getOwner(ISAFEManager _manager, uint _safeId) public view returns (address) {
        DSProxy proxy = DSProxy(uint160(_manager.ownsSAFE(_safeId)));

        return proxy.owner();
    }

    /// @notice Based on the manager type returns the address
    /// @param _managerType Type of vault manager to use
    function getManagerAddr(ManagerType _managerType) public pure returns (address) {
        if (_managerType == ManagerType.RAI) {
            return 0xEfe0B4cA532769a3AE758fD82E1426a03A94F185;
        }
    }
}
