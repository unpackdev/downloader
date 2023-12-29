// Copyright 2023 Energi Core

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
//       match requirement.

pragma solidity 0.8.20;

import "./Ownable.sol";
import "./WmbApp.sol";
import "./Pausable.sol";
import "./IEnergiWanBridge.sol";

contract EnergiWmbApp is Ownable, WmbApp, Pausable {
  // execute a function only from energiwanbridge contract

  // EnergiWanBridge Proxy address
  address private energiWanBridgeAddress;

  // mapping to store wmb addresses of different chain ids
  mapping(uint256 => address) private chainIdToWmbAppContract;
  mapping(uint256 => uint256) private chainIdToBIP44ChainId;

  // mapping of mapping to store token addresses for different chains
  mapping(address => mapping(uint256 => address)) public tokenAddressForChainId;

  constructor(address admin, address _wmbGateway, address _energiBridgeProxy) WmbApp() {
    initialize(admin, _wmbGateway);
    energiWanBridgeAddress = _energiBridgeProxy;
  }

  // access modifier which allows only energi wan bridge proxy contract can call
  modifier onlyEnergiWanBridge() {
    require(
      msg.sender == energiWanBridgeAddress,
      'EnergiWmbApp:: Must be EnergiWanBridge contract'
    );
    _;
  }

  // access modifier which allows only gateway contract can call
  modifier onlyGateway() {
    require(msg.sender == wmbGateway, 'EnergiWmbApp:: Must be gateway contract');
    _;
  }

  event EnergiWanBridgeAddressUpdated(
    address oldEnergiWanBridgeAddress,
    address newEnergiWanBridgeAddress
  );

  event MessgeSent(
    address _from,
    address _to,
    uint256 _amount,
    address _tokenAddress,
    uint256 _chainId
  );

  event MessegeReceived(address from, address to, uint256 amount, address tokenAddress);

  // send meesege to gateway contract on source chain
  // only energi wan bridge contract can call this function
  function sendMessage(
    address _from,
    address _to,
    uint256 _amount,
    address _tokenAddress,
    uint256 _chainId,
    uint256 _gasLimit
  ) public whenNotPaused onlyEnergiWanBridge {
    require(
      chainIdToWmbAppContract[_chainId] != address(0),
      'EnergiWmbApp:: WmbApp address cannot be address zero'
    );
    uint fee = estimateFee(chainIdToBIP44ChainId[_chainId], _gasLimit);

    // gate way interaction
    _dispatchMessage(
      chainIdToBIP44ChainId[_chainId],
      chainIdToWmbAppContract[_chainId],
      abi.encode(_from, _to, _amount, tokenAddressForChainId[_tokenAddress][_chainId]),
      fee
    );

    emit MessgeSent(_from, _to, _amount, _tokenAddress, _chainId);
  }

  function getEstimatedFees(uint256 _chainId, uint256 _gasLimit) external view returns (uint256) {
    return estimateFee(chainIdToBIP44ChainId[_chainId], _gasLimit);
  }

  // returns energi wan bridge proxy contract
  function getEnergiWanBridgeAddress() public view returns (address) {
    return energiWanBridgeAddress;
  }

  // return wmb address for given chain id
  function getEnergiWmbAppAddressForChainId(uint256 _chainId) public view returns (address) {
    return chainIdToWmbAppContract[_chainId];
  }

  // returns address of destination chain
  // _chainId - destination chain id
  // _sourceTokenAddress - address of token in source chain
  function getDestinationTokenAddress(
    uint256 _chainId,
    address _sourceTokenAddress
  ) public view returns (address) {
    return tokenAddressForChainId[_sourceTokenAddress][_chainId];
  }

  function getBIP44ChainIdForChainId(uint256 _chainId) public view returns (uint256) {
    return chainIdToBIP44ChainId[_chainId];
  }

  // add wmb contract for destination chains
  // _chainId - destination chainid
  // _wmbAppContractAddress - WmbApp contract address for destination chain
  // only called by owner of smart contract
  function addWmbAppContract(uint256 _chainId, address _wmbAppContractAddress) external onlyOwner {
    require(_wmbAppContractAddress != address(0), 'EnergiWmbApp:: Address cannot be zero address');

    require(
      chainIdToWmbAppContract[_chainId] != _wmbAppContractAddress,
      'EnergiWmbApp:: Cannot add dupicate value'
    );

    chainIdToWmbAppContract[_chainId] = _wmbAppContractAddress;
  }

  // set's energiWanBridge address
  // only called by owner of smart contract
  function setEnergiWanBridgeAddress(address _newEnergiWanBridgeAddress) external onlyOwner {
    address oldEnergiWanBridgeAddress = energiWanBridgeAddress;
    energiWanBridgeAddress = _newEnergiWanBridgeAddress;
    require(
      _newEnergiWanBridgeAddress != address(0),
      'EnergiWmbApp:: EnergiWanBridge cannot be zero address'
    );
    require(
      oldEnergiWanBridgeAddress != _newEnergiWanBridgeAddress,
      'EnergiWmbApp:: EnergiWanBridge address cannot be same as previous EnergiWanBridge address'
    );

    emit EnergiWanBridgeAddressUpdated(oldEnergiWanBridgeAddress, _newEnergiWanBridgeAddress);
  }

  // add tokens for different chain ids
  // _sourceTokenAddress - token address on source chain
  // _destinationTokenAddress - token address on destiantion chain
  // _destinationChainId - chain id of destination chain
  function setTokensWithChainId(
    address _sourceTokenAddress,
    address _destinationTokenAddress,
    uint256 _destinationChainId
  ) external onlyOwner {
    require(_sourceTokenAddress != address(0), 'EnergiWmbApp:: Source token address is invalid');
    require(
      _destinationTokenAddress != address(0),
      'EnergiWmbApp:: Destination token address is invalid'
    );

    tokenAddressForChainId[_sourceTokenAddress][_destinationChainId] = _destinationTokenAddress;
  }

  function addChainIdToBIP44ChainId(uint256 _chainId, uint256 _bip44ChainId) external onlyOwner {
    chainIdToBIP44ChainId[_chainId] = _bip44ChainId;
  }

  function pause() external whenNotPaused onlyOwner {
    _pause();
  }

  function unpause() external whenPaused onlyOwner {
    _unpause();
  }

  function _currentTime() internal view returns (uint256) {
    return block.timestamp;
  }

  function _wmbReceive(
    bytes calldata data,
    bytes32 /*messageId*/,
    uint256 fromChainId,
    address /*fromSC*/
  ) internal override {
    (address _from, address _to, uint256 _amount, address _tokenAddress) = abi.decode(
      data,
      (address, address, uint256, address)
    );

    IEnergiWanBridge(energiWanBridgeAddress).receiveTokens(
      _from,
      _to,
      _amount,
      _tokenAddress,
      fromChainId
    );

    emit MessegeReceived(_from, _to, _amount, _tokenAddress);
  }

  /* solhint-disable */
  fallback() external {}

  receive() external payable {}
  /* solhint-enable */
}
