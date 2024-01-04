// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC165Upgradeable.sol";
import "./IERCWithRoyalties.sol";

abstract contract ERCWithRoyalties is ERC165Upgradeable, IERCWithRoyalties {
    event RoyaltiesDefined(
        uint256 indexed id,
        address indexed recipient,
        uint256 value
    );

    event RoyaltiesReceived(
        uint256 indexed id,
        address indexed recipient,
        uint256 value
    );

    uint256 private _maxRoyalty;

    /*
     * bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     * bytes4(keccak256('onRoyaltiesReceived(uint256)')) == 0x058639c2
     *
     * => 0xbb3bafd6 ^ 0x058639c2 == 0xbebd9614
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES = 0xbebd9614;

    struct Royalty {
        address recipient;
        uint256 value;
    }

    mapping(uint256 => Royalty) internal _royalties;

    function __ERCWithRoyalties_init() internal initializer {
        _registerInterface(_INTERFACE_ID_ROYALTIES);
        _maxRoyalty = 10000;
    }

    /**
     * @dev returns _maxRoyalty
     */
    function maxRoyalty() public view returns (uint256) {
        return _maxRoyalty;
    }

    /**
     * @dev Set max allowed royalty value
     */
    function _setMaxRoyalty(uint256 maxAllowedRoyalty) internal {
        require(
            maxAllowedRoyalty <= 10000,
            'Royalties: max royalty can not be more than 100%'
        );

        _maxRoyalty = maxAllowedRoyalty;
    }

    /**
     * @dev Set Royalties
     *
     * Requirements:
     *
     * - value should be lte 100%
     * - recipient can not be address(0)
     */
    function _setRoyalties(
        uint256 id,
        address recipient,
        uint256 value
    ) internal {
        require(
            recipient != address(0),
            'Royalties: Royalties recipient can not be null address'
        );

        require(
            value <= _maxRoyalty,
            'Royalties: Royalties can not be more than the defined max royalty'
        );

        _royalties[id] = Royalty(recipient, value);

        emit RoyaltiesDefined(id, recipient, value);
    }
}
