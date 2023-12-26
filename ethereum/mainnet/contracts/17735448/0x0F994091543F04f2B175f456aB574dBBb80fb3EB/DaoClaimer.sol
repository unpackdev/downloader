// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";

interface TruthDao {
    function checkClaimed(uint256 tokenId) external view returns (bool);
    function transferOwnership(address newOwner) external;
    function aidrop(uint256[] calldata illuminatiIDs, address[] calldata addr) external;
}

contract DaoClaimer is Ownable, ReentrancyGuard {

    address public truthDaoToken = 0xe25f0fe686477F9Df3C2876C4902D3B85F75f33a;
    address public illuminatiToken = 0x8CB05890B7A640341069fB65DD4e070367f4D2E6;


    function claimTokensFor(uint256[] calldata illuminatiIds) public nonReentrant {
        require(illuminatiIds.length > 0, "Must claim at least one token");

        address[] memory owners = new address[](1);
        owners[0] = msg.sender;
        
        for(uint i = 0; i < illuminatiIds.length; i++) {
            require(IERC721(illuminatiToken).ownerOf(illuminatiIds[i]) == msg.sender, "You do not own this token");
            require(!isTokenClaimed(illuminatiIds[i]), "Token already claimed");

            uint256[] memory ids = new uint256[](1);
            ids[0] = illuminatiIds[i];

            TruthDao(truthDaoToken).aidrop(ids, owners);
        }
    }

    function isTokenClaimed(uint256 tokenId) public view returns (bool) {
        return TruthDao(truthDaoToken).checkClaimed(tokenId);
    }

    function returnOwnership() public onlyOwner {
        TruthDao(truthDaoToken).transferOwnership(msg.sender);
    }

}