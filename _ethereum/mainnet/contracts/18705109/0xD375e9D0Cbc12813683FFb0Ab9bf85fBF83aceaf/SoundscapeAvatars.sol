// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

/**   ███████╗ ██████╗ ██╗   ██╗███╗   ██╗██████╗ ███████╗ ██████╗ █████╗ ██████╗ ███████╗
 *    ██╔════╝██╔═══██╗██║   ██║████╗  ██║██╔══██╗██╔════╝██╔════╝██╔══██╗██╔══██╗██╔════╝
 *    ███████╗██║   ██║██║   ██║██╔██╗ ██║██║  ██║███████╗██║     ███████║██████╔╝█████╗
 *    ╚════██║██║   ██║██║   ██║██║╚██╗██║██║  ██║╚════██║██║     ██╔══██║██╔═══╝ ██╔══╝
 *    ███████║╚██████╔╝╚██████╔╝██║ ╚████║██████╔╝███████║╚██████╗██║  ██║██║     ███████╗
 *    ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝     ╚══════╝
 *
 *                                       █████████████╗
 *                                       ╚════════════╝
 *                                        ███████████╗
 *                                        ╚══════════╝
 *                                     █████████████████╗
 *                                     ╚════════════════╝
 *
 *                  █████╗ ██╗   ██╗ █████╗ ████████╗ █████╗ ██████╗ ███████╗
 *                 ██╔══██╗██║   ██║██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗██╔════╝
 *                 ███████║██║   ██║███████║   ██║   ███████║██████╔╝███████╗
 *                 ██╔══██║╚██╗ ██╔╝██╔══██║   ██║   ██╔══██║██╔══██╗╚════██║
 *                 ██║  ██║ ╚████╔╝ ██║  ██║   ██║   ██║  ██║██║  ██║███████║
 *                 ╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
 */

import "./AwaitingTheUNMUTOOOOR.sol";
import "./AvatarVolumeAndFrequency.sol";
import "./StatefulSale.sol";
import "./ERC2981Plus.sol";
import "./ERC721Consecutive.sol";
import "./ERC721.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ISANPASS.sol";
import "./ISANWEAR.sol";

/**
 * @title Soundscape Avatars™ by SAN SOUND
 * @author Aaron Hanson <coffee.becomes.code@gmail.com> @CoffeeConverter
 * @notice https://sansound.io/
 */
