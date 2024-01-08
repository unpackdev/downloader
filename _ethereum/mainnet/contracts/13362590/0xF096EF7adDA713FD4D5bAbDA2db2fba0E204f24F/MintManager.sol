// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721Enumerable.sol";
import "./Ownable.sol";

interface BaseTokenContract {
      function mintTokenPrivileged(address _recipient) external payable;
}

interface ISaconiStakingAgent is IERC721Enumerable {
    function isStakedByAddress(address staker, address tokenContract, uint256 tokenID) external view returns (bool);
}

contract MintManager is Ownable {
    
    uint256 constant tokenPrice = 100000000000000000;
    
    uint256 constant normalLimit = 1241; // 3000 - 1659 - 100
    uint256 constant waltzLimit = 100;
    
    address constant waltzAddress = 0xD58434F33a20661f186ff67626ea6BDf41B80bCA; // Mainnet
  	address constant saconiStakingAddress = 0x23e369A9A725c7Da18d023d1C7c8b928237e24f7; // Mainnet
  	ISaconiStakingAgent ITokenContract = ISaconiStakingAgent(saconiStakingAddress);
    
    // Needed for staking function to check tokenId
    address constant saconiHolmovimientoAddress = 0x0B1F901EEDfa11E7cf65efeB566EEffb6D38fbc0; // Mainnet
    address constant baseAddress = 0xEc8bcffD08bb22Aed27F083b59212b8194B99dBa; // Mainnet

    bool specialMintingEnabled;
    bool normalMintingEnabled;
    
    uint256 waltzCount;
    uint256 normalCount;
    
    address payable recipient1;
    address payable recipient2;
    address payable recipient3;

    
    mapping (uint256 => bool) waltzTokenIsRedeemed;
    mapping (address => uint256) freeMintsClaimedSaconi;
    
    constructor() {
        recipient1 = payable(0x6a024f521f83906671e1a23a8B6c560be7e980F4);
        recipient2 = payable(0x212Da8c9Dad7e9B6a71422665c58Bf9a7ECAe6D0);
        recipient3 = payable(0xf0bE1F2FB8abfa9aBF7d218a226ef4F046f09a40);
        
        specialMintingEnabled = false;
        normalMintingEnabled = false;
        
        waltzCount = 0;
        normalCount = 0;
    }
    
    function mintSpecialSaconi() private {
        require(specialMintingEnabled == true, "Special minting not enabled");
        BaseTokenContract(baseAddress).mintTokenPrivileged(msg.sender);
    }
  
    function maxFreeClaimsSaconi(uint256 stakedAmount) internal pure returns (uint256) {
        if (stakedAmount >= 7) {
            return 4+(stakedAmount-5)/2;
        } else if (stakedAmount >= 4) {
            return 3;
        } else if (stakedAmount >= 2) {
            return 2;
        } else if (stakedAmount == 1) {
            return 1;
        } else {
            return 0;
        }
    }
  
    function claimFreeMintsSaconi(uint256 mint, uint256 stakedAmount, uint256[] calldata tokenIDList) external {
        require(mint <= 10, "Max. 10 per transaction");
        
        for (uint256 i=0; i<stakedAmount; i++) {
            require(ITokenContract.isStakedByAddress(msg.sender, saconiHolmovimientoAddress, tokenIDList[i]), "Token not owned");
        }
        require(mint + freeMintsClaimedSaconi[msg.sender] <= maxFreeClaimsSaconi(stakedAmount), "All free mints used");
        
        for (uint256 i=0; i<mint; i++) {
            // no need for args, internal function
            mintSpecialSaconi();
            freeMintsClaimedSaconi[msg.sender]++;
        }
    }
    
    function mintPaid() internal {
        require(msg.value == tokenPrice, "Incorrect value");
        BaseTokenContract(baseAddress).mintTokenPrivileged(msg.sender);
        
        uint256 part1 = (33 * 100 * msg.value) / (100*100);
        uint256 part2 = (33 * 100 * msg.value) / (100*100);
        uint256 part3 = (msg.value) - (part1+part2);
        recipient1.transfer(part1);
        recipient2.transfer(part2);
        recipient3.transfer(part3);
    }
    
    function mintSpecialWaltz() public payable {
        require(specialMintingEnabled == true, "Special minting not enabled");
        require(waltzCount < waltzLimit, "WALTZ special limit reached");
        waltzCount++;
        uint256 ownedTokenID = IERC721Enumerable(waltzAddress).tokenOfOwnerByIndex(msg.sender, 0);
        require(waltzTokenIsRedeemed[ownedTokenID] == false);
        waltzTokenIsRedeemed[ownedTokenID] = true;
        mintPaid();
    }
    
    function mintNormal() public payable {
        require(normalMintingEnabled == true, "Normal minting not enabled");
      	require(normalCount < normalLimit, "Normal limit reached");
      	normalCount++;
        mintPaid();
    }
    
    function setMintingEnabled(bool _specialMintingEnabled, bool _normalMintingEnabled) public onlyOwner {
        specialMintingEnabled = _specialMintingEnabled;
        normalMintingEnabled = _normalMintingEnabled;
    }

}