//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;

import "./Ownable.sol";
import "./SNS.sol";
import "./ABIResolver.sol";
import "./AddrResolver.sol";
import "./ContentHashResolver.sol";
import "./InterfaceResolver.sol";
import "./NameResolver.sol";
import "./PubkeyResolver.sol";
import "./TextResolver.sol";

contract PublicResolver is
  Ownable,
  ABIResolver,
  AddrResolver,
  ContentHashResolver,
  // DNSResolver,
  InterfaceResolver,
  NameResolver,
  PubkeyResolver,
  TextResolver
{
  SNS immutable sns;
  address public trustedReverseRegistrar;
  address public trustedSeeDAOController;
  address public trustedSeeDAOSubdomainController;

  mapping(address => mapping(address => bool)) private _operatorApprovals;

  mapping(address => mapping(bytes32 => mapping(address => bool)))
    private _tokenApprovals;

  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  event Approved(
    address owner,
    bytes32 indexed node,
    address indexed delegate,
    bool indexed approved
  );

  constructor(
    SNS _sns,
    address _trustedReverseRegistrar,
    address _trustedSeeDAOController,
    address _trustedSeeDAOSubdomainController
  ) {
    sns = _sns;
    trustedReverseRegistrar = _trustedReverseRegistrar;
    trustedSeeDAOController = _trustedSeeDAOController;
    trustedSeeDAOSubdomainController = _trustedSeeDAOSubdomainController;
  }

  function setApprovalForAll(address operator, bool approved) external {
    require(
      msg.sender != operator,
      "ERC1155: setting approval status for self"
    );

    _operatorApprovals[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function isApprovedForAll(
    address account,
    address operator
  ) public view returns (bool) {
    return _operatorApprovals[account][operator];
  }

  function approve(bytes32 node, address delegate, bool approved) external {
    require(msg.sender != delegate, "Setting delegate status for self");

    _tokenApprovals[msg.sender][node][delegate] = approved;
    emit Approved(msg.sender, node, delegate, approved);
  }

  function isApprovedFor(
    address owner,
    bytes32 node,
    address delegate
  ) public view returns (bool) {
    return _tokenApprovals[owner][node][delegate];
  }

  function isAuthorised(bytes32 node) internal view override returns (bool) {
    if (
      msg.sender == trustedReverseRegistrar ||
      msg.sender == trustedSeeDAOController ||
      msg.sender == trustedSeeDAOSubdomainController
    ) {
      return true;
    }
    address owner = sns.owner(node);
    // if (owner == address(nameWrapper)) {
    //     owner = nameWrapper.ownerOf(uint256(node));
    // }
    return
      owner == msg.sender ||
      isApprovedForAll(owner, msg.sender) ||
      isApprovedFor(owner, node, msg.sender);
  }

  function supportsInterface(
    bytes4 interfaceID
  )
    public
    view
    override(
      ABIResolver,
      AddrResolver,
      ContentHashResolver,
      InterfaceResolver,
      NameResolver,
      PubkeyResolver,
      TextResolver
    )
    returns (bool)
  {
    return super.supportsInterface(interfaceID);
  }

  function updateReverseRegistrar(
    address _trustedReverseRegistrar
  ) external onlyOwner {
    trustedReverseRegistrar = _trustedReverseRegistrar;
  }

  function updateSeeDAOController(
    address _trustedSeeDAOController
  ) external onlyOwner {
    trustedSeeDAOController = _trustedSeeDAOController;
  }

  function updateSeeDAOSubdomainController(
    address _trustedSeeDAOSubdomainController
  ) external onlyOwner {
    trustedSeeDAOSubdomainController = _trustedSeeDAOSubdomainController;
  }
}
