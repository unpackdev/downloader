pragma solidity ^0.5.11;

import "./KeepsTreatment.sol";
import "./Cryptopunks.sol";

/**
 * @title KeepsCryptopunks
 * KeepsCryptopunks - Cryptopunks that have kept their hair
 * Want to work with us? Check out our careers page at https://thirtymadison.com/careers/
 */
contract KeepsCryptopunks is ERC1155Tradable {
  KeepsTreatment private keepsTreatment;
  Cryptopunks private cryptopunks;
  address private contractOwner;

  constructor(address ownerAddress, address _proxyRegistryAddress, address keepsTreatmentAddress, address cryptopunksAddress)
  ERC1155Tradable(
    "KeepsCryptopunks",
    "KCP",
    _proxyRegistryAddress
  ) public {
    _setBaseMetadataURI("https://shop.keeps.com/api/nft/KeepsCryptopunks/");
    keepsTreatment = KeepsTreatment(keepsTreatmentAddress);
    cryptopunks = Cryptopunks(cryptopunksAddress);
    contractOwner = ownerAddress;
  }

  function contractURI() public view returns (string memory) {
    return "https://shop.keeps.com/api/nft/KeepsCryptopunks/metadata";
  }

  function treatmentAddress() public view returns (address) {
    return address(keepsTreatment);
  }

  function cryptopunksAddress() public view returns (address) {
    return address(cryptopunks);
  }

  function useKeepsToKeepYourHair( uint256 keepsTreatmentId, uint256 cryptopunkId)
  public {
    require(cryptopunks.punkIndexToAddress(cryptopunkId) == msg.sender, "Must own a crytpopunk");
    require(totalSupply(cryptopunkId) == 0, "Must not have already minted this cryptopunkId");

    require(keepsTreatment.balanceOf(msg.sender, keepsTreatmentId) > 0, "Must have keeps treatment to treat your hair");
    keepsTreatment.useKeepsTreatmentOnPatient(msg.sender, keepsTreatmentId);

    _mint(msg.sender, cryptopunkId, 1, "");
    creators[cryptopunkId] = contractOwner;
    tokenSupply[cryptopunkId] = tokenSupply[cryptopunkId].add(1);
  }
}

