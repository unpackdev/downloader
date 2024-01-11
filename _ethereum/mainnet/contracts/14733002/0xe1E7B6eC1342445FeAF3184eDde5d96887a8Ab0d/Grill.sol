//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155Holder.sol";
import "./IERC1155Receiver.sol";
import "./Ownable.sol";
import "./Counters.sol";

/**
 * Interfaces SuperFarm's Super1155 contract
 * See example contracts: https://etherscan.io/address/0x71B11Ac923C967CD5998F23F6dae0d779A6ac8Af#code,
 * https://etherscan.io/address/0xc7b9D8483FD01C379a4141B2Ee7c39442172b259#code
 *
 * @notice To stake tokens an account must setApprovalForAll() using the address of this contract in the above contracts
 */
interface Super1155 {
  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) external;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes calldata _data
  ) external;

  function balanceOf(address _owner, uint256 _id)
    external
    view
    returns (uint256);

  function isApprovedForAll(address _owner, address _operator)
    external
    view
    returns (bool);
}

/**
 * @title A staking contract for Super1155 tokens.
 * @author DegenDeveloper.eth
 *
 * April 25, 2022
 *
 * This contract allows users to stake their tokens to earn emission tokens.
 *
 * This contract is only capable of transferring tokens to their original stakers.
 *
 * Accounts always have the ability to unstake their tokens no matter the contract state.
 *
 * The contract owner has the following permissions:
 *
 * - Open/close staking; enabling/disabling the addition of new stakes
 * - Blacklist an account; disabling the addition of new stakes for a specific address
 * - Pause emissions; stops the counting of emission tokens
 * - Set new emission rates; sets a new rate for earning emission tokens
 *    - if emissions are paused this unpauses them
 *    - historic emission rates (emRates) are stored in the contract to accurately calculate emissions
 *
 * --------( In case of security breach )---------
 *
 * Accounts will always have the ability to unstake their tokens, no matter the state of the contract; however,
 *
 * If there is a security breach or the team wishes to terminate the grill, they have the ability to permanently close staking,
 * sending back all tokens to their original stakers.
 *
 * The contract owner must call toggleBailout() before they force unstake any tokens.
 *
 * ToggleBailout() is only callable once
 *
 * Once toggleBailout() has been called, bailoutAllStakes() becomes callable. This function will unstake all tokens and send them back to their original stakers.
 * If there are gas limits sending back all tokens in a single transaction, the function bailoutSingleStake(_tokenId) also becomes callable,
 * allowing each tokenId to be unstaked manually
 */