contract SoundscapeAvatars is
    Ownable,
    ERC721Consecutive,
    StatefulSale,
    ERC2981Plus,
    AvatarVolumeAndFrequency,
    AwaitingTheUNMUTOOOOR
{
    error BurnsExceedMints();
    error ExceedsMaxSupply();
    error ExceedsMintAllocation();
    error ExceedsPaidMintsRemaining();
    error FailedToWithdraw();
    error InvalidPaymentAmount();
    error InvalidSignature();
    error SuncoreSecurityAlarm();
    error ZeroMints();

    using Strings for uint256;

    uint256 public totalSupply;
    uint256 public paidMintsRemaining = MAX_PAID_SUPPLY;

    ISANPASS public immutable SANPASS;
    ISANWEAR public immutable SANWEAR;

    string public contractURI;
    string public baseUri;
    bool public isRevealed;

    uint256[40] public tokenFactionBitmap;
    mapping(address => mapping(SaleState => uint256)) public userMinted;

    constructor(
        string memory _baseUri,
        string memory _contractUri,
        address _sanpass,
        address _sanwear,
        address _signer,
        address _initMintTo
    )
        ERC721("Soundscape Avatars by SAN SOUND", "SANAV")
        StatefulSale(_signer)
        Ownable(_msgSender())
    {
        _setBaseURI(_baseUri, false);
        contractURI = _contractUri;
        SANPASS = ISANPASS(_sanpass);
        SANWEAR = ISANWEAR(_sanwear);
        _setDefaultRoyalty(_initMintTo, INITIAL_ROYALTY_BPS);
        _mintConsecutive(_initMintTo, INITIAL_MINT_AMOUNT);
        totalSupply = INITIAL_MINT_AMOUNT;
        tokenFactionBitmap[0] = 0x468d8d1b1a36346c68d8d1b1a36346c68d8d1b1a36346c68d8d1b1a36346c688;
        tokenFactionBitmap[1] = 0x468d8d1b1a36346c68d8d1b1a36346c68d8d1b1a36346c68d8d1b1a36346c68d;
        tokenFactionBitmap[2] = 0x468d8d1b1a36346c68d8d1b1a36346c68d8d1b1a36346c68d8d1b1a36346c68d;
        tokenFactionBitmap[3] = 0x2c68d8d1b1a36346c68d8d1b1a36346c68d;
    }

    function ___3___(
        string memory ___
    )
        public
    {
        if (_msgSender() != address(this)) revert SuncoreSecurityAlarm();
        _setBaseURI(___, true);
    }

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _tokenIDs
    )
        external
    {
        for (uint256 i = 0; i < _tokenIDs.length; ++i) {
            transferFrom(_from, _to, _tokenIDs[i]);
        }
    }

    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _tokenIDs,
        bytes calldata _data
    )
        external
    {
        for (uint256 i = 0; i < _tokenIDs.length; ++i) {
            safeTransferFrom(_from, _to, _tokenIDs[i], _data);
        }
    }

    function mintMembersList(
        uint256[5] calldata _factionMints,
        uint256[7] calldata _sanpassBurns,
        uint256 _mintLimit,
        bytes calldata _signature
    )
        external
        payable
    {
        if (saleState != SaleState.MEMBERS_LIST) revert SaleStateNotActive();
        _mintPrivate(
            _factionMints,
            _sanpassBurns,
            _mintLimit,
            _signature
        );
    }

    function mintAllowList(
        uint256[5] calldata _factionMints,
        uint256[7] calldata _sanpassBurns,
        uint256 _mintLimit,
        bytes calldata _signature
    )
        external
        payable
    {
        if (saleState != SaleState.ALLOW_LIST) revert SaleStateNotActive();
        _mintPrivate(
            _factionMints,
            _sanpassBurns,
            _mintLimit,
            _signature
        );
    }

    function mintPublic(
        uint256[5] calldata _factionMints,
        uint256[7] calldata _sanpassBurns
    )
        external
        payable
    {
        if (saleState != SaleState.PUBLIC) revert SaleStateNotActive();
        _mintMain(
            _factionMints,
            _sanpassBurns,
            0,
            PRICE_FULL
        );
    }

    function _mintPrivate(
        uint256[5] calldata _factionMints,
        uint256[7] calldata _sanpassBurns,
        uint256 _mintLimit,
        bytes calldata _signature
    )
        private
    {
        if (false == isValidSignature(
            _signature,
            _msgSender(),
            block.chainid,
            address(this),
            saleState,
            _mintLimit
        )) revert InvalidSignature();

        _mintMain(
            _factionMints,
            _sanpassBurns,
            _mintLimit,
            PRICE_DISCOUNTED
        );
    }

    function setContractURI(
        string calldata _newContractURI
    )
        external
        onlyOwner
    {
        contractURI = _newContractURI;
    }

    function setBaseURI(
        string calldata _newBaseUri,
        bool _isRevealed
    )
        external
        onlyOwner
    {
        _setBaseURI(_newBaseUri, _isRevealed);
    }

    function withdrawAll()
        external
        onlyOwner
    {
        withdraw(address(this).balance);
    }

    function withdraw(
        uint256 _weiAmount
    )
        public
        onlyOwner
    {
        (bool success, ) = payable(_msgSender()).call{value: _weiAmount}("");
        if (!success) revert FailedToWithdraw();
    }

    function tokenFaction(
        uint256 _tokenId
    )
        external
        view
        returns (Faction)
    {
        _requireOwned(_tokenId);
        return Faction(
            tokenFactionBitmap[_tokenId / EIGHTY_FIVE] >> THREE * (_tokenId % EIGHTY_FIVE) & MASK_THREE_BITS
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC2981, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(
        uint256 _tokenId
    )
        public
        view
        override
        returns (string memory)
    {
        _requireOwned(_tokenId);
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? (isRevealed
                ? string.concat(baseURI, _tokenId.toString(), ".json")
                : baseURI
            )
            : "";
    }

    function _setBaseURI(
        string memory _newBaseUri,
        bool _isRevealed
    )
        internal
    {
        baseUri = _newBaseUri;
        isRevealed = _isRevealed;
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseUri;
    }

    function _firstConsecutiveId()
        internal
        pure
        override
        returns (uint96)
    {
        return 1;
    }

    function _mintMain(
        uint256[5] calldata _factionMints,
        uint256[7] calldata _sanpassBurns,
        uint256 _mintLimit,
        uint256 _price
    )
        private
    {
        uint256[] memory factionIds;
        uint256[] memory factionAmts;
        uint256[] memory sanpassIds;
        uint256[] memory sanpassAmts;
        unchecked {
            uint256 factionIdCount;
            uint256 sanpassIdCount;
            for (uint i; i < 7; ++i) {
                if (i < 5) if (_factionMints[i] > 0) ++factionIdCount;
                if (_sanpassBurns[i] > 0) ++sanpassIdCount;
            }
            if (factionIdCount == 0) revert ZeroMints();
            factionIds = new uint256[](factionIdCount);
            factionAmts = new uint256[](factionIdCount);
            sanpassIds = new uint256[](sanpassIdCount);
            sanpassAmts = new uint256[](sanpassIdCount);
        }
        unchecked {
            uint256 mintCount;
            uint256 burnCount;
            uint256 factionIndex;
            uint256 sanpassIndex;
            for (uint i; i < 7; ++i) {
                uint256 burns = _sanpassBurns[i];
                if (burns > 0) {
                    burnCount += burns;
                    sanpassIds[sanpassIndex] = i + 1;
                    sanpassAmts[sanpassIndex++] = burns;
                }
                if (i > 4) continue;
                uint256 mints = _factionMints[i];
                if (burns > mints) revert BurnsExceedMints();
                if (mints > 0) {
                    mintCount += mints;
                    factionIds[factionIndex] = i + 1;
                    factionAmts[factionIndex++] = mints;
                }
            }

            if (burnCount > mintCount) revert BurnsExceedMints();
            uint256 paidCount = mintCount - burnCount;
            if (paidCount > 0) {
                if (msg.value != _price * paidCount) revert InvalidPaymentAmount();
                if (paidCount > paidMintsRemaining) revert ExceedsPaidMintsRemaining();
                paidMintsRemaining -= paidCount;
            }

            SaleState state = saleState;
            if (state < SaleState.PUBLIC) {
                uint256 userMintsInState = userMinted[_msgSender()][state] + mintCount;
                if (userMintsInState > _mintLimit) revert ExceedsMintAllocation();
                userMinted[_msgSender()][state] = userMintsInState;
            }

            if (sanpassIds.length > 0) SANPASS.burnBatch(_msgSender(), sanpassIds, sanpassAmts);
            _mintSanwear(factionIds, factionAmts);
            _mintAvatars(factionIds, factionAmts);
        }
    }

    function _mintSanwear(
        uint256[] memory _factionIds,
        uint256[] memory _amounts
    )
        private
    {
        _factionIds.length > 1
            ? SANWEAR.mintBatch(_msgSender(), _factionIds, _amounts)
            : SANWEAR.mint(_msgSender(), _factionIds[0], _amounts[0]);
    }

    function _mintAvatars(
        uint256[] memory _factionIds,
        uint256[] memory _amounts
    )
        private
    {
        unchecked {
            uint256 curSupply = totalSupply;
            uint256 facPageIdx = (curSupply + 1) / EIGHTY_FIVE;
            uint256 lastFacPageIdx = facPageIdx;
            uint256 facPage = tokenFactionBitmap[facPageIdx] | _factionIds[0] << THREE * ((curSupply + 1) % EIGHTY_FIVE);
            for (uint i; i < _factionIds.length; ++i) {
                uint256 amount = _amounts[i];
                for (uint j; j < amount; ++j) {
                    uint256 tokenId = ++curSupply;
                    if (i > 0 || j > 0) {
                        facPageIdx = tokenId / EIGHTY_FIVE;
                        if (facPageIdx > lastFacPageIdx) {
                            tokenFactionBitmap[lastFacPageIdx] = facPage;
                            facPage = tokenFactionBitmap[facPageIdx];
                            lastFacPageIdx = facPageIdx;
                        }
                        facPage |= _factionIds[i] << THREE * (tokenId % EIGHTY_FIVE);
                    }
                    _mint(_msgSender(), tokenId);
                }
            }
            tokenFactionBitmap[facPageIdx] = facPage;
            if (curSupply > MAX_SUPPLY) revert ExceedsMaxSupply();
            totalSupply = curSupply;
        }
    }
}
