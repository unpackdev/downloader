// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Math.sol";
import "./IMemeLtd.sol";
import "./ERC1155Holder.sol";
import "./Ownable.sol";
import "./BadgerScarcityPoolLib.sol";
import "./ERC20.sol";
import "./Pausable.sol";

contract BadgerScarcityPool is ERC1155Holder, Ownable, Pausable {
  using BadgerScarcityPoolLib for *;
  using SafeMath for *;
  BadgerScarcityPoolLib.Isolate public isolate;
  function bdigg() public view returns (ERC20) {
     return isolate.bdigg;
  }
  function memeLtd() public view returns (IMemeLtd) {
    return isolate.memeLtd;
  }
  function poolTokens(uint256 i) public view returns (BadgerScarcityPoolLib.PoolToken memory) {
    return isolate.poolTokens[i];
  }
  constructor(address _bdigg, address _memeLtd, uint256 _totalSupply, uint256[] memory _tokenIds, uint256[] memory _roots) Ownable() public {
    require(_tokenIds.length == _roots.length, "tokenIds must be same size as roots");
    isolate.totalSupply = _totalSupply;
    for (uint256 i = 0 ; i < _tokenIds.length; i++) {
      isolate.poolTokens.push(BadgerScarcityPoolLib.PoolToken({
        tokenId: _tokenIds[i],
        root: _roots[i]
      }));
    }
    isolate.memeLtd = IMemeLtd(_memeLtd);
    isolate.bdigg = ERC20(_bdigg);
  }
  function _assertMemeLtd() internal view {
    require(msg.sender == address(isolate.memeLtd), "can only send MemeLtd tokens");
  }
  function handleTransfer(address operator, uint256 id, uint256 value, uint256 alreadyTransferred, uint256 _reserve) internal returns (bool) {
    BadgerScarcityPoolLib.PoolToken storage poolToken = isolate.getPoolTokenRecord(id);
    require(isolate.bdigg.transfer(operator, isolate.computePayoutForToken(poolToken, value, alreadyTransferred, _reserve)), "failed to transfer BDigg");
    return true;
  }
  function withdraw(uint256[] memory ids, uint256[] memory values) public onlyOwner {
    isolate.memeLtd.safeBatchTransferFrom(address(this), msg.sender, ids, values, new bytes(0));
  }
  function withdrawFunds() public onlyOwner {
    require(isolate.bdigg.transfer(msg.sender, isolate.bdigg.balanceOf(address(this))), "failed to ERC20.transfer funds");
  }
  function pause() public virtual onlyOwner {
    _pause();
  }
  function unpause() public virtual onlyOwner {
    _unpause();
  }
  function onERC1155Received(address operator, address /* from */, uint256 id, uint256 value, bytes memory /* data */) public whenNotPaused virtual override returns (bytes4) {
    _assertMemeLtd();
    require(value == 1, "can only transfer one token at a time");
    uint256 _reserve = reserve();
    require(handleTransfer(operator, id, value, value, _reserve), "handleTransfer: failure");
    return ERC1155Holder.onERC1155Received.selector;
  }
  function reserve() public view returns (uint256 result) {
    result = isolate.reserve();
  }
  function onERC1155BatchReceived(address /* operator */, address /* from */, uint256[] memory /* ids */, uint256[] memory /* values */, bytes memory /* data */) public virtual override returns (bytes4) {
    revert("batch transfers unsupported");
	  /*
    _assertMemeLtd();
    uint256 alreadyTransferred = values.sum();
    uint256 back = 0;
    for (uint256 i = 0; i < ids.length; i++) {
      back = back.add(values[i]);
      require(handleTransfer(operator, ids[i], values[i], alreadyTransferred.sub(back), reserve()), "handleTransfer: failure");
    }
    return ERC1155Holder.onERC1155BatchReceived.selector;
   */
  }
}
