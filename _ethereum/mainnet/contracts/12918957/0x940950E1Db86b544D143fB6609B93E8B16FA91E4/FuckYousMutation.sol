// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "./EternalLib.sol";
import "./MutationLib.sol";
import "./Modifier.sol";

contract FuckYousMutation is Modifier {

  // NOTES: we check for 0/""/[], so if you want to override
  // something to 0/""/[] you have to set it to 0x00...001 or " "

  function devMutateName(uint tokenId, string memory name) external onlyOwner {
    MutationLib.mutateName(tokenId, name);
  }
  function devMutateText(uint tokenId, string memory text) external onlyOwner {
    MutationLib.mutateText(tokenId, text);
  }
  function devMutateDesc(uint tokenId, string memory desc) external onlyOwner {
    MutationLib.mutateDesc(tokenId, desc);
  }
  function devMutateFenotype(uint tokenId, uint fenotype) external onlyOwner {
    MutationLib.mutateFenotype(tokenId, fenotype);
  }
  function devMutateTemplate(uint tokenId, bytes16 template) external onlyOwner {
    MutationLib.mutateTemplate(tokenId, template);
  }

	function setMutationStart(bool start) external onlyOwner {
    MutationLib.setMutationStart(start);
  }
	function setMutationPrice(uint price) external onlyOwner {
    MutationLib.setMutationPrice(price);
  }
  function getMutationPaid() external payable onlyOwner {
		require(payable(msg.sender).send(address(this).balance));
	}

	function mutateName(uint tokenId, string memory name) external payable canMutate(tokenId) {
    MutationLib.mutateName(tokenId, name);
    MutationLib.mutateTemplate(tokenId, '~s00-mutation');
  }
  function mutateText(uint tokenId, string memory text) external payable canMutate(tokenId) {
    MutationLib.mutateText(tokenId, text);
    MutationLib.mutateTemplate(tokenId, '~s00-mutation');
  }
  function mutateDesc(uint tokenId, string memory desc) external payable canMutate(tokenId) {
    MutationLib.mutateDesc(tokenId, desc);
    MutationLib.mutateTemplate(tokenId, '~s00-mutation');
  }
  function mutateFenotype(uint tokenId, uint fenotype) external payable canMutate(tokenId) {
    MutationLib.mutateFenotype(tokenId, fenotype);
    MutationLib.mutateTemplate(tokenId, '~s00-mutation');
  }

}