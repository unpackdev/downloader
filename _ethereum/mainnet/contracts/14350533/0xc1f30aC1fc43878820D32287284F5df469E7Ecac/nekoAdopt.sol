// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract nekoAdopt is Ownable, ERC721A, ReentrancyGuard {

    uint256 public constant MINT_PRICE = 0.1 ether;
    uint256 public constant MAX_MINT_PER_TX = 5;
    uint256 public constant FEEDING_FEE = 0.03 ether;
    uint256 public constant TOTAL_ROUNDS = 2;

    uint256 public winnersShare;
    uint256 public totalPetsSurvived;
    uint256 public _gameIndex = 0;
    uint256[] public usersTokenIds;

    bool public mintActive;
    bool public feedingIsActive;
    bool public refundStatus;
    bool public gameHadEnded;
    bool public _withdrew;

    mapping (uint256 => bool) public isPetAlive;
    mapping (uint256 => bool) public isFed;
    mapping(uint256 => uint256) public petFedIndex;
    mapping(uint256 => bool) public petHasClaimedPrize;
    mapping(address => bool) public isWhitelisted;


    constructor()ERC721A("NekoDegen", "nAdopt") {

    }

    function getTotalSupply() external view onlyOwner returns(uint256){
        return totalSupply();
    }

    function setMintActive() external onlyOwner {
        mintActive = true;
    }

    function setMintInactive() external onlyOwner {
        mintActive = false;
    }

    //UTILITIES
    function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    returns (uint256)
  {
    require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
    uint256 numMintedSoFar = totalSupply();
    uint256 tokenIdsIdx = 0;
    address currOwnershipAddr = address(0);
    for (uint256 i = 0; i < numMintedSoFar; i++) {
      TokenOwnership memory ownership = _ownerships[i];
      if (ownership.addr != address(0)) {
        currOwnershipAddr = ownership.addr;
      }
      if (currOwnershipAddr == owner) {
        if (tokenIdsIdx == index) {
          return i;
        }
        tokenIdsIdx++;
      }
    }
    revert("ERC721A: unable to get token of owner by index");
  }

    function whitelistAddress (address user) external onlyOwner {
            isWhitelisted[user] = true;
    }

    function mint(uint256 quantity) external payable {
        require(quantity <= MAX_MINT_PER_TX, "Max 5 mints per tx");
        require(mintActive);
        require(MINT_PRICE * quantity == msg.value);
        require(isWhitelisted[msg.sender]);
        // require(verifySignature(signature, nonce, _signatureVerifier));
        _safeMint(msg.sender, quantity);
    }

    function getUserTokenIds(address user) external view onlyOwner returns(uint256[] memory) {
        return walletOfOwner(user);
    }


    function mapTokenIds() public onlyOwner {
        for (uint256 i = 0; i < totalSupply(); i++){
            isPetAlive[i] = true;
            isFed[i] = false;
            petHasClaimedPrize[i] = false;
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }


    //GAME LOGIC
    function checkPetAlive(uint256 tokenId) internal view onlyOwner returns (bool) {
        bool isAlive = isPetAlive[tokenId];
        if(isAlive == true){
            return isAlive = true;
        }
        return isAlive = false;
    }

    function checkPetFedStatus(uint256 tokenId) internal view onlyOwner returns (bool) {
        bool isPetFed = isFed[tokenId];
        if(isPetFed == true){
            return isPetFed = true;
        }
        return isPetFed = false;
    }
    
    function checkPetHasClaimed(uint256 tokenId) internal view onlyOwner returns (bool) {
        bool petHasClaimed = petHasClaimedPrize[tokenId];
        if(petHasClaimed == true){
            return petHasClaimed = true;
        }
        return petHasClaimed = false;
    }

    function checkPetIndex() external onlyOwner {
        for(uint256 i = 0; i < totalSupply(); i++){
            if(petFedIndex[i] < _gameIndex){
                isPetAlive[i] = false;
            }
        }
    }

    function toggleFeedingState(bool state) external onlyOwner {
        _gameIndex++;
        feedingIsActive = state;
    }

    function resetFedStatus() external onlyOwner {
        for (uint256 i = 0; i <= totalSupply(); i ++) {
            isFed[i] = false;
        }  
    }

    function feedPet(uint256 tokenId) external payable {
        require(ownerOf(tokenId) == msg.sender);
        require(isPetAlive[tokenId]);
        require(!isFed[tokenId]);
        require(feedingIsActive);
        petFedIndex[tokenId] = _gameIndex + 1;
        isFed[tokenId] = true;
    }

    function isGameOver(uint256 currentRound) internal view onlyOwner returns (bool) {
        if(currentRound == TOTAL_ROUNDS){
            return true;
        }
        return false;
    }

    function endGame() external onlyOwner {
        require(isGameOver(_gameIndex), "Game is not over");
        require(!_withdrew, "already withdrew");
        uint256 balance = address(this).balance;
        uint256 ownerShare = balance / 100 * 30;
        winnersShare = balance - ownerShare;
        uint256 alivePetCount;
        for (uint256 i = 0; i < totalSupply(); i++){
            if (checkPetAlive(i) == true) {
                alivePetCount++;
            }
        }
        totalPetsSurvived = alivePetCount;
        _withdrew = true;
        gameHadEnded = true;
        payable(msg.sender).transfer(ownerShare);
    }

    function feedAll(address user) external payable {
        require(feedingIsActive);
        require(FEEDING_FEE * walletOfOwner(user).length == msg.value);
        for(uint256 i = 0; i < totalSupply(); i++){
            uint256 currentPet = i;
            bool petAlive = isPetAlive[i];
            bool petFed = isFed[i];
            if(ownerOf(currentPet) != msg.sender || petAlive == false || petFed == true){
                continue;
            }
            petFedIndex[currentPet] = _gameIndex + 1;
            isFed[currentPet] = true;
        }
    }

    function claimPrize(uint256[] memory pets) external nonReentrant { 
        require(_withdrew, "Awaiting game to end");
        uint256 alivePetsToClaimPrize;
        for (uint256 i = 0; i < pets.length; i++) {
            uint256 currentPet = pets[i];
            bool petAlive = isPetAlive[i];
            bool petHasClaimed = petHasClaimedPrize[i];
            if (ownerOf(currentPet) != msg.sender ||  petAlive == false || petHasClaimed == true) {
                continue;
            }
            petHasClaimedPrize[currentPet] = true;
            alivePetsToClaimPrize++;
        }
        uint256 claimablePrize = winnersShare * alivePetsToClaimPrize / totalPetsSurvived;
        payable(msg.sender).transfer(claimablePrize);
    }


}