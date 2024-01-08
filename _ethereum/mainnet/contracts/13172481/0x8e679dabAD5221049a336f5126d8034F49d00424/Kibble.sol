// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeMath.sol";

import "./ERC20.sol";
import "./IFTPAntiBot.sol";

import "./KibbleAccessControl.sol";
import "./KibbleBase.sol";

import "./IUniswapV2Router.sol";
import "./IUniswapV2Factory.sol";

//
//                                               `````
//                                       `.-/+oosssssssoo+/:.`
//                                   `:+syyso++/////////++osyyso:.
//                                .+yhs+/:::::::::::::::::::://oshy+.
//                             `/yhs/:::::://///////////////:::::/+ohy/`
//                           `+hy+:::://///++osso++++++++oo++////:::/+yh+.
//                          /dh+:::/++/+osyhhhhhs+/////+yhhhyyo++++/::/+yh+`
//                        .yms::/oo+++syhhhhhhhhs+////+yhhhhhhhhys++++/:/ohy-
//                       :dd+::oyo++++hhhhhhhhhhs+///+yhhhhhhhhhhho+++o+//+yh/
//                      /mh/:/ys+++//+hhhhhhhhhhs++++yhhhhhhhhhhhs+/++oso///sd+
//                     /mh::+ys++////+hhhhhhhhhhs+++yhhhhhhhhhhhs+////+oss+//sd+
//                    -dd/:+ys++/////+hhhhhhhhhhy++yhhhhhhhhhhhs+//////+osy+//yd:
//                    ym+:/yy+o//////+hhhhhhhhhhyoyhhhhhhhhhhhs+////////+sys+/+hh`
//                   :my::oh/o///////+hhhhhhhhhhyyhhhhhhhhhhho+//////////osho//sd+
//                   ym+:/ys++///////+hhhhhhhhhhhhhhhhhhhhhho+////////////syy+/+hh
//                  `dm::+d+o////////+hhhhhhhhhhhhhhhhhhhhho+/////////////ssh+//hd.
//                  .md::oh/o////////+hhhhhhhhhhhhhhhhhhhho+//////////////oyho//ym-
//                  .mh::oh/o////////+hhhhhhhhhhhhhhhhhhhho+//////ydho////oyho//ym:
//                  .dd::od/o////////+hhhhhhhhhhhhhhhhhhhhho+////+mmms////osh+//ym.
//                   hm/:/hoo////////+hhhhhhhhhhhhhhhhhhhhhhs+////+o+/////ssy+/+hh`
//                   /ms::sh/o///////+hhhhhhhhhhhhhhhhhhhhhhhs+//////////+sho//sdo
//                   `hm/:/yo++//////+hhhhhhhhhhyshhhhhhhhhhhhs+/////////ssy+/+hd.
//                    :mh::+h+++/////+hhhhhhhhhhy+ohhhhhhhhhhhhs+///////osy+//sd+
//                     oms::oho++////+hhhhhhhhhhy++oyhhhhhhhhhhhy+////+osy+//ohs
//                     `oms::+yo++///+hhhhhhhhhhs+++oyhhhhhhhhhhhy+//+oss+//ohs`
//                       omy/:/ss+++/+hhhhhhhhhhs+//+oyhhhhhhhhhhhy++oo+///oho`
//                        :dd+::+ss++oyhhhhhhhhhs+////+yhhhhhhhhhyo+o+///+sh/
//                         .sdy/::+oo++osyhhhhhhs+/////+yhhhhyyo+++/:://oys.
//                           -ydy/::::///++osyyys//////++sso++///::://+yy:
//                             -ods/::::::::///////////////::::::://oys-
//                               `/syo//:::::-------------::::///oys/`
//                                  `:+sss+/:::::::::::::///+osso:`
//                                      `.:+oooosoooooooooo+:-`
//                                            `````.`````
//
/// @notice Kibble the main utility token of the Sanshu eco-system.
contract Kibble is KibbleBase {
  using SafeMath for uint256;
  /// erc20 meta
  string internal constant NAME = 'Kibble Token';
  string internal constant SYMBOL = 'KIBBLE';
  uint8 internal constant DECIMALS = 18;
  uint256 internal constant MIN_TOTAL_SUPPLY = 250 * 10**6 * 10**18;

  bytes public constant EIP712_REVISION = bytes('1');
  bytes32 internal constant EIP712_DOMAIN =
    keccak256(
      'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
    );
  bytes32 public constant PERMIT_TYPEHASH =
    keccak256(
      'Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'
    );

  bytes32 public DOMAIN_SEPARATOR =
  keccak256(
    abi.encode(
      EIP712_DOMAIN,
      keccak256(bytes(NAME)),
      keccak256(EIP712_REVISION),
      block.chainid,
      address(this)
    )
  );

  /// max supply
  uint256 public maxSupply = 0;

  /// anti-bot state
  IFTPAntiBot private antiBot;
  bool public antiBotEnabled = false;

  /// uniswap state
  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;

  /// track pair addresses so that transfers can be subject to
  /// fees for swaps
  mapping(address => bool) public tokenPairs;

  /// track sell contracts
  mapping(address => bool) public sellContracts;

  /// fee state
  bool public feeEnabled = false;
  uint256 public feeResetCooldown = 1 days;
  address public redistributionPolicyAddress;
  mapping(address => bool) public excluded;
  mapping(address => uint256) private _firstSell;
  mapping(address => uint256) private _sellCount;
  uint256 private _taxFee = 5;
  uint256 private _feeMultiplier = 5;

  /// governance state
  mapping(address => uint256) public _nonces;
  mapping(address => uint256) internal _votingCheckpointsCounts;
  mapping(address => address) internal _votingDelegates;
  mapping(address => mapping(uint256 => Checkpoint)) public votingCheckpoints;
  mapping(address => mapping(uint256 => Checkpoint))
    internal _propositionPowerCheckpoints;
  mapping(address => uint256) internal _propositionPowerCheckpointsCounts;
  mapping(address => address) internal _propositionPowerDelegates;

  // events
  event LogTokenPair(address pair, bool included);
  event LogSellContracts(address targetAddress, bool included);
  event LogExcluded(address targetAddress, bool included);

  /// @notice main constructor for token
  /// @param _antiBotAddress address for anti-bot protection https://antibot.fairtokenproject.com/
  /// @param _uniswapRouterAddress address for uniswap router
  constructor(address _antiBotAddress, address _uniswapRouterAddress)
    ERC20(NAME, SYMBOL)
  {
    /// set up antiBot
    IFTPAntiBot _antiBot = IFTPAntiBot(_antiBotAddress);
    antiBot = _antiBot;

    /// initiate new pair for KIBBLE/WETH
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      _uniswapRouterAddress
    );
    address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
    .createPair(address(this), _uniswapV2Router.WETH());

    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = _uniswapV2Pair;

    _setTrackedPair(_uniswapV2Pair, true);
    _setSellContracts(_uniswapRouterAddress, true);
  }

  /// @notice sets max supply
  /// @param _amount The amount that is max supply
  function setMaxSupply(uint256 _amount) external virtual onlyOwner {
    require(_amount > _totalSupply, "Kibble: current supply is greater than inputed amount");
    require(maxSupply == 0, "Kibble: cannot set max supply again");
    maxSupply = _amount;
  }

  /// @notice mints an amount to an account only can be ran by minter
  /// @param _recipient The address to mint to
  /// @param _amount The amount to mint
  function mint(address _recipient, uint256 _amount)
    external
    virtual
    onlyMinter
  {
    require(
      maxSupply == 0 || maxSupply > _totalSupply,
      'Kibble: Max supply reached'
    );
    uint256 safeAmount = maxSupply == 0 || _amount + _totalSupply <= maxSupply
      ? _amount
      : maxSupply - _totalSupply;

    _mint(_recipient, safeAmount);
  }

  /// @notice burns an amount to an account only can be ran by burner
  /// @param _sender The address to burn from
  /// @param _amount The amount to burn
  function burn(address _sender, uint256 _amount) external virtual onlyBurner {
    _burn(_sender, _amount);
  }

  /// @notice implements the permit function
  /// @param _owner the owner of the funds
  /// @param _spender the _spender
  /// @param _value the amount
  /// @param _deadline the deadline timestamp, type(uint256).max for no deadline
  /// @param _v signature param
  /// @param _r signature param
  /// @param _s signature param
  function permit(
    address _owner,
    address _spender,
    uint256 _value,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external {
    require(_owner != address(0), 'Kibble: owner invalid');
    require(block.timestamp <= _deadline, 'Kibble: invalid deadline');
    uint256 currentValidNonce = _nonces[_owner];
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        DOMAIN_SEPARATOR,
        keccak256(
          abi.encode(
            PERMIT_TYPEHASH,
            _owner,
            _spender,
            _value,
            currentValidNonce,
            _deadline
          )
        )
      )
    );

    require(
      _owner == ecrecover(digest, _v, _r, _s),
      'Kibble: invalid signature'
    );
    _nonces[_owner] = currentValidNonce.add(1);
    _approve(_owner, _spender, _value);
  }

  /// @notice Delegates power from signatory to `delegatee`
  /// @param _delegatee The address to delegate votes to
  /// @param _power the power of delegation
  /// @param _nonce The contract state required to match the signature
  /// @param _expiry The time at which to expire the signature
  /// @param _v The recovery byte of the signature
  /// @param _r Half of the ECDSA signature pair
  /// @param _s Half of the ECDSA signature pair
  function delegateByPowerBySig(
    address _delegatee,
    DelegationPower _power,
    uint256 _nonce,
    uint256 _expiry,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external {
    bytes32 structHash = keccak256(
      abi.encode(
        DELEGATE_BY_POWER_TYPEHASH,
        _delegatee,
        uint256(_power),
        _nonce,
        _expiry
      )
    );
    bytes32 digest = keccak256(
      abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, structHash)
    );
    address signatory = ecrecover(digest, _v, _r, _s);
    require(
      signatory != address(0),
      'Kibble: delegateByPowerBySig: invalid signature'
    );
    require(
      _nonce == _nonces[signatory]++,
      'Kibble: delegateByPowerBySig: invalid nonce'
    );
    require(
      block.timestamp <= _expiry,
      'Kibble: delegateByPowerBySig: invalid expiration'
    );
    _delegateByPower(signatory, _delegatee, _power);
  }

  /// @notice Delegates power from signatory to `_delegatee`
  /// @param _delegatee The address to delegate votes to
  /// @param _nonce The contract state required to match the signature
  /// @param _expiry The time at which to expire the signature
  /// @param _v The recovery byte of the signature
  /// @param _r Half of the ECDSA signature pair
  /// @param _s Half of the ECDSA signature pair
  function delegateBySig(
    address _delegatee,
    uint256 _nonce,
    uint256 _expiry,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external {
    bytes32 structHash = keccak256(
      abi.encode(DELEGATE_TYPEHASH, _delegatee, _nonce, _expiry)
    );
    bytes32 digest = keccak256(
      abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, structHash)
    );
    address signatory = ecrecover(digest, _v, _r, _s);
    require(
      signatory != address(0),
      'Kibble: delegateByPowerBySig: invalid signature'
    );
    require(
      _nonce == _nonces[signatory]++,
      'Kibble: delegateByPowerBySig: invalid nonce'
    );
    require(
      block.timestamp <= _expiry,
      'Kibble: delegateByPowerBySig: invalid expiration'
    );

    _delegateByPower(signatory, _delegatee, DelegationPower.Voting);
    _delegateByPower(signatory, _delegatee, DelegationPower.Proposition);
  }

  /// @notice transfers tokens to recipient
  /// @param _recipient who the tokens are going to
  /// @param _amount amount of tokens
  function transfer(address _recipient, uint256 _amount)
    public
    virtual
    override
    returns (bool success_)
  {
    require(_recipient != address(0), 'Kibble: transfer to the zero address');

    address sender = _msgSender();

    if (_amount == 0) {
      super._transfer(sender, _recipient, 0);
      return false;
    }

    if (antiBotEnabled) {
      if (tokenPairs[_recipient]) {
        require(
          !antiBot.scanAddress(sender, _recipient, tx.origin),
          'Kibble: no bots allowed'
        );
      }
    }

    uint256 amountMinusFees = _removeFees(sender, _recipient, _amount);

    _transfer(sender, _recipient, amountMinusFees);

    _resetFee();

    success_ = true;
  }

  /// @notice transfers tokens from sender to recipient
  /// @param _sender who the tokens are from
  /// @param _recipient who the tokens are going to
  /// @param _amount amount of tokens
  function transferFrom(
    address _sender,
    address _recipient,
    uint256 _amount
  ) public virtual override returns (bool success_) {
    require(_sender != address(0), 'Kibble: transfer from the zero address');
    require(_recipient != address(0), 'Kibble: transfer to the zero address');

    if (_amount == 0) {
      _transfer(_sender, _recipient, 0);
      return false;
    }

    if (antiBotEnabled) {
      if (tokenPairs[_sender]) {
        require(
          !antiBot.scanAddress(_recipient, _sender, tx.origin),
          'Kibble: no bots allowed'
        );
      }
      if (tokenPairs[_recipient]) {
        require(
          !antiBot.scanAddress(_sender, _recipient, tx.origin),
          'Kibble: no bots allowed'
        );
      }
    }

    uint256 amountMinusFees = _removeFees(_sender, _recipient, _amount);

    _transfer(_sender, _recipient, amountMinusFees);

    _resetFee();

    success_ = true;
  }

  /// @notice sets new redistribution address
  /// @param _address address for redistribution policy
  function setRedistributionPolicyAddress(address _address) external onlyOwner {
    require(_address != address(0), 'Kibble: address cannot be zero address');
    require(_isContract(_address), 'Kibble: address has to be a contract');

    if (redistributionPolicyAddress != address(0)) {
      delete excluded[redistributionPolicyAddress];
    }

    redistributionPolicyAddress = _address;
    _setExcluded(_address, true);
  }

  /// @notice enable fees to be sent to redistribution policy
  function enableFees() external onlyOwner {
    require(
      redistributionPolicyAddress != address(0),
      'Kibble: redistribution policy not set'
    );
    require(!feeEnabled, 'Kibble: fee already enabled');
    feeEnabled = true;
  }

  /// @notice disable fees to be sent to redistribution policy
  function disableFees() external onlyOwner {
    require(feeEnabled, 'Kibble: fee already disabled');
    feeEnabled = false;
  }

  /// @notice set a new tax fee
  /// @param _fee the new fee
  function setTaxFee(uint256 _fee) external onlyOwner {
    _taxFee = _fee;
  }

  /// @notice set a new fee multiplier
  /// @param _multiplier the new multiplier
  function setFeeMultiplier(uint256 _multiplier) external onlyOwner {
    _feeMultiplier = _multiplier;
  }

  /// @notice set cool down for fee reset
  /// @param _cooldown cool down in days
  function setFeeResetCooldown(uint256 _cooldown) external onlyOwner {
    feeResetCooldown = _cooldown;
  }

  /// @notice set a pair to be included/excluded into antibot
  /// @param _pair the pair address
  /// @param _included if the pair is included or not
  function setTrackedPair(address _pair, bool _included) external onlyOwner {
    require(_pair != uniswapV2Pair, 'Kibble: og weth pair cannot be updated');
    require(_isContract(_pair), 'Kibble: address has to be a contract');

    _setTrackedPair(_pair, _included);
  }

  /// @notice set contract address to include in fees
  /// @param _targetAddress the address
  /// @param _included if the pair is included or not
  function setSellContracts(address _targetAddress, bool _included)
    external
    onlyOwner
  {
    require(
      _isContract(_targetAddress),
      'Kibble: address has to be a contract'
    );
    _setSellContracts(_targetAddress, _included);
  }

  /// @notice set contract address to excluded from fees
  /// @param _targetAddress the address
  /// @param _included if the pair is included or not
  function setExcluded(address _targetAddress, bool _included)
    external
    onlyOwner
  {
    _setExcluded(_targetAddress, _included);
  }

  /// @notice calculate fees for given user and send to redis
  /// @param _sender the amount of tokens being transferred
  /// @param _recipient the amount of tokens being transferred
  /// @param _amount the amount of tokens being transferred
  function _removeFees(
    address _sender,
    address _recipient,
    uint256 _amount
  ) internal returns (uint256 amount_) {
    if (!_includedInFee(_sender, _recipient)) return _amount;

    _calcFee(_sender);
    uint256 fee = _amount.mul(_taxFee).div(100);

    _balances[redistributionPolicyAddress] = _balances[
      redistributionPolicyAddress
    ]
    .add(fee);

    amount_ = _amount.sub(fee);

    emit Transfer(_sender, redistributionPolicyAddress, fee);
  }

  /// @notice choose fee percentage and update reset time and tx counts
  /// @param _sender the amount of tokens being transferred
  function _calcFee(address _sender) internal {
    if (_firstSell[_sender] + feeResetCooldown < block.timestamp) {
      _sellCount[_sender] = 0;
    }

    if (_sellCount[_sender] == 0) {
      _firstSell[_sender] = block.timestamp;
    }

    if (_sellCount[_sender] < 4) {
      _sellCount[_sender]++;
    }

    _taxFee = _sellCount[_sender].mul(_feeMultiplier);
  }

  /// @notice Writes a checkpoint before any operation involving transfer of value: _transfer, _mint and _burn
  /// - On _transfer, it writes checkpoints for both "from" and "to"
  /// - On _mint, only for _recipient
  /// - On _burn, only for _sender
  /// @param _sender the from address
  /// @param _recipient the to address
  /// @param _amount the amount to transfer
  function _beforeTokenTransfer(
    address _sender,
    address _recipient,
    uint256 _amount
  ) internal override {
    address votingFromDelegatee = _getDelegatee(_sender, _votingDelegates);
    address votingToDelegatee = _getDelegatee(_recipient, _votingDelegates);
    uint256 fee = 0;

    if (_includedInFee(_sender, _recipient)) {
      fee = _amount.mul(_taxFee).div(100);
    }

    _moveDelegatesByPower(
      votingFromDelegatee,
      votingToDelegatee,
      _amount.add(fee),
      DelegationPower.Voting
    );

    address propPowerFromDelegatee = _getDelegatee(
      _sender,
      _propositionPowerDelegates
    );
    address propPowerToDelegatee = _getDelegatee(
      _recipient,
      _propositionPowerDelegates
    );

    _moveDelegatesByPower(
      propPowerFromDelegatee,
      propPowerToDelegatee,
      _amount.add(fee),
      DelegationPower.Proposition
    );
  }

  /// @notice get delegation data by power
  /// @param _power the power querying by from
  function _getDelegationDataByPower(DelegationPower _power)
    internal
    view
    override
    returns (
      mapping(address => mapping(uint256 => Checkpoint)) storage checkpoints_,
      mapping(address => uint256) storage checkpointsCount_,
      mapping(address => address) storage delegates_
    )
  {
    if (_power == DelegationPower.Voting) {
      checkpoints_ = votingCheckpoints;
      checkpointsCount_ = _votingCheckpointsCounts;
      delegates_ = _votingDelegates;
    } else {
      checkpoints_ = _propositionPowerCheckpoints;
      checkpointsCount_ = _propositionPowerCheckpointsCounts;
      delegates_ = _propositionPowerDelegates;
    }
  }

  /// @notice set a pair to be included/excluded into fees
  /// @param _pair the pair address
  /// @param _included if the pair is included or not
  function _setTrackedPair(address _pair, bool _included) internal {
    require(
      tokenPairs[_pair] != _included,
      'Kibble: pair is already tracked with included state'
    );

    tokenPairs[_pair] = _included;
    emit LogTokenPair(_pair, _included);
  }

  /// @notice set an address for selling contracts
  /// @param _targetAddress the address
  /// @param _included if the pair is included or not
  function _setSellContracts(address _targetAddress, bool _included) internal {
    require(
      sellContracts[_targetAddress] != _included,
      'Kibble: This address is already tracked with included state'
    );

    sellContracts[_targetAddress] = _included;
    emit LogSellContracts(_targetAddress, _included);
  }

  /// @notice set an address to be excluded from fees
  /// @param _targetAddress the address
  /// @param _included if the pair is included or not
  function _setExcluded(address _targetAddress, bool _included) internal {
    require(
      excluded[_targetAddress] != _included,
      'Kibble: This address is already tracked with included state'
    );

    excluded[_targetAddress] = _included;
    emit LogExcluded(_targetAddress, _included);
  }

  /// @notice reset the fee
  function _resetFee() private {
    _taxFee = 5;
  }

  /// @notice check to included from fees
  /// @param _sender the amount of tokens being transferred
  /// @param _recipient the amount of tokens being transferred
  function _includedInFee(address _sender, address _recipient)
    private
    view
    returns (bool included_)
  {
    included_ =
      feeEnabled &&
      (sellContracts[_recipient] || tokenPairs[_recipient]) &&
      !excluded[_sender];
  }
}
