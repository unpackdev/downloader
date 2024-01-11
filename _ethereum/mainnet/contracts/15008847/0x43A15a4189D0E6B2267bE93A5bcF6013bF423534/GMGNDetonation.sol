//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./IGMGN.sol";

contract GMGNDetonation is ERC721A, Ownable {
    using Strings for uint256;

    uint8 constant DETONATION_TYPES = 2;
    IERC721 constant GENESIS_TOKEN_CONTRACT = IERC721(address(0x19b86299c21505cdf59cE63740B240A9C822b5E4));
    IGMGN constant GMGN_DYNAMITE_CONTRACT = IGMGN(address(0x390416aE4324494338293974EE6388E777faC34b));

    error DetonationNotEnabled();
    error InvalidDetonationType();
    error NotEnoughDynamite();
    error AlreadyDetonated();
    error UriQueryForNonexistentToken();

    event Detonation(uint256 indexed genesisTokenId, uint256 indexed detonationType, uint256 indexed detonatedTokenId, address owner);

    struct TokenData {
        uint256 genesisTokenId;
        uint256 detonationType;
    }

    struct DetonationStatus {
        uint256 tokenId;
        bool normal;
        bool radioactive;
    }

    string public uriPrefix = '';
    string public uriSuffix = '.json';

    bool public canDetonate = false;

    mapping (uint256 => TokenData) public tokenData;
    mapping (uint256 => bool[DETONATION_TYPES]) public hasBeenDetonated;

    constructor() ERC721A("Detonated Toonz", "DTNT") {
    }

    function detonate(uint256 _genesisTokenId, uint256 _detonationType) public {
        if (!canDetonate) {
            revert DetonationNotEnabled();
        }

        if (_detonationType >= DETONATION_TYPES) {
            revert InvalidDetonationType();
        }

        if (GMGN_DYNAMITE_CONTRACT.balanceOf(msg.sender, _detonationType) < 1) {
            revert NotEnoughDynamite();
        }

        if (hasBeenDetonated[_genesisTokenId][_detonationType]) {
            revert AlreadyDetonated();
        }

        hasBeenDetonated[_genesisTokenId][_detonationType] = true;
        tokenData[_currentIndex] = TokenData(_genesisTokenId, _detonationType);

        emit Detonation(_genesisTokenId, _detonationType, _currentIndex, msg.sender);

        GMGN_DYNAMITE_CONTRACT.burn(msg.sender, _detonationType, 1);
        _safeMint(msg.sender, 1);
    }

    function getDetonationStatus(uint256 _tokenId) public view returns(DetonationStatus memory) {
        if (_tokenId < 1 || _tokenId > 8888) {
            revert UriQueryForNonexistentToken();
        }

        return DetonationStatus(_tokenId, hasBeenDetonated[_tokenId][0], hasBeenDetonated[_tokenId][1]);
    }

    function walletDetonationStatus(
        address _owner,
        uint256 _startId,
        uint256 _endId,
        uint256 _startBalance
    ) public view returns(DetonationStatus[] memory) {
        uint256 ownerBalance = GENESIS_TOKEN_CONTRACT.balanceOf(_owner) - _startBalance;
        DetonationStatus[] memory tokensData = new DetonationStatus[](ownerBalance);
        uint256 currentOwnedTokenIndex = 0;

        for (uint256 i = _startId; currentOwnedTokenIndex < ownerBalance && i <= _endId; i++) {
            if (GENESIS_TOKEN_CONTRACT.ownerOf(i) == _owner) {
                tokensData[currentOwnedTokenIndex] = getDetonationStatus(i);

                currentOwnedTokenIndex++;
            }
        }

        assembly {
            mstore(tokensData, currentOwnedTokenIndex)
        }

        return tokensData;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setCanDetonate(bool _canDetonate) public onlyOwner {
        canDetonate = _canDetonate;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (!_exists(_tokenId)) {
            revert UriQueryForNonexistentToken();
        }

        string memory currentBaseURI = uriPrefix;

        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
            : '';
    }

    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }
}
