// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract CHICHIAdoptionCenter is Ownable {
  using Counters for Counters.Counter;

  // Emitted when an adoption occurred
  event Adopted(address indexed adopter, uint numberOfChichis);
  event TransferredToTreasury(uint numberOfChichis);

  // Name of the smart contract
  string constant private _name = "CHICHI Adoption Center";

  // Token that will be used to transfer funds
  ERC20 private _token;

  // Block number when the program starts
  uint256 private _startingBlock;

  // Duration of the program measured in number of blocks
  uint256 private _activeDuration;

  // Address of the CHICHI Treasury.
  address private _treasury;

  // Number of times people have adopted CHICHIs
  Counters.Counter private _adoptions;

  // Mapping from adopter to number of CHICHIs adopted
  mapping(address => uint256) private _adopters;

  /**
    Smart contract initialization.
    */
  constructor(ERC20 token, uint256 startingAt, uint256 activeDuration, address treasuryAddress) {
    require(treasuryAddress != address(0), "Treasury address cannot be the zero address");

    _token = token;
    _startingBlock = startingAt;
    _activeDuration = activeDuration;
    _treasury = treasuryAddress;
  }

  /**
   Returns the block number when the program starts.
   */
  function startingBlock() external view returns (uint256) {
    return _startingBlock;
  }

  /**
   Returns the duration of the program measured in number of blocks.
   */
  function activeForNumberOfBlocks() external view returns (uint256) {
    return _activeDuration;
  }

  /**
   Returns the block number when the program ends.
   */
  function endingBlock() public view returns (uint256) {
    return _startingBlock + _activeDuration;
  }

  /**
   Indicates if the program has started.
   */
  function hasStarted() public view returns (bool) {
    return block.number >= _startingBlock;
  }

  /**
   Indicates if the program has ended.
   */
  function hasEnded() public view returns (bool) {
    return block.number > endingBlock();
  }

  /**
    Returns the smart contract name.
    */
  function name() external pure returns (string memory) {
    return _name;
  }

  /**
    Returns the treasury address.
    */
  function treasury() external view returns (address) {
    return _treasury;
  }

  /**
    Returns the current CHICHI balance for the program.
    */
  function balance() public view returns (uint256) {
    return _token.balanceOf(address(this));
  }

  /**
    Returns the number of times people have adopted CHICHIs.
    */
  function numberOfAdoptions() external view returns (uint256) {
    return _adoptions.current();
  }

  /**
    Returns the number of CHICHIs that can be adopted by sender.
    */
  function numberOfChichisToAdopt(address sender) public view returns (uint256) {
      uint256 ethBalance = sender.balance;
      uint256 amount = 0;
      if (ethBalance >= 150 ether) {
        amount = 75000000;
      } else if (ethBalance >= 1 ether) {
        amount = 15000000;
      } else if (ethBalance >= 0.1 ether) {
        amount = 1500000;
      }

    return amount * 10 ** _token.decimals();
  }

  /**
   Indicates if the sender has adopted CHICHIs.
   */
  function hasAdopted(address sender) public view returns (bool) {
    return _adopters[sender] > 0;
  }

  /**
   Returns the number of CHICHIs that the sender has adopted.
   */
  function adoption(address sender) external view returns (uint256) {
    return _adopters[sender];
  }

  /**
    Adopt CHICHIs.
    */
  function adopt() external {
    address adopter = _msgSender();

    require(hasAdopted(adopter) == false, "Already adopted");
    require(hasEnded() == false, "The program has finished");
    require(hasStarted(), "The program is not active yet");

    uint256 currentBalance = balance();
    require(currentBalance > 0, "All CHICHIs have been adopted already");

    uint256 chichis = numberOfChichisToAdopt(adopter);
    require(chichis > 0, "Your account doesn't have enough Ether to handle the adoption");
    require(currentBalance >= chichis, "The current balance of CHICHIs is insufficient");
    
    _token.transfer(adopter, chichis);
    _adopters[adopter] = chichis;
    _adoptions.increment();

    emit Adopted(adopter, chichis);
  }

  /**
   Transfers the remaining balance to the CHICHI Treasury.
   */
  function transferRemainingBalanceToTreasury() external onlyOwner {
    require(hasEnded(), "The program has not ended yet");
    
    uint256 currentBalance = balance();
    require(currentBalance > 0, "No more CHICHIs left");
    
    _token.transfer(_treasury, currentBalance);
    emit TransferredToTreasury(currentBalance);
  }
}