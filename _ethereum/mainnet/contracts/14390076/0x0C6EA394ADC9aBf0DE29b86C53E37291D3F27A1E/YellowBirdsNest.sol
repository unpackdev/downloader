// SPDX-License-Identifier: MIT
// Yellow Bird's Nest - tweet tweet. Come get me, if you can... ethertree.org

pragma solidity ^0.8.11;
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

contract YellowBirdsNest is IERC721Receiver, Ownable {
  // Contract implementation Ether Tree:
  address public constant ETHER_TREE_ADDRESS = 0xe77c4E5e17Ea350993CAC2EB48BB50DbCcCc956B;
  IERC721 public constant ETHER_TREE = IERC721(ETHER_TREE_ADDRESS);
  uint256 public constant YELLOW_BIRD = 98;
  string  public constant MAGIC_LOCK = "My heart leaps up when I behold A rainbow in the sky: So was it when my life began; So is it now I am a man; So be it when I shall grow old, Or let me die! The Child is father of the Man; And I could wish my days to be Bound each to each by natural piety."; 
  bytes32 public constant MAGIC_ANSWER = 0x76e1338484b250842899780087a8b6889265e7aa9f15e1c29df82fed71098d7b;

  /** -----------------------------------------------------------------------------
   *   Contract event definitions
   *   -----------------------------------------------------------------------------
   */
  event nestRaided(
    address newYellowBirdCarer,
    string message
  );

  constructor() {}

  function onERC721Received(
    address,
    address,
    uint256 tokenId,
    bytes memory
  ) external virtual override returns (bytes4) {
    require((msg.sender == ETHER_TREE_ADDRESS && tokenId == YELLOW_BIRD), "Wait, you aren't yellow bird! Begone!");
    return this.onERC721Received.selector;
  }

  // Ain't no reason to have eth arrive here:
  receive() external payable {
    revert();
  }

  fallback() external payable {
    revert();
  }

  function gentlyRemoveTheNest(uint256 magicKey) external {
    if (keccak256(abi.encodePacked(magicKey, MAGIC_LOCK)) == MAGIC_ANSWER) {
      // Has some hardy soul beaten you here? My sympathy. But we will save your gas, this will revert cleanly:
      require((ETHER_TREE.ownerOf(YELLOW_BIRD) == address(this)), "Oh no, someone beat you to it! :(");
      // A shocked crowd looks on in wonder as you climb the fabled tree. You take the next gently in your
      // hands and it lifts free from the branches! Everyone holds their breath as you climb to the ground,
      // a great cheer eruption as your feet hit the soil! Where so many have failed, you did it! Yellow
      // Bird is yours!
      ETHER_TREE.safeTransferFrom(address(this), msg.sender, YELLOW_BIRD);
      emit nestRaided(msg.sender, "Look after my bird please");
    }
    else {
      // Not today friend - you fall from the tree, your body uninjured but your pride dented. Remember, the prize
      // is still there to be won....
      bool beauty = false;
      bool truth = true;
      require(beauty == truth, "Incorrect key noble searcher. Search on!");
    }
  }
}