pragma solidity >=0.8.4;

import "./PublicResolver.sol";
import "./ENS.sol";
import "./SDaoRegistrar.sol";
import "./SDaoRegistrarLimited.sol";
import "./SDaoRegistrarReserved.sol";
import "./SDaoRegistrarERC1155Generator.sol";
import "./SDaoRegistrarCodeAccessible.sol";

contract SismoSDaoRegistrar is
  SDaoRegistrar,
  SDaoRegistrarLimited,
  SDaoRegistrarReserved,
  SDaoRegistrarERC1155Generator,
  SDaoRegistrarCodeAccessible
{
  uint256 public _groupId;
  uint256 public _gen;
  uint256 public _maxGenReached;
  bytes public _tokenData;

  event GroupIdUpdated(uint256 groupId);
  event GenUpdated(uint256 gen);
  event TokenDataUpdated(bytes tokenData);

  /**
   * @dev Constructor.
   * @param ensAddr The address of the ENS registry.
   * @param resolver The address of the Resolver.
   * @param erc1155Token The address of the ERC1155 Token.
   * @param node The node that this registrar administers.
   * @param owner The owner of the contract.
   * @param reservationDuration The duration of the reservation period.
   * @param registrationLimit The limit of registration number.
   * @param groupId The initial group ID.
   * @param codeSigner The address of the code signer.
   */
  constructor(
    ENS ensAddr,
    PublicResolver resolver,
    IERC1155Minter erc1155Token,
    bytes32 node,
    address owner,
    uint256 reservationDuration,
    uint256 registrationLimit,
    uint256 groupId,
    address codeSigner
  )
    SDaoRegistrarCodeAccessible('Sismo', '1.0', codeSigner)
    SDaoRegistrarERC1155Generator(erc1155Token)
    SDaoRegistrarLimited(registrationLimit)
    SDaoRegistrarReserved(reservationDuration)
    SDaoRegistrar(ensAddr, resolver, node, owner)
  {
    _groupId = groupId;
    _tokenData = bytes('');
    _gen = 1;
    _maxGenReached = 1;
  }

  /**
   * @notice Transit to a new generation.
   * @dev Can only be called by the owner.
   * @param registrationLimit The new registration limit.
   * @param gen The new generation.
   * @param groupId The new group ID.
   * @param tokenData The new token data.
   */
  function transitToGeneration(
    uint256 registrationLimit,
    uint256 gen,
    uint256 groupId,
    bytes calldata tokenData
  ) external onlyOwner {
    _updateGeneration(gen);
    _updateRegistrationLimit(registrationLimit);
    _setGroupId(groupId);
    _updateTokenData(tokenData);
  }

  /**
   * @notice Add a generation.
   * @dev Can only be called by the owner.
   * @param gen The new generation.
   */
  function updateGeneration(uint256 gen) external onlyOwner {
    _updateGeneration(gen);
  }

  /**
   * @notice Update the group ID.
   * @dev Can only be called by the owner.
   * @param groupId The new group ID.
   */
  function updateGroupId(uint256 groupId) external onlyOwner {
    _setGroupId(groupId);
  }

  /**
   * @notice Update the token data.
   * @dev Can only be called by the owner.
   * @param tokenData The new token data.
   */
  function updateTokenData(bytes calldata tokenData) external onlyOwner {
    _updateTokenData(tokenData);
  }

  /**
   * @dev Update the token data.
   * @param tokenData The new token data.
   */
  function _updateTokenData(bytes memory tokenData) internal {
    _tokenData = tokenData;
    emit TokenDataUpdated(tokenData);
  }

  /**
   * @dev Get the current group ID.
   * @return The current group ID.
   */
  function _getCurrentGroupId() internal view override returns (uint256) {
    return _groupId;
  }

  /**
   * @dev Get token ID and data. The token ID is the current generation.
   * @return The ID and the data of the token
   */
  function _getToken(address, bytes32)
    internal
    view
    override
    returns (uint256, bytes memory)
  {
    return (_gen, _tokenData);
  }

  /**
   * @dev Get the total balance of an account over the generations.
   * @param account The address for which the balance is needed.
   * @return The total balance of an account over the generations.
   */
  function _balanceOf(address account)
    internal
    view
    override
    returns (uint256)
  {
    address[] memory accounts = new address[](_maxGenReached);
    uint256[] memory gens = new uint256[](_maxGenReached);
    for (uint256 index = 0; index < _maxGenReached; index++) {
      accounts[index] = account;
      gens[index] = index + 1;
    }
    uint256[] memory balances = ERC1155_MINTER.balanceOfBatch(accounts, gens);
    uint256 sum = 0;
    for (uint256 index = 0; index < _maxGenReached; index++) {
      sum += balances[index];
    }
    return sum;
  }

  function _setGroupId(uint256 groupId) internal {
    _groupId = groupId;
    emit GroupIdUpdated(groupId);
  }

  /**
   * @dev Add a new generation.
   * @param gen The new generation.
   */
  function _updateGeneration(uint256 gen) internal {
    _gen = gen;
    if (gen > _maxGenReached) {
      _maxGenReached = gen;
    }
    emit GenUpdated(gen);
  }

  function _beforeRegistration(address account, bytes32 labelHash)
    internal
    virtual
    override(
      SDaoRegistrar,
      SDaoRegistrarReserved,
      SDaoRegistrarLimited,
      SDaoRegistrarERC1155Generator
    )
  {
    super._beforeRegistration(account, labelHash);
  }

  function _afterRegistration(address account, bytes32 labelHash)
    internal
    virtual
    override(SDaoRegistrar, SDaoRegistrarLimited, SDaoRegistrarERC1155Generator)
  {
    super._afterRegistration(account, labelHash);
  }
}
