// SPDX-License-Identifier: MIT

import "./Initializable.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./EnumerableSet.sol";

pragma solidity ^0.8.0;

contract UBridge is Ownable, Pausable, ReentrancyGuard, Initializable {
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  uint256 public chainId;
  uint256 public count;
  bool public pausedDeposits;
  EnumerableSet.AddressSet private verifyAddresses;
  uint256[] private chainIds = new uint256[](0);
  address[] private originAddresses = new address[](0);

  struct WithdrawalParams {
    address withdrawalAddress;
    address originTokenAddress;
    address destinationTokenAddress;
    uint256 amount;
    uint256 originChainId;
    uint256 targetChainId;
    uint256 _count;
    bytes[] signatures;
  }

  mapping(bytes => bool) public filledSwaps;
  mapping(uint256 => bool) public chainIdSupported;
  mapping(address => mapping(uint256 => address)) public tokensSupported; // originERC20Addr[chainIdTarget] = targetERC20Addr
  mapping(address => uint256) public chainsSupportedForTokenAddress;
  mapping(uint256 => uint256) public chainIdFees;

  event Deposit(
    address withdrawalAddress,
    address originTokenAddress,
    address destinationTokenAddress,
    uint256 amount,
    uint256 indexed originChainId,
    uint256 targetChainId,
    uint256 indexed count
  );
  event Withdraw(
    address withdrawalAddress,
    address originTokenAddress,
    address destinationTokenAddress,
    uint256 amount,
    uint256 indexed originChainId,
    uint256 targetChainId,
    uint256 indexed count
  );
  event ChainIdAdded(uint256 newChainId);
  event ChainIdRemoved(uint256 newChainId);
  event ChainIdFeeUpdated(uint256 newChainId, uint256 fees);
  event TokenAdded(address tokenAddress, uint256 chainIdsTarget);
  event TokenRemove(address tokenAddress, uint256 chainIdsTarget);
  event DepositStatusUpdated(bool isPaused);
  event VerifyAddressAdded(address newVerifier);
  event VerifyAddressRemoved(address oldVerifier);

  modifier whenNotDepositsPaused() {
    require(!pausedDeposits, "Deposits have been suspended");
    _;
  }

  function init(address[] memory _verifyAddresses, uint256 _chainId) public initializer {
    for (uint256 i; i < _verifyAddresses.length; i += 1) {
      verifyAddresses.add(_verifyAddresses[i]);
    }
    chainId = _chainId;
  }

  function addVerifyAddress(address newVerifier) public onlyOwner {
    require(newVerifier != address(0), "ADDRESS_0");
    verifyAddresses.add(newVerifier);
    emit VerifyAddressAdded(newVerifier);
  }

  function removeVerifyAddress(address oldVerifier) public onlyOwner {
    verifyAddresses.remove(oldVerifier);
    emit VerifyAddressRemoved(oldVerifier);
  }

  function getVerifyAddresses() public view returns (address[] memory) {
    return verifyAddresses.values();
  }

  function addToken(
    address originTokenAddress,
    address[] memory destinationTokenAddresses,
    uint256[] memory chainIdsTarget
  ) public onlyOwner {
    require(originTokenAddress != address(0), "ADDRESS_0");
    require(destinationTokenAddresses.length == chainIdsTarget.length, "ARRAYS_LENGTH_DIFFER");
    if (chainsSupportedForTokenAddress[originTokenAddress] == 0)
      originAddresses.push(originTokenAddress);
    for (uint256 i = 0; i < chainIdsTarget.length; i++) {
      require(chainIdSupported[chainIdsTarget[i]], "CHAIN_ID_NOT_SUPPORTED");
      chainsSupportedForTokenAddress[originTokenAddress]++;
      tokensSupported[originTokenAddress][chainIdsTarget[i]] = destinationTokenAddresses[i];
      emit TokenAdded(originTokenAddress, chainIdsTarget[i]);
    }
  }

  function addChainId(uint256[] memory newChainId) public onlyOwner {
    for (uint256 i = 0; i < newChainId.length; i++) {
      if (!chainIdSupported[newChainId[i]]) chainIds.push(newChainId[i]);
      chainIdSupported[newChainId[i]] = true;
      emit ChainIdAdded(newChainId[i]);
    }
  }

  function setChainIdFee(uint256[] memory _chainIds, uint256[] memory fees) public onlyOwner {
    require(_chainIds.length == fees.length, "INVALID_PARAMS");
    for (uint256 i = 0; i < _chainIds.length; ++i) {
      uint256 _chainId = _chainIds[i];
      uint256 _chainIdFee = fees[i];
      chainIdFees[_chainId] = _chainIdFee;
      emit ChainIdFeeUpdated(_chainId, _chainIdFee);
    }
  }

  function removeToken(address tokenAddress, uint256[] memory chainIdsTarget) public onlyOwner {
    for (uint256 j = 0; j < chainIdsTarget.length; j++) {
      uint256 _chainId = chainIdsTarget[j];
      require(chainIdSupported[_chainId], "CHAIN_ID_NOT_SUPPORTED");
      require(
        tokensSupported[tokenAddress][chainIdsTarget[j]] != address(0),
        "TOKEN_CHAIN_ID_NOT_SUPPORTED"
      );
      tokensSupported[tokenAddress][chainIdsTarget[j]] = address(0);
      chainsSupportedForTokenAddress[tokenAddress]--;
      emit TokenRemove(tokenAddress, chainIdsTarget[j]);
    }
    if (chainsSupportedForTokenAddress[tokenAddress] > 0) return;
    uint256 i;
    for (i = 0; i < originAddresses.length; i++) {
      if (originAddresses[i] == tokenAddress) break;
    }
    for (; i < originAddresses.length - 1; i++) {
      originAddresses[i] = originAddresses[i + 1];
    }
    originAddresses.pop();
  }

  function removeChainId(uint256 _chainId) public onlyOwner {
    require(chainIdSupported[_chainId], "CHAIN_ID_NOT_SUPPORTED");
    uint256 i;
    for (i = 0; i < chainIds.length; i++) {
      if (chainIds[i] == _chainId) break;
    }
    for (; i < chainIds.length - 1; i++) {
      chainIds[i] = chainIds[i + 1];
    }
    chainIds.pop();
    chainIdSupported[_chainId] = false;
    emit ChainIdRemoved(_chainId);
  }

  function getChainIds() public view returns (uint256[] memory) {
    return chainIds;
  }

  function getOriginAddresses() public view returns (address[] memory) {
    return originAddresses;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function changeDepositsState(bool isPaused) public onlyOwner {
    emit DepositStatusUpdated(isPaused);
    pausedDeposits = isPaused;
  }

  function deposit(
    address withdrawalAddress,
    address originTokenAddress,
    uint256 amount,
    uint256 targetChainId
  ) public payable nonReentrant whenNotDepositsPaused whenNotPaused {
    require(msg.value == chainIdFees[targetChainId], "WRONG_FEE");
    require(withdrawalAddress != address(0), "WRONG_ADDRESS");
    require(chainIdSupported[targetChainId], "CHAIN_ID_NOT_SUPPORTED");
    address destinationTokenAddress = tokensSupported[originTokenAddress][targetChainId];
    require(destinationTokenAddress != address(0), "UNSUPPORTED_TOKEN_ON_CHAIN_ID");
    count += 1;
    IERC20(originTokenAddress).safeTransferFrom(msg.sender, address(this), amount);

    emit Deposit(
      withdrawalAddress,
      originTokenAddress,
      destinationTokenAddress,
      amount,
      chainId,
      targetChainId,
      count
    );
  }

  function claimFees() public nonReentrant {
    uint256 balance = address(this).balance;
    (bool sent, ) = address(owner()).call{value: balance}("");
    require(sent, "Failed to send Ether");
  }

  function withdraw(
    address withdrawalAddress,
    address originTokenAddress,
    address destinationTokenAddress,
    uint256 amount,
    uint256 originChainId,
    uint256 targetChainId,
    uint256 _count,
    bytes[] memory signatures
  ) public nonReentrant whenNotPaused {
    require(verifyAddresses.length() > 0, "NO_VERIFIERS");
    require(targetChainId == chainId, "WRONG_CHAIN_ID");
    require(signatures.length == verifyAddresses.length(), "WRONG_SIGNATURES");

    for (uint256 i; i < signatures.length; i++) {
      bytes memory signature = signatures[i];
      require(!filledSwaps[signature], "ALREADY_FILLED");
      require(
        verify(
          withdrawalAddress,
          originTokenAddress,
          destinationTokenAddress,
          amount,
          originChainId,
          targetChainId,
          _count,
          signature
        ),
        "WRONG_SIGNER"
      );
      filledSwaps[signature] = true;
    }

    IERC20(destinationTokenAddress).safeTransfer(withdrawalAddress, amount);

    emit Withdraw(
      withdrawalAddress,
      originTokenAddress,
      destinationTokenAddress,
      amount,
      originChainId,
      targetChainId,
      _count
    );
  }

  function withdrawBatch(WithdrawalParams[] memory withdrawals) public {
    WithdrawalParams memory withdrawal;
    for (uint256 i = 0; i < withdrawals.length; i++) {
      withdrawal = withdrawals[i];
      withdraw(
        withdrawal.withdrawalAddress,
        withdrawal.originTokenAddress,
        withdrawal.destinationTokenAddress,
        withdrawal.amount,
        withdrawal.originChainId,
        withdrawal.targetChainId,
        withdrawal._count,
        withdrawal.signatures
      );
    }
  }

  function verify(
    address withdrawalAddress,
    address originTokenAddress,
    address destinationTokenAddress,
    uint256 amount,
    uint256 originChainId,
    uint256 targetChainId,
    uint256 _count,
    bytes memory signature
  ) private view returns (bool) {
    bytes32 message = ECDSA.toEthSignedMessageHash(
      keccak256(
        abi.encodePacked(
          withdrawalAddress,
          originTokenAddress,
          destinationTokenAddress,
          amount,
          originChainId,
          targetChainId,
          _count
        )
      )
    );
    address signer = ECDSA.recover(message, signature);
    return verifyAddresses.contains(signer);
  }
}
