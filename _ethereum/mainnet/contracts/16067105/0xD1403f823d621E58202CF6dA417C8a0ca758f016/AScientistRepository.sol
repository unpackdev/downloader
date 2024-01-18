// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "./SafeMath.sol";
import "./Multicall.sol";
import "./Counters.sol";
import "./EnumerableSet.sol";
import "./IScientistRepository.sol";
import "./ScientistData.sol";

/**
 * @title Interface for interaction with particular scientist
 */
abstract contract AScientistRepository is IScientistRepository, Multicall {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    //  are meta scientists
    mapping(uint256 => ScientistData.Scientist) scientists;
    mapping(address => uint256[]) private userIndexesArray;

    function _addScientist(address _account, uint256 _tokenId) internal {
        address _owner = ownerOf(_tokenId);
        require(_owner == _account, "Account is not the owner");
        userIndexesArray[_account].push(_tokenId);
	    emit AddScientist(_tokenId, scientists[_tokenId], block.timestamp);
    }

    function _removeScientist(address _account, uint256 _tokenId) internal {
        address _owner = ownerOf(_tokenId);
        require(_owner != address(0), "Token is not exists");
        require(_owner == _account, "Account is not the owner");


        uint256 indexInArray = _getIndexInScientistsArray(_account, _tokenId);
        require(indexInArray != type(uint256).max, "No such index");
        userIndexesArray[_account][indexInArray] = userIndexesArray[_account][userIndexesArray[_account].length - 1];
        userIndexesArray[_account].pop();
        emit RemoveScientist(_tokenId, scientists[_tokenId], block.timestamp);
    }

    function _getIndexInScientistsArray(address _user, uint256 _value)
        internal
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < userIndexesArray[_user].length; i++) {
            if (userIndexesArray[_user][i] == _value) {
                return i;
            }
        }
        return type(uint256).max;
    }

    /**
     * @dev Returns meta scientist id's for particular user
     */
    function getUserMetascientistsIndexes(address _user)
        external
        view
        override
        returns (uint256[] memory)
    {
        return userIndexesArray[_user];
    }

    function _updateScientist(
        uint256 _tokenId,
        ScientistData.Scientist memory _scientist,
        address _account
    ) internal {
        ScientistData.Scientist memory _oldscientist = scientists[_tokenId];
        require(_account != address(0), "Token not exists");
        require(_account == ownerOf(_tokenId), "wrong owner of Scientist");
        scientists[_tokenId] = _scientist;
        emit UpdateScientist(_tokenId, _oldscientist, _scientist, block.timestamp);
    }

    function getScientist(uint256 _tokenId)
        external
        view
        override
        returns (ScientistData.Scientist memory)
    {
        return scientists[_tokenId];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address);
}
