// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./Ownable.sol";
import "./TideweighCendrillon.sol";

// Public minting utility for Cendrillon
contract CendrillonPublicMinter is Ownable {

    Cendrillon public cendrillon; 
    uint256 public minimumAmount = 0.1 ether;
    uint256 public nextTokenId;
    bool public allOpen = false;
    mapping(address => uint256) public preApprovedMinters;
    mapping(address => uint256) public mintsDone;

    constructor(address _cendrillonAddress, uint256 _nextTokenId) {
        cendrillon = Cendrillon(_cendrillonAddress);
        nextTokenId = _nextTokenId;
    }

    function _mint(address to) private {
        cendrillon.mint(to, nextTokenId, "");
        nextTokenId += 1;
    }

    // Convenience function, just in case...
    function ownerMint(address to) public onlyOwner {
        _mint(to);
    }

    // Sales function
    function payableMint(address to) public payable {
        require(msg.value >= minimumAmount, "Insufficient payment");
        _mint(to);
    }

    function isEligibleForFreeMint(address caller, address to) public view returns (bool) {
        return (mintsDone[caller] < preApprovedMinters[caller])                     // Pre-approved minters can mint up to their limit
               || (allOpen && (mintsDone[caller] < 1) && (caller == to))            // One free mint per address if open for all
               || ((cendrillon.balanceOf(caller) > 0) && (mintsDone[caller] < 1));  // One free mint per existing Cendrillon holder
    }

    // Free mint function
    function freeMint(address to) public {
        require(isEligibleForFreeMint(msg.sender, to), "Free mint condition unsatisfied");
        mintsDone[msg.sender] += 1;
        _mint(to);
    }

    function setMinimumAmount(uint256 _minimumAmount) external onlyOwner {
        minimumAmount = _minimumAmount;
    }

    function setNextTokenId(uint256 _nextTokenId) external onlyOwner {
        nextTokenId = _nextTokenId;
    }

    function preApproveMinter(address minter, uint256 maxMints) external onlyOwner {
        preApprovedMinters[minter] = maxMints;
    }

    function setAllOpen(bool _allOpen) external onlyOwner {
        allOpen = _allOpen;
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        payable(owner()).transfer(amount);
    }
    
}
