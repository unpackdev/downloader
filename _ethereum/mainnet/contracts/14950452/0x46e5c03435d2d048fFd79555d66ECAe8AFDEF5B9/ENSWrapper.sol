//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "./ERC721Holder.sol";
import "./IFlashNFTReceiver.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./ERC721.sol";
import "./INafta.sol";
import "./IBaseRegistrar.sol";
import "./console.sol";

// ENS access control can be done in three ways:
//   1. by the Owner of the NFT (of BaseRegistrar ERC721 contract)
//   2. by the Controller (Node Owner of ENSRegistry contract)
//   3. by the Authorized address (setAuthorization in PublicResolver)
//
// They all have different permissions:
//   1. Owner is god - can do anything and everything
//   2. Controller is similar to Owner, except it cannot do ERC721 functions (Transfers, Approvals, etc) and cannot assign other Controllers.
//      Controller can give Authorizations in Public Resolver, change the Resolver address entirely, register SubDomains, etc.
//   3. Authorized address of the Resolver can only change the values in PublicResolver and cannot set new authorizations (but it isn't supported by ENS UI unfortunately - June 2022)
//
// This wrapper gives its holder the right to change the Controller to an arbitrary address.
//
// After receiving Controller rights, the address can go to ENS UI and interact with all functionality, except transfering the Registration (ENS ERC721) away.
contract ENSWrapper is IFlashNFTReceiver, ERC721, ERC721Holder {
  using SafeERC20 for IERC20;

  address public immutable ensAddress;

  mapping(uint256 => address) nftOwners;

  uint256 internal immutable chainId;

  constructor(address _ensAddress) ERC721("Wrapped ENS", "WENS") {
    chainId = block.chainid;
    ensAddress = _ensAddress;
  }

  /// @notice Wraps ENS NFT
  /// @param tokenId The ID of the ENS NFT (minted wrappedNFT will have the same token ID)
  function wrap(uint256 tokenId) external {
    nftOwners[tokenId] = msg.sender;
    _safeMint(msg.sender, tokenId);
    IERC721(ensAddress).safeTransferFrom(msg.sender, address(this), tokenId);
  }

  /// @notice Unwraps ENS NFT
  /// @param tokenId The ID of the ENS NFT (minted wrappedNFT has the same token ID)
  function unwrap(uint256 tokenId) external {
    require(nftOwners[tokenId] == msg.sender, "Only owner can unwrap NFT");
    require(ownerOf(tokenId) == msg.sender, "You must hold wrapped NFT to unwrap");
    IBaseRegistrar(ensAddress).reclaim(tokenId, nftOwners[tokenId]);
    _burn(tokenId);
    IERC721(ensAddress).safeTransferFrom(address(this), msg.sender, tokenId);
  }

  /// @notice Wraps a ENS NFT, then adds to a Nafta pool
  /// @param tokenId The ID of the ENS NFT (minted wrappedNFT has the same token ID)
  /// @param naftaAddress Address of Nafta
  /// @param flashFee - The fee user has to pay for a single rent (in WETH9) [Range: 0-4722.36648 ETH] (0 if flashrent is free)
  /// @param pricePerBlock - If renting longterm - this is the price per block (0 if not allowing renting longterm) [Range: 0-4722.36648 ETH]
  /// @param maxLongtermBlocks - Maximum amount of blocks for longterm rent [Range: 0-16777216]
  function wrapAndAddToNafta(
    uint256 tokenId,
    address naftaAddress,
    uint256 flashFee,
    uint256 pricePerBlock,
    uint256 maxLongtermBlocks
  ) external {
    INafta nafta = INafta(naftaAddress);
    // get the id of the next minted naftaNFT
    uint256 naftaNFTId = nafta.lenderNFTCount() + 1;

    // wrap the ENS NFT in-place
    nftOwners[tokenId] = msg.sender;
    _safeMint(address(this), tokenId);
    IERC721(ensAddress).safeTransferFrom(msg.sender, address(this), tokenId);

    // approves wrapped ENS to nafta pool and adds it to the pool, this will mint a naftaNFT to this contract
    IERC721(address(this)).approve(naftaAddress, tokenId);
    nafta.addNFT(address(this), tokenId, flashFee, pricePerBlock, maxLongtermBlocks);

    // send a newly minted lender naftaNFT back to msg.sender
    IERC721(naftaAddress).safeTransferFrom(address(this), msg.sender, naftaNFTId);
  }

  /// @notice Removes a wrapped ENS NFT from a Nafta pool and returns the unwrapped NFT to the owner
  /// @param naftaAddress Address of Nafta
  /// @param tokenId The ID of the ENS NFT, wrapped version also has the same ID
  /// @param naftaNFTId The ID of the Nafta NFT one receives when they added to the pool
  function unwrapAndRemoveFromNafta(
    address naftaAddress,
    uint256 tokenId,
    uint256 naftaNFTId
  ) external {
    require(nftOwners[tokenId] == msg.sender, "Only owner can unwrap NFT");

    // Transfer the nafta NFT from user to this contract
    IERC721(naftaAddress).safeTransferFrom(msg.sender, address(this), naftaNFTId);

    INafta nafta = INafta(naftaAddress);
    // removes the wrapped ENS NFT from nafta
    nafta.removeNFT(address(this), tokenId);

    IBaseRegistrar(ensAddress).reclaim(tokenId, nftOwners[tokenId]);

    // burns the Wrapped ENS NFT
    _burn(tokenId);

    // transfers the original ENS NFT back to the lender
    IERC721(ensAddress).safeTransferFrom(address(this), msg.sender, tokenId);
  }

  function setController(uint256 tokenId, address newController) external {
    require(ownerOf(tokenId) == msg.sender, "Only holder of wrapped ENS can set Controller");
    IBaseRegistrar(ensAddress).reclaim(tokenId, newController);
  }

  function getNetworkName() internal view returns (string memory) {
    if (chainId == 5) return "goerli";
    if (chainId == 4) return "rinkeby";
    if (chainId == 3) return "ropsten";
    return "mainnet";
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string memory baseURI = string.concat("https://metadata.ens.domains/", getNetworkName(), "/", toString(ensAddress), "/");
    return string.concat(baseURI, toString(tokenId), "/");
  }

  //////////////////////////////////////
  // IFlashNFTReceiver implementation
  //////////////////////////////////////

  event ExecuteCalled(address nftAddress, uint256 nftId, uint256 feeInWeth, address msgSender, bytes data);

  /// @notice Handles Nafta flashloan to Change ENS's Controller
  /// @dev This function is called by Nafta contract.
  /// @dev Nafta gives this reciever the NFT and expects it back, so we need to approve it here in the end.
  /// @dev But make sure you don't send any NFTs to this contract manually - that's not safe
  /// @param nftAddress  The address of NFT contract
  /// @param nftId  The id of NFT
  /// @param msgSender address of the account calling the flashloan function of Nafta contract
  /// @param data optional calldata passed into the function (can pass a newOperator address here)
  /// @return returns a boolean (true on success)
  function executeOperation(
    address nftAddress,
    uint256 nftId,
    uint256 feeInWeth,
    address msgSender,
    bytes calldata data
  ) external override returns (bool) {
    emit ExecuteCalled(nftAddress, nftId, feeInWeth, msgSender, data);
    require(nftAddress == address(this), "Only Wrapped ENS NFTs are supported");

    // Change ENS Controller
    if (data.length == 20) {
      // If data is passed - we assume an address there
      this.setController(nftId, address(bytes20(data)));
    } else {
      // If it wasn't passed - we just make msgSender a new operator
      this.setController(nftId, msgSender);
    }

    // Approve WrappedENS NFT back to Nafta to return it
    this.approve(msg.sender, nftId);
    return true;
  }

  //////////////////////////////////////
  // Utilitary functions
  //////////////////////////////////////

  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  function toString(address account) public pure returns (string memory) {
    bytes20 data = bytes20(abi.encodePacked(account));
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = "0";
    str[1] = "x";
    for (uint256 i = 0; i < data.length; i++) {
      str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
      str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
    }
    return string(str);
  }
}
