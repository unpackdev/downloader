// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./IFlashLoanReceiver.sol";
import "./IBNFT.sol";
import "./IBNFTRegistry.sol";

import "./AddressUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";

contract AirdropFlashLoanReceiverV2 is
  IFlashLoanReceiver,
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable,
  ERC721HolderUpgradeable,
  ERC1155HolderUpgradeable
{
  address public bnftRegistry;
  mapping(bytes32 => bool) public airdropClaimRecords;
  uint256 public deployType;

  function initialize(
    address owner_,
    address bnftRegistry_,
    uint256 deployType_
  ) public initializer {
    __ReentrancyGuard_init();
    __Ownable_init();
    __ERC721Holder_init();
    __ERC1155Holder_init();

    require(owner_ != address(0), "zero owner address");
    require(bnftRegistry_ != address(0), "zero registry address");

    bnftRegistry = bnftRegistry_;
    deployType = deployType_;

    _transferOwnership(owner_);
  }

  struct ExecuteOperationLocalVars {
    uint256[] airdropTokenTypes;
    address[] airdropTokenAddresses;
    uint256[] airdropTokenIds;
    address airdropContract;
    bytes airdropParams;
    uint256 airdropBalance;
    uint256 airdropTokenId;
    bytes32 airdropKeyHash;
  }

  function executeOperation(
    address nftAsset,
    uint256[] calldata nftTokenIds,
    address initiator,
    address operator,
    bytes calldata params
  ) external override returns (bool) {
    ExecuteOperationLocalVars memory vars;

    // check caller and owner
    (address bnftProxy, ) = IBNFTRegistry(bnftRegistry).getBNFTAddresses(nftAsset);
    require(bnftProxy == msg.sender, "caller not bnft");

    if (deployType != 0) {
      require(initiator == owner(), "initiator not owner");
    }

    require(nftTokenIds.length > 0, "empty token list");

    // decode parameters
    (
      vars.airdropTokenTypes,
      vars.airdropTokenAddresses,
      vars.airdropTokenIds,
      vars.airdropContract,
      vars.airdropParams
    ) = abi.decode(params, (uint256[], address[], uint256[], address, bytes));

    require(vars.airdropTokenTypes.length > 0, "invalid airdrop token type");
    require(vars.airdropTokenAddresses.length == vars.airdropTokenTypes.length, "invalid airdrop token address length");
    require(vars.airdropTokenIds.length == vars.airdropTokenTypes.length, "invalid airdrop token id length");

    require(vars.airdropContract != address(0), "invalid airdrop contract address");
    require(vars.airdropParams.length >= 4, "invalid airdrop parameters");

    // allow operator transfer borrowed nfts back to bnft
    IERC721Upgradeable(nftAsset).setApprovalForAll(operator, true);

    // call project aidrop contract
    AddressUpgradeable.functionCall(vars.airdropContract, vars.airdropParams, "call airdrop method failed");

    vars.airdropKeyHash = getClaimKeyHash(initiator, nftAsset, nftTokenIds, params);
    airdropClaimRecords[vars.airdropKeyHash] = true;

    // transfer airdrop tokens to borrower
    for (uint256 typeIndex = 0; typeIndex < vars.airdropTokenTypes.length; typeIndex++) {
      require(vars.airdropTokenAddresses[typeIndex] != address(0), "invalid airdrop token address");

      if (vars.airdropTokenTypes[typeIndex] == 1) {
        // ERC20
        vars.airdropBalance = IERC20Upgradeable(vars.airdropTokenAddresses[typeIndex]).balanceOf(address(this));
        if (vars.airdropBalance > 0) {
          IERC20Upgradeable(vars.airdropTokenAddresses[typeIndex]).transfer(initiator, vars.airdropBalance);
        }
      } else if (vars.airdropTokenTypes[typeIndex] == 2) {
        // ERC721 with Enumerate
        vars.airdropBalance = IERC721Upgradeable(vars.airdropTokenAddresses[typeIndex]).balanceOf(address(this));
        for (uint256 i = 0; i < vars.airdropBalance; i++) {
          vars.airdropTokenId = IERC721EnumerableUpgradeable(vars.airdropTokenAddresses[typeIndex]).tokenOfOwnerByIndex(
            address(this),
            0
          );
          IERC721EnumerableUpgradeable(vars.airdropTokenAddresses[typeIndex]).safeTransferFrom(
            address(this),
            initiator,
            vars.airdropTokenId
          );
        }
      } else if (vars.airdropTokenTypes[typeIndex] == 3) {
        // ERC1155
        vars.airdropBalance = IERC1155Upgradeable(vars.airdropTokenAddresses[typeIndex]).balanceOf(
          address(this),
          vars.airdropTokenIds[typeIndex]
        );
        IERC1155Upgradeable(vars.airdropTokenAddresses[typeIndex]).safeTransferFrom(
          address(this),
          initiator,
          vars.airdropTokenIds[typeIndex],
          vars.airdropBalance,
          new bytes(0)
        );
      } else if (vars.airdropTokenTypes[typeIndex] == 4) {
        // ERC721 without Enumerate
        IERC721EnumerableUpgradeable(vars.airdropTokenAddresses[typeIndex]).safeTransferFrom(
          address(this),
          initiator,
          vars.airdropTokenIds[typeIndex]
        );
      }
    }

    return true;
  }

  function transferERC20(
    address token,
    address to,
    uint256 amount
  ) external nonReentrant onlyOwner {
    IERC20Upgradeable(token).transfer(to, amount);
  }

  function transferERC721(
    address token,
    address to,
    uint256 id
  ) external nonReentrant onlyOwner {
    IERC721Upgradeable(token).safeTransferFrom(address(this), to, id);
  }

  function transferERC1155(
    address token,
    address to,
    uint256 id,
    uint256 amount
  ) external nonReentrant onlyOwner {
    IERC1155Upgradeable(token).safeTransferFrom(address(this), to, id, amount, new bytes(0));
  }

  function transferEther(address to, uint256 amount) external nonReentrant onlyOwner {
    (bool success, ) = to.call{value: amount}(new bytes(0));
    require(success, "ETH_TRANSFER_FAILED");
  }

  function getAirdropClaimRecord(
    address initiator,
    address nftAsset,
    uint256[] calldata nftTokenIds,
    bytes calldata params
  ) public view returns (bool) {
    bytes32 airdropKeyHash = getClaimKeyHash(initiator, nftAsset, nftTokenIds, params);
    return airdropClaimRecords[airdropKeyHash];
  }

  function encodeFlashLoanParams(
    uint256[] calldata airdropTokenTypes,
    address[] calldata airdropTokenAddresses,
    uint256[] calldata airdropTokenIds,
    address airdropContract,
    bytes calldata airdropParams
  ) public pure returns (bytes memory) {
    return abi.encode(airdropTokenTypes, airdropTokenAddresses, airdropTokenIds, airdropContract, airdropParams);
  }

  function getClaimKeyHash(
    address initiator,
    address nftAsset,
    uint256[] calldata nftTokenIds,
    bytes calldata params
  ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(initiator, nftAsset, nftTokenIds, params));
  }
}
