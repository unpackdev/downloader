// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./INafterRoyaltyRegistry.sol";
import "./INafterTokenCreatorRegistry.sol";
import "./INafter.sol";

/**
 * @title IERC1155 Non-Fungible Token Creator basic interface
 */
contract NafterTokenCreatorRegistry is Ownable, INafterTokenCreatorRegistry {
    using SafeMath for uint256;

    /////////////////////////////////////////////////////////////////////////
    // State Variables
    /////////////////////////////////////////////////////////////////////////

    // Mapping of ERC1155 token to it's creator.
    mapping(uint256 => address payable)
    private tokenCreators;
    address public nafter;

    /////////////////////////////////////////////////////////////////////////
    // tokenCreator
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Gets the creator of the token
     * @param _tokenId uint256 ID of the token
     * @return address of the creator
     */
    function tokenCreator(uint256 _tokenId)
    external
    view
    override
    returns (address payable)
    {
        if (tokenCreators[_tokenId] != address(0)) {
            return tokenCreators[_tokenId];
        }

        return address(0);
    }

    /////////////////////////////////////////////////////////////////////////
    // setNafter
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Set nafter contract address
     * @param _nafter uint256 ID of the token
     */
    function setNafter(address _nafter) external onlyOwner {
        nafter = _nafter;
    }

    /////////////////////////////////////////////////////////////////////////
    // setTokenCreator
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Sets the creator of the token
     * @param _tokenId uint256 ID of the token
     * @param _creator address of the creator for the token
     */
    function setTokenCreator(
        uint256 _tokenId,
        address payable _creator
    ) external override {
        require(
            _creator != address(0),
            "setTokenCreator::Cannot set null address as creator"
        );

        require(msg.sender == nafter || msg.sender == owner(), "setTokenCreator::only nafter and owner allowed");

        tokenCreators[_tokenId] = _creator;
    }

    /**
     * @dev restore data from old contract, only call by owner
     * @param _oldAddress address of old contract.
     * @param _oldNafterAddress get the token ids from the old nafter contract.
     * @param _startIndex start index of array
     * @param _endIndex end index of array
     */
    function restore(address _oldAddress, address _oldNafterAddress, uint256 _startIndex, uint256 _endIndex) external onlyOwner {
        NafterTokenCreatorRegistry oldContract = NafterTokenCreatorRegistry(_oldAddress);
        INafter oldNafterContract = INafter(_oldNafterAddress);

        uint256 length = oldNafterContract.getTokenIdsLength();
        require(_startIndex < length, "wrong start index");
        require(_endIndex <= length, "wrong end index");

        for (uint i = _startIndex; i < _endIndex; i++) {
            uint256 tokenId = oldNafterContract.getTokenId(i);
            if (tokenCreators[tokenId] != address(0)) {
                tokenCreators[tokenId] = oldContract.tokenCreator(tokenId);
            }
        }
    }

}
