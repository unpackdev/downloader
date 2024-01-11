// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/*
                          .-=*#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#*+=:
                      :+#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*-
                   :+%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=
                .+%@@@@@@@@@@@@%#*++==================================++*#%@@@@@@@@@@@@@#-
               +@@@@@@@@@@@*=:                                              :=*@@@@@@@@@@@%.
             :%@@@@@@@@@*:                                                      :*@@@@@@@@@@+
            =@@@@@@@@@+                                                           .*@@@@@@@@@%.
           *@@@@@@@@+.                                                              .+@@@@@@@@@-
          #@@@@@@@#.                                                                  .#@@@@@@@@-
         +@@@@@@@*                                                                      *@@@@@@@@
        .@@@@@@@*                                                                        *@@@@@@@=
        +@@@@@@%                                                                          %@@@@@@#
        %@@@@@@=                                                                          =@@@@@@@
        @@@@@@@:                                                                          :@@@@@@@
        @@@@@@@.              :#####.                                .#####.              .@@@@@@@
        @@@@@@@.              :@@@@@.                                :@@@@@:              .@@@@@@@
        @@@@@@@.              :%%%%@#***:                        :***#@%%%%:              .@@@@@@@
        @@@@@@@.                   #@@@@-                        -@@@@#                   .@@@@@@@
        @@@@@@@.                   #@@@@*====                ====*@@@@#                   .@@@@@@@
        @@@@@@@.                       +@@@@@                @@@@@+                       .@@@@@@@
        @@@@@@@.                       +@@@@@                @@@@@+                       .@@@@@@@
        @@@@@@@.                       .:::::                :::::.                       .@@@@@@@
        @@@@@@@.                                                                          .@@@@@@@
        @@@@@@@.                                                                          .@@@@@@@
        @@@@@@@.                           -##################                            .@@@@@@@
        @@@@@@@.                           =@@@@@@@@@@@@@@@@@@                            .@@@@@@@
        @@@@@@@.                       ++++#@%%%%%%%%%%%%%%%%@++++-                       .@@@@@@@
        @@@@@@@.                      .@@@@@+                @@@@@*                       .@@@@@@@
        @@@@@@@.                  .---=@@@@@+                @@@@@#---:                   .@@@@@@@
        @@@@@@@.                  =@@@@%....                 ....-@@@@@                   .@@@@@@@
        @@@@@@@.                  =@@@@#                         :@@@@@                   .@@@@@@@
        @@@@@@@:                   ::::.                          ::::.                   :@@@@@@@
        %@@@@@@=                                                                          =@@@@@@@
        *@@@@@@%                                                                          %@@@@@@#
        :@@@@@@@*                                                                        *@@@@@@@=
         *@@@@@@@*                                                                      *@@@@@@@@.
          @@@@@@@@#.                                                                  .#@@@@@@@@=
          .%@@@@@@@@+.                                                              .+@@@@@@@@@=
            #@@@@@@@@@+                                                           .*@@@@@@@@@@-
             =@@@@@@@@@@*:                                                      :*@@@@@@@@@@#.
              .#@@@@@@@@@@@*=:                                              :=*@@@@@@@@@@@@=
                -#@@@@@@@@@@@@@%#*++==================================++*#%@@@@@@@@@@@@@@+.
                  .=%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*:
                     .=%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%+:
                         .-=+*#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#*+=:.

*/

import "./IERC1155.sol";
import "./ERC1155Receiver.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract DeeKaySpecialsMinter is Ownable, ERC1155Receiver {
  uint256 public price = 0.2 ether;
  bool public saleActive = false;

  bytes32 public merkleRoot;
  mapping(address => bool) private _hasClaimed;

  IERC1155 public collection;

  constructor(address collectionAddress) {
    collection = IERC1155(collectionAddress);
  }

  // Accessors

  function setSaleActive(bool active) public onlyOwner {
    saleActive = active;
  }

  function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
    merkleRoot = merkleRoot_;
  }

  function hasClaimed(address account) public view returns (bool) {
    return _hasClaimed[account];
  }

  function balances() public view returns (uint256, uint256, uint256) {
    return (
      collection.balanceOf(address(this), 1),
      collection.balanceOf(address(this), 2),
      collection.balanceOf(address(this), 3)
    );
  }

  // Store

  function purchaseToken(uint256 tokenId, bytes32[] calldata merkleProof) public payable {
    require(saleActive, "Sale is closed");
    require(tokenId == 1 || tokenId == 2 || tokenId == 3, "Unknown token");
    require(msg.value == price, "Incorrect payable amount");
    require(!_hasClaimed[_msgSender()], "Already claimed");
    require(_verify(merkleProof, _msgSender()), "Invalid proof");

    _hasClaimed[_msgSender()] = true;
    collection.safeTransferFrom(address(this), _msgSender(), tokenId, 1, "");
  }

  function ownerTransferTo(address to, uint256 tokenId, uint256 amount) public onlyOwner {
    collection.safeTransferFrom(address(this), to, tokenId, amount, "");
  }

  function withdraw(address receiver) public onlyOwner {
    payable(receiver).transfer(address(this).balance);
  }

  // Private

  function _verify(
    bytes32[] calldata merkleProof,
    address sender
  ) private view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(sender));
    return MerkleProof.verify(merkleProof, merkleRoot, leaf);
  }

  // IERC1155Receiver

  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) external pure returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }
}
