// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IERC20.sol";
import "./IKeep3rV1Proxy.sol";
import "./IvKP3R.sol";
import "./IrKP3R.sol";
import "./IGauge.sol";
import "./IGaugeProxy.sol";

contract GaugeProxyV2 is IGaugeProxy {
  address constant _rkp3r = 0xEdB67Ee1B171c4eC66E6c10EC43EDBbA20FaE8e9;
  address constant _vkp3r = 0x2FC52C61fB0C03489649311989CE2689D93dC1a2;
  address constant _kp3rV1 = 0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44;
  address constant _kp3rV1Proxy = 0x976b01c02c636Dd5901444B941442FD70b86dcd5;
  address constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

  /// @inheritdoc IGaugeProxy
  uint256 public totalWeight;

  /// @inheritdoc IGaugeProxy
  address public keeper;
  /// @inheritdoc IGaugeProxy
  address public gov;
  /// @inheritdoc IGaugeProxy
  address public nextgov;
  /// @inheritdoc IGaugeProxy
  uint256 public commitgov;
  /// @inheritdoc IGaugeProxy
  uint256 public constant delay = 1 days;

  address[] internal _tokens;
  /// @inheritdoc IGaugeProxy
  mapping(address => address) public gauges; // token => gauge
  /// @inheritdoc IGaugeProxy
  mapping(address => uint256) public weights; // token => weight
  /// @inheritdoc IGaugeProxy
  mapping(address => mapping(address => uint256)) public votes; // msg.sender => votes
  /// @inheritdoc IGaugeProxy
  mapping(address => address[]) public tokenVote; // msg.sender => token
  /// @inheritdoc IGaugeProxy
  mapping(address => uint256) public usedWeights; // msg.sender => total voting weight of user
  /// @inheritdoc IGaugeProxy
  mapping(address => bool) public enabled;

  /// @inheritdoc IGaugeProxy
  function tokens() external view returns (address[] memory) {
    return _tokens;
  }

  constructor(address _gov) {
    gov = _gov;
    _safeApprove(_kp3rV1, _rkp3r, type(uint256).max);
  }

  modifier g() {
    require(msg.sender == gov);
    _;
  }

  modifier k() {
    require(msg.sender == keeper);
    _;
  }

  /// @inheritdoc IGaugeProxy
  function setKeeper(address _keeper) external g {
    keeper = _keeper;
  }

  /// @inheritdoc IGaugeProxy
  function setGov(address _gov) external g {
    nextgov = _gov;
    commitgov = block.timestamp + delay;
  }

  /// @inheritdoc IGaugeProxy
  function acceptGov() external {
    require(msg.sender == nextgov && commitgov < block.timestamp);
    gov = nextgov;
  }

  /// @inheritdoc IGaugeProxy
  function reset() external {
    _reset(msg.sender);
  }

  function _reset(address _owner) internal {
    address[] storage _tokenVote = tokenVote[_owner];
    uint256 _tokenVoteCnt = _tokenVote.length;

    for (uint256 i = 0; i < _tokenVoteCnt; i++) {
      address _token = _tokenVote[i];
      uint256 _votes = votes[_owner][_token];

      if (_votes > 0) {
        totalWeight -= _votes;
        weights[_token] -= _votes;
        votes[_owner][_token] = 0;
      }
    }

    delete tokenVote[_owner];
  }

  /// @inheritdoc IGaugeProxy
  function poke(address _owner) public {
    address[] memory _tokenVote = tokenVote[_owner];
    uint256 _tokenCnt = _tokenVote.length;
    uint256[] memory _weights = new uint256[](_tokenCnt);

    uint256 _prevUsedWeight = usedWeights[_owner];
    uint256 _weight = IvKP3R(_vkp3r).get_adjusted_ve_balance(_owner, ZERO_ADDRESS);

    for (uint256 i = 0; i < _tokenCnt; i++) {
      uint256 _prevWeight = votes[_owner][_tokenVote[i]];
      _weights[i] = (_prevWeight * _weight) / _prevUsedWeight;
    }

    _vote(_owner, _tokenVote, _weights);
  }

  function _vote(
    address _owner,
    address[] memory _tokenVote,
    uint256[] memory _weights
  ) internal {
    // _weights[i] = percentage * 100
    _reset(_owner);
    uint256 _tokenCnt = _tokenVote.length;
    uint256 _weight = IvKP3R(_vkp3r).get_adjusted_ve_balance(_owner, ZERO_ADDRESS);
    uint256 _totalVoteWeight = 0;
    uint256 _usedWeight = 0;

    for (uint256 i = 0; i < _tokenCnt; i++) {
      _totalVoteWeight += _weights[i];
    }

    for (uint256 i = 0; i < _tokenCnt; i++) {
      address _token = _tokenVote[i];
      address _gauge = gauges[_token];
      uint256 _tokenWeight = (_weights[i] * _weight) / _totalVoteWeight;

      if (_gauge != address(0x0)) {
        _usedWeight += _tokenWeight;
        totalWeight += _tokenWeight;
        weights[_token] += _tokenWeight;
        tokenVote[_owner].push(_token);
        votes[_owner][_token] = _tokenWeight;
      }
    }

    usedWeights[_owner] = _usedWeight;
  }

  /// @inheritdoc IGaugeProxy
  function vote(address[] calldata _tokenVote, uint256[] calldata _weights) external {
    require(_tokenVote.length == _weights.length);
    _vote(msg.sender, _tokenVote, _weights);
  }

  /// @inheritdoc IGaugeProxy
  function addGauge(address _token, address _gauge) external g {
    require(gauges[_token] == address(0x0), 'exists');
    _safeApprove(_rkp3r, _gauge, type(uint256).max);
    gauges[_token] = _gauge;
    enabled[_token] = true;
    _tokens.push(_token);
  }

  /// @inheritdoc IGaugeProxy
  function disable(address _token) external g {
    enabled[_token] = false;
  }

  /// @inheritdoc IGaugeProxy
  function enable(address _token) external g {
    enabled[_token] = true;
  }

  /// @inheritdoc IGaugeProxy
  function length() external view returns (uint256) {
    return _tokens.length;
  }

  /// @inheritdoc IGaugeProxy
  function forceDistribute() external g {
    _distribute();
  }

  /// @inheritdoc IGaugeProxy
  function distribute() external k {
    _distribute();
  }

  function _distribute() internal {
    uint256 _balance = IKeep3rV1Proxy(_kp3rV1Proxy).draw();
    IrKP3R(_rkp3r).deposit(_balance);

    if (_balance > 0 && totalWeight > 0) {
      uint256 _totalWeight = totalWeight;
      for (uint256 i = 0; i < _tokens.length; i++) {
        if (!enabled[_tokens[i]]) {
          _totalWeight -= weights[_tokens[i]];
        }
      }
      for (uint256 x = 0; x < _tokens.length; x++) {
        if (enabled[_tokens[x]]) {
          uint256 _reward = (_balance * weights[_tokens[x]]) / _totalWeight;
          if (_reward > 0) {
            address _gauge = gauges[_tokens[x]];
            IGauge(_gauge).deposit_reward_token(_rkp3r, _reward);
          }
        }
      }
    }
  }

  function _safeApprove(
    address token,
    address spender,
    uint256 value
  ) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, spender, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))));
  }
}
