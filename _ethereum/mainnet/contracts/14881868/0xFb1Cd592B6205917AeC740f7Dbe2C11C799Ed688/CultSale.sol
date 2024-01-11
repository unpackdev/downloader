// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./Owned.sol";
import "./Strings.sol";
import "./AccessControl.sol";

import "./Cult.sol";

contract CultSale is Owned, AccessControl {
    bool public paused = true;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    Cult cult;

    address public withdrawRecipient;

    uint256 public totalSupply;
    uint256 supplyLimit = 200;
    uint256 public mintPrice = 0.420 ether;

    constructor(Cult _cult, address _withdrawRecipient) Owned(msg.sender) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);

        cult = _cult;
        withdrawRecipient = _withdrawRecipient;
    }

    fallback() external payable {}

    receive() external payable {}

    function mint() external payable {
        require(!paused, "SALE PAUSED");
        require(cult.totalSupply() + 1 <= supplyLimit, "SOLD OUT");
        require(msg.value >= mintPrice, "NOT ENOUGH ETH");

        cult.mint(msg.sender, 1);
    }

    function withdraw() external {
        (bool sent, ) = payable(withdrawRecipient).call{
            value: address(this).balance
        }("");
        require(sent, "FAILED TO SEND ETH");
    }

    function setSaleState(bool _paused) external onlyRole(ADMIN_ROLE) {
        paused = _paused;
    }

    function setPrice(uint256 _price) external onlyRole(ADMIN_ROLE) {
        require(_price != mintPrice, "ALREADY CURRENT PRICE");
        mintPrice = _price;
    }

    function setWithdrawRecipient(address _withdrawRecipient)
        external
        onlyRole(ADMIN_ROLE)
    {
        withdrawRecipient = _withdrawRecipient;
    }
}
