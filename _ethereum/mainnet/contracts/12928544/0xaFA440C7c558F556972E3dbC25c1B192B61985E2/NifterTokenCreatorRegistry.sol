// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./INifterRoyaltyRegistry.sol";
import "./INifterTokenCreatorRegistry.sol";
import "./INifter.sol";

/**
 * @title IERC1155 Non-Fungible Token Creator basic interface
 */
contract NifterTokenCreatorRegistry is Ownable, INifterTokenCreatorRegistry {
    using SafeMath for uint256;

    /////////////////////////////////////////////////////////////////////////
    // State Variables
    /////////////////////////////////////////////////////////////////////////

    // Mapping of ERC1155 token to it's creator.
    mapping(uint256 => address payable)
    private tokenCreators;
    address public nifter;

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
    // setNifter
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Set nifter contract address
     * @param _nifter uint256 ID of the token
     */
    function setNifter(address _nifter) external onlyOwner {
        nifter = _nifter;
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

        require(msg.sender == nifter || msg.sender == owner(), "setTokenCreator::only nifter and owner allowed");

        tokenCreators[_tokenId] = _creator;
    }

    /**
     * @dev restore data from old contract, only call by owner
     * @param _oldAddress address of old contract.
     * @param _oldNifterAddress get the token ids from the old nifter contract.
     * @param _startIndex start index of array
     * @param _endIndex end index of array
     */
    function restore(address _oldAddress, address _oldNifterAddress, uint256 _startIndex, uint256 _endIndex) external onlyOwner {
        NifterTokenCreatorRegistry oldContract = NifterTokenCreatorRegistry(_oldAddress);
        INifter oldNifterContract = INifter(_oldNifterAddress);

        uint256 length = oldNifterContract.getTokenIdsLength();
        require(_startIndex < length, "wrong start index");
        require(_endIndex <= length, "wrong end index");

        for (uint i = _startIndex; i < _endIndex; i++) {
            uint256 tokenId = oldNifterContract.getTokenId(i);
            if (tokenCreators[tokenId] != address(0)) {
                tokenCreators[tokenId] = oldContract.tokenCreator(tokenId);
            }
        }
    }

}
