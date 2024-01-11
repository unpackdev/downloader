// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract ProxyEternalPassport is Ownable, ReentrancyGuard {
    // Information about Mtt NFT
    ERC721 public mttContract = ERC721(0x6070CcC90779F8F8F11cd121aD3E19dcBEd3668f);
    uint256 public mttTokenId = 2;
    address public mttSender = 0x24625aa92AB44c59Bb45a535db04a8774a388Eb7;

    // Information about Org NFT
    ERC721 public orgContract = ERC721(0x310910BcF0d8301a835D8831c44Fb616BaEae5F3);
    uint256 public orgTokenId = 1;
    address public orgReceiver = 0xDB5838C958C83836b654A4383a41314f422C2b4c;

    // Declare event
    event eternalPassportClaimed(address from);

    // Constructor
    constructor() payable {}

    // Perform the switch of the two NFTs
    function claimEternalPassport() public nonReentrant {
        orgContract.safeTransferFrom(msg.sender, orgReceiver, orgTokenId);
        mttContract.safeTransferFrom(mttSender, msg.sender, mttTokenId);
        payable(msg.sender).transfer(address(this).balance);

        emit eternalPassportClaimed(msg.sender);
    }

    // Setter if NFTs info change for some reason
    function setInfo(
        address _mttAddress,
        uint256 _mttTokenId,
        address _mttSender,
        address _orgAddress,
        uint256 _orgTokenId,
        address _orgReceiver
    ) external onlyOwner {
        mttContract = ERC721(_mttAddress);
        mttTokenId = _mttTokenId;
        mttSender = _mttSender;

        orgContract = ERC721(_orgAddress);
        orgTokenId = _orgTokenId;
        orgReceiver = _orgReceiver;
    }
}
