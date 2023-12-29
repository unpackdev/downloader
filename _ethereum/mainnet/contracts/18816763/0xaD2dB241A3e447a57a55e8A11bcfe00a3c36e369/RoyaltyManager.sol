// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./IRoyaltyManager.sol";
import "./ISplitsMain.sol";

import "./Constants.sol";

/**
 * @title RoyaltyManager
 * @author fx(hash)
 * @notice See the documentation in {IRoyaltyManager}
 */
abstract contract RoyaltyManager is IRoyaltyManager {
    /*//////////////////////////////////////////////////////////////////////////
                                    STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns royalty information of index in array list
     */
    RoyaltyInfo public baseRoyalties;

    /**
     * @notice Mapping of token ID to array of royalty information
     */
    mapping(uint256 => RoyaltyInfo) public tokenRoyalties;

    /*//////////////////////////////////////////////////////////////////////////
                                EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRoyaltyManager
     */
    function getRoyalties(
        uint256 _tokenId
    ) external view returns (address[] memory receivers, uint256[] memory basisPoints) {
        RoyaltyInfo storage tokenRoyalties_ = tokenRoyalties[_tokenId];
        if (tokenRoyalties_.receiver != address(0) && tokenRoyalties_.basisPoints != 0) {
            receivers = new address[](2);
            basisPoints = new uint256[](2);
            receivers[1] = tokenRoyalties_.receiver;
            basisPoints[1] = tokenRoyalties_.basisPoints;
        } else {
            receivers = new address[](1);
            basisPoints = new uint256[](1);
        }
        receivers[0] = baseRoyalties.receiver;
        basisPoints[0] = baseRoyalties.basisPoints;
    }

    /**
     * @inheritdoc IRoyaltyManager
     */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 amount) {
        RoyaltyInfo storage tokenRoyalties_ = tokenRoyalties[_tokenId];
        if (tokenRoyalties_.receiver != address(0) && tokenRoyalties_.basisPoints != 0) {
            revert MoreThanOneRoyaltyReceiver();
        } else if (baseRoyalties.receiver == address(0) && baseRoyalties.basisPoints == 0) {
            return (receiver, amount);
        } else {
            receiver = baseRoyalties.receiver;
            amount = (_salePrice * baseRoyalties.basisPoints) / FEE_DENOMINATOR;
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _getOrCreateSplit(
        address[] calldata _receivers,
        uint32[] calldata _allocations
    ) internal returns (address receiver) {
        receiver = ISplitsMain(SPLITS_MAIN).predictImmutableSplitAddress(_receivers, _allocations, 0);
        if (receiver.code.length == 0) {
            ISplitsMain(SPLITS_MAIN).createSplit(_receivers, _allocations, 0, address(0));
        }
    }

    /**
     * @notice Sets the base royalties for all tokens
     * @param _receivers Array of addresses receiving royalties
     * @param _allocations Array of allocation amounts for calculating royalty shares
     * @param _basisPoints Total allocation scalar for calculating royalty shares
     */
    function _setBaseRoyalties(
        address[] calldata _receivers,
        uint32[] calldata _allocations,
        uint96 _basisPoints
    ) internal virtual {
        _checkRoyalties(_receivers, _allocations, _basisPoints);
        /// compute split if necessary
        address receiver;
        if (_receivers.length == 0 || _basisPoints == 0) {
            delete baseRoyalties;
        } else if (_receivers.length > 1) {
            receiver = _getOrCreateSplit(_receivers, _allocations);
        } else {
            receiver = _receivers[0];
        }
        baseRoyalties = RoyaltyInfo(receiver, _basisPoints);
        emit TokenRoyaltiesUpdated(receiver, _receivers, _allocations, _basisPoints);
    }

    /**
     * @notice Sets the royalties for a specific token ID
     * @param _tokenId ID of the token
     * @param _receiver Address receiving royalty payments
     * @param _basisPoints Total allocation scalar for calculating royalty shares
     */
    function _setTokenRoyalties(uint256 _tokenId, address _receiver, uint96 _basisPoints) internal {
        if (!_exists(_tokenId)) revert NonExistentToken();
        if (_basisPoints > MAX_ROYALTY_BPS) revert OverMaxBasisPointsAllowed();
        if (baseRoyalties.basisPoints + _basisPoints >= FEE_DENOMINATOR) revert InvalidRoyaltyConfig();
        tokenRoyalties[_tokenId] = RoyaltyInfo(_receiver, _basisPoints);
        emit TokenIdRoyaltiesUpdated(_tokenId, _receiver, _basisPoints);
    }

    /**
     * @dev Checks if the token ID exists
     */
    function _exists(uint256 _tokenId) internal view virtual returns (bool);

    /**
     * @dev Checks if:
     * 1. Total basis points of royalties exceeds 10,000 (100%)
     * 2. A single receiver exceeds 2,500 (25%)
     */
    function _checkRoyalties(
        address[] memory _receivers,
        uint32[] memory _allocations,
        uint96 _basisPoints
    ) internal pure {
        uint256 allocationsLength = _allocations.length;
        if (_receivers.length != allocationsLength) revert LengthMismatch();
        if (_basisPoints >= FEE_DENOMINATOR) revert InvalidRoyaltyConfig();
        for (uint256 i; i < allocationsLength; ++i) {
            if ((_allocations[i] * _basisPoints) / ALLOCATION_DENOMINATOR > MAX_ROYALTY_BPS)
                revert OverMaxBasisPointsAllowed();
        }
    }
}
