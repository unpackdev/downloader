// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ISportManager {
    struct Game {
        uint256 id;
        bool active;
        string name;
        ProviderGameData provider;
    }

    struct Attribute {
        uint256 id;
        bool teamOption;
        AttributeSupportFor attributeSupportFor;
        string name;
    }

    enum ProviderGameData {
        GameScoreKeeper,
        SportRadar
    }

    enum AttributeSupportFor {
        None,
        Team,
        Player,
        All
    }

    event AddNewGame(uint256 indexed gameId, string name);
    event DeactiveGame(uint256 indexed gameId);
    event ActiveGame(uint256 indexed gameId);
    event AddNewAttribute(uint256 indexed attributeId, string name);

    function getGameById(uint256 id) external view returns (Game memory);

    function addNewGame(
        string memory name,
        bool active,
        ProviderGameData provider
    ) external returns (uint256 gameId);

    function deactiveGame(uint256 gameId) external;

    function activeGame(uint256 gameId) external;

    function addNewAttribute(Attribute[] calldata attribute) external;

    function setSupportedAttribute(
        uint256 gameId,
        uint256[] memory attributeIds,
        bool isSupported
    ) external;

    function checkSupportedGame(uint256 gameId) external view returns (bool);

    function checkSupportedAttribute(uint256 gameId, uint256 attributeId)
        external
        view
        returns (bool);

    function checkTeamOption(uint256 attributeId) external view returns (bool);

    function getAttributeById(uint256 attributeId)
        external
        view
        returns (Attribute calldata);
}
