// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Initializable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AdminManagerUpgradable.sol";
import "./IERC721Upgradeable.sol";

contract PrimordiaLandStaking is
    Initializable,
    ERC721HolderUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    AdminManagerUpgradable
{
    event Staked(address account, uint256 id);
    event UnStaked(address account, uint256 id);

    mapping(uint256 => address) owners;
    mapping(address => uint256) balances;

    IERC721Upgradeable public constant PRIMORDIA_LAND =
        IERC721Upgradeable(0xFbB87a6A4876820d996a9bbe106e4f73a5E4A71C);

    function initialize() public initializer {
        __ERC721Holder_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __AdminManager_init();
    }

    function stake(
        uint256[] calldata tokenIds_
    ) external nonReentrant whenNotPaused {
        balances[msg.sender] += tokenIds_.length;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            owners[tokenId] = msg.sender;
            PRIMORDIA_LAND.safeTransferFrom(msg.sender, address(this), tokenId);
            emit Staked(msg.sender, tokenId);
        }
    }

    function unStake(
        uint256[] calldata tokenIds_
    ) external nonReentrant whenNotPaused {
        balances[msg.sender] -= tokenIds_.length;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            require(owners[tokenId] == msg.sender, "Not owner");
            owners[tokenId] = address(0);
            PRIMORDIA_LAND.safeTransferFrom(address(this), msg.sender, tokenId);
            emit UnStaked(msg.sender, tokenId);
        }
    }

    function tokensOfOwner(
        address owner_
    ) external view virtual returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsLength = balances[owner_];
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i = 0; tokenIdsIdx != tokenIdsLength; ++i) {
                if (owners[i] == owner_) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }
}
