// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC165.sol";
import "./AccessControlUpgradeable.sol";
import "./IRoyalty.sol";

contract Royalty is IRoyalty, ERC165, AccessControlUpgradeable {
    bytes32 public constant SETROYALTIES_ROLE = keccak256("SETROYALTIES_ROLE");

    // Royalty configurations
    mapping(uint256 => address payable[]) internal _tokenRoyaltyReceivers;
    mapping(uint256 => uint256[]) internal _tokenRoyaltyBPS;
    address payable[] internal _defaultRoyaltyReceivers;
    uint256[] internal _defaultRoyaltyBPS;

    function __Royalty_init() internal onlyInitializing {
        __Royalty_init_unchained();
    }

    function __Royalty_init_unchained() internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SETROYALTIES_ROLE, msg.sender);
    }

    /**
     * Helper to get royalties for a token
     */
    function _getRoyalties(uint256 tokenId)
        internal
        view
        returns (address payable[] storage, uint256[] storage)
    {
        return (_getRoyaltyReceivers(tokenId), _getRoyaltyBPS(tokenId));
    }

    /**
     * Helper to get royalty receivers for a token
     */
    function _getRoyaltyReceivers(uint256 tokenId)
        internal
        view
        returns (address payable[] storage)
    {
        if (_tokenRoyaltyReceivers[tokenId].length > 0) {
            return _tokenRoyaltyReceivers[tokenId];
        }
        return _defaultRoyaltyReceivers;
    }

    /**
     * Helper to get royalty basis points for a token
     */
    function _getRoyaltyBPS(uint256 tokenId)
        internal
        view
        returns (uint256[] storage)
    {
        if (_tokenRoyaltyBPS[tokenId].length > 0) {
            return _tokenRoyaltyBPS[tokenId];
        }
        return _defaultRoyaltyBPS;
    }

    function _getRoyaltyInfo(uint256 tokenId, uint256 value)
        internal
        view
        returns (address receiver, uint256 amount)
    {
        address payable[] storage receivers = _getRoyaltyReceivers(tokenId);
        require(receivers.length <= 1, "More than 1 royalty receiver");

        if (receivers.length == 0) {
            return (address(this), 0);
        }
        return (receivers[0], (_getRoyaltyBPS(tokenId)[0] * value) / 10000);
    }

    /**
     * Set royalties for a token
     */
    function _setRoyalties(
        uint256 tokenId,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) internal {
        require(receivers.length == basisPoints.length, "Invalid input");
        uint256 totalBasisPoints;
        for (uint256 i = 0; i < basisPoints.length; i++) {
            totalBasisPoints += basisPoints[i];
        }
        require(totalBasisPoints < 10000, "Invalid total royalties");
        _tokenRoyaltyReceivers[tokenId] = receivers;
        _tokenRoyaltyBPS[tokenId] = basisPoints;
        emit RoyaltiesUpdated(tokenId, receivers, basisPoints);
    }

    /**
     * Set royalties for all tokens of an extension
     */
    function _setDefaultRoyalties(
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) internal {
        require(receivers.length == basisPoints.length, "Invalid input");
        uint256 totalBasisPoints;
        for (uint256 i = 0; i < basisPoints.length; i++) {
            totalBasisPoints += basisPoints[i];
        }
        require(totalBasisPoints < 10000, "Invalid total royalties");
        _defaultRoyaltyReceivers = receivers;
        _defaultRoyaltyBPS = basisPoints;

        emit DefaultRoyaltiesUpdated(receivers, basisPoints);
    }

    function setRoyalties(
        uint256 tokenId,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external {
        require(
            hasRole(SETROYALTIES_ROLE, _msgSender()),
            "must have set royalties role"
        );
        _setRoyalties(tokenId, receivers, basisPoints);
    }

    function setDefaultRoyalties(
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external {
        require(
            hasRole(SETROYALTIES_ROLE, _msgSender()),
            "must have set royalties role"
        );
        _setDefaultRoyalties(receivers, basisPoints);
    }

    function getRoyalties(uint256 tokenId)
        external
        view
        override
        returns (address payable[] memory, uint256[] memory)
    {
        return _getRoyalties(tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, AccessControlUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IRoyalty).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