contract Grill is Ownable, ERC1155Holder {
  /// used for variables that start at 0 and only increment/decrement by 1 at a time
  using Counters for Counters.Counter;

  /// the contract instance for the tokens being staked
  Super1155 private immutable Parent;

  bool private STAKING_ACTIVE;
  bool private BAILED_OUT;

  /// the max number of tokens to stake/unstake in a single txn
  uint256 private constant MAX_TXN = 20;

  /// the max number of seconds possible, used for pausing emissions
  uint256 private constant MAX_INT = 2**256 - 1;

  /// a mapping from each tokenId to its stake details
  mapping(uint256 => Stake) private stakes;

  /// a mapping from each address to an indexed mapping of the tokenIds they have staked
  mapping(address => mapping(uint256 => uint256)) private addrStakesIds;

  /// a mapping from each address to a counter for tokens currently staked
  mapping(address => Counters.Counter) private addrStakesCount;

  /// a mapping from each address to their ability to add new stakes
  mapping(address => bool) private blacklist;

  /// a counter for the number of times the emission rate changes
  Counters.Counter private emChanges;

  /// a mapping from each emChange to its associated emission details
  mapping(uint256 => Emission) private emissions;

  /// a mapping from each address to their emission claims earned from their removed stakes
  mapping(address => uint256) private unstakedClaims;

  /// a counter for the number of active stakes
  Counters.Counter private allStakesCount;

  /// an indexed mapping for all tokenIds staked currently
  mapping(uint256 => uint256) private allStakes;

  /**
   * This struct stores information about staked tokens. They are stored
   * in the `stakes` mapping by tokenId
   * @param status If tokenId is staked or not
   * @param staker The staker of tokenId
   * @param timestamp The time tokenId was staked
   */
  struct Stake {
    bool status;
    address staker;
    uint256 timestamp;
  }

  /**
   * This struct stores information about emissions. They are stored in
   * the 'emissions' mapping by emChange
   * @param rate The number of seconds to earn 1 token
   * @param timestamp The time the emission rate was set
   */
  struct Emission {
    uint256 rate;
    uint256 timestamp;
  }

  /// ============ CONSTRUCTOR ============ ///

  /**
   * Initializes the parent contract instance, the initial emission rate, and timestamps the deploy
   * @param _parentAddr The contract address to allow staking from
   */
  constructor(address _parentAddr) {
    Parent = Super1155(_parentAddr);
    STAKING_ACTIVE = true;
    BAILED_OUT = false;
    uint256 secondsIn45Days = 3600 * 24 * 45;
    emissions[emChanges.current()] = Emission(secondsIn45Days, block.timestamp);
  }

  /// ============ OWNER FUNCTIONS ============ ///

  /**
   * For allowing/unallowing the addition of new stakes
   * @notice This function is disabled once toggleBailout() is called
   */
  function toggleStaking() external onlyOwner {
    require(!BAILED_OUT, "GRILL: contract has been terminated");
    STAKING_ACTIVE = !STAKING_ACTIVE;
  }

  /**
   * For allowing/unallowing an address to add new stakes
   * @notice A staker is always able to remove their stakes regardless of contract state
   * @param _addr The address to set blacklist status for
   * @param _status The status to set for _addr
   */
  function blacklistAddr(address _addr, bool _status) external onlyOwner {
    blacklist[_addr] = _status;
  }

  /**
   * Stops the counting of emission tokens
   * @notice No tokens can be earned with an emission rate this long
   * @notice To continue emissions counting, the owner must set a new emission rate
   */
  function pauseEmissions() external onlyOwner {
    _setEmissionRate(MAX_INT);
  }

  /**
   * Sets new emission rate
   * @param _seconds The number of seconds a token must be staked for to earn 1 emission token
   */
  function setEmissionRate(uint256 _seconds) external onlyOwner {
    require(!BAILED_OUT, "GRILL: cannot change emission rate after bailout");
    _setEmissionRate(_seconds);
  }

  /**
   * Pauses staking/emissions counting permanently
   * @notice This function is only callable once and all state changes are final
   * @notice It must be called before bailoutAllStakes() or bailoutSingleStake()
   */
  function toggleBailout() external onlyOwner {
    require(!BAILED_OUT, "GRILL: bailout already called");
    STAKING_ACTIVE = false;
    BAILED_OUT = true;
    _setEmissionRate(MAX_INT);
  }

  /**
   * Sends back all tokens to their original stakers
   * @notice toggleBailout() must be called
   */
  function bailoutAllStakes() external onlyOwner {
    require(BAILED_OUT, "GRILL: toggleBailout() must be called first");

    /// @dev copies current number of stakes before bailout ///
    uint256 _totalCount = allStakesCount.current();
    for (uint256 i = 1; i <= _totalCount; ++i) {
      /// @dev gets token and staker for last token staked ///
      uint256 _lastTokenId = allStakes[allStakesCount.current()];
      address _staker = stakes[_lastTokenId].staker;

      /// @dev transferrs _lastTokenId from the contract to associated _staker ///
      Parent.safeTransferFrom(address(this), _staker, _lastTokenId, 1, "0x0");

      /// @dev sets state changes ///
      uint256[] memory _singleArray = _makeOnesArray(1);
      _singleArray[0] = _lastTokenId; // _removeStakes() requires an array of tokenIds
      _removeStakes(_staker, _singleArray);
    }
  }

  /**
   * Sends back _tokenId to its original staker
   * @notice toggleBailout() must be called
   * @notice This function is here in case bailoutAllStakes() has gas limitations
   */
  function bailoutSingleStake(uint256 _tokenId) external onlyOwner {
    require(BAILED_OUT, "GRILL: toggleBailout() must be called first");

    Parent.safeTransferFrom(
      address(this),
      stakes[_tokenId].staker,
      _tokenId,
      1,
      "0x0"
    );

    /// @dev sets state changes ///
    uint256[] memory _singleArray = _makeOnesArray(1);
    _singleArray[0] = _tokenId;
    _removeStakes(stakes[_tokenId].staker, _singleArray);
  }

  /// ============ PUBLIC FUNCTIONS ============ ///

  /**
   * Transfer tokens from caller to contract and begins emissions counting
   * @param _tokenIds The tokenIds to stake
   * @param _amounts The amount of each tokenId to stake
   * @notice _amounts must have a value of 1 at each index
   */
  function addStakes(uint256[] memory _tokenIds, uint256[] memory _amounts)
    external
  {
    require(STAKING_ACTIVE, "GRILL: staking is not active");
    require(!blacklist[msg.sender], "GRILL: caller is blacklisted");
    require(_tokenIds.length > 0, "GRILL: must stake more than 0 tokens");
    require(
      _tokenIds.length <= MAX_TXN,
      "GRILL: must stake less than MAX_TXN tokens per txn"
    );
    require(
      _isOwnerOfBatch(msg.sender, _tokenIds, _amounts),
      "GRILL: caller does not own these tokens"
    );
    require(
      Parent.isApprovedForAll(msg.sender, address(this)),
      "GRILL: contract is not an approved operator for caller's tokens"
    );

    /// @dev transfers token batch from caller to contract
    Parent.safeBatchTransferFrom(
      msg.sender,
      address(this),
      _tokenIds,
      _amounts,
      "0x0"
    );

    /// @dev sets contract state
    _addStakes(msg.sender, _tokenIds);
  }

  /**
   * Transfer tokens from contract to caller and records emissions in unStakedClaims
   * @param _tokenIds The tokenIds to unstake
   * @param _amounts The amount of each tokenId to unstake
   * @notice _amounts must have a value of 1 at each index
   */
  function removeStakes(uint256[] memory _tokenIds, uint256[] memory _amounts)
    external
  {
    require(_tokenIds.length > 0, "GRILL: must unstake more than 0 tokens");
    require(
      _tokenIds.length <= MAX_TXN,
      "GRILL: cannot stake more than MAX_TXN tokens in a single txn"
    );
    require(_tokenIds.length == _amounts.length, "GRILL: arrays mismatch");
    require(
      _isStakerOfBatch(msg.sender, _tokenIds, _amounts),
      "GRILL: caller was not the staker of these tokens"
    );
    require(
      _tokenIds.length <= addrStakesCount[msg.sender].current(),
      "GRILL: caller is unstaking too many tokens"
    );

    /// @dev transfers token batch from contract to caller ///
    Parent.safeBatchTransferFrom(
      address(this),
      msg.sender,
      _tokenIds,
      _amounts,
      "0x0"
    );

    /// @dev sets contract state ///
    _removeStakes(msg.sender, _tokenIds);
  }

  /// ============ PRIVATE/HELPER FUNCTIONS ============ ///

  /**
   * Verifies if an address can stake a batch of tokens
   * @param _operator The address trying to stake
   * @param _tokenIds The tokenIds _operator is trying to stake
   * @param _amounts The amount of each tokenId caller is trying to stake
   * @notice Each element in _amounts must be 1
   * @return _b If _operator can unstake _tokenIds
   */
  function _isOwnerOfBatch(
    address _operator,
    uint256[] memory _tokenIds,
    uint256[] memory _amounts
  ) private view returns (bool _b) {
    _b = true;
    for (uint256 i = 0; i < _tokenIds.length; ++i) {
      if (parentBalance(_operator, _tokenIds[i]) == 0 || _amounts[i] != 1) {
        _b = false;
        break;
      }
    }
  }

  /**
   * Verifies if an address can unstake a batch of tokens
   * @param _operator The address trying to unstake
   * @param _tokenIds The tokenIds _operator is trying to unstake
   * @param _amounts The amount of each tokenId caller is trying to unstake
   * @notice Each element in _amounts must be 1
   * @return _b If _operator can unstake _tokenIds
   */
  function _isStakerOfBatch(
    address _operator,
    uint256[] memory _tokenIds,
    uint256[] memory _amounts
  ) private view returns (bool _b) {
    _b = true;
    for (uint256 i = 0; i < _tokenIds.length; ++i) {
      if (stakes[_tokenIds[i]].staker != _operator || _amounts[i] != 1) {
        _b = false;
        break;
      }
    }
  }

  /**
   * Helper function for setting contract state when tokens are staked
   * @param _staker The address staking tokens
   * @param _tokenIds The tokenIds being staked
   */
  function _addStakes(address _staker, uint256[] memory _tokenIds) private {
    for (uint256 i = 0; i < _tokenIds.length; ++i) {
      require(!stakes[_tokenIds[i]].status, "GRILL: token already staked");

      /// increment counters
      addrStakesCount[_staker].increment();
      allStakesCount.increment();

      /// set mappings
      addrStakesIds[_staker][addrStakesCount[_staker].current()] = _tokenIds[i];
      allStakes[allStakesCount.current()] = _tokenIds[i];
      stakes[_tokenIds[i]] = Stake(true, _staker, block.timestamp);
    }
  }

  /**
   * Helper function for setting contract state when tokens are unstaked
   * @param _staker The address unstaking tokens
   * @param _tokenIds The tokenIds being unstaked
   */
  function _removeStakes(address _staker, uint256[] memory _tokenIds) private {
    for (uint256 i = 0; i < _tokenIds.length; ++i) {
      require(
        stakes[_tokenIds[i]].status,
        "GRILL: token is not currently staked"
      );

      /// count rewards earned
      uint256 _tokenId = _tokenIds[i];
      unstakedClaims[_staker] += _countEmissions(_tokenId);

      /// @dev resets Stake object in `stakes` mapping ///
      delete stakes[_tokenId];

      /// last index of mappings
      uint256 _t = addrStakesCount[_staker].current();
      uint256 _t1 = allStakesCount.current();

      /// @dev finds _tokenId in mappings, swaps it with last index ///
      for (uint256 j = 1; j < _t; ++j) {
        if (addrStakesIds[_staker][j] == _tokenId) {
          addrStakesIds[_staker][j] = addrStakesIds[_staker][_t];
        }
      }
      for (uint256 k = 1; k < _t1; ++k) {
        if (allStakes[k] == _tokenId) {
          allStakes[k] = allStakes[_t1];
        }
      }

      /// @dev resets last item in mappings
      delete addrStakesIds[_staker][_t];
      delete allStakes[_t1];

      /// decrement counters, avoiding decrement overflow
      if (_t != 0) {
        addrStakesCount[_staker].decrement();
      }
      if (_t1 != 0) {
        allStakesCount.decrement();
      }
    }
  }

  /**
   * Helper function for setting contract state when emission changes occur
   * @param _seconds The number of seconds a token must be staked for to earn 1 emission token
   * @notice The emission rate cannot be 0 seconds
   */
  function _setEmissionRate(uint256 _seconds) private {
    require(_seconds > 0, "GRILL: emission rate cannot be 0");
    emChanges.increment();
    emissions[emChanges.current()] = Emission(_seconds, block.timestamp);
  }

  /**
   * Helper function to count number of emission tokens _tokenId has earned
   * @param _tokenId The tokenId to check
   * @notice A token must be staked to count emissions
   */
  function _countEmissions(uint256 _tokenId) private view returns (uint256 _c) {
    require(stakes[_tokenId].status, "GRILL: token is not currently staked");

    /// @dev finds the first emission rate _tokenId was staked for ///
    uint256 minT;
    uint256 timeStake = stakes[_tokenId].timestamp;
    for (uint256 i = 1; i <= emChanges.current(); ++i) {
      if (emissions[i].timestamp < timeStake) {
        minT += 1;
      }
    }
    /// @dev counts all emissions earned starting from minT -> now
    for (uint256 i = minT; i <= emChanges.current(); ++i) {
      uint256 tSmall = emissions[i].timestamp;
      uint256 tBig = emissions[i + 1].timestamp;
      if (i == minT) {
        tSmall = timeStake;
      }
      if (i == emChanges.current()) {
        tBig = block.timestamp;
      }
      _c += (tBig - tSmall) / emissions[i].rate;
    }
  }

  /**
   * Helper function for creating an array of all 1's
   * @param _n The size of the array
   * @return _ones An array of size _n with a value of 1 at each index
   */
  function _makeOnesArray(uint256 _n)
    private
    pure
    returns (uint256[] memory _ones)
  {
    _ones = new uint256[](_n);
    for (uint256 i = 0; i < _n; i++) {
      _ones[i] = 1;
    }
    return _ones;
  }

  /// ============ READ-ONLY FUNCTIONS ============ ///

  /**
   * Get the balance for a specifc tokenId in parent contract
   * @param _operator The address to lookup
   * @param _tokenId The token id to check balance of
   * @return _c The _tokenId balance of _operator
   */
  function parentBalance(address _operator, uint256 _tokenId)
    public
    view
    returns (uint256 _c)
  {
    _c = Parent.balanceOf(_operator, _tokenId);
  }

  /**
   * @return _b If the contract is allowing new stakes to be added
   */
  function isStakingActive() external view returns (bool _b) {
    _b = STAKING_ACTIVE;
  }

  /**
   * @return _b If the contract has been bailed out
   */
  function isBailedOut() external view returns (bool _b) {
    _b = BAILED_OUT;
  }

  /**
   * @param _addr The address to lookup
   * @return _b Blacklist status
   */
  function isBlacklisted(address _addr) external view returns (bool _b) {
    _b = blacklist[_addr];
  }

  /**
   * @return _changes The current number of emission changes to date
   */
  function getEmissionChanges() external view returns (uint256 _changes) {
    _changes = emChanges.current();
  }

  /**
   * Get details for an emission change
   * @param _change The change number to lookup
   * @return _emission The emission object for emChange _change
   * @notice A _change must have occured to view it
   */
  function getEmission(uint256 _change)
    external
    view
    returns (Emission memory _emission)
  {
    require(_change <= emChanges.current(), "GRILL: invalid index to lookup");
    _emission = emissions[_change];
  }

  /**
   * @return _allStakingIds Array of tokenIds currently being staked
   */
  function getAllStakedIds()
    external
    view
    returns (uint256[] memory _allStakingIds)
  {
    _allStakingIds = new uint256[](allStakesCount.current());
    for (uint256 i = 0; i < _allStakingIds.length; ++i) {
      _allStakingIds[i] = allStakes[i + 1];
    }
  }

  /**
   * Get details for a staked token
   * @param _tokenId The tokenId to lookup
   * @return _stake The stake of _tokenId
   * @notice A _tokenId must currently be staked to view it
   */
  function getStake(uint256 _tokenId)
    external
    view
    returns (Stake memory _stake)
  {
    require(stakes[_tokenId].status, "GRILL: tokenId is not staked");
    _stake = stakes[_tokenId];
  }

  /**
   * @param _operator The address to lookup
   * @return _addrStakes Array of tokenIds currently staked by _operator
   */
  function getIdsOfAddr(address _operator)
    external
    view
    returns (uint256[] memory _addrStakes)
  {
    _addrStakes = new uint256[](addrStakesCount[_operator].current());
    for (uint256 i = 0; i < _addrStakes.length; ++i) {
      _addrStakes[i] = addrStakesIds[_operator][i + 1];
    }
  }

  /**
   * @param _operator The address to lookup
   * @return _claims The number of claims _operator has earned from their unstaked bulls
   */
  function getUnstakedClaims(address _operator) public view returns (uint256) {
    return unstakedClaims[_operator];
  }

  /**
   * @param _operator The address to lookup
   * @return _total The number of claims an address has earned from their current stakes
   */
  function getStakedClaims(address _operator)
    public
    view
    returns (uint256 _total)
  {
    for (uint256 i = 1; i <= addrStakesCount[_operator].current(); i++) {
      _total += _countEmissions(addrStakesIds[_operator][i]);
    }
  }

  /**
   * @param _operator The address to lookup
   * @return _total The number of emissions _operator has earned from all past and current stakes
   */
  function getTotalClaims(address _operator)
    external
    view
    returns (uint256 _total)
  {
    _total = unstakedClaims[_operator];
    _total += getStakedClaims(_operator);
  }
}
