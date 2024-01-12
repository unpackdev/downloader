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

contract AirdropFlashLoanReceiverV3 is
  IFlashLoanReceiver,
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable,
  ERC721HolderUpgradeable,
  ERC1155HolderUpgradeable
{
  address public bnftRegistry;
  mapping(bytes32 => bool) public airdropClaimRecords;
  uint256 public deployType;
  uint256 public constant VERSION = 3;

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

    // 0 = used for public, created by BendDAO, 1 - used for private, created by owner
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

  function callMethod(address targetContract, bytes calldata callParams) external nonReentrant onlyOwner {
    require(targetContract != address(0), "invalid contract address");
    require(callParams.length >= 4, "invalid call parameters");

    // call project claim contract
    AddressUpgradeable.functionCall(targetContract, callParams, "call method failed");
  }

  function approveERC20(
    address token,
    address spender,
    uint256 amount
  ) external nonReentrant onlyOwner {
    IERC20Upgradeable(token).approve(spender, amount);
  }

  function transferERC20(address token, uint256 amount) external nonReentrant onlyOwner {
    address to = owner();
    IERC20Upgradeable(token).transfer(to, amount);
  }

  function approveERC721(
    address token,
    address operator,
    uint256 tokenId
  ) external nonReentrant onlyOwner {
    IERC721Upgradeable(token).approve(operator, tokenId);
  }

  function approveERC721ForAll(
    address token,
    address operator,
    bool approved
  ) external nonReentrant onlyOwner {
    IERC721Upgradeable(token).setApprovalForAll(operator, approved);
  }

  function transferERC721(address token, uint256 id) external nonReentrant onlyOwner {
    address to = owner();
    IERC721Upgradeable(token).safeTransferFrom(address(this), to, id);
  }

  function approveERC1155ForAll(
    address token,
    address operator,
    bool approved
  ) external nonReentrant onlyOwner {
    IERC1155Upgradeable(token).setApprovalForAll(operator, approved);
  }

  function transferERC1155(
    address token,
    uint256 id,
    uint256 amount
  ) external nonReentrant onlyOwner {
    address to = owner();
    IERC1155Upgradeable(token).safeTransferFrom(address(this), to, id, amount, new bytes(0));
  }

  function transferEther(uint256 amount) external nonReentrant onlyOwner {
    address to = owner();
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
