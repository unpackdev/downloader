// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./NiftyEntity.sol";
import "./IERC2981.sol";
import "./Initializable.sol";
import "./ERC165.sol";

contract ERC2981 is ERC165, IERC2981, Initializable, NiftyEntity {
    GlobalRoyaltyInfo private _globalRoyaltyInfo;

    RoyaltyRange[] public royaltyRanges;
    bool public contractEnabled;
    address public tokenAddress;

    struct GlobalRoyaltyInfo {
        bool enabled;
        uint24 amount;
        address recipient;
    }

    struct RoyaltyRange {
        uint256 startTokenId;
        uint256 endTokenId;
        address recipient;
        uint16 amount;
    }

    constructor(address _niftyRegistryContract) NiftyEntity(_niftyRegistryContract) {}

    function initialize(
        address _recipient,
        uint256 _value,
        address _tokenAddress
    ) public initializer {
        tokenAddress = _tokenAddress;
        contractEnabled = true;
        if (_value != 0) {
            _setGlobalRoyalties(_recipient, _value);
        }
    }

    /**
     * @dev Function responsible for updating existing token level royalties.
     * @param rangeIdx int256 represents the royaltyRanges index to delete. If writing a new range
     * then this value is set to '-1'. Deleting elements results in a gas refund.
     * @param startTokenId uint256 that is the first token in a RoyaltyRange
     * @param endTokenId uint256 that is the last token in a RoyaltyRange
     * @param recipient address of who should be sent the royalty payment
     * @param amount uint256 value for percentage (using 2 decimals - 10000 = 100, 0 = 0)
     */
    function updateTokenRoyaltyRange(
        int256 rangeIdx,
        uint256 startTokenId,
        uint256 endTokenId,
        address recipient,
        uint256 amount
    ) public onlyValidSender {
        RoyaltyRange storage r = royaltyRanges[uint256(rangeIdx)];
        if (r.startTokenId == startTokenId && r.endTokenId == endTokenId) {
            delete royaltyRanges[uint256(rangeIdx)];
        }
        _setTokenRoyaltyRange(startTokenId, endTokenId, recipient, amount);
    }

    /**
     * @dev Function responsible for setting token level royalties. To be gas efficient
     * this function provides the ability to set royalty information in ranges. It is
     * the responsibility of the caller to determine what these ranges are and to invoke
     * this function accordingly e.g. 'setTokenRoyaltyRange(0, 4, addressX, 250)' -
     * will set the the first 5 tokens to have 'addressX' and '250' as their royalty info.
     *
     * When reading royaltyInfo, the latest write for a token in a royalty range gets selected.
     * @param startTokenId uint256 that is the first token in a RoyaltyRange
     * @param endTokenId uint256 that is the last token in a RoyaltyRange
     * @param recipient address of who should be sent the royalty payment
     * @param amount uint256 value for percentage (using 2 decimals - 10000 = 100, 0 = 0)
     */
    function setTokenRoyaltyRange(
        uint256 startTokenId,
        uint256 endTokenId,
        address recipient,
        uint256 amount
    ) public onlyValidSender {
        _setTokenRoyaltyRange(startTokenId, endTokenId, recipient, amount);
    }

    function _setTokenRoyaltyRange(
        uint256 startTokenId,
        uint256 endTokenId,
        address recipient,
        uint256 amount
    ) internal {
        require(contractEnabled, "Contract disabled");
        require(amount <= 10000, "Royalties too high");
        require(startTokenId <= endTokenId && startTokenId >= 0, "Bad tokenId range values");
        royaltyRanges.push(RoyaltyRange(startTokenId, endTokenId, recipient, uint16(amount)));
    }

    function royaltyRangeCount() external view returns (uint256) {
        return royaltyRanges.length;
    }

    function globalRoyaltiesEnabled() external view returns (bool) {
        return _globalRoyaltyInfo.enabled;
    }

    function setGlobalRoyalties(address recipient, uint256 value) public onlyValidSender {
        require(contractEnabled, "Contract disabled");
        _setGlobalRoyalties(recipient, value);
    }

    function _setGlobalRoyalties(address recipient, uint256 value) internal {
        require(value <= 10000, "Royalties too high");
        _globalRoyaltyInfo = GlobalRoyaltyInfo(true, uint24(value), recipient);
    }

    /// @inheritdoc IERC2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(contractEnabled, "Contract disabled");
        uint256 basis;
        GlobalRoyaltyInfo memory globalInfo = _globalRoyaltyInfo;
        if (globalInfo.enabled) {
            receiver = globalInfo.recipient;
            basis = globalInfo.amount;
        } else {
            if (royaltyRanges.length > 0) {
                uint256 i = royaltyRanges.length;
                while (i > 0) {
                    RoyaltyRange memory r = royaltyRanges[--i];
                    if (_tokenId >= r.startTokenId && _tokenId <= r.endTokenId) {
                        receiver = r.recipient;
                        basis = r.amount;
                        break;
                    }
                }
            }
        }
        royaltyAmount = (_salePrice * basis) / 10000;
    }

    function setContractEnabled(bool _contractEnabled) public onlyValidSender {
        contractEnabled = _contractEnabled;
    }

    function setGlobalRoyaltiesEnabled(bool _globalRoyaltiesEnabled) public onlyValidSender {
        _globalRoyaltyInfo.enabled = _globalRoyaltiesEnabled;
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}