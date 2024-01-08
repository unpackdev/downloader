// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract CHICHIHelp is Ownable {
  using Counters for Counters.Counter;

  struct Claimer {
    string name;
    uint256 allowance;
}

  // Emitted when a claimer has been added
  event AddedClaimer(address indexed wallet, string name, uint numberOfChichis);
  // Emitted when the allowance is increased for an address
  event IncreasedAllowance(address indexed to, uint numberOfChichis);
  // Emitted when a claim occurred
  event Claimed(address indexed by, uint numberOfChichis);
  // Emitted when the assets are transferred to the treasury
  event TransferredToTreasury(uint numberOfChichis);

  // Name of the smart contract
  string constant private _name = "CHICHI Help";

  // Token that will be used to transfer funds
  ERC20 private _token;

  // Block number when the program starts
  uint256 private _startingBlock;

  // Duration of the program measured in number of blocks
  uint256 private _activeDuration;

  // Address of the CHICHI Treasury.
  address private _treasury;

  // Number of times the CHICHIs have been claimed
  Counters.Counter private _claims;

  // CHICHI claimers
  mapping(address => Claimer) private _claimers;

  /**
    Smart contract initialization.
    */
  constructor(ERC20 token, uint256 startingAt, uint256 activeDuration, address treasuryAddress) {
    require(treasuryAddress != address(0), "Treasury address cannot be the zero address");
    require(startingAt > 0, "Starting block must be greater than 0");
    require(activeDuration > 0, "Active duration must be greater than 0");

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
    Returns the number of times the CHICHIs have been claimed.
    */
  function numberOfClaims() external view returns (uint256) {
    return _claims.current();
  }

  /**
    Adds a new claimer.
    */
  function addClaimer(address claimer, string memory nameOfClaimer, uint256 allowance) external onlyOwner {
    require(_claimers[claimer].allowance == 0, "Already added");

    _claimers[claimer] = Claimer({
      name: nameOfClaimer,
      allowance: allowance
    });

    emit AddedClaimer(claimer, nameOfClaimer, allowance);
  }

  /**
    Increase the number of CHICHIs that can be claimed by an address.
    */
  function increaseAllowance(address to, uint256 amount) external onlyOwner {
    _claimers[to].allowance += amount;
    emit IncreasedAllowance(to, amount);
  }

  /**
    Returns the number of CHICHIs that can be claimed by an address.
    */
  function numberOfChichisToClaim(address by) public view returns (uint256) {
    return _claimers[by].allowance;
  }

  /**
    Returns the name of a claimer.
    */
  function nameOf(address by) external view returns (string memory) {
    return _claimers[by].name;
  }

  /**
    Claim CHICHIs.
    */
  function claim() external {
    address claimer = _msgSender();

    require(hasEnded() == false, "The program has finished");
    require(hasStarted(), "The program is not active yet");

    uint256 currentBalance = balance();
    require(currentBalance > 0, "All CHICHIs have been claimed already");

    uint256 chichis = numberOfChichisToClaim(claimer);
    require(chichis > 0, "You have no allowance");

    chichis = currentBalance < chichis ? currentBalance : chichis; // If the balance is less than the allowance for the claimer, claim all the remaining CHICHIs
    require(currentBalance >= chichis, "The current balance of CHICHIs is insufficient");
    
    _token.transfer(claimer, chichis);
    _claimers[claimer].allowance -= chichis;
    _claims.increment();

    emit Claimed(claimer, chichis);
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