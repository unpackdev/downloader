pragma solidity ^0.8.19;
import "./IXENFTMinimal.sol";

contract XENFTStorage {
    address factory;

    constructor(){
        factory = msg.sender;
    }

    function claimXenFromStorage(address xenft, address dest, uint256 tokenId) public {
        require(msg.sender == factory, "Caller is not factory");

        IXENFTMinimal(xenft).bulkClaimMintReward(tokenId, dest);
    }
}