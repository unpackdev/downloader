// SPDX-License-Identifier: MIT
// Omnus Contracts (contracts/NFT-utilities/NiftyMoves.sol)
// https://omnus.land/nifty-moves
 
// NiftyMoves (Gas efficient batch ERC721 transfer)

pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./IERC721.sol";
import "./SafeERC20.sol";

contract NiftyMoves is Ownable {
  using SafeERC20 for IERC20;

  /**
  *
  * @dev constructor: no args
  *
  */
  constructor() 
    {}

  /**
  *
  * @dev makeNiftyMoves: function call for transfers:
  *
  */
  function makeNiftyMoves(address _contract, address _to, uint256[] memory _tokenIds) external {

    for (uint256 i = 0; i < _tokenIds.length;) {
      IERC721(_contract).transferFrom(msg.sender, _to, _tokenIds[i]);
      unchecked{ i++; }
    }
   
  }

  /** 
  *
  * @dev owner can withdraw eth. No eth is ever taken but this allows the owner to return
  * funds sent incorrectly to the contract
  *
  */ 
  function withdrawEth(uint256 _amount) external onlyOwner returns (bool) {
    (bool success, ) = owner().call{value: _amount}("");
    require(success, "Transfer failed.");
    return true;
  }

  /** 
  *
  * @dev owner can withdraw ERC20s. No payment is ever taken but this allows the owner to return
  * funds sent incorrectly to the contract
  *
  */ 
  function withdrawERC20(IERC20 _token, uint256 _amountToWithdraw) external onlyOwner {
    _token.safeTransfer(owner(), _amountToWithdraw); 
  }

  /**
  *
  * @dev Do not receive unidentified Eth or function calls:
  *
  */
  receive() external payable {
    require(msg.sender == owner(), "Only owner can fund contract");
  }

  fallback() external payable {
    revert();
  }
}
