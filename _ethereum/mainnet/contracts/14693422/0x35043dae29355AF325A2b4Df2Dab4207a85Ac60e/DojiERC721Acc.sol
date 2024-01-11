// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IERC721Enumerable.sol";
import "./console.sol";
import "./DojiCourrier.sol";

contract Doji721Accounting is Ownable {
    event LuckyHolder(uint256 indexed luckyHolder, address indexed sender);
    event ChosenHolder(uint256 indexed chosenHolder, address indexed sender);

    DojiClaimsProxy claimContract;

    struct NFTClaimInfo {
      address nftContract;
      uint256 tokenID;
      uint256 holder;
      bool claimed;
    }
    mapping (uint256 => NFTClaimInfo[]) public nftClaimInfo;

    constructor(){
    }

    modifier onlyClaimContract() { // Modifier
        require(
            msg.sender == address(claimContract),
            "Only Claim contract can call this."
        );
        _;
    }

  function random721(address nftContract, uint256 tokenID) external onlyClaimContract {
    uint256 luckyFuck = pickLuckyHolder();
    NFTClaimInfo memory newClaim = NFTClaimInfo(nftContract, tokenID, luckyFuck, false);
    nftClaimInfo[luckyFuck].push(newClaim);
    emit LuckyHolder(luckyFuck, nftContract);
  }

  function send721(address nftContract, uint256 tokenID, uint256 chosenHolder) public {
    require(chosenHolder > 0 && chosenHolder <= 11111, "That Doji ID is does not exist");
    ERC721(nftContract).safeTransferFrom(msg.sender,address(claimContract),tokenID, 'true');
    NFTClaimInfo memory newClaim = NFTClaimInfo(nftContract, tokenID, chosenHolder, false);
    nftClaimInfo[chosenHolder].push(newClaim);
    emit ChosenHolder(chosenHolder, nftContract);
  }

	function pickLuckyHolder() private view returns (uint) {
		uint256 rando = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, claimContract._currentBaseTokensHolder())));
		uint index = (rando % claimContract._currentBaseTokensHolder());
		uint result = IERC721Enumerable(claimContract._baseTokenAddress()).tokenByIndex(index);
		return result;
	}

    function viewNFTsPending(uint ID)view external returns (NFTClaimInfo[] memory) {
      return nftClaimInfo[ID];
    }

    function viewNFTsPendingByIndex(uint ID, uint index)view external returns (NFTClaimInfo memory) {
      return nftClaimInfo[ID][index];
    }

    function viewNumberNFTsPending(uint ID) view external returns (uint) {
      return nftClaimInfo[ID].length;
    }

    function viewNumberNFTsPendingByAcc(address account) public view returns(uint256){
      BaseToken baseToken = BaseToken(claimContract._baseTokenAddress());
      uint256[] memory userInventory = baseToken.walletInventory(account);
      uint256 pending;

      // get pending payouts for all tokenIDs in caller's wallet
      for (uint256 index = 0; index < userInventory.length; index++) {
          for(uint256 j = 0; j < nftClaimInfo[userInventory[index]].length; j++) {
              if (nftClaimInfo[userInventory[index]][j].claimed == false) {
                  pending++;
              }
          }
      }
      return pending;
    }

    function claimNft(uint ID, uint index) external onlyClaimContract {
      require(msg.sender == address(claimContract));
      nftClaimInfo[ID][index].claimed = true;
    }

    function setClaimProxy (address proxy) public onlyOwner {
      claimContract = DojiClaimsProxy(payable(proxy));
    }
}