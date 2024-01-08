// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./ERC721Holder.sol";
import "./IERC721Enumerable.sol";
import "./Ownable.sol";

interface CardInterface is IERC721Enumerable {
  function setPublicMax(uint256 _publicMax) external;

  function publicMax() external view returns (uint256);

  function transferOwnership(address newOwner) external;

  function mintPublic() external;
}

contract CardInterfaceOwner is Ownable {
  CardInterface AC = CardInterface(0x329Fd5E0d9aAd262b13CA07C87d001bec716ED39);

  constructor() {}

  function mint(uint256 number) external onlyOwner {
    uint256 start = AC.publicMax();
    AC.setPublicMax(start + number);
    for (uint256 i = 0; i < number / 2; i++) {
      OneMint newContract = new OneMint();
      newContract.mint();
    }
  }

  function returnToSender() external onlyOwner {
    AC.transferOwnership(msg.sender);
  }
}

contract OneMint is ERC721Holder {
  CardInterface AC = CardInterface(0x329Fd5E0d9aAd262b13CA07C87d001bec716ED39);

  constructor() {}

  function mint() external {
    AC.mintPublic();
    AC.safeTransferFrom(
      address(this),
      tx.origin,
      AC.tokenOfOwnerByIndex(address(this), 0)
    );

    AC.mintPublic();
    AC.safeTransferFrom(
      address(this),
      tx.origin,
      AC.tokenOfOwnerByIndex(address(this), 0)
    );
  }
}
