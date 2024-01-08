pragma solidity 0.8.6;
import "./IERC721.sol";

contract ColoringParticipant {
    constructor(address nftContract, address coloringCoordinator) {
        IERC721(nftContract).setApprovalForAll(coloringCoordinator, true);
    }
}