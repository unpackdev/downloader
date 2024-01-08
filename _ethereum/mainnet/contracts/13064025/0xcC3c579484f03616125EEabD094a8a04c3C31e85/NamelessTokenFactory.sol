// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./Clones.sol";
import "./INamelessTokenData.sol";
import "./INamelessTemplateLibrary.sol";

contract NamelessTokenFactory is AccessControl, INamelessTemplateLibrary {
  address public clonableTokenAddress;
  address public clonableTokenDataAddress;

  constructor( address _clonableTokenAddress, address _clonableTokenDataAddress ) {
    clonableTokenAddress = _clonableTokenAddress;
    clonableTokenDataAddress = _clonableTokenDataAddress;

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  event NewNamelessTokenDataContract(address indexed owner, address tokenDataAddress);

  function setClonableTokenAddress(address _clonableTokenAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
    clonableTokenAddress = _clonableTokenAddress;
  }

  function setClonableTokenDataAddress(address _clonableTokenDataAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
    clonableTokenDataAddress = _clonableTokenDataAddress;
  }

  function createTokenDataContract(uint maxGenerationSize) public returns (address) {
    address clone = Clones.clone(clonableTokenDataAddress);
    INamelessTokenData assetData = INamelessTokenData(clone);
    assetData.initialize(address(this), clonableTokenAddress, msg.sender, maxGenerationSize);
    emit NewNamelessTokenDataContract(msg.sender, clone);
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
