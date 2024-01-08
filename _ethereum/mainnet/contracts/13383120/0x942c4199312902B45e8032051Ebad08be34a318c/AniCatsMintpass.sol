// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract AniCatsMintpass is ERC1155, Ownable {
    uint constant public TICKET_ID = 0;
    uint constant public MAX_SUPPLY = 900;
    uint constant public TEAM_RESERVE = 50;

    struct MintpassPlan {
        uint price;
        uint amount;
    }

    bool public mintpassEnabled;
    bool public transferLocked;
    uint public ticketsMinted;

    mapping(address => bool) public isOperatorApproved;
    mapping(uint => MintpassPlan) public minpassPlans;

    constructor() ERC1155("https://anicats-mintpass.herokuapp.com/meta/{id}") {
        minpassPlans[1] = MintpassPlan(0.06 ether, 1); // 0.06 per one ticket
        minpassPlans[2] = MintpassPlan(0.165 ether, 3); // 0.055 per one ticket
        minpassPlans[3] = MintpassPlan(0.25 ether, 5); // 0.05 per one ticket
    }

    // Admin methods region
    function setURI(string memory uri) external onlyOwner {
        _setURI(uri);
    }

    function approveOperator(address operator, bool approved) external onlyOwner {
        isOperatorApproved[operator] = approved;
    }

    function setTransferLocked(bool locked) external onlyOwner {
        transferLocked = locked;
    }
    
    function setMintpassSaleState(bool state) external onlyOwner {
        mintpassEnabled = state;
    }
    
    function withdraw(address to) external onlyOwner {
        uint balance = address(this).balance;
        payable(to).transfer(balance);
    }

    function giveAway(address to, uint amount) public onlyOwner {
        _mint(to, TICKET_ID, amount, "");
    }
    // endregion

    // Mint methods
    modifier mintpassGuard(uint planId) {
        require(mintpassEnabled, "Minting is not available");
        require(ticketsMinted + minpassPlans[planId].amount <= MAX_SUPPLY - TEAM_RESERVE, "Mintpass tickets supply reached limit");
        require(minpassPlans[planId].amount != 0, "No such Mintpass plan");
        _;
    }

    function buyMintpass(uint planId) external payable mintpassGuard(planId) {
        require(minpassPlans[planId].price == msg.value, "Incorrect ethers value");

        ticketsMinted += minpassPlans[planId].amount;

        _mint(msg.sender, TICKET_ID, minpassPlans[planId].amount, "");
    }
    // endregion

    function mintpassPlanPrice(uint planId) external view returns (uint) {
        return minpassPlans[planId].price;
    }

    // 1151 interface region
    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        return isOperatorApproved[operator] || super.isApprovedForAll(account, operator);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(!transferLocked, "Transfer is locked");
        super._safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(!transferLocked, "Transfer is locked");
        super._safeBatchTransferFrom(from, to, ids, amounts, data);
    }
    // endregion
}