pragma solidity ^0.8.12;
import "./ERC721.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./SkyFarm.sol";

contract CollabInfo is
    Initializable,
    ContextUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    ERC721 public skyverseContract;
    SkyFarm public skyfarmContract;

    //======================INIT=====================//

    function initialize(address nftContract, address farmContract)
        public
        initializer
    {
        __Ownable_init();
        skyverseContract = ERC721(nftContract);
        skyfarmContract = SkyFarm(farmContract);
    }

    //======================OVERRIDES=====================//

    function _authorizeUpgrade(address) internal override onlyOwner {}

    //======================OWNER FUNCTION=====================//

    function setContract(address nftContract, address farmContract)
        external
        onlyOwner
    {
        skyverseContract = ERC721(nftContract);
        skyfarmContract = SkyFarm(farmContract);
    }

    //======================PUBLIC=====================//

    /// @notice For collab.land to give a role based on staking status / in wallet NFT
    function balanceOf(address owner) external view returns (uint256) {
        return
            skyfarmContract.getStakedIds(owner).length +
            skyverseContract.balanceOf(owner);
    }

    /// @notice For collab.land to give a role based on staking status / in wallet NFT for collab specific
    function ownerOf(uint256 tokenId) external view virtual returns (address) {
        address owner = skyverseContract.ownerOf(tokenId);
        if (owner == address(skyfarmContract))
            owner = skyfarmContract.stakedBy(tokenId);
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }
}
