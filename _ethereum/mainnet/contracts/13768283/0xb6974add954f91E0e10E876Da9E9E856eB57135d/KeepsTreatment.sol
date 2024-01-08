pragma solidity ^0.5.11;

import "./ERC1155Tradable.sol";

/**
 * @title KeepsTreatment
 * KeepsTreatment - a contract for my semi-fungible tokens.
 */
contract KeepsTreatment is ERC1155Tradable {
  address private punkContractAddress;

  constructor(address _proxyRegistryAddress)
  ERC1155Tradable(
    "KeepsTreatment",
    "KTR",
    _proxyRegistryAddress
  ) public {
    _setBaseMetadataURI("https://shop.keeps.com/api/nft/KeepsTreatment/");
  }

  function contractURI() public view returns (string memory) {
    return "https://shop.keeps.com/api/nft/KeepsTreatment/metadata";
  }

  function setPunkContractAddress(address updatedPunkContractAddress) external onlyOwner {
    punkContractAddress = updatedPunkContractAddress;
  }

  function useKeepsTreatmentOnPatient(address patient, uint256 keepsTreatmentId) public {
    require(msg.sender == punkContractAddress, "Can only apply treatment via KeepsCryptopunks");
    _burn(patient, keepsTreatmentId, 1);
  }
}

