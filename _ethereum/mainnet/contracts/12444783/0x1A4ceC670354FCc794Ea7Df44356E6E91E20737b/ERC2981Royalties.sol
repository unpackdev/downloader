// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC2981Royalties.sol";

abstract contract ERC2981Royalties is IERC2981Royalties {
    event RoyaltiesDefined(
        uint256 indexed id,
        address indexed recipient,
        uint256 value
    );

    struct Royalty {
        address recipient;
        uint256 value;
    }

    mapping(uint256 => Royalty) internal _royalties;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC2981Royalties).interfaceId;
    }

    /**
     * @dev Set Royalties
     *
     * Requirements:
     *
     * - value should be lte 100%
     * - recipient can not be address(0)
     */
    function _setTokenRoyalty(
        uint256 id,
        address recipient,
        uint256 value
    ) internal {
        require(recipient != address(0), 'Royalties: Invalid recipient');
        require(value <= 10000, 'Royalties: Too high');

        _royalties[id] = Royalty(recipient, value);

        emit RoyaltiesDefined(id, recipient, value);
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 value,
        bytes calldata
    )
        external
        view
        override
        returns (
            address receiver,
            uint256 royaltyAmount,
            bytes memory royaltyPaymentData
        )
    {
        Royalty memory royalty = _royalties[tokenId];

        if (royalty.recipient == address(0)) {
            return (address(0), 0, '');
        }

        return (royalty.recipient, (value * royalty.value) / 10000, '');
    }
}
