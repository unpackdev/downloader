// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./Ownable.sol";
import "./ISportManager.sol";
import "./String.sol";

contract SportManager is ISportManager, Ownable {
    using String for string;

    uint256 private _currentGameId = 0;
    uint256 private _currentAttributeId = 0;

    Game[] private games;
    Attribute[] private attributes;
    mapping(uint256 => mapping(uint256 => bool)) private supportedAttribute;

    function addNewGame(
        string memory name,
        bool active,
        ProviderGameData provider
    ) external override onlyOwner returns (uint256 gameId) {
        gameId = _currentGameId;
        _currentGameId++;
        games.push(Game(gameId, active, name, provider));
        emit AddNewGame(_currentGameId, name);
        if (active) {
            emit ActiveGame(_currentGameId);
        } else {
            emit DeactiveGame(_currentGameId);
        }
    }

    function updateGame(
        uint256 _gameId,
        string memory _newName,
        ProviderGameData _provider
    ) external onlyOwner {
        games[_gameId].name = _newName;
        games[_gameId].provider = _provider;
    }

    function getGameById(uint256 id)
        external
        view
        override
        returns (Game memory)
    {
        return games[id];
    }

    function deactiveGame(uint256 gameId) external override onlyOwner {
        Game storage game = games[gameId];
        require(game.active, "SM: deactived");
        game.active = false;
        emit DeactiveGame(gameId);
    }

    function activeGame(uint256 gameId) external override onlyOwner {
        Game storage game = games[gameId];
        require(!game.active, "SM: actived");
        game.active = true;
        emit ActiveGame(gameId);
    }

    function addNewAttribute(Attribute[] memory attribute)
        external
        override
        onlyOwner
    {
        uint256 attributeId = _currentAttributeId;
        for (uint256 i = 0; i < attribute.length; i++) {
            attributes.push(
                Attribute(
                    attributeId,
                    attribute[i].teamOption,
                    attribute[i].attributeSupportFor,
                    attribute[i].name
                )
            );
            attributeId++;
        }
        _currentAttributeId = attributeId;
    }

    function updateAttribute(
        uint256 _attributeId,
        string memory _name,
        bool _teamOption,
        AttributeSupportFor _attributeSupportFor
    ) external onlyOwner {
        if (!attributes[_attributeId].name.compare(_name)) {
            attributes[_attributeId].name = _name;
        }
        if (attributes[_attributeId].teamOption != _teamOption) {
            attributes[_attributeId].teamOption = _teamOption;
        }
        if (
            attributes[_attributeId].attributeSupportFor != _attributeSupportFor
        ) {
            attributes[_attributeId].attributeSupportFor = _attributeSupportFor;
        }
    }

    function setSupportedAttribute(
        uint256 gameId,
        uint256[] memory attributeIds,
        bool isSupported
    ) external override onlyOwner {
        require(gameId < _currentGameId);
        for (uint256 i = 0; i < attributeIds.length; i++) {
            uint256 attributeId = attributeIds[i];
            if (attributeId < _currentAttributeId) {
                supportedAttribute[gameId][attributeId] = isSupported;
            }
        }
    }

    function checkSupportedGame(uint256 gameId)
        external
        view
        override
        returns (bool)
    {
        if (gameId < _currentGameId) {
            Game memory game = games[gameId];
            return game.active;
        } else {
            return false;
        }
    }

    function checkSupportedAttribute(uint256 gameId, uint256 attributeId)
        external
        view
        override
        returns (bool)
    {
        return supportedAttribute[gameId][attributeId];
    }

    function getAllGame() external view returns (Game[] memory) {
        return games;
    }

    function getAllAttribute() external view returns (Attribute[] memory) {
        return attributes;
    }

    function getAttributesSupported(uint256 gameId)
        external
        view
        returns (Attribute[] memory result, uint256 size)
    {
        result = new Attribute[](attributes.length);
        size = 0;
        for (uint256 i = 0; i < attributes.length; i++) {
            Attribute memory attribute = attributes[i];
            if (supportedAttribute[gameId][attribute.id]) {
                result[size] = attribute;
                size++;
            }
        }
    }

    function getAttributeById(uint256 attributeId)
        external
        view
        override
        returns (Attribute memory)
    {
        return attributes[attributeId];
    }

    function checkTeamOption(uint256 attributeId)
        external
        view
        override
        returns (bool)
    {
        if (attributeId < _currentAttributeId) {
            Attribute memory attribute = attributes[attributeId];
            return attribute.teamOption;
        } else {
            return false;
        }
    }
}
