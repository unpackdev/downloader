// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./OwnableUpgradeable.sol";
import "./IERC2981Upgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";

abstract contract PromptStorage {
    mapping(address => bool) public isMinter;
    mapping(uint256 => string) internal tokenInfo;
    mapping(string => uint256) public tokenIdByInfo;

    uint256 public tokenNumber;
    uint256 public royaltyPortion;
    address public royaltyReceiver;

    uint256[50] private __gap;
}

contract Prompt is
PromptStorage,
OwnableUpgradeable,
IERC2981Upgradeable,
ERC721BurnableUpgradeable {
    uint256 public constant PORTION_BASE = 10000;

    error Duplicated();
    error InvalidParam();
    error Unauthorized();

    function initialize() external initializer {
        unchecked {
            __ERC721_init('Prompt', 'PROMPT');
            __Ownable_init_unchained();

            royaltyPortion = 500;
            royaltyReceiver = address(0x9899d6f384972d9d402B61393afb67F16678d858);

            isMinter[msg.sender] = true;
        }
    }

    function updateRoyaltyPortion(uint256 _royaltyPortion) external onlyOwner {
        if (_royaltyPortion > PORTION_BASE) revert InvalidParam();
        royaltyPortion = _royaltyPortion;
    }

    function updateRoyaltyReceiver(address _royaltyReceiver) external onlyOwner {
        royaltyReceiver = _royaltyReceiver;
    }

    function setMinterState(address _minter, bool _state) external onlyOwner {
        isMinter[_minter] = _state;
    }

    function mint(address _receiver, string calldata _info) external returns (uint256) {
        if (!isMinter[msg.sender]) revert Unauthorized();
        if (tokenIdByInfo[_info] != 0) revert Duplicated();

        if (_receiver == address(0)) _receiver = msg.sender;

        unchecked {
            uint256 tokenId = ++tokenNumber;
            _safeMint(_receiver, tokenId);
            tokenInfo[tokenId] = _info;
            tokenIdByInfo[_info] = tokenId;
            return tokenId;
        }
    }

    function batchMint(address _receiver, string[] calldata _infos) external {
        if (!isMinter[msg.sender]) revert Unauthorized();

        uint256 n = _infos.length;

        unchecked {
            for (uint256 i = 0; i < n; ++i) {
                if (tokenIdByInfo[_infos[i]] != 0) revert Duplicated();
                uint256 tokenId = ++tokenNumber;
                _safeMint(_receiver, tokenId);
                tokenInfo[tokenId] = _infos[i];
                tokenIdByInfo[_infos[i]] = tokenId;
            }
        }
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721Upgradeable) returns (string memory) {
        _requireMinted(_tokenId);
        return tokenInfo[_tokenId];
    }

    function modifyTokenInfo(uint256 _tokenId, string calldata _info) external onlyOwner {
        _requireMinted(_tokenId);
        tokenIdByInfo[tokenInfo[_tokenId]] = 0;
        tokenInfo[_tokenId] = _info;
        tokenIdByInfo[_info] = _tokenId;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256) {
        return (
            royaltyReceiver,
            _salePrice * royaltyPortion / PORTION_BASE
        );
    }
}