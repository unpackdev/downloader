//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Pausable.sol";

import "./SignedAllowanceWithData.sol";

interface IKitBag {
  function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
  function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract ComicDrop is Ownable, Pausable, SignedAllowanceWithData {
    IKitBag public kitBag;

    event Drop(address recipient, uint256[] odds, uint256 comic);

    constructor(
        address _kitBag
    ) {
        kitBag = IKitBag(_kitBag);
    }

    function allowancesSigner() public view override returns (address) {
        return owner();
    }

    function createComicMessage(address account, uint256 index, uint256[] calldata odds) public view returns (bytes32) {
        return createMessage(account, index, abi.encode(odds[0], odds[1]));
    }

    function pickComic(uint256 pseudoRandom, uint256[] calldata odds) internal pure returns(uint256) {
      if(pseudoRandom < odds[0]) {
        return 1;
      } else if (pseudoRandom < odds[1]) {
        return 2;
      } else {
        return 3;
      }
    }

    function mint(uint256 index, uint256[] calldata odds, bytes calldata signature) public whenNotPaused {
      _useAllowance(index, abi.encode(odds[0], odds[1]), signature);
      uint256 pseudoRandom = uint256(keccak256(abi.encode(blockhash(block.number-1), blockhash(block.number-5), odds[0], odds[1], msg.sender)));
      uint256 comic = pickComic(pseudoRandom & 0xFF, odds);
      kitBag.mint(msg.sender, comic, 1, "0x");
      emit Drop(msg.sender, odds, comic);
    }

    function setPaused(bool _bPaused) external onlyOwner {
        if (_bPaused) _pause();
        else _unpause();
    }

    function comicBalance(address _user) public view returns(uint256) {
      return kitBag.balanceOf(_user, 1) + kitBag.balanceOf(_user, 2) + kitBag.balanceOf(_user, 3);
    }

}
