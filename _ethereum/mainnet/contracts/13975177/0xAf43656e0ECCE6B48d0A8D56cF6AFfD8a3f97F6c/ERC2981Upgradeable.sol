// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "./Initializable.sol";
import "./ERC165Upgradeable.sol";
import "./ContextUpgradeable.sol";
import "./IERC2981Upgradeable.sol";

contract ERC2981Upgradeable is
    Initializable,
    IERC2981Upgradeable,
    ContextUpgradeable
{
    struct RoyaltyInfo {
        address receiver;
        address candidateOwner;
        uint64 feeType;
        uint128 value;
    }

    event TransferRoyaltyOwnership(
        address indexed from,
        address indexed to,
        uint256 id
    );

    mapping(uint256 => RoyaltyInfo) internal _royalties;

    function __ERC2981_init() internal initializer {}

    function __ERC2981_init_unchained() internal initializer {}

    function _setRoyaltyInfo(
        address receiver,
        uint256 tokenID,
        uint64 feeType,
        uint128 value
    ) internal virtual {
        _royalties[tokenID] = RoyaltyInfo(receiver, address(0), feeType, value);
    }

    function royaltyInfo(uint256 tokenID, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalty = _royalties[tokenID];

        return (royalty.receiver, (salePrice * royalty.value) / 10000);
    }

    function royaltyByTokenID(uint256 _tokenID)
        external
        view
        returns (
            address,
            uint64,
            uint128
        )
    {
        RoyaltyInfo memory royalty = _royalties[_tokenID];
        return (royalty.receiver, royalty.feeType, royalty.value);
    }

    function transferRoyaltyOwnership(address candidateOwner, uint256 tokenID)
        external
    {
        require(
            _msgSender() == _royalties[tokenID].receiver,
            'ERC2981: caller is not a royalty receiver.'
        );

        require(
            candidateOwner != address(0),
            'ERC2981: cannot transfer roalty ownership to the zero address.'
        );

        _royalties[tokenID].candidateOwner = candidateOwner;
    }

    function claimRoyaltyOwnership(uint256 tokenID) external {
        require(
            _msgSender() == _royalties[tokenID].candidateOwner,
            'ERC2981: transaction submitter is not the candidate owner.'
        );
        address oldOwner = _royalties[tokenID].receiver;
        _royalties[tokenID].receiver = _royalties[tokenID].candidateOwner;
        _royalties[tokenID].candidateOwner = address(0);

        emit TransferRoyaltyOwnership(
            oldOwner,
            _royalties[tokenID].receiver,
            tokenID
        );
    }

    uint256[50] private __gap;
}
