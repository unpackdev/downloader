// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./AdminController.sol";
import "./ReentrancyGuard.sol";
import "./IERC721Token.sol";

contract BaseMint is AdminController {
    IERC721Token public nft;
    uint256 public price = 0.18 ether;
    uint256 public maxPerTx = 5;
    uint256 public currentStage;
    address public treasury = 0x6745a0b4fDF94Fb0AeD81FE7aC73bDF85aCF8310;

    function publicMint(uint256 quantity) payable external callerIsUser enoughPrice(quantity, price) {
        require(currentStage == 3, "Not Live");
        require(quantity <= maxPerTx, "Exceeds Limit");
        _mint(quantity, msg.sender);
    }

    function _mint(uint256 quantity, address to) internal {
        nft.mint(to, quantity);
    }

    function setNFT(IERC721Token _nft) public adminOnly {
        nft = _nft;
    }

    function setPrice(uint256 _price) public adminOnly {
        price = _price;
    }

    function setMaxPerTx(uint256 _max) public adminOnly {
        maxPerTx = _max;
    }

    function changeCurrentStage(uint256 stage) public adminOnly {
        currentStage = stage;
    }
    
    modifier callerIsUser {
        require(tx.origin == msg.sender, "Caller is not user");
        _;
    }

    modifier enoughPrice(uint256 quantity, uint256 mintCost) {
        require(msg.value >= quantity * mintCost, "Not enough eth");
        _;
    }

    function changeTreasury(address _treasury) external adminOnly {
        treasury = _treasury;
    }

    function withdraw() external adminOnly {
        uint256 balance = address(this).balance;
        payable(treasury).transfer(balance);
    }
}