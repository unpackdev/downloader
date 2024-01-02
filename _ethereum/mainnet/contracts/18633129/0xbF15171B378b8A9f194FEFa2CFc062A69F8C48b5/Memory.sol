// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC2981Upgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";

abstract contract MemoryStorage {
    mapping(address => bool) internal isMinter;
    mapping(uint256 => string) internal tokenInfo;

    uint256 public tokenNumber;
    uint256 public royaltyPortion;
    address public royaltyReceiver;

    uint256[50] private __gap;
}

contract Memory is
MemoryStorage,
OwnableUpgradeable,
ReentrancyGuardUpgradeable,
IERC2981Upgradeable,
ERC721BurnableUpgradeable,
ERC721PausableUpgradeable {
    uint256 public constant PORTION_BASE = 10000;

    event RoyaltyPortionUpdate(uint256 newValue);
    event RoyaltyReceiverUpdate(address newAddress);
    event Mint(
        uint256 indexed tokenId,
        address indexed minter,
        address indexed receiver
    );
    event MintersRegistration(uint256 registeredMinterNumber);
    event MintersUnregistration(uint256 unregisteredMinterNumber);
    event TokenInfoModification(uint256 tokenId);

    error InvalidParam();
    error MinterAlreadyRegistered();
    error MinterNotRegistered();
    error Unauthorized();

    function initialize(
        string memory _name,
        string memory _symbol,
        address _royaltyReceiver,
        uint256 _royaltyPortion,
        address[] memory _minters
    ) external initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();

        if (_royaltyPortion > PORTION_BASE) revert InvalidParam();
        royaltyPortion = _royaltyPortion;

        royaltyReceiver = _royaltyReceiver;

        uint256 minterNumber = _minters.length;
        for (uint256 i = 0; i < minterNumber; ++i) {
            if (isMinter[_minters[i]]) revert MinterAlreadyRegistered();
            isMinter[_minters[i]] = true;
        }

        emit RoyaltyPortionUpdate(_royaltyPortion);
        emit MintersRegistration(minterNumber);
    }

    function version() external pure returns (string memory) {
        return "v0.0.1";
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateRoyaltyPortion(uint256 _royaltyPortion) external onlyOwner {
        if (_royaltyPortion > PORTION_BASE) revert InvalidParam();
        royaltyPortion = _royaltyPortion;
        emit RoyaltyPortionUpdate(_royaltyPortion);
    }

    function updateRoyaltyReceiver(address _royaltyReceiver) external onlyOwner {
        royaltyReceiver = _royaltyReceiver;
        emit RoyaltyReceiverUpdate(_royaltyReceiver);
    }

    function registerMinters(address[] calldata _minters) external onlyOwner {
        uint256 minterNumber = _minters.length;
        unchecked {
            for (uint256 i = 0; i < minterNumber; ++i) {
                if (isMinter[_minters[i]]) revert MinterAlreadyRegistered();
                isMinter[_minters[i]] = true;
            }
        }
        emit MintersRegistration(minterNumber);
    }

    function unregisterMinters(address[] calldata _minters) external onlyOwner {
        uint256 minterNumber = _minters.length;
        unchecked {
            for (uint256 i = 0; i < minterNumber; ++i) {
                if (!isMinter[_minters[i]]) revert MinterNotRegistered();
                isMinter[_minters[i]] = false;
            }
        }
        emit MintersUnregistration(minterNumber);
    }

    function mint(address _receiver, string calldata _info) external payable returns (uint256) {
        if (!isMinter[msg.sender]) revert Unauthorized();

        uint256 tokenId = ++tokenNumber;
        _safeMint(_receiver, tokenId);
        tokenInfo[tokenId] = _info;

        emit Mint(tokenId, msg.sender, _receiver);

        return tokenId;
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _firstTokenId,
        uint256 _batchSize
    ) internal virtual override(ERC721Upgradeable, ERC721PausableUpgradeable) {
        super._beforeTokenTransfer(_from, _to, _firstTokenId, _batchSize);
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721Upgradeable) returns (string memory) {
        _requireMinted(_tokenId);
        return tokenInfo[_tokenId];
    }

    function modifyTokenInfo(uint256 _tokenId, string calldata _info) external onlyOwner {
        _requireMinted(_tokenId);
        tokenInfo[_tokenId] = _info;
        emit TokenInfoModification(_tokenId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256) {
        return (
            royaltyReceiver,
            _salePrice * royaltyPortion / PORTION_BASE
        );
    }
}