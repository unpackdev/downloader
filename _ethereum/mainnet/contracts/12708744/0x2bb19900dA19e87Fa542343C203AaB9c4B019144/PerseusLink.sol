pragma solidity 0.8.0;

import "./ownable.sol";

contract PerseusLink is Ownable {
    struct Link {
        uint32 block;
        uint256 hash;
    }

    uint32 currentId;
    mapping (uint32 => Link) internal idToLink;

    constructor(){
        currentId = 0;    
    }

    function link(uint32 _block, uint256 _hash) external onlyOwner {
        idToLink[currentId].block = _block;
        idToLink[currentId].hash = _hash;
        currentId = currentId + 1;
    }

    function getLinkBlock(uint32 _id) external view returns (uint32) {
        require(_id < currentId, "LINK_DO_NOT_EXISTS");
        return idToLink[_id].block;
    }

    function getLinkHash(uint32 _id) external view returns (uint256) {
        require(_id < currentId, "LINK_DO_NOT_EXISTS");
        return idToLink[_id].hash;
    }

    function getLinksNumber() external view returns (uint32) {
        return currentId;
    }
}