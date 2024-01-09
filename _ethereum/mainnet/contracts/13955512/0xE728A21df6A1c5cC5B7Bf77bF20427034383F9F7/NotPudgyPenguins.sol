// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721.sol";
import "./IERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Holder.sol";
import "./SafeERC20.sol";
import "./IPGLD.sol";

/**
 * @title A new breed of Penguins
 * @author Pengu Rescue Team
 */
contract NotPudgyPenguins is ERC721Enumerable, Ownable, ERC721Burnable, ReentrancyGuard, ERC721Holder {
    using SafeERC20 for IPGLD;

    address public immutable oldPenguins;
    uint256 public constant PGLD_PER_PENGUIN = 10000 * 1 ether;
    uint256 public constant LOCK_PERIOD_IN_DAYS = 90 days;

    string public baseTokenURI;
    uint256 public unlockTime;
    IPGLD public immutable pgld;

    constructor(
        address oldPenguins_,
        address dao,
        string memory baseURI,
        IPGLD pgld_
    ) Ownable() ERC721("NotPudgyPenguins", "NPP") {
        require(oldPenguins_ != address(0), "0 address not allowed");
        require(dao != address(0), "0 address not allowed");
        setBaseURI(baseURI);
        pgld = pgld_;
        oldPenguins = oldPenguins_;
        unlockTime = block.timestamp + LOCK_PERIOD_IN_DAYS;
        transferOwnership(dao);
    }

    function totalMint() public view returns (uint256) {
        return totalSupply();
    }

    /**
     * @notice Mints not pudgy penguings in exchange for pudgy penguins
     * @param ids Ids of the penguing to mint
     */
    function mint(uint256[] calldata ids) external nonReentrant {
        require(ids.length > 0, "Show us the penguins!");
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(oldPenguins).safeTransferFrom(msg.sender, address(this), ids[i]);
            _mint(msg.sender, ids[i]);
        }
        uint256 proRataAmount = mintablePGLDAmountPerPenguin();
        if (proRataAmount > 0) {
            pgld.mint(msg.sender, proRataAmount * ids.length);
        }
    }

    /**
     * @notice Returns the amount of gold mintable if a penguing is minted now
     */
    function mintablePGLDAmountPerPenguin() public view returns (uint256 proRataAmount) {
        uint256 elapsed = block.timestamp >= unlockTime ? 0 : unlockTime - block.timestamp;
        proRataAmount = (PGLD_PER_PENGUIN * elapsed) / LOCK_PERIOD_IN_DAYS;
    }

    /**
     * @notice Redeems legacy penguings
     * @dev Work only after lock period and until more than half have not migrated
     * @param ids Ids of the penguing to redeem
     */
    function redeem(uint256[] calldata ids) external nonReentrant {
        require(block.timestamp > unlockTime && totalSupply() < 4445, "Gone with the wind");
        for (uint256 i = 0; i < ids.length; i++) {
            require(ownerOf(ids[i]) == msg.sender, "You're cheating");
            _burn(ids[i]);
            IERC721(oldPenguins).safeTransferFrom(address(this), msg.sender, ids[i]);
        }
    }

    /**
     * @notice Destroys legacy penguings if the migrations is successful
     * @param ids Ids of the penguing to destroy
     */
    function destroy(uint256[] calldata ids) external nonReentrant {
        require(totalSupply() >= 4445, "Easy tiger, time will come");
        for (uint256 i = 0; i < ids.length; i++) {
            ERC721Burnable(oldPenguins).burn(ids[i]);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
