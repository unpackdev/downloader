// SPDX-License-Identifier: MIT

pragma solidity >=0.8.13;

import "./Tokcunts.sol";
import "./IERC721.sol";
import "./IERC20.sol";

contract TokcuntsMint {
    uint256 public price = 0.03 ether;
    uint256 shareRecipient1;
    uint256 shareRecipient2;
    uint256 shareRecipient3;
    address public tokcuntsAddress;
    address recipient1;
    address recipient2;
    address recipient3;
    bool public mintOpened;
    mapping(address => bool) public isAdmin;

    constructor(
        address _tokcuntsAddress,
        address _recipient1,
        address _recipient2,
        address _recipient3,
        uint256 _shareRecipient1,
        uint256 _shareRecipient2,
        uint256 _shareRecipient3
    ) {
        require(
            _shareRecipient1 + _shareRecipient2 + _shareRecipient3 == 100,
            "Invalid split"
        );
        tokcuntsAddress = _tokcuntsAddress;
        recipient1 = _recipient1;
        recipient2 = _recipient2;
        recipient3 = _recipient3;
        shareRecipient1 = _shareRecipient1;
        shareRecipient2 = _shareRecipient2;
        isAdmin[msg.sender] = true;
    }

    modifier adminOnly() {
        require(isAdmin[msg.sender]);
        _;
    }

    function toggleAdmin(address _admin) external adminOnly {
        isAdmin[_admin] = !isAdmin[_admin];
    }

    function setRecipients(
        address _recipient1,
        address _recipient2,
        address _recipient3
    ) external adminOnly {
        recipient1 = _recipient1;
        recipient2 = _recipient2;
        recipient3 = _recipient3;
    }

    function setShares(
        uint256 _shareRecipient1,
        uint256 _shareRecipient2,
        uint256 _shareRecipient3
    ) external adminOnly {
        require(
            shareRecipient1 + shareRecipient2 + shareRecipient3 == 100,
            "Invalid split"
        );
        shareRecipient1 = _shareRecipient1;
        shareRecipient2 = _shareRecipient2;
        shareRecipient3 = _shareRecipient3;
    }

    function setTokcuntsAddress(address _tokcuntsAddress) external adminOnly {
        tokcuntsAddress = _tokcuntsAddress;
    }

    function setPrice(uint256 _price) external adminOnly {
        price = _price;
    }

    function toggleMintOpened() external adminOnly {
        mintOpened = !mintOpened;
    }

    function mint(uint256 _quantity) external payable {
        require(mintOpened, "Mint closed");
        require(msg.value >= price * _quantity, "Not enough funds");
        bool successTransfer1 = payable(recipient1).send(
            (price * _quantity * shareRecipient1) / 100
        );
        bool successTransfer2 = payable(recipient2).send(
            (price * _quantity * shareRecipient2) / 100
        );
        bool successTransfer3 = payable(recipient3).send(
            (price * _quantity * shareRecipient3) / 100
        );
        require(successTransfer1, "Could not transfer funds to recipient1");
        require(successTransfer2, "Could not transfer funds to recipient2");
        require(successTransfer3, "Could not transfer funds to recipient3");
        for (uint256 i = 0; i < _quantity; i++) {
            Tokcunts(tokcuntsAddress).mint(msg.sender);
        }
    }
}
