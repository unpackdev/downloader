//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

import "./IERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";

interface IApeNFT is IERC721Upgradeable, IERC721EnumerableUpgradeable{
  // Market related functions
  function quote(uint256 num) external view returns(uint256);
  function quoteSpecific(uint256 id) external view returns(uint256);
  function validOrder(address proposer, uint256 num) external view returns(bool);
  function mintBatch(address target, uint256 num) payable external;
  function mintSpecific(address target, uint256 id) payable external;
}