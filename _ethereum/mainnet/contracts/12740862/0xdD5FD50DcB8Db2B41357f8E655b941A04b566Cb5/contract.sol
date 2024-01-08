//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./IUniswapV2Router.sol";
import "./Ownable.sol";
/**
 * @title Myobu Buyback Contract 2
 * @author Myobu Devs
 */
contract myobuBuybackContract is Ownable{
  /**
   * @dev
   * _uniswapV2Router: The Uniswap V2 Router
   * _myobu: The Myobu token contract
   * _burnAddress: Where all tokens that are buybacked will be sent to
   */
  IUniswapV2Router private _uniswapV2Router;
  address private _myobu;
  address private _burnAddress;
  uint256 private _senderFee;

  /**
   * @dev Sets the Uniswap V2 Contracts, The Myobu token address and the
   * burn address
   */
  constructor(){
    _uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    _myobu = address(0x75D12E4F91Df721faFCae4c6cD1d5280381370AC);
    _burnAddress = address(0x000000000000000000000000000000000000dEaD);
    _senderFee = 200;
  }

  /**
   * @dev Swaps all Ether the contract has to Myobu and sends to the 
   * burn address
   */
  function buyback() external {
    address[] memory path = new address[](2);
    path[0] = _uniswapV2Router.WETH();
    path[1] = _myobu;
    uint256 feeToSender = (address(this).balance * _senderFee) / 10000;
    payable(_msgSender()).transfer(feeToSender);
    _uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: address(this).balance}(0, path, _burnAddress, block.timestamp);
  }
  
  function setSenderFee(uint256 newSenderFee) external onlyOwner {
    require(newSenderFee > 9);
    _senderFee = newSenderFee;
  }
  
  /**
   * @dev Functions so that the contract can recieve Ether
   */
  receive() external payable { }
  function recieve() external payable { }


  /**
   * @return The current Uniswap V2 Router contract being used
   */
  function uniswapV2Router() external view returns (IUniswapV2Router){
    return _uniswapV2Router;
  }

  /**
   * @return The current token being used
   */
  function myobu() external view returns (address){
    return _myobu;
  }

  /**
   * @return Where all tokens that are buybacked will be sent to
   */
  function burnAddress() external view returns (address) {
    return _burnAddress;
  }
  
  /**
   * @dev Functions that only the owner can call that change the variables
   * of this Contract
   */
  function senderFee() external view returns (uint256) {
     return _senderFee;
  }
  
}
