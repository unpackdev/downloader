// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./INafterRoyaltyRegistry.sol";
import "./INafter.sol";

/**
 * @title IERC1155 Non-Fungible Token Creator basic interface
 */
contract NafterRoyaltyRegistry is Ownable, INafterRoyaltyRegistry {
    using SafeMath for uint256;

    /////////////////////////////////////////////////////////////////////////
    // State Variables
    /////////////////////////////////////////////////////////////////////////

    // Mapping of ERC1155 contract to royalty percentage for all NFTs,  3 == 3%
    uint8 private contractRoyaltyPercentage;

    // Mapping of ERC1155 creator to royalty percentage for all NFTs.
    mapping(address => uint8) public creatorRoyaltyPercentage;
    mapping(address => bool) private creatorRigistered;
    address[] public creators;

    address public nafter;

    // Mapping of ERC1155 token to royalty percentage for all NFTs.
    mapping(uint256 => uint8)
    private tokenRoyaltyPercentage;

    IERC1155TokenCreator public iERC1155TokenCreator;

    /////////////////////////////////////////////////////////////////////////
    // Constructor
    /////////////////////////////////////////////////////////////////////////
    constructor(address _iERC1155TokenCreator) public {
        require(
            _iERC1155TokenCreator != address(0),
            "constructor::Cannot set the null address as an _iERC1155TokenCreator"
        );
        iERC1155TokenCreator = IERC1155TokenCreator(_iERC1155TokenCreator);
    }

    /////////////////////////////////////////////////////////////////////////
    // setIERC1155TokenCreator
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Set an address as an IERC1155TokenCreator
     * @param _contractAddress address of the IERC1155TokenCreator contract
     */
    function setIERC1155TokenCreator(address _contractAddress)
    external
    onlyOwner
    {
        require(
            _contractAddress != address(0),
            "setIERC1155TokenCreator::_contractAddress cannot be null"
        );

        iERC1155TokenCreator = IERC1155TokenCreator(_contractAddress);
    }

    /////////////////////////////////////////////////////////////////////////
    // getERC1155TokenRoyaltyPercentage
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Get the royalty fee percentage for a specific ERC1155 contract.
     * @param _tokenId uint256 token ID.
     * @return uint8 wei royalty fee.
     */
    function getTokenRoyaltyPercentage(
        uint256 _tokenId
    ) public view override returns (uint8) {
        if (tokenRoyaltyPercentage[_tokenId] > 0) {
            return tokenRoyaltyPercentage[_tokenId];
        }
        address creator =
        iERC1155TokenCreator.tokenCreator(_tokenId);
        if (creatorRoyaltyPercentage[creator] > 0) {
            return creatorRoyaltyPercentage[creator];
        }
        return contractRoyaltyPercentage;
    }

    /////////////////////////////////////////////////////////////////////////
    // getPercentageForTokenRoyalty
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Gets the royalty percentage set for an ERC1155 token
     * @param _tokenId uint256 token ID.
     * @return uint8 wei royalty fee.
     */
    function getPercentageForTokenRoyalty(
        uint256 _tokenId
    ) external view returns (uint8) {
        return tokenRoyaltyPercentage[_tokenId];
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
    // setPercentageForTokenRoyalty
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Sets the royalty percentage set for an Nafter token
     * Requirements:

     * - `_percentage` must be <= 100.
     * - only the owner of this contract or the creator can call this method.
     * @param _tokenId uint256 token ID.
     * @param _percentage uint8 wei royalty fee.
     */
    function setPercentageForTokenRoyalty(
        uint256 _tokenId,
        uint8 _percentage
    ) external override returns (uint8) {
        require(
            msg.sender == iERC1155TokenCreator.tokenCreator(_tokenId) ||
            msg.sender == owner() ||
            msg.sender == nafter,
            "setPercentageForTokenRoyalty::Must be contract owner or creator or nafter"
        );
        require(
            _percentage <= 100,
            "setPercentageForTokenRoyalty::_percentage must be <= 100"
        );
        tokenRoyaltyPercentage[_tokenId] = _percentage;
    }

    /////////////////////////////////////////////////////////////////////////
    // creatorsLength
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Gets creator length
     * @return uint256 length.
     */
    function creatorsLength() external view returns (uint256){
        return creators.length;
    }
    /////////////////////////////////////////////////////////////////////////
    // getPercentageForSetERC1155CreatorRoyalty
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Gets the royalty percentage set for an ERC1155 creator
     * @param _tokenId uint256 token ID.
     * @return uint8 wei royalty fee.
     */
    function getPercentageForSetERC1155CreatorRoyalty(
        uint256 _tokenId
    ) external view returns (uint8) {
        address creator =
        iERC1155TokenCreator.tokenCreator(_tokenId);
        return creatorRoyaltyPercentage[creator];
    }

    /////////////////////////////////////////////////////////////////////////
    // setPercentageForSetERC1155CreatorRoyalty
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Sets the royalty percentage set for an ERC1155 creator
     * Requirements:

     * - `_percentage` must be <= 100.
     * - only the owner of this contract or the creator can call this method.
     * @param _creatorAddress address token ID.
     * @param _percentage uint8 wei royalty fee.
     */
    function setPercentageForSetERC1155CreatorRoyalty(
        address _creatorAddress,
        uint8 _percentage
    ) external returns (uint8) {
        require(
            msg.sender == _creatorAddress || msg.sender == owner(),
            "setPercentageForSetERC1155CreatorRoyalty::Must be owner or creator"
        );
        require(
            _percentage <= 100,
            "setPercentageForSetERC1155CreatorRoyalty::_percentage must be <= 100"
        );

        if (creatorRigistered[_creatorAddress] == false) {
            creators.push(_creatorAddress);
        }
        creatorRigistered[_creatorAddress] = true;
        creatorRoyaltyPercentage[_creatorAddress] = _percentage;

    }

    /////////////////////////////////////////////////////////////////////////
    // getPercentageForSetERC1155ContractRoyalty
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Gets the royalty percentage set for an ERC1155 contract
     * @return uint8 wei royalty fee.
     */
    function getPercentageForSetERC1155ContractRoyalty()
    external
    view
    returns (uint8)
    {
        return contractRoyaltyPercentage;
    }

    /**
     * @dev restore data from old contract, only call by owner
     * @param _oldAddress address of old contract.
     * @param _oldNafterAddress get the token ids from the old nafter contract.
     * @param _startIndex start index of array
     * @param _endIndex end index of array
     */
    function restore(address _oldAddress, address _oldNafterAddress, uint256 _startIndex, uint256 _endIndex) external onlyOwner {
        NafterRoyaltyRegistry oldContract = NafterRoyaltyRegistry(_oldAddress);
        INafter oldNafterContract = INafter(_oldNafterAddress);

        uint256 length = oldNafterContract.getTokenIdsLength();
        require(_startIndex < length, "wrong start index");
        require(_endIndex <= length, "wrong end index");

        for (uint i = _startIndex; i < _endIndex; i++) {
            uint256 tokenId = oldNafterContract.getTokenId(i);
            uint8 percentage = oldContract.getPercentageForTokenRoyalty(tokenId);
            if (percentage != 0) {
                tokenRoyaltyPercentage[tokenId] = percentage;
            }
        }

        for (uint i; i < oldContract.creatorsLength(); i++) {
            address creator = oldContract.creators(i);
            creators.push(creator);
            creatorRigistered[creator] = true;
            creatorRoyaltyPercentage[creator] = oldContract.creatorRoyaltyPercentage(creator);
        }
    }

    /////////////////////////////////////////////////////////////////////////
    // setPercentageForSetERC1155ContractRoyalty
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Sets the royalty percentage set for an ERC1155 token
     * Requirements:

     * - `_percentage` must be <= 100.
     * - only the owner of this contract.
     * @param _percentage uint8 wei royalty fee.
     */
    function setPercentageForSetERC1155ContractRoyalty(
        uint8 _percentage
    ) external onlyOwner returns (uint8) {
        require(
            _percentage <= 100,
            "setPercentageForSetERC1155ContractRoyalty::_percentage must be <= 100"
        );
        contractRoyaltyPercentage = _percentage;
    }

    /////////////////////////////////////////////////////////////////////////
    // calculateRoyaltyFee
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Utililty function to calculate the royalty fee for a token.
     * @param _tokenId uint256 token ID.
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculateRoyaltyFee(
        uint256 _tokenId,
        uint256 _amount
    ) external view override returns (uint256) {
        return
        _amount
        .mul(
            getTokenRoyaltyPercentage(_tokenId)
        )
        .div(100);
    }

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
        return iERC1155TokenCreator.tokenCreator(_tokenId);
    }
}
