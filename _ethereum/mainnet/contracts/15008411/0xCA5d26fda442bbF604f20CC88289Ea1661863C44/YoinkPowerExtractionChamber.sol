pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";


contract YoinkPowerExtractionChamber is Ownable {
    address immutable edwone;
    bool public yoinkPowerExtractionActivated = true;
    address _yoinkPowerReceiver;

    constructor(address _edwone) {
        edwone = _edwone;
    }

    // Yoink-Chain Power Extraction Technology (patent pending)
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4) {
        if (Ownable(edwone).owner() == operator && yoinkPowerExtractionActivated == true) {
            return 0;
        }
        return IERC721Receiver.onERC721Received.selector;
    }

    function toggleYoinkPowerExtraction() external onlyOwner {
        yoinkPowerExtractionActivated = !yoinkPowerExtractionActivated;
    }

    // WARNING! MUST RECEIVE FAILED YOINK TO PROPERLY PRIME EXTRACTION CHAMBER!
    // FAILURE TO DO SO BEFORE REDIRECTING IS UNTESTED AND MAY RESULT IN UNTIMELY DEATH
    function redirectYoinkPowerTo(address to) external onlyOwner {
        _yoinkPowerReceiver = to;
    }

    function yoinkPowerReceiver() public view returns (address) {
        if (ERC721(edwone).ownerOf(0) == address(this)) {
            return _yoinkPowerReceiver;
        }
        return address(0);
    }

    function escortWormTo(address to) public onlyOwner {
        yoinkPowerExtractionActivated = false;
        IERC721(edwone).transferFrom(address(this), to, 0);
    }
}
