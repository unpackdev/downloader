// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IOneWar {
    struct Settlement {
        uint32 soldiers;
        uint32 towers;
        uint32 catapults;
        uint256 goldRedeemed;
        uint256 genesis;
        uint256 seed;
        address founder;
        string motto;
        uint32 glory;
        uint256 sanctuary;
        uint256 treasure;
        uint256 miners;
    }

    struct DefenderAssets {
        uint32 soldiers;
        uint32 towers;
    }

    struct AttackerAssets {
        uint32 soldiers;
        uint32 catapults;
    }

    struct ArmyMove {
        uint256 source;
        uint256 destination;
        uint32 soldiers;
        uint32 catapults;
    }

    event Scout(address _by, uint256 indexed _blockNumber);

    event Settle(address _by, uint256 indexed _settlement);

    event Burn(uint256 indexed _settlement);

    event BuildArmy(uint256 indexed _settlement, uint32 _soldiers, uint32 _towers, uint32 _catapults);

    event MoveArmy(
        uint256 indexed _sourceSettlement,
        uint256 indexed _destinationSettlement,
        uint32 _soldiers,
        uint32 _catapults
    );

    event SuccessfulAttack(uint256 indexed _attackingSettlement, uint256 indexed _defendingSettlement);

    event FailedAttack(uint256 indexed _attackingSettlement, uint256 indexed _defendingSettlement);

    event ChangeMotto(uint256 indexed _settlement, string _motto);

    function hasWarCountdownBegun() external view returns (bool);

    function scout() external payable;

    function settle() external;

    function burn(uint256 _settlement) external;

    function commenceWarCountdown() external;

    function redeemableGold(uint256 _settlement) external view returns (uint256);

    function redeemGold(uint256[] calldata _settlements) external;

    function armyCost(uint32 _soldiers, uint32 _towers, uint32 _catapults) external pure returns (uint256);

    function buildArmy(uint256 _settlement, uint32 _soldiers, uint32 _towers, uint32 _catapults) external;

    function moveArmy(uint256 _sourceSettlement, uint256 _destinationSettlement, uint32 _soldiers, uint32 _catapults) external;

    function multiMoveArmy(ArmyMove[] calldata _moves) external;

    function attack(uint256 _attackingSettlement, uint256 _defendingSettlement, uint32 _soldiers, uint32 _catapults) external;

    function blocksUntilSanctuaryEnds(uint256 _settlement) external view returns (uint256);

    function blocksUntilWarBegins() external view returns (uint256);

    function changeMotto(uint256 _settlement, string memory _newMotto) external;

    function redeemFundsToOneWarTreasury() external;

    function settlementTraits(uint256 _settlement) external view returns (Settlement memory);

    function isRulerOrCoruler(address _address, uint256 _settlement) external view returns (bool);

    function isSettled(uint256 _settlement) external view returns (bool);
}
