// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./ERC20Snapshot.sol";
import "./SafeMath.sol";

contract BrincGovToken is ERC20, ERC20Burnable, ERC20Snapshot, ERC20Pausable, Ownable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) private _allowances;

  // The treasury will be controlled by a separate address, NOT THE OWNER OF THIS CONTRACT ADDRESS.
  // The owner will be relinquished to the BrincStaking contract upon deployment.
  address public treasuryOwner;

  mapping(address => bool) public isMinter;

  // MembersOnly is the mapping of addresses to the BRINC team and/or investors. The addresses can and will only be included by use of the contract constructor and the manual addition by the OWNER of this contract address.

  struct MemberInfo {
    uint256 vestingStartBlock; // Block of when vesting begins.
    uint256 vestingBlocks; // Vesting duration in blocks (1 block estimated to be 13 seconds).
    uint256 claimedBalance; // Amount of gBRC that has be claimed.
    uint256 awardBalance; // Total amount of gBRC awarded. Note, this balance is different than the balanceOf that is part of the ERC20 methods. awardBalance is the number of tokens that has been allocated based on specified team/investor allocations.
  }

  mapping (address => MemberInfo) public members;

  uint256 public maxTotalSupply;
  
  event BalanceUpdated(address indexed user, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  event Mint(address _to, uint256 amount);
  event Burn(address _from, uint256 amount);
  event SetMinter(address _minter, bool _isMinter);

  constructor (
    string memory _name,
    string memory _symbol,
    address[] memory _initAllocAddrs,
    uint256[] memory _initAllocAmount,
    uint256[] memory _initVestBlocks,
    uint256 _maxTotalSupply
  ) public ERC20(_name, _symbol) {
    require(_initAllocAddrs.length == _initAllocAmount.length);
    require(_initAllocAddrs.length == _initVestBlocks.length);
    // sets the initial gov token allocations to the corresponding address to their token amount.
    for (uint i = 0; i < _initAllocAddrs.length; i++) {
      MemberInfo storage member = members[_initAllocAddrs[i]];
      require(_initVestBlocks[i] > 0);
      require(_initAllocAmount[i] > 0);
      member.vestingStartBlock = block.number;
      member.vestingBlocks = _initVestBlocks[i];
      member.claimedBalance = 0;
      member.awardBalance = _initAllocAmount[i];
    }
    maxTotalSupply = _maxTotalSupply;
    treasuryOwner = msg.sender;
    isMinter[msg.sender] = true;
  }

  modifier onlyMembers {
      require(members[msg.sender].vestingStartBlock > 0, "onlyMemebers: member does not exist");
      require(members[msg.sender].awardBalance > 0, "onlyMemebers: member does not exist");
      _;
   }

  modifier onlyTreasuryOwner {
    require(msg.sender == treasuryOwner, "onlyTreasuryOwner: only treasury owner can call this operation");
    _;
  }

  modifier onlyMinter {
    require(isMinter[msg.sender], "onlyMinter: only minter can call this operation");
    _;
  }

  /**
    * @dev shows the amount of time in blocks remaining for vesting.
    *
    */
  /// #if_succeeds {:msg "vestingTimeRemaining: vesting time in blocks remaining is correct - case endBlock > block.number"}
      /// let endBlock := members[msg.sender].vestingStartBlock + members[msg.sender].vestingBlocks in
      /// endBlock > block.number ==> $result == endBlock - block.number;
  /// #if_succeeds {:msg "vestingTimeRemaining: vesting time remaining is incorrect - case endBlock < block.number"}
      /// let endBlock := members[msg.sender].vestingStartBlock + members[msg.sender].vestingBlocks in
      /// endBlock < block.number ==> $result == 0;
  function vestingTimeRemaining() public view onlyMembers returns (uint256) {
    uint256 endBlock = members[msg.sender].vestingStartBlock.add(members[msg.sender].vestingBlocks);
    if (endBlock > block.number) {
      return endBlock.sub(block.number);
    }
    return 0;
  }

  /**
    * @dev gets the claimable tokens for _address. 
    * this will return 0 if _address does not have any stakes
    * 
    * formula:
    * claimableAmount = (blocks passed) * (awardAmount / vestingBlocks)
    *
    * @return claimable amount in gov tokens
    */
  /// #if_succeeds {:msg "getClaimableAmount: case block.number >= member.vestingStartBlock + member.vestingBlocks"}
    /// block.number >= members[_address].vestingStartBlock + members[_address].vestingBlocks ==>
    /// $result == members[_address].awardBalance.sub(members[_address].claimedBalance);
  /// #if_succeeds {:msg "getClaimableAmount: 0"}
    /// block.number < members[_address].vestingStartBlock + members[_address].vestingBlocks && block.number < members[_address].vestingStartBlock ==> $result == 0;
  function getClaimableAmount(address _address) public view returns (uint256) {
    MemberInfo memory member = members[_address];
    require(member.claimedBalance < member.awardBalance, "getClaimableAmount: no claimable balance");

    if (block.number >= member.vestingStartBlock.add(member.vestingBlocks)) {
      return member.awardBalance.sub(member.claimedBalance);
    }
    if (block.number > member.vestingStartBlock) {
      uint256 timePassed = block.number.sub(member.vestingStartBlock);
      return member.awardBalance.mul(1e10).div(member.vestingBlocks).mul(timePassed).div(1e10).sub(member.claimedBalance);
    }
    return 0;
  }

  /**
    * @dev claims the member reward.
    * The number of tokens that can be claimed will be calculated based off the following formula:
    *    withdrawableAmount = (awardBalance) / (vestingEndBlock - block.number)
    *    This will produce the amount of tokens that can be claimed depending on the vesting time remaining.
    */
  /// #if_succeeds {:msg "memberClaim: claimed balance mints correctly"}
      /// let claimableAmount := old(this.getClaimableAmount(msg.sender)) in
      /// this.balanceOf(msg.sender) == old(this.balanceOf(msg.sender)) + claimableAmount;
  /// #if_succeeds {:msg "memberClaim: updates member info correctly"}
      /// let claimableAmount := old(this.getClaimableAmount(msg.sender)) in
      /// members[msg.sender].claimedBalance == old(members[msg.sender].claimedBalance) + claimableAmount;
  function memberClaim() public onlyMembers {
    uint256 claimableAmount = getClaimableAmount(msg.sender);
    require(claimableAmount > 0, "memberClaim: nothing to claim");

    MemberInfo storage member = members[msg.sender];
    member.claimedBalance = member.claimedBalance.add(claimableAmount);

    _mint(msg.sender, claimableAmount);
    emit Mint(msg.sender, claimableAmount);
  }

  /**
    * @dev transfer ownership of treasury. Only the current treasury owner can invoke this method.
    *
    * @param _address new owner of the treasury.
    */
  /// #if_succeeds {:msg "transferTreasuryOwnership: The sender must be treasuryOwner"}
      /// old(msg.sender == getTreasuryOwner());
  /// #if_succeeds {:msg "transferTreasuryOwnership: treasuryOwner updated correctly"}
      /// getTreasuryOwner() == _address;
  function transferTreasuryOwnership(address _address) public onlyTreasuryOwner {
    require(treasuryOwner != _address, "TrasnferTreasuryOwnership: transferring ownership to self");
    treasuryOwner = _address;
  }

  /**
    * @dev mint to treasury owner.
    * The minter will be the staking contract that will be allowed to mint tokens on behalf of the treasury owner.
    * The staking contract will only allow msg.sender == treasuryOwner to call this method.
    *
    * @param _amount amount to mint to the treasury contract.
    *
    */
  /// #if_succeeds {:msg "mintToTreasury: The sender must be Minter"}
      /// isMinter[msg.sender] == true;
  /// #if_succeeds {:msg "mintToTreasury: balance of treasury address is correct after mint"}
      /// this.balanceOf(treasuryOwner) == old(this.balanceOf(treasuryOwner) + _amount);
  function mintToTreasury(uint256 _amount) public onlyMinter {
    _mint(treasuryOwner, _amount);
    emit Mint(treasuryOwner, _amount);
  }

  /**
    * @dev burns the specified number of tokens. can only be called by the treasury owner.
    *
    * @param _to address to mint tokens to.
    * @param _amount amount to burn by the treasury owner.
    * @notice Creates `_amount` token to `_to`. Must only be called by the owner (BrincStaking).
    */
  /// #if_succeeds {:msg "mint: The sender must be Owner"}
      /// isMinter[msg.sender] == true;
  /// #if_succeeds {:msg "mint: balance of receiving address is correct after mint"}
      /// this.balanceOf(_to) == old(this.balanceOf(_to) + _amount);
  function mint(address _to, uint256 _amount) public onlyMinter {
    _mint(_to, _amount);
    emit Mint(_to, _amount);
  }

  /**
    * @dev burns the specified number of tokens. can only be called by the treasury owner.
    *
    * @param _amount amount to burn by the treasury owner.
    */
  /// #if_succeeds {:msg "burn: The sender must be treasuryOwner"}
      /// old(msg.sender == getTreasuryOwner());
  /// #if_succeeds {:msg "burn: balance of treasury address is correct after burn"}
      /// this.balanceOf(treasuryOwner) == old(this.balanceOf(treasuryOwner) - _amount);
  function burn(uint256 _amount) public override onlyTreasuryOwner {
    require(balanceOf(address(treasuryOwner))>0, "burn: Not enough funds in treasury");
    _burn(treasuryOwner, _amount);
    emit Burn(treasuryOwner, _amount);
  }

  /**
    * @dev transfer the specified number of tokens to a specific address. can only be called by the treasury owner.
    *
    * @param _to address to send the treasury tokens to.
    * @param _amount amount to burn by the treasury owner.
    */
  /// #if_succeeds {:msg "treasuryTransferToken: The sender must be treasuryOwner"}
      /// old(msg.sender == getTreasuryOwner());
  /// #if_succeeds {:msg "treasuryTransferToken: balance of receiving address is correct after transfer"}
      /// _to != getTreasuryOwner() ==>
      /// this.balanceOf(_to) == old(this.balanceOf(_to)) + _amount;
  /// #if_succeeds {:msg "treasuryTransferToken: balance of treasury address is correct after transfer"}
      /// _to != getTreasuryOwner() ==>
      /// this.balanceOf(treasuryOwner) == old(this.balanceOf(treasuryOwner)) - _amount;
  function treasuryTransferToken(address _to, uint256 _amount) public onlyTreasuryOwner {
    require(balanceOf(address(treasuryOwner)) > 0, "treasuryTransferToken: Not enough funds in treasury");
    _transfer(treasuryOwner, _to, _amount);
    emit Transfer(treasuryOwner, _to, _amount);
  }

  /**
    * @dev add a Member. Only the treasury owner is authorized to call this method.
    *
    * @param _address address of member.
    * @param _awardAmount award amount attributed to user. The tokens will be locked up and released over the vesting time.
    * @param _vestingBlocks time given in block numbers.
    */
  /// #if_succeeds {:msg "addMember: The sender must be treasuryOwner"}
      /// old(msg.sender == getTreasuryOwner());
  /// #if_succeeds {:msg "addMember: member should be added correctly"}
      /// members[_address].vestingStartBlock != 0 && 
      /// members[_address].vestingBlocks != 0 &&
      /// members[_address].claimedBalance == 0 &&
      /// members[_address].awardBalance != 0;
  function addMember(address _address, uint256 _awardAmount, uint256 _vestingBlocks) public onlyTreasuryOwner {
    MemberInfo storage member = members[_address];
    require(member.awardBalance == member.claimedBalance, "addMember: member already exists");
    require(_awardAmount > 0, "addMember: invalid _awardAmount provided");
    require(_vestingBlocks > 0, "addMember: invalid _vestingBlocks provided");

    member.vestingStartBlock = block.number;
    member.vestingBlocks = _vestingBlocks;
    member.claimedBalance = 0;
    member.awardBalance = _awardAmount;
  }

  /**
    * @dev remove a Member. Only the treasury owner is authorized to call this method.
    *
    * @param _address address of member.
    */
  /// #if_succeeds {:msg "removeMember: The sender must be treasuryOwner"}
      /// old(msg.sender == getTreasuryOwner());
  /// #if_succeeds {:msg "removeMember: member should be removed correctly"}
      /// let claimableAmount := old(getClaimableAmount(_address)) in
      /// claimableAmount > 0 ==>
      /// members[_address].vestingStartBlock != 0 && 
      /// members[_address].vestingBlocks == 1 &&
      /// members[_address].awardBalance == claimableAmount;
  function removeMember(address _address) public onlyTreasuryOwner {
    MemberInfo storage member = members[_address];
    require(member.vestingStartBlock != 0, "removeMember: member does not exist");
    require(member.awardBalance > 0, "removeMember: member does not exist");
    uint256 claimableAmount = getClaimableAmount(_address);
    member.vestingBlocks = 1;
    member.awardBalance = claimableAmount;
  }


  /**
    * @dev gets a member information for msg.sender.
    *
    */
  function getMemberInfo() public view returns(MemberInfo memory) {
    return members[msg.sender];
  }

  /**
    * @dev returns the treasury owner address.
    *
    */
  /// #if_succeeds {:msg "getTreasuryOwner: result should be the treasuryOwner"}
      /// $result == treasuryOwner;
  function getTreasuryOwner() public view returns(address) {
    return treasuryOwner;
  }

  /**
    * @dev returns the treasury owner address.
    *
    */
  /// #if_succeeds {:msg "getTreasuryBalance: result should give the treasury balance"}
      /// $result == this.balanceOf(treasuryOwner);
  function getTreasuryBalance() public view returns(uint256) {
    return this.balanceOf(treasuryOwner);
  }

  /**
    * @dev returns the treasury owner address.
    * note: CirculatingSupply is the number of tokens that are currently in circulation.
    * The circulating supply represents the number of tokens that have been minted minus the number of tokens that are locked up.
    * Locked tokens will be associated to a the treasury contract address. All other tokens are considered unlocked and circulating.
    * The number of tokens located in the treasury will be locked indefinitely by the BRINC_TEAM until a time of their choosing (or can be discovered by the community through governance).
    */
  /// #if_succeeds {:msg "circulatingSupply: result should give the total supply minus treasury balance"}
      /// $result == totalSupply().sub(this.balanceOf(treasuryOwner));
  function circulatingSupply() public view returns (uint256) {
    return totalSupply().sub(this.balanceOf(treasuryOwner));
  }

  // ERC20Pausable
  /**
    * @dev Pauses the contract's transfer, mint & burn functions
    *
    */
  /// #if_succeeds {:msg "The caller must be Owner"}
    /// old(msg.sender == getTreasuryOwner());
  function pause() public onlyTreasuryOwner {
    _pause();
  }
  /**
    * @dev Unpauses the contract's transfer, mint & burn functions
    *
    */
  /// #if_succeeds {:msg "The caller must be Owner"}
    /// old(msg.sender == getTreasuryOwner());
  function unpause() public onlyTreasuryOwner {
    _unpause();
  }

  // ERC20Snapshot
  /**
    * @dev Creates a new snapshot and returns its snapshot id.
    *
    * Emits a {Snapshot} event that contains the same id.
    *
    */
  /// #if_succeeds {:msg "The caller must be Owner"}
    /// old(msg.sender == getTreasuryOwner());
  function snapshot() public onlyTreasuryOwner {
    _snapshot();
  }

  /**
   * @dev setMinter will set and allow the specified address to mint gBRC tokens.
   * only the owner will be able to call this method.
   * changing _isMinter to false will revoke minting privileges.
   *
   * @param _address address of minter
   * @param _isMinter bool access
   * 
   */
  /// #if_succeeds {:msg "setMinter: The sender must be owner"}
    /// old(msg.sender == this.owner());;
  function setMinter(address _minter, bool _isMinter) public onlyOwner {
    require(_minter != address(0), "invalid minter address");
    isMinter[_minter] = _isMinter;
    emit SetMinter(_minter, _isMinter);
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Snapshot, ERC20Pausable) {
    super._beforeTokenTransfer(from, to, amount);
  }

}