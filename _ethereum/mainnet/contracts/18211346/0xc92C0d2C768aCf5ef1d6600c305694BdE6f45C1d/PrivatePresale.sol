// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
/*⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⢦⡀⠉⠙⢦⡀⠀⠀⣀⣠⣤⣄⣀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣀⡤⠤⠴⠶⠤⠤⢽⣦⡀⠀⢹⡴⠚⠁⠀⢀⣀⣈⣳⣄⠀⠀
⠀⠀⠀⠀⠀⢠⠞⣁⡤⠴⠶⠶⣦⡄⠀⠀⠀⠀⠀⠀⠀⠶⠿⠭⠤⣄⣈⠙⠳⠀
⠀⠀⠀⠀⢠⡿⠋⠀⠀⢀⡴⠋⠁⠀⣀⡖⠛⢳⠴⠶⡄⠀⠀⠀⠀⠀⠈⠙⢦⠀
⠀⠀⠀⠀⠀⠀⠀⠀⡴⠋⣠⠴⠚⠉⠉⣧⣄⣷⡀⢀⣿⡀⠈⠙⠻⡍⠙⠲⢮⣧
⠀⠀⠀⠀⠀⠀⠀⡞⣠⠞⠁⠀⠀⠀⣰⠃⠀⣸⠉⠉⠀⠙⢦⡀⠀⠸⡄⠀⠈⠟
⠀⠀⠀⠀⠀⠀⢸⠟⠁⠀⠀⠀⠀⢠⠏⠉⢉⡇⠀⠀⠀⠀⠀⠉⠳⣄⢷⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡾⠤⠤⢼⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡇⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠉⠉⠉⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣀⣀⣀⣻⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣀⣀⡤⠤⠤⣿⠉⠉⠉⠘⣧⠤⢤⣄⣀⡀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢀⡤⠖⠋⠉⠀⠀⠀⠀⠀⠙⠲⠤⠤⠴⠚⠁⠀⠀⠀⠉⠉⠓⠦⣄⠀⠀⠀
⢀⡞⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⣄⠀
⠘⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠚⠀
  _____ ____      _   _   _ ____    ____  ____  _____ ____    _    _     _____ 
 |  ___|  _ \    / \ | | | |  _ \  |  _ \|  _ \| ____/ ___|  / \  | |   | ____|
 | |_  | |_) |  / _ \| | | | | | | | |_) | |_) |  _| \___ \ / _ \ | |   |  _|  
 |  _| |  _ <  / ___ \ |_| | |_| | |  __/|  _ <| |___ ___) / ___ \| |___| |___ 
 |_|   |_| \_\/_/   \_\___/|____/  |_|   |_| \_\_____|____/_/   \_\_____|_____|
                                                                               
    Twitter: https://twitter.com/fraudeth_gg
    Telegram: http://t.me/fraudportal
    Website: https://fraudeth.gg
    Docs: https://docs.fraudeth.gg                                                                              

*/


