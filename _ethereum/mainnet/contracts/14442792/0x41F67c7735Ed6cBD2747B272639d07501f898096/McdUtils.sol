//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./DSMath.sol";
import "./ManagerLike.sol";
import "./ICommand.sol";
import "./Mcd.sol";
import "./BotLike.sol";

import "./ServiceRegistry.sol";

/// @title Getter contract for Vault info from Maker protocol
contract McdUtils is DSMath {
    address public immutable serviceRegistry;
    IERC20 private immutable DAI;
    address private immutable daiJoin;
    address public immutable jug;

    constructor(
        address _serviceRegistry,
        IERC20 _dai,
        address _daiJoin,
        address _jug
    ) {
        serviceRegistry = _serviceRegistry;
        DAI = _dai;
        daiJoin = _daiJoin;
        jug = _jug;
    }

    function toInt256(uint256 x) internal pure returns (int256 y) {
        y = int256(x);
        require(y >= 0, "int256-overflow");
    }

    function _getDrawDart(
        address vat,
        address urn,
        bytes32 ilk,
        uint256 wad
    ) internal returns (int256 dart) {
        // Updates stability fee rate
        uint256 rate = IJug(jug).drip(ilk);

        // Gets DAI balance of the urn in the vat
        uint256 dai = IVat(vat).dai(urn);

        // If there was already enough DAI in the vat balance, just exits it without adding more debt
        if (dai < mul(wad, RAY)) {
            // Calculates the needed dart so together with the existing dai in the vat is enough to exit wad amount of DAI tokens
            dart = toInt256(sub(mul(wad, RAY), dai) / rate);
            // This is neeeded due lack of precision. It might need to sum an extra dart wei (for the given DAI wad amount)
            dart = mul(uint256(dart), rate) < mul(wad, RAY) ? dart + 1 : dart;
        }
    }

    function drawDebt(
        uint256 borrowedDai,
        uint256 cdpId,
        ManagerLike manager,
        address sendTo
    ) external {
        address urn = manager.urns(cdpId);
        address vat = manager.vat();

        manager.frob(cdpId, 0, _getDrawDart(vat, urn, manager.ilks(cdpId), borrowedDai));
        manager.move(cdpId, address(this), mul(borrowedDai, RAY));

        if (IVat(vat).can(address(this), daiJoin) == 0) {
            IVat(vat).hope(daiJoin);
        }

        IJoin(daiJoin).exit(sendTo, borrowedDai);
    }
}
