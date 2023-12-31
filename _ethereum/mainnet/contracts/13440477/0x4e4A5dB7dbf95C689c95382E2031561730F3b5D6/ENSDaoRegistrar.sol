pragma solidity >=0.8.4;

import "./ENS.sol";
import "./ERC721.sol";
import "./NameWrapper.sol";
import "./ERC1155Holder.sol";
import "./Ownable.sol";
import "./PublicResolver.sol";
import "./ENSDaoToken.sol";
import "./ENSLabelBooker.sol";
import "./IENSDaoRegistrar.sol";

/**
 * A registrar that allocates subdomains to the first person to claim them.
 */
contract ENSDaoRegistrar is ERC1155Holder, Ownable, IENSDaoRegistrar {
  PublicResolver public immutable RESOLVER;
  NameWrapper public immutable NAME_WRAPPER;
  ENSDaoToken public immutable DAO_TOKEN;
  ENS public immutable ENS_REGISTRY;
  ENSLabelBooker immutable ENS_LABLEL_BOOKER;
  bytes32 public immutable ROOT_NODE;

  string NAME;
  bytes32 public constant ETH_NODE =
    keccak256(abi.encodePacked(bytes32(0), keccak256('eth')));
  uint256 public immutable RESERVATION_DURATION;
  uint256 public immutable DAO_BIRTH_DATE;
  uint256 public _maxEmissionNumber;

  /**
   * @dev Constructor.
   * @param ensAddr The address of the ENS registry.
   * @param resolver The address of the Resolver.
   * @param nameWrapper The address of the Name Wrapper. can be 0x00
   * @param ensLabelBooker The address of the ens label booker. can be 0x00
   * @param daoToken The address of the DAO Token.
   * @param node The node that this registrar administers.
   * @param name The label string of the administered subdomain.
   */
  constructor(
    ENS ensAddr,
    PublicResolver resolver,
    NameWrapper nameWrapper,
    ENSDaoToken daoToken,
    ENSLabelBooker ensLabelBooker,
    bytes32 node,
    string memory name,
    address owner,
    uint256 reservationDuration
  ) {
    require(
      address(ensAddr) == address(ensLabelBooker.ENS_REGISTRY()),
      'ENS_DAO_REGISTRAR: REGISTRY_MISMATCH'
    );
    require(
      node == ensLabelBooker.ROOT_NODE(),
      'ENS_DAO_REGISTRAR: NODE_MISMATCH'
    );
    ENS_REGISTRY = ensAddr;
    RESOLVER = resolver;
    NAME_WRAPPER = nameWrapper;
    DAO_TOKEN = daoToken;
    ENS_LABLEL_BOOKER = ensLabelBooker;
    NAME = name;
    ROOT_NODE = node;
    DAO_BIRTH_DATE = block.timestamp;
    RESERVATION_DURATION = reservationDuration;
    _maxEmissionNumber = 500;

    transferOwnership(owner);
  }

  /**
   * @notice Register a name and mints a DAO token.
   * @dev Can only be called if and only if
   *  - the subdomain of the root node is free
   *  - sender does not already have a DAO token OR sender is the owner
   *  - if still in the reservation period, the associated .eth subdomain is free OR owned by the sender
   * @param label The label to register.
   */
  function register(string memory label) external override {
    bytes32 labelHash = keccak256(bytes(label));

    require(
      address(ENS_LABLEL_BOOKER) == address(0) ||
        ENS_LABLEL_BOOKER.getBooking(label) == address(0),
      'ENS_DAO_REGISTRAR: LABEL_BOOKED'
    );

    if (block.timestamp - DAO_BIRTH_DATE <= RESERVATION_DURATION) {
      address dotEthSubdomainOwner = ENS_REGISTRY.owner(
        keccak256(abi.encodePacked(ETH_NODE, labelHash))
      );
      require(
        dotEthSubdomainOwner == address(0x0) ||
          dotEthSubdomainOwner == _msgSender(),
        'ENS_DAO_REGISTRAR: SUBDOMAIN_RESERVED'
      );
    }

    _register(_msgSender(), label, labelHash);
  }

  /**
   * @notice Claim a booked name.
   * @dev Can only be called by owner or registered booking address if ENS label booker setup.
   * @param label The label to claim.
   * @param account The account to which the registration is done.
   */
  function claim(string memory label, address account) external override {
    bytes32 labelHash = keccak256(bytes(label));
    address bookedAddress = ENS_LABLEL_BOOKER.getBooking(label);
    require(bookedAddress != address(0), 'ENS_DAO_REGISTRAR: LABEL_NOT_BOOKED');
    require(
      bookedAddress == _msgSender() || owner() == _msgSender(),
      'ENS_DAO_REGISTRAR: SENDER_NOT_ALLOWED'
    );

    _register(account, label, labelHash);

    ENS_LABLEL_BOOKER.deleteBooking(label);
  }

  /**
   * @notice Give back the root domain of the ENS DAO Registrar to DAO owner.
   * @dev Can be called by the owner of the registrar.
   */
  function giveBackDomainOwnership() external override onlyOwner {
    if (address(NAME_WRAPPER) != address(0)) {
      NAME_WRAPPER.unwrapETH2LD(keccak256(bytes(NAME)), owner(), owner());
    } else {
      ENS_REGISTRY.setOwner(ROOT_NODE, owner());
    }

    emit OwnershipConceded(_msgSender());
  }

  /**
   * @notice Update max emission number.
   * @dev Can only be called by owner.
   */
  function updateMaxEmissionNumber(uint256 emissionNumber)
    external
    override
    onlyOwner
  {
    require(
      emissionNumber >= DAO_TOKEN.totalSupply(),
      'ENS_DAO_REGISTRAR: NEW_MAX_EMISSION_TOO_LOW'
    );
    _maxEmissionNumber = emissionNumber;
    emit MaxEmissionNumberUpdated(emissionNumber);
  }

  /**
   * @dev Register a name and mint a DAO token.
   *      Can only be called if and only if
   *        - the maximum number of emissions has not been reached,
   *        - the subdomain is free to be registered,
   *        - the destination address does not alreay own a subdomain or the sender is the owner
   * @param account The address that will receive the subdomain and the DAO token.
   * @param label The label to register.
   * @param labelHash The hash of the label to register, given as input because of parent computation.
   */
  function _register(
    address account,
    string memory label,
    bytes32 labelHash
  ) internal {
    require(
      DAO_TOKEN.totalSupply() < _maxEmissionNumber,
      'ENS_DAO_REGISTRAR: TOO_MANY_EMISSION'
    );

    bytes32 childNode = keccak256(abi.encodePacked(ROOT_NODE, labelHash));
    address subdomainOwner = ENS_REGISTRY.owner(
      keccak256(abi.encodePacked(ROOT_NODE, labelHash))
    );
    require(
      subdomainOwner == address(0x0),
      'ENS_DAO_REGISTRAR: SUBDOMAIN_ALREADY_REGISTERED'
    );

    require(
      DAO_TOKEN.balanceOf(account) == 0 || _msgSender() == owner(),
      'ENS_DAO_REGISTRAR: TOO_MANY_SUBDOMAINS'
    );

    if (address(NAME_WRAPPER) != address(0)) {
      _registerWithNameWrapper(account, label, childNode);
    } else {
      _registerWithEnsRegistry(account, labelHash, childNode);
    }

    // Minting the DAO Token
    DAO_TOKEN.mintTo(account, uint256(childNode));

    emit NameRegistered(uint256(childNode), _msgSender());
  }

  /**
   * @dev Register a name using the Name Wrapper.
   * @param label The label to register.
   * @param childNode The node to register, given as input because of parent computation.
   */
  function _registerWithNameWrapper(
    address account,
    string memory label,
    bytes32 childNode
  ) internal {
    // Set ownership to ENS DAO, so that the contract can set resolver
    NAME_WRAPPER.setSubnodeRecordAndWrap(
      ROOT_NODE,
      label,
      address(this),
      address(RESOLVER),
      60,
      0
    );
    // Setting the resolver for the user
    RESOLVER.setAddr(childNode, account);

    // Giving back the ownership to the user
    NAME_WRAPPER.safeTransferFrom(
      address(this),
      account,
      uint256(childNode),
      1,
      ''
    );
  }

  /**
   * @dev Register a name using the ENS Registry.
   * @param labelHash The hash of the label to register.
   * @param childNode The node to register, given as input because of parent computation.
   */
  function _registerWithEnsRegistry(
    address account,
    bytes32 labelHash,
    bytes32 childNode
  ) internal {
    // Set ownership to ENS DAO, so that the contract can set resolver
    ENS_REGISTRY.setSubnodeRecord(
      ROOT_NODE,
      labelHash,
      address(this),
      address(RESOLVER),
      60
    );

    // Setting the resolver for the user
    RESOLVER.setAddr(childNode, account);

    // Giving back the ownership to the user
    ENS_REGISTRY.setSubnodeOwner(ROOT_NODE, labelHash, account);
  }
}
