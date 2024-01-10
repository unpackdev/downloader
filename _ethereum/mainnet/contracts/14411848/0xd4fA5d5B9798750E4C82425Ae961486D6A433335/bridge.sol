//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract Bridge is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  mapping(uint256 => mapping(address => address)) public reversePairs;
  mapping(uint256 => mapping(bytes32 => bool)) isFilled;
  mapping(uint256 => uint256) public staticFee;
  mapping(uint256 => uint256) public performanceFee;
  address public nativeTokenAddr = address(1);
  uint256 public chainId;

  constructor() {
    uint256 id;
    assembly {
        id := chainid()
    }
    chainId = id;
  }

  event NewPairRegistered(
    uint256 chainId,
    address _token,
    uint256[] chainIds,
    address[] _tokens
  );

  event BridgeSwapStarted(
    address token,
    uint256 amount,
    uint256 targetChainId,
    address to
  );

  event BridgeSwapFilled(
    uint256 chainId,
    address token,
    uint256 amount,
    address to
  );

  function reisterPair(address _token, uint256[] memory _chainIds, address[] memory _tokens) external onlyOwner {
    require(_chainIds.length == _tokens.length, "not-equal-length");
    for(uint i = 0; i < _chainIds.length; i++) {
      reversePairs[_chainIds[i]][_tokens[i]] = _token;
    }

    emit NewPairRegistered(
      chainId,
      _token,
      _chainIds,
      _tokens
    );
  }

  function deposit() external payable {}

  function updateStaticFee(uint256 _staticFee, uint256 _chainId) external onlyOwner {
      staticFee[_chainId] = _staticFee;
  }

  function updatePerformanceFee(uint256 _performanceFee, uint256 _chainId) external onlyOwner {
      performanceFee[_chainId] = _performanceFee;
  }

  function bridgeToken(address _token, uint256 _targetChainId, uint256 _amount, address _to) external payable nonReentrant {
    if(_token == nativeTokenAddr) {
        require(_amount + staticFee[_targetChainId] <= msg.value, "not-enough-static-fee");
    } else {
        require(msg.value >= staticFee[_targetChainId], "not-enough-static-fee");
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    }
    uint256 bridgeAmount = _amount.mul(10000 - performanceFee[_targetChainId]).div(10000);
    emit BridgeSwapStarted(_token, bridgeAmount , _targetChainId, _to);
  }

  function fillBridgeSwap(bytes32 originTxHash, address _token, uint256 _chainId, address _to, uint256 _amount) external payable onlyOwner {
    require(!isFilled[_chainId][originTxHash], "already-filled");
    if(reversePairs[_chainId][_token] == nativeTokenAddr) {
        address payable to = payable(_to);
        to.transfer(_amount);
    } else {
        IERC20(reversePairs[_chainId][_token]).safeTransfer(_to, _amount);
    }
    isFilled[_chainId][originTxHash] = true;
    emit BridgeSwapFilled(_chainId, _token, _amount, _to);
  }

  function withdrawToken(address _token, uint256 _amount) external onlyOwner {
    IERC20(_token).safeTransfer(msg.sender, _amount);
  }

  function withdrawNativeCurrency() external payable onlyOwner {
      address payable msgSender = payable(msg.sender);
      msgSender.transfer(address(this).balance);
  }

  function withdrawNativeCurrency(uint256 _amount) external payable onlyOwner {
      address payable msgSender = payable(msg.sender);
      msgSender.transfer(_amount);
  }
}
