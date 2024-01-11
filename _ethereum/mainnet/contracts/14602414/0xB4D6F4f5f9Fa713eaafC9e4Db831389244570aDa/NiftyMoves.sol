// SPDX-License-Identifier: MIT
// Omnus Contracts (contracts/NFT-utilities/NiftyMoves.sol)
// https://omnuslab.com/nifty-moves
 
// NiftyMoves (Gas efficient batch ERC721 transfer)

pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./IERC721.sol";
import "./SafeERC20.sol";
import "./ERC20SpendableReceiver.sol"; 

contract NiftyMoves is Ownable, ERC20SpendableReceiver {
  using SafeERC20 for IERC20;

  uint256 public ethFee;
  uint256 public oatFee;
  address public treasury;

  /**
  *
  * @dev TreasurySet: Emit that the treasury has been set.
  *
  */
  event TreasurySet(address treasury);

  /**
  *
  * @dev EthFeeUpdated: Emit that the Eth fee has been set.
  *
  */
  event EthFeeUpdated(uint256 oldFee, uint256 newFee);

  /**
  *
  * @dev EthFeeUpdated: Emit that the oat fee has been set.
  *
  */
  event OatFeeUpdated(uint256 oldFee, uint256 newFee);

  /**
  *
  * @dev TokenWithdrawal: Emit that tokens or ETH have been withdrawn:
  *
  */
  event EthWithdrawal(uint256 indexed withdrawal);
  event TokenWithdrawal(uint256 indexed withdrawal, address indexed tokenAddress);

  /**
  *
  * @dev NiftyMovesMade: Emit that the service has been used.
  *
  */
  event NiftyMovesMade(
    address sender,
    address tokenContract,
    address to,
    uint256 totalTransfers,
    uint256 totalFeeEth,
    uint256 totalFeeOat
  );

  /**
  *
  * @dev constructor: must recieve the address of the ERC20Spendable.
  *
  */
  constructor(address _ERC20Spendable) 
    ERC20SpendableReceiver(_ERC20Spendable) {
  }

  function totalFee(uint256 itemCount) external view returns(uint256 totalEthFee, uint256 totalOatFee) {
    return(ethFee * itemCount, oatFee * itemCount);
  }

  /**
  *
  * @dev makeNiftyMoves: function call for transfers with fee payment in Eth:
  *
  */
  function makeNiftyMoves(address _contract, address _to, uint256[] memory _tokenIds) payable external {
    
    uint256 expectedFeeEth = _tokenIds.length * ethFee;

    require(msg.value == expectedFeeEth, "Incorrect fee paid");

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      IERC721(_contract).safeTransferFrom(msg.sender, _to, _tokenIds[i]);
    }

    emit NiftyMovesMade(msg.sender, _contract, _to, _tokenIds.length, expectedFeeEth, 0);
   
  }

  /**
  *
  * @dev receiveSpendableERC20: standard entry point for all calls relayed via the payable ERC20. 
  *
  */
  function receiveSpendableERC20(address _caller, uint256 _tokenPaid, uint256[] memory _arguments) override external onlyERC20Spendable(msg.sender) returns(bool, uint256[] memory) { 

    /**
    *
    * @dev Array is in the following format:
    *   Position 0 = contract that items are being transfered from.
    *   Position 1 = address that the items are being transfered to.
    *   Position 2 to n = tokenIds to be transfered.
    *
    */
    address nftContract = address(uint160(_arguments[0]));
    address toAddress   = address(uint160(_arguments[1]));

    uint256 expectedFeeOat = (_arguments.length - 2) * oatFee;

    require(_tokenPaid == expectedFeeOat, "Incorrect fee paid");

    for (uint256 i = 2; i < _arguments.length; i++) {
      IERC721(nftContract).safeTransferFrom(_caller, toAddress, _arguments[i]);
    }

    emit NiftyMovesMade(_caller, nftContract, toAddress, _arguments.length - 2, 0, expectedFeeOat);

    uint256[] memory returnResults = new uint256[](1);

    return(true, returnResults);

  }

  /** 
  *
  * @dev setTreasury: Owner can update treasury address.
  *
  */ 
  function setTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
    emit TreasurySet(_treasury);
  }

  /**
  *
  * @dev updateEthFee: Owner can updte the Eth fee.
  *
  */
  function updateEthFee(uint256 _ethFee) external onlyOwner {
    uint256 oldFee = ethFee;
    ethFee = _ethFee;
    emit EthFeeUpdated(oldFee, ethFee);
  }

  /**
  *
  * @dev updateOatFee: Owner can updte the oat fee.
  *
  */
  function updateOatFee(uint256 _oatFee) external onlyOwner {
    uint256 oldFee = oatFee;
    oatFee = _oatFee;
    emit EthFeeUpdated(oldFee, oatFee);
  }

  /** 
  * @dev owner can withdraw eth to treasury:
  */ 
  function withdrawEth(uint256 _amount) external onlyOwner returns (bool) {
    (bool success, ) = treasury.call{value: _amount}("");
    require(success, "Transfer failed.");
    emit EthWithdrawal(_amount);
    return true;
  }

  /**
  *
  * @dev Allow any token payments to be withdrawn:
  *
  */
  function withdrawERC20(IERC20 _token, uint256 _amountToWithdraw) external onlyOwner {
    _token.safeTransfer(treasury, _amountToWithdraw); 
    emit TokenWithdrawal(_amountToWithdraw, address(_token));
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