import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";  
import "./IFraudToken.sol";
import "./IBribeToken.sol";
import "./IDubai.sol";
contract PrivatePresale is Ownable {

    using SafeMath for uint256;
    
    // FRAUD
    IFraudToken public fraud;
    // Bribe
    IBribeToken public bribe;
    // Dubai
    IDubai public dubai;

    struct Allocation {
        uint256 bribeDelayed;
        uint256 fraudClaimable;
        uint256 fraudDelayed;
        uint256 fraudInDubai;
        uint256 ethAmount;
    }
    
    uint256 public claimOpenDate;
    uint256 public lockedInDubai;
    bool public claimOpen = false;
    uint256 public claimOpenEpoch;
    
    mapping(address => Allocation) public allocations;
    mapping(address => bool) public frozen;

    event AllocationsAdded(address[] participants, uint256[] ethAmounts);
    event Claimed(address indexed user, uint256 fraudAmount);
    event DelayedClaimed(address indexed user, uint256 fraudAmount, uint256 bribeAmount);

    constructor(address _fraud, address _bribe, address _dubai) {
        fraud = IFraudToken(_fraud);
        bribe = IBribeToken(_bribe);
        dubai = IDubai(_dubai);
    }
    
    function addAllocations(address[] calldata participants, uint256[] calldata ethAmounts, uint256[] calldata fraudAllocations, uint256[] calldata bribeAllocations) external onlyOwner(){
        require(participants.length == fraudAllocations.length, "Mismatched participants and fraudAllocations");
        require(participants.length == bribeAllocations.length, "Mismatched participants and bribeAllocations");
        require(participants.length == ethAmounts.length, "Mismatched participants and ethAmounts");
        
        for (uint256 i = 0; i < participants.length; i++) {
            uint256 ethAmount = ethAmounts[i];
            uint256 fraudAmount = fraudAllocations[i];
            uint256 bribeAmount = bribeAllocations[i];
            address participant = participants[i];

            allocations[participant].ethAmount = ethAmount;
            allocations[participant].fraudClaimable = fraudAmount.mul(60).div(100);
            allocations[participant].fraudDelayed = fraudAmount.mul(20).div(100);
            allocations[participant].fraudInDubai = fraudAmount.mul(20).div(100);
            allocations[participant].bribeDelayed = bribeAmount;

            lockedInDubai = lockedInDubai.add(allocations[participant].fraudInDubai);

        }
        emit AllocationsAdded(participants, ethAmounts);
    }
    
    // Should we burn or not tokens ? Here virtual tokens are burned
    // Rebase 
    function claim() external {
        require(claimOpen == true, "Claiming not yet opened");
        require(allocations[msg.sender].fraudClaimable > 0, "No tokens to claim");
        uint256 fraudClaimable = allocations[msg.sender].fraudClaimable;
        uint256 epochsElapsed = fraud.getCurrentEpoch().sub(claimOpenEpoch);
        if (epochsElapsed >= 1) {
            uint256 rebaseFactor = 1 ether;  
            for (uint256 i = 0; i < epochsElapsed; i++) {
                rebaseFactor = rebaseFactor.mul(900).div(1000); 
            }
            fraudClaimable = fraudClaimable.mul(rebaseFactor).div(1 ether);
        }

        fraud.mint(msg.sender, fraudClaimable);
        allocations[msg.sender].fraudClaimable = 0;
        emit Claimed(msg.sender, fraudClaimable);
    }

    function claimLocked() external {
        require(claimOpen == true, "Claiming not yet opened");
        require(allocations[msg.sender].fraudDelayed > 0, "No tokens to claim");
        require(block.timestamp >= claimOpenDate.add(1 days), "Claiming time not yet open");
        require(!frozen[msg.sender],"Not authorized");
        uint256 fraudDelayed = allocations[msg.sender].fraudDelayed;
        uint256 openEpoch = claimOpenEpoch.add(1); // 1 day lock = 1 epoch
        uint256 epochsElapsed = fraud.getCurrentEpoch().sub(openEpoch);

        if (epochsElapsed >= 1) {
            uint256 rebaseFactor = 1 ether;  
            for (uint256 i = 0; i < epochsElapsed; i++) {
                rebaseFactor = rebaseFactor.mul(900).div(1000); 
            }
            fraudDelayed = fraudDelayed.mul(rebaseFactor).div(1 ether);
        }
        uint256 bribeDelayed = allocations[msg.sender].bribeDelayed;
        fraud.mint(msg.sender, fraudDelayed);
        bribe.mint(msg.sender, bribeDelayed);
        allocations[msg.sender].fraudDelayed = 0;
        allocations[msg.sender].bribeDelayed = 0;
        emit DelayedClaimed(msg.sender, fraudDelayed, bribeDelayed);
    }
    function setClaimOpen(bool _claimOpen) external onlyOwner {
        claimOpen = _claimOpen;
        claimOpenDate = block.timestamp;
        claimOpenEpoch = fraud.getCurrentEpoch();
    }
    function freeze(address target, bool isFrozen)external onlyOwner{
        frozen[target] = isFrozen;
    }

    function getAllocationFraudInDubai(address _user) external view returns (uint256) {
        return allocations[_user].fraudInDubai;
    }

    function getClaimOpenDate() external view returns (uint256) {
        return claimOpenDate;
    }

    function getClaimOpenEpoch() external view returns (uint256) {
        return claimOpenEpoch;
    }

    function getLockedInDubai() external view returns (uint256) {
        return lockedInDubai;
    }
}
