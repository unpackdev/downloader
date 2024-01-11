//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "./ERC721Holder.sol";
import "./IFlashNFTReceiver.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./ERC721.sol";
import "./INafta.sol";
import "./ILANDRegistry.sol";
import "./console.sol";

// EstateWrapper is exactly the same as LandWrapper, but for Estate Decentraland contract - so just the address and naming changes
// TODO: Think if we can make these two contracts into one codebase without repetitions, but also without too much complexity

contract EstateWrapper is IFlashNFTReceiver, ERC721, ERC721Holder {
  using SafeERC20 for IERC20;

  address public immutable estateAddress;

  mapping(uint256 => address) nftOwners;

  constructor(address _estateAddress) ERC721("Wrapped Decentraland Estate", "WrappedEST") {
    estateAddress = _estateAddress;
  }

  /// @notice Wraps Estate NFT
  /// @param tokenId The ID of the Estate NFT (minted wrappedNFT will have the same token ID)
  function wrap(uint256 tokenId) external {
    nftOwners[tokenId] = msg.sender;
    _safeMint(msg.sender, tokenId);
    IERC721(estateAddress).safeTransferFrom(msg.sender, address(this), tokenId);
  }

  /// @notice Unwraps Estate NFT
  /// @param tokenId The ID of the Estate NFT (minted wrappedNFT has the same token ID)
  function unwrap(uint256 tokenId) external {
    require(nftOwners[tokenId] == msg.sender, "Only owner can unwrap NFT");
    require(ownerOf(tokenId) == msg.sender, "You must hold wrapped NFT to unwrap");
    _burn(tokenId);
    IERC721(estateAddress).safeTransferFrom(address(this), msg.sender, tokenId);
  }

  /// @notice Wraps a Estate NFT, then adds to a Nafta pool
  /// @param estateTokenId The ID of the Estate NFT (minted wrappedNFT has the same token ID)
  /// @param naftaAddress Address of Nafta
  /// @param flashFee - The fee user has to pay for a single rent (in WETH9) [Range: 0-4722.36648 ETH] (0 if flashrent is free)
  /// @param pricePerBlock - If renting longterm - this is the price per block (0 if not allowing renting longterm) [Range: 0-4722.36648 ETH]
  /// @param maxLongtermBlocks - Maximum amount of blocks for longterm rent [Range: 0-16777216]
  function wrapAndAddToNafta(
    uint256 estateTokenId,
    address naftaAddress,
    uint256 flashFee,
    uint256 pricePerBlock,
    uint256 maxLongtermBlocks
  ) external {
    INafta nafta = INafta(naftaAddress);
    // get the id of the next minted naftaNFT
    uint256 naftaNFTId = nafta.lenderNFTCount() + 1;

    // wrap the ESTNFT in-place
    nftOwners[estateTokenId] = msg.sender;
    _safeMint(address(this), estateTokenId);
    IERC721(estateAddress).safeTransferFrom(msg.sender, address(this), estateTokenId);

    // approves wrapped Estate to nafta pool and adds it to the pool, this will mint a naftaNFT to this contract
    IERC721(address(this)).approve(naftaAddress, estateTokenId);
    nafta.addNFT(address(this), estateTokenId, flashFee, pricePerBlock, maxLongtermBlocks);

    // send a newly minted lender naftaNFT back to msg.sender
    IERC721(naftaAddress).safeTransferFrom(address(this), msg.sender, naftaNFTId);
  }

  /// @notice Removes a wrapped Estate NFT from a Nafta pool and returns the unwrapped NFT to the owner
  /// @param naftaAddress Address of Nafta
  /// @param estateTokenId The ID of the Estate NFT, wrapped version also has the same ID
  /// @param naftaNFTId The ID of the Nafta NFT one receives when they added to the pool
  function unwrapAndRemoveFromNafta(
    address naftaAddress,
    uint256 estateTokenId,
    uint256 naftaNFTId
  ) external {
    require(nftOwners[estateTokenId] == msg.sender, "Only owner can unwrap NFT");

    // Transfer the nafta NFT from user to this contract
    IERC721(naftaAddress).safeTransferFrom(msg.sender, address(this), naftaNFTId);

    INafta nafta = INafta(naftaAddress);
    // removes the wrapped Estate NFT from nafta
    nafta.removeNFT(address(this), estateTokenId);

    // burns the Wrapped Estate NFT
    _burn(estateTokenId);

    // transfers the original Estate NFT back to the lender
    IERC721(estateAddress).safeTransferFrom(address(this), msg.sender, estateTokenId);
  }

  function changeUpdateOperator(uint256 tokenId, address newOperator) external {
    require(ownerOf(tokenId) == msg.sender, "Only holder of wrapped Estate can change UpdateOperator");
    ILANDRegistry(estateAddress).setUpdateOperator(tokenId, newOperator);
  }

  function tokenURI(uint256 tokenId) public pure override returns (string memory) {
    return string.concat("https://api.decentraland.org/v2/contracts/0x959e104e1a4db6317fa58f8295f586e1a978c297/tokens/", toString(tokenId));
  }

  //////////////////////////////////////
  // IFlashNFTReceiver implementation
  //////////////////////////////////////

  event ExecuteCalled(address nftAddress, uint256 nftId, uint256 feeInWeth, address msgSender, bytes data);

  /// @notice Handles Nafta flashloan to Change Estate's UpdateOperator
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
    require(nftAddress == address(this), "Only Wrapped Estate NFTs are supported");

    // Change Estate UpdateOperator
    if (data.length == 20) {
      // If data is passed - we assume an address there
      this.changeUpdateOperator(nftId, address(bytes20(data)));
    } else {
      // If it wasn't passed - we just make msgSender a new operator
      this.changeUpdateOperator(nftId, msgSender);
    }

    // Approve WrappedEST NFT back to Nafta to return it
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
}
