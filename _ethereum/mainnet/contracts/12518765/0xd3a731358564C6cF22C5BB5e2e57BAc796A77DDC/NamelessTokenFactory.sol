// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./Clones.sol";
import "./NamelessToken.sol";
import "./INamelessTemplateLibrary.sol";

contract NamelessTokenFactory is AccessControl, INamelessTemplateLibrary {
  address public clonableTokenAddress;

  constructor( address _clonableTokenAddress ) {
    clonableTokenAddress = _clonableTokenAddress;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  event NewNamelessTokenContract(address indexed owner, address tokenAddress);

  function setClonableTokenAddress(address _clonableTokenAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
    clonableTokenAddress = _clonableTokenAddress;
  }

  function createTokenContract(string memory name, string memory symbol) public returns (address) {
    address clone = Clones.clone(clonableTokenAddress);
    NamelessToken asset = NamelessToken(clone);
    asset.initialize(name, symbol, address(this), msg.sender);
    emit NewNamelessTokenContract(msg.sender, clone);
    return clone;
  }

  struct TemplateInfo {
    bytes32[] dataSection;
    bytes32[] codeSection;
  }

  mapping (uint256 => TemplateInfo) private templates;

  function setTemplate(uint256 templateIndex, bytes32[] calldata dataSection, bytes32[] calldata codeSection) public onlyRole(DEFAULT_ADMIN_ROLE) {
    templates[templateIndex].dataSection = dataSection;
    templates[templateIndex].codeSection = codeSection;
  }

  function getTemplate(uint256 templateIndex) public view override returns (bytes32[] memory, bytes32[] memory) {
    return (
      templates[templateIndex].dataSection,
      templates[templateIndex].codeSection
    );
  }

  string public arweaveContentApi;
  string public ipfsContentApi;

  function setContentApis(string calldata _arweaveContentApi, string calldata _ipfsontentApi ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    arweaveContentApi = _arweaveContentApi;
    ipfsContentApi = _ipfsontentApi;
  }

  function getContentApis() public view  override returns (string memory, string memory) {
    return (arweaveContentApi, ipfsContentApi);
  }
}
