// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./LibAppStorage.sol";
import "./LibNftCommon.sol";
import "./LibDiamond.sol";
import "./IERC20.sol";

contract GameFacet is Modifiers {
    event GameManagerAdded(address indexed _newGameManager);
    event GameManagerRemoved(address indexed _removedGameManager);
    event NameSet(uint256 indexed _tokenId, string _oldName, string _newName);

    function setNftName(uint256 _tokenId, string calldata _name) external onlyNftOwner(_tokenId) {
        string memory lowerName = LibNftCommon.validateAndLowerName(_name);
        string memory existingName = s.nfts[_tokenId].name;

        require(!s.nftNamesUsed[lowerName], "GameFacet: Nft name used already");

        if (bytes(existingName).length > 0) {
            delete s.nftNamesUsed[LibNftCommon.validateAndLowerName(existingName)];
        }

        s.nftNamesUsed[lowerName] = true;
        s.nfts[_tokenId].name = _name;

        emit NameSet(_tokenId, existingName, _name);
    }

    function addGameManagers(address[] calldata _newGameManagers) external onlyOwner {
        for (uint256 i; i < _newGameManagers.length; i++) {
            address newGameManager = _newGameManagers[i];
            s.gameManagers[newGameManager] = true;
            
            emit GameManagerAdded(newGameManager);
        }
    }

    function removeGameManagers(address[] calldata _gameManagersToRemove) external onlyOwner {
         for (uint256 i; i < _gameManagersToRemove.length; i++) {
            address gameManager = _gameManagersToRemove[i];
            require(s.gameManagers[gameManager] == true, "GameFacet: GameManager does not exist or already removed");
            s.gameManagers[gameManager] = false;
            
            emit GameManagerRemoved(gameManager);
        }
    }
}
