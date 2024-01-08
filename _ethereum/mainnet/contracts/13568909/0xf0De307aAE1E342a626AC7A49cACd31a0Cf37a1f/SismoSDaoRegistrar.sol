pragma solidity >=0.8.4;

import "./PublicResolver.sol";
import "./ENS.sol";
import "./SDaoRegistrar.sol";
import "./SDaoRegistrarLimited.sol";
import "./SDaoRegistrarReserved.sol";
import "./SDaoRegistrarERC721Generator.sol";
import "./SDaoRegistrarCodeAccessible.sol";

contract SismoSDaoRegistrar is
  SDaoRegistrar,
  SDaoRegistrarLimited,
  SDaoRegistrarReserved,
  SDaoRegistrarERC721Generator,
  SDaoRegistrarCodeAccessible
{
  uint256 public _groupId;

  event GroupIdUpdated(uint256 groupId);

  /**
   * @dev Constructor.
   * @param ensAddr The address of the ENS registry.
   * @param resolver The address of the Resolver.
   * @param erc721Token The address of the ERC721 Token.
   * @param node The node that this registrar administers.
   * @param owner The owner of the contract.
   * @param reservationDuration The duration of the reservation period.
   * @param registrationLimit The limit of registration number.
   */
  constructor(
    ENS ensAddr,
    PublicResolver resolver,
    IERC721Minter erc721Token,
    bytes32 node,
    address owner,
    uint256 reservationDuration,
    uint256 registrationLimit,
    uint256 groupId,
    address codeSigner
  )
    SDaoRegistrarCodeAccessible('Sismo', '1.0', codeSigner)
    SDaoRegistrarERC721Generator(erc721Token)
    SDaoRegistrarLimited(registrationLimit)
    SDaoRegistrarReserved(reservationDuration)
    SDaoRegistrar(ensAddr, resolver, node, owner)
  {
    _groupId = groupId;
  }

  function _beforeRegistration(address account, bytes32 labelHash)
    internal
    virtual
    override(
      SDaoRegistrar,
      SDaoRegistrarReserved,
      SDaoRegistrarLimited,
      SDaoRegistrarERC721Generator
    )
  {
    super._beforeRegistration(account, labelHash);
  }

  function _afterRegistration(address account, bytes32 labelHash)
    internal
    virtual
    override(SDaoRegistrar, SDaoRegistrarLimited, SDaoRegistrarERC721Generator)
  {
    super._afterRegistration(account, labelHash);
  }

  function _getCurrentGroupId() internal view override returns (uint256) {
    return _groupId;
  }

  function updateGroupId(uint256 groupId) external onlyOwner {
    _groupId = groupId;
    emit GroupIdUpdated(groupId);
  }
}
