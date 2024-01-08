// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./MTGY.sol";
import "./MTGYSpend.sol";
import "./MTGYAtomicSwapInstance.sol";

/**
 * @title MTGYAtomicSwap
 * @dev This is the main contract that supports holding metadata for MTGY atomic inter and intrachain swapping
 */
contract MTGYAtomicSwap is Ownable {
  struct TargetSwapInfo {
    bytes32 id;
    uint256 timestamp;
    uint256 index;
    address creator;
    address sourceContract;
    string targetNetwork;
    address targetContract;
    bool isActive;
  }

  MTGY private _mtgy;
  MTGYSpend private _spend;

  uint256 public mtgyServiceCost = 25000 * 10**18;
  uint256 public swapCreationGasLoadAmount = 1 * 10**16; // 10 finney (0.01 ether)
  address public creator;
  address payable public oracleAddress;

  // mapping with "0xSourceContractInstance" => targetContractInstanceInfo that
  // our oracle can query and get the target network contract as needed.
  TargetSwapInfo[] public targetSwapContracts;
  mapping(address => TargetSwapInfo) public targetSwapContractsIndexed;
  mapping(address => TargetSwapInfo) private lastUserCreatedContract;

  // event CreateSwapContract(
  //   uint256 timestamp,
  //   address contractAddress,
  //   string targetNetwork,
  //   address indexed targetContract,
  //   address creator
  // );

  constructor(
    address _mtgyAddress,
    address _mtgySpendAddress,
    address _oracleAddress
  ) {
    creator = msg.sender;
    _mtgy = MTGY(_mtgyAddress);
    _spend = MTGYSpend(_mtgySpendAddress);
    oracleAddress = payable(_oracleAddress);
  }

  function updateSwapCreationGasLoadAmount(uint256 _amount) external onlyOwner {
    swapCreationGasLoadAmount = _amount;
  }

  function getLastCreatedContract(address _addy)
    external
    view
    returns (TargetSwapInfo memory)
  {
    return lastUserCreatedContract[_addy];
  }

  function changeOracleAddress(address _oracleAddress, bool _changeAll)
    external
    onlyOwner
  {
    oracleAddress = payable(_oracleAddress);
    if (_changeAll) {
      for (uint256 _i = 0; _i < targetSwapContracts.length; _i++) {
        MTGYAtomicSwapInstance _contract = MTGYAtomicSwapInstance(
          targetSwapContracts[_i].sourceContract
        );
        _contract.changeOracleAddress(oracleAddress);
      }
    }
  }

  function changeMtgyTokenAddy(address _tokenAddy) external onlyOwner {
    _mtgy = MTGY(_tokenAddy);
  }

  function changeSpendAddress(address _spendAddress) external onlyOwner {
    _spend = MTGYSpend(_spendAddress);
  }

  /**
   * @dev If the price of MTGY changes significantly, need to be able to adjust price
   * to keep cost appropriate for providing the service
   */
  function changeMtgyServiceCost(uint256 _newCost) external onlyOwner {
    mtgyServiceCost = _newCost;
  }

  function getAllSwapContracts()
    external
    view
    returns (TargetSwapInfo[] memory)
  {
    return targetSwapContracts;
  }

  function updateSwapContract(
    uint256 _createdBlockTimestamp,
    address _sourceContract,
    address _targetContract,
    bool _isActive
  ) external {
    TargetSwapInfo storage swapContInd = targetSwapContractsIndexed[
      _sourceContract
    ];
    TargetSwapInfo storage swapCont = targetSwapContracts[swapContInd.index];

    require(
      msg.sender == creator ||
        msg.sender == swapCont.creator ||
        msg.sender == oracleAddress,
      'updateSwapContract must be contract creator'
    );

    bytes32 _id = sha256(
      abi.encodePacked(swapCont.creator, _createdBlockTimestamp)
    );
    require(
      swapCont.id == _id && swapContInd.id == _id,
      "we don't recognize the info you sent with the swap"
    );

    swapCont.targetContract = address(0) != _targetContract
      ? _targetContract
      : swapCont.targetContract;
    swapCont.isActive = _isActive;
    swapContInd.targetContract = swapCont.targetContract;
    swapContInd.isActive = _isActive;
  }

  function createNewAtomicSwapContract(
    address _tokenAddy,
    uint256 _tokenSupply,
    uint256 _maxSwapAmount,
    string memory _targetNetwork,
    address _targetContract
  ) external payable returns (uint256, address) {
    require(
      msg.value >= swapCreationGasLoadAmount,
      'Going to ask the user to fill up the atomic swap contract with some gas'
    );
    _mtgy.transferFrom(msg.sender, address(this), mtgyServiceCost);
    _mtgy.approve(address(_spend), mtgyServiceCost);
    _spend.spendOnProduct(mtgyServiceCost);

    MTGYAtomicSwapInstance _contract = new MTGYAtomicSwapInstance(
      address(_mtgy),
      address(_spend),
      oracleAddress,
      msg.sender,
      _tokenAddy,
      _maxSwapAmount
    );
    oracleAddress.transfer(msg.value);
    ERC20 _token = ERC20(_tokenAddy);
    _token.transferFrom(msg.sender, address(_contract), _tokenSupply);
    _contract.updateSupply();
    _contract.transferOwnership(oracleAddress);

    uint256 _ts = block.timestamp;
    TargetSwapInfo memory newContract = TargetSwapInfo({
      id: sha256(abi.encodePacked(msg.sender, _ts)),
      timestamp: _ts,
      index: targetSwapContracts.length,
      creator: msg.sender,
      sourceContract: address(_contract),
      targetNetwork: _targetNetwork,
      targetContract: _targetContract,
      isActive: true
    });

    targetSwapContracts.push(newContract);
    targetSwapContractsIndexed[address(_contract)] = newContract;
    lastUserCreatedContract[msg.sender] = newContract;
    // emit CreateSwapContract(
    //   _ts,
    //   address(_contract),
    //   _targetNetwork,
    //   _targetContract,
    //   msg.sender
    // );
    return (_ts, address(_contract));
  }
}
