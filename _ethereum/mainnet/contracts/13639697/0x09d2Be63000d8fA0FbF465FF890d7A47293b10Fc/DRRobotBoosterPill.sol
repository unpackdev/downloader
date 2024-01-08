// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./DRToken.sol";
import "./ITraitRegistry.sol";

contract DRRobotBoosterPill is Ownable {

    bool            public locked;
    uint256         public unlockTime = 1635778800;

    // contracts
    DRToken         public nft;
    ITraitRegistry  public traitRegistry;

    uint16          public lastMintedTokenId = 8501;
    uint16          public traitId = 7;
    uint16          public robotBoosterPillCollectionID = 16;

    event Pilled(uint256 tokenId, uint256 mintedTokenId);

    constructor(
        address erc721,
        address _tr
        ) {

        nft = DRToken(erc721);
        traitRegistry = ITraitRegistry(_tr);
    }

    function TakePill(uint256 tokenId) public {

        require(!locked && getBlockTimestamp() > unlockTime, "DRRobotBoosterPill: Contract locked");
        require(tokenId > 4000 && tokenId < 4129, "DRRobotBoosterPill: Token id does not participate");
        require(nft.ownerOf(tokenId) == msg.sender, "DRRobotBoosterPill: Token must be owned by message sender!");

        // check token has required trait
        require(traitRegistry.hasTrait(7, uint16(tokenId)), "DRRobotBoosterPill: Token must have Robot Booster Pill trait!");

        // remove trait
        traitRegistry.setTrait(traitId, uint16(tokenId), false);

        // mint the new token
        nft.mintTo(msg.sender, robotBoosterPillCollectionID);

        // read balance and find out last token id minted
        uint256 tokenCount = nft.balanceOf(msg.sender);
        lastMintedTokenId = uint16( nft.tokenOfOwnerByIndex(msg.sender, tokenCount - 1) );
        emit Pilled(tokenId, lastMintedTokenId);
    }

    struct Stats {
        bool    locked;
        address nft;
        address traitRegistry;
        uint16  lastMintedTokenId;
        uint16  traitId;
        uint16  collectionID;
        uint256 unlockTime;
    }

    function getStats() external view returns (Stats memory) {
        return Stats(
            locked,
            address(nft),
            address(traitRegistry),
            lastMintedTokenId,
            traitId,
            robotBoosterPillCollectionID,
            unlockTime
        );
    }
    
    function toggleLocked() public onlyOwner {
        locked = !locked;
    }

    function removeUnlockTime() public onlyOwner {
        unlockTime = block.timestamp;
    }

    function getBlockTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }

    /// blackhole prevention methods
    function retrieveERC20(address _tracker, uint256 amount)
        external
        onlyOwner
    {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }

}