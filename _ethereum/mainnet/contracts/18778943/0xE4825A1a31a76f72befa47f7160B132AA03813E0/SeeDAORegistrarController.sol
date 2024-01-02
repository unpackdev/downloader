// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./SNS.sol";
import "./BaseRegistrar.sol";
import "./Resolver.sol";
import "./ResolverBase.sol";
import "./ReverseRegistrar.sol";
import "./ISeeDAORegistrarController.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PublicResolver.sol";

contract SeeDAORegistrarController is
  Initializable,
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable,
  ISeeDAORegistrarController
{
  SNS public sns;
  BaseRegistrar public baseRegistrar;
  ReverseRegistrar public reverseRegistrar;

  // list of minter which can issue sns to user
  mapping(address => bool) public minters;

  // minimum and maximum commitment age
  uint256 public minCommitmentAge;
  uint256 public maxCommitmentAge;
  // commitments
  mapping(bytes32 => uint256) public commitments;

  // enable/disable register feature
  bool public registrable;

  // max owned count of sns
  uint256 public maxOwnedNumber;

  // `namehash("seedao")`
  bytes32 private constant SEEDAO_NODE =
    0x5e55419d79fa352b3401db837903c9d6425f83393880fd079b57ad5f232def51;
  string private constant SEEDAO_NAME = ".seedao";

  modifier onlyMinter() {
    require(minters[_msgSender()], "Only minter can call this function");
    _;
  }

  modifier onlyRegistrable() {
    require(registrable, "Not registrable");
    _;
  }

  modifier checkNameValid(string memory name) {
    require(valid(name), "Invalid name");
    _;
  }

  modifier checkMaxOwnedNumber(address owner) {
    if (
      maxOwnedNumber != 0 && baseRegistrar.balanceOf(owner) >= maxOwnedNumber
    ) {
      revert ReachedMaxOwnedNumberLimit(
        baseRegistrar.balanceOf(owner),
        maxOwnedNumber
      );
    }
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    SNS _sns,
    BaseRegistrar _baseRegistrar,
    ReverseRegistrar _reverseRegistrar,
    uint256 _minCommitmentAge,
    uint256 _maxCommitmentAge
  ) public initializer {
    require(_maxCommitmentAge > _minCommitmentAge, "MaxCommitmentAge too low");
    require(_maxCommitmentAge < block.timestamp, "MaxCommitmentAge too high");

    __Ownable_init();
    __ReentrancyGuard_init();

    minCommitmentAge = _minCommitmentAge;
    maxCommitmentAge = _maxCommitmentAge;

    sns = _sns;
    baseRegistrar = _baseRegistrar;
    reverseRegistrar = _reverseRegistrar;

    // add `msg.sender` to minters
    minters[msg.sender] = true;

    // set default maxOwnedNumber to 1
    maxOwnedNumber = 1;
  }

  /// check if name is available
  /// @param name is the name to check, not include the top-level domain, for example: `abc` not `abc.seedao`
  function available(string memory name) public view override returns (bool) {
    bytes32 label = keccak256(bytes(name));
    return valid(name) && baseRegistrar.available(label);
  }

  /// check if name is valid
  /// @param name is the name to check, not include the top-level domain, for example: `abc` not `abc.seedao`
  function valid(string memory name) public pure override returns (bool) {
    bytes memory n = bytes(name);
    uint256 len = n.length;
    // check: if contains not allowed char
    for (uint256 i = 0; i < len; i++) {
      bytes1 b = n[i];
      // only allow:
      //    0-9: [0x30, 0x39]
      //    a-z: [0x61, 0x7A]
      //    !  : 0x21
      //    $  : 0x24
      //    (  : 0x28
      //    )  : 0x29
      //    *  : 0x2A
      //    +  : 0x2B
      //    -  : 0x2D
      //    _  : 0x5F
      if (
        (b >= 0x61 && b <= 0x7A) ||
        (b >= 0x30 && b <= 0x39) ||
        b == 0x21 ||
        b == 0x24 ||
        b == 0x28 ||
        b == 0x29 ||
        b == 0x2A ||
        b == 0x2B ||
        b == 0x2D ||
        b == 0x5F
      ) {
        continue;
      }

      return false;
    }

    // check: name's length is match [4, 15]
    return len >= 4 && len <= 15;
  }

  function balanceOf(address owner) public view override returns (uint256) {
    return baseRegistrar.balanceOf(owner);
  }

  function maxOwnedNumberReached(
    address owner
  ) public view override returns (bool) {
    return
      maxOwnedNumber != 0 && baseRegistrar.balanceOf(owner) >= maxOwnedNumber;
  }

  function nextTokenId() public view override returns (uint256) {
    return baseRegistrar.nextTokenId();
  }

  // ------ ------ ------ ------ ------ ------ ------ ------ ------
  // ------ ------ ------ ------ ------ ------ ------ ------ ------

  function batchRegister(
    string[] calldata name,
    address[] calldata owner,
    address resolver
  ) external onlyMinter {
    uint256 size = name.length;
    require(size == owner.length, "Name and owner parameter's length mismatch");

    for (uint256 i = 0; i < size; i++) {
      _register(name[i], owner[i], owner[i], resolver);
    }
  }

  // ------ ------ ------ ------ ------ ------ ------ ------ ------

  function makeCommitment(
    string memory name,
    address owner,
    address resolver,
    bytes32 secret
  ) public pure override returns (bytes32) {
    bytes32 label = keccak256(bytes(name));
    return keccak256(abi.encode(label, owner, resolver, secret));
  }

  function commit(bytes32 commitment) external override {
    if (commitments[commitment] + maxCommitmentAge >= block.timestamp) {
      revert("unexpired commitment exists");
    }
    commitments[commitment] = block.timestamp;
  }

  function registerWithCommitment(
    string memory name,
    address owner,
    address resolver,
    bytes32 secret
  )
    external
    override
    onlyRegistrable
    onlyMinter
    checkNameValid(name)
    checkMaxOwnedNumber(owner)
  {
    _consumeCommitment(makeCommitment(name, owner, resolver, secret));

    _register(name, owner, owner, resolver);
  }

  function register(
    string memory name,
    address owner,
    address resolver
  )
    external
    override
    onlyRegistrable
    onlyMinter
    checkNameValid(name)
    checkMaxOwnedNumber(owner)
  {
    _register(name, owner, owner, resolver);
  }

  // ------ ------ ------ ------ ------ ------ ------ ------ ------

  // reclaim the sns
  function reclaim(
    string memory name,
    address newSNSOwner,
    address resolver
  ) external override onlyOwner nonReentrant {
    bytes32 label = keccak256(bytes(name));
    bytes32 subnode = keccak256(abi.encodePacked(SEEDAO_NODE, label));

    address oldSNSOwner = sns.owner(subnode);
    require(oldSNSOwner != newSNSOwner, "New owner is same to old owner");

    // PublicResolver: clean old resolvers data
    ResolverBase(resolver).clearRecords(subnode);
    // ReverseRegistrar: old owner's reverse record should be delete
    reverseRegistrar.setNameForAddr(oldSNSOwner, oldSNSOwner, resolver, "");

    // reclaim sns
    baseRegistrar.reclaim(label, newSNSOwner);

    // ReverseRegistrar: set reverse record
    reverseRegistrar.setNameForAddr(
      newSNSOwner, // !! should be newSNSOwner, not `msg.sender`
      newSNSOwner,
      resolver,
      string.concat(name, SEEDAO_NAME)
    );
    // PublicResolver: set the address record on the resolver
    Resolver(resolver).setAddr(subnode, newSNSOwner);

    emit NameReclaimed(baseRegistrar.labelToTokenId(label), name, newSNSOwner);
  }

  // set new name for caller address
  function setDefaultName(
    string memory destName,
    address resolver
  ) external override {
    bytes32 label = keccak256(bytes(destName));
    bytes32 subnode = keccak256(abi.encodePacked(SEEDAO_NODE, label));

    require(
      sns.owner(subnode) == _msgSender(),
      "Only SNS's owner can set resolving to the SNS"
    );

    reverseRegistrar.setNameForAddr(
      _msgSender(),
      _msgSender(),
      resolver,
      string.concat(destName, SEEDAO_NAME) // result: "abc.seedao"
    );
  }

  // set new addr for the name
  function setDefaultAddr(
    string memory name,
    address destAddr,
    address resolver
  ) external override {
    bytes32 label = keccak256(bytes(name));
    bytes32 subnode = keccak256(abi.encodePacked(SEEDAO_NODE, label));

    require(
      sns.owner(subnode) == _msgSender(),
      "Only SNS's owner can set SNS's addr"
    );

    Resolver(resolver).setAddr(subnode, destAddr);
  }

  // ------ ------ ------ ------ ------ ------ ------ ------ ------

  function _register(
    string memory name,
    address addr,
    address owner,
    address resolver
  ) internal {
    bytes32 label = keccak256(bytes(name));

    // register sns
    baseRegistrar.register(label, owner, resolver);

    // set reverse record
    reverseRegistrar.setNameForAddr(
      addr,
      owner,
      resolver,
      string.concat(name, SEEDAO_NAME) // result: "abc.seedao"
    );

    // set the address record on the resolver
    bytes32 subnode = keccak256(abi.encodePacked(SEEDAO_NODE, label));
    Resolver(resolver).setAddr(subnode, owner);

    emit NameRegistered(baseRegistrar.labelToTokenId(label), name, owner);
  }

  function _consumeCommitment(bytes32 commitment) internal {
    // commitment too new.
    if (commitments[commitment] + minCommitmentAge > block.timestamp) {
      revert CommitmentTooNew(commitment);
    }

    // commitment is too old
    if (commitments[commitment] + maxCommitmentAge <= block.timestamp) {
      revert CommitmentTooOld(commitment);
    }

    delete (commitments[commitment]);
  }

  // ------ ------ ------ ------ ------ ------ ------ ------ ------
  // ------ ------ ------ ------ ------ ------ ------ ------ ------

  function grantMinter(address addr) external onlyOwner {
    minters[addr] = true;
    emit MinterChanged(addr, true);
  }

  function revokeMinter(address addr) external onlyOwner {
    minters[addr] = false;
    emit MinterChanged(addr, false);
  }

  function enableRegister() external onlyOwner {
    registrable = true;
  }

  function disableRegister() external onlyOwner {
    registrable = false;
  }

  function setMaxOwnedNumber(uint256 _maxOwnedNumber) external onlyOwner {
    maxOwnedNumber = _maxOwnedNumber;
  }

  function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
    return
      interfaceID == type(IERC165).interfaceId ||
      interfaceID == type(ISeeDAORegistrarController).interfaceId;
  }
}
