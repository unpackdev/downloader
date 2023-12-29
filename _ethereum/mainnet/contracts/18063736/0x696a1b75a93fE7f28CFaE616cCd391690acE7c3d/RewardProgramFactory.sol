// SPDX-License-Identifier: MIT

// RewardProgramFactory.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2023 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";

import "./RewardProgram.sol";
import "./BlackholePrevention.sol";

contract RewardProgramFactory is BlackholePrevention, Ownable {
  event RewardProgramCreated(address indexed rewardProgram);

  address public _template;

  constructor () public {
    _template = address(new RewardProgram());
  }

  // function _msgSender() internal view override returns (address payable) {
  //   return msg.sender;
  // }

  function createRewardProgram(
    address stakingToken,
    address rewardToken,
    uint256 baseMultiplier,
    address chargedManagers,
    address universe
  )
    external
    onlyOwner
    returns (address)
  {
    address newRewardProgram = _createClone(_template);
    RewardProgram rewardProgram = RewardProgram(newRewardProgram);
    rewardProgram.initialize(stakingToken, rewardToken, baseMultiplier, chargedManagers, universe, _msgSender());
    emit RewardProgramCreated(newRewardProgram);
    return newRewardProgram;
  }

  /**
    * @dev Creates Contracts from a Template via Cloning
    * see: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1167.md
    */
  function _createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }


  /***********************************|
  |          Only Admin/DAO           |
  |      (blackhole prevention)       |
  |__________________________________*/

  function withdrawEther(address payable receiver, uint256 amount) external onlyOwner {
    _withdrawEther(receiver, amount);
  }

  function withdrawErc20(address payable receiver, address tokenAddress, uint256 amount) external onlyOwner {
    _withdrawERC20(receiver, tokenAddress, amount);
  }

  function withdrawERC721(address payable receiver, address tokenAddress, uint256 tokenId) external onlyOwner {
    _withdrawERC721(receiver, tokenAddress, tokenId);
  }

  function withdrawERC1155(address payable receiver, address tokenAddress, uint256 tokenId, uint256 amount) external onlyOwner {
    _withdrawERC1155(receiver, tokenAddress, tokenId, amount);
  }
}
