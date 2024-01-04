// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./MultiRole.sol";
import "./RegistryInterface.sol";

import "./SafeMath.sol";

contract Registry is RegistryInterface, MultiRole {
  using SafeMath for uint256;

  enum Roles {Owner, ContractCreator}

  enum Validity {Invalid, Valid}

  struct FinancialContract {
    Validity valid;
    uint128 index;
  }

  struct Party {
    address[] contracts;
    mapping(address => uint256) contractIndex;
  }

  address[] public registeredContracts;

  mapping(address => FinancialContract) public contractMap;

  mapping(address => Party) private partyMap;

  event NewContractRegistered(
    address indexed contractAddress,
    address indexed creator,
    address[] parties
  );
  event PartyAdded(address indexed contractAddress, address indexed party);
  event PartyRemoved(address indexed contractAddress, address indexed party);

  constructor() public {
    _createExclusiveRole(
      uint256(Roles.Owner),
      uint256(Roles.Owner),
      msg.sender
    );

    _createSharedRole(
      uint256(Roles.ContractCreator),
      uint256(Roles.Owner),
      new address[](0)
    );
  }

  function registerContract(address[] calldata parties, address contractAddress)
    external
    override
    onlyRoleHolder(uint256(Roles.ContractCreator))
  {
    FinancialContract storage financialContract = contractMap[contractAddress];
    require(
      contractMap[contractAddress].valid == Validity.Invalid,
      'Can only register once'
    );

    registeredContracts.push(contractAddress);

    financialContract.index = uint128(registeredContracts.length.sub(1));

    financialContract.valid = Validity.Valid;
    for (uint256 i = 0; i < parties.length; i = i.add(1)) {
      _addPartyToContract(parties[i], contractAddress);
    }

    emit NewContractRegistered(contractAddress, msg.sender, parties);
  }

  function addPartyToContract(address party) external override {
    address contractAddress = msg.sender;
    require(
      contractMap[contractAddress].valid == Validity.Valid,
      'Can only add to valid contract'
    );

    _addPartyToContract(party, contractAddress);
  }

  function removePartyFromContract(address partyAddress) external override {
    address contractAddress = msg.sender;
    Party storage party = partyMap[partyAddress];
    uint256 numberOfContracts = party.contracts.length;

    require(numberOfContracts != 0, 'Party has no contracts');
    require(
      contractMap[contractAddress].valid == Validity.Valid,
      'Remove only from valid contract'
    );
    require(
      isPartyMemberOfContract(partyAddress, contractAddress),
      'Can only remove existing party'
    );

    uint256 deleteIndex = party.contractIndex[contractAddress];

    address lastContractAddress = party.contracts[numberOfContracts - 1];

    party.contracts[deleteIndex] = lastContractAddress;

    party.contractIndex[lastContractAddress] = deleteIndex;

    party.contracts.pop();
    delete party.contractIndex[contractAddress];

    emit PartyRemoved(contractAddress, partyAddress);
  }

  function isContractRegistered(address contractAddress)
    external
    view
    override
    returns (bool)
  {
    return contractMap[contractAddress].valid == Validity.Valid;
  }

  function getRegisteredContracts(address party)
    external
    view
    override
    returns (address[] memory)
  {
    return partyMap[party].contracts;
  }

  function getAllRegisteredContracts()
    external
    view
    override
    returns (address[] memory)
  {
    return registeredContracts;
  }

  function isPartyMemberOfContract(address party, address contractAddress)
    public
    view
    override
    returns (bool)
  {
    uint256 index = partyMap[party].contractIndex[contractAddress];
    return
      partyMap[party].contracts.length > index &&
      partyMap[party].contracts[index] == contractAddress;
  }

  function _addPartyToContract(address party, address contractAddress)
    internal
  {
    require(
      !isPartyMemberOfContract(party, contractAddress),
      'Can only register a party once'
    );
    uint256 contractIndex = partyMap[party].contracts.length;
    partyMap[party].contracts.push(contractAddress);
    partyMap[party].contractIndex[contractAddress] = contractIndex;

    emit PartyAdded(contractAddress, party);
  }
}
