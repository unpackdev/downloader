//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.9;

import "./ERC721Holder.sol";
import "./INonfungiblePositionManager.sol";
import "./IFlashNFTReceiver.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./ERC721.sol";
import "./INafta.sol";
import "./console.sol";

import "./IUniV3Wrapper.sol";

contract UniV3Wrapper is IUniV3Wrapper, ERC721, ERC721Holder {
  using SafeERC20 for IERC20;

  address public immutable uniV3Address;

  mapping(uint256 => address) nftOwners;

  event FeesCollected(address token0, uint256 amount0, address token1, uint256 amount1);

  constructor(address _uniV3Address) ERC721("Wrapped Uniswap V3 Positions", "WUNI-V3-POS") {
    uniV3Address = _uniV3Address;

    // TODO: Wanted to do this, but dunno the proper syntax:
    // string name = INonfungiblePositionManager(_uniV3Address).name();
    // string symbol = INonfungiblePositionManager(_uniV3Address).symbol();
    // ERC721.constructor(name, symbol);
  }

  /// @notice Wraps Uniswap V3 NFT
  /// @param tokenId The ID of the uniswap nft (minted wrappedNFT will have the same ID)
  function wrap(uint256 tokenId) external {
    nftOwners[tokenId] = msg.sender;
    _safeMint(msg.sender, tokenId);
    IERC721(uniV3Address).safeTransferFrom(msg.sender, address(this), tokenId);
  }

  /// @notice Unwraps Uniswap V3 NFT
  /// @param tokenId The ID of the uniswap nft (minted wrappedNFT has the same ID)
  function unwrap(uint256 tokenId) external {
    require(nftOwners[tokenId] == msg.sender, "Only owner can unwrap NFT");
    require(ownerOf(tokenId) == msg.sender, "You must hold wrapped NFT to unwrap");
    _burn(tokenId);
    IERC721(uniV3Address).safeTransferFrom(address(this), msg.sender, tokenId);
  }

  /// @notice Wraps a uniV3 NFT, then adds to a Nafta pool
  /// @dev Explain to a developer any extra details
  /// @param uniTokenId The ID of the uniswap nft (minted wrappedNFT has the same ID)
  /// @param naftaAddress Address of Nafta
  /// @param flashFee - The fee user has to pay for a single rent (in WETH9) [Range: 1gwei-1099.51163 ETH]
  /// @param pricePerBlock - If renting longterm - this is the price per block (0 if not renting longterm) [Range: 1gwei-1099.51163 ETH, or 0]
  /// @param maxLongtermBlocks - Maximum amount of blocks for longterm rent [Range: 0-16777216]
  function wrapAndAddToNafta(
    uint256 uniTokenId,
    address naftaAddress,
    uint256 flashFee,
    uint256 pricePerBlock,
    uint256 maxLongtermBlocks
  ) external {
    INafta nafta = INafta(naftaAddress);
    // get the id of the next minted naftaNFT
    uint256 naftaNFTId = nafta.lenderNFTCount() + 1;

    // wrap the UniNFT in-place
    nftOwners[uniTokenId] = msg.sender;
    _safeMint(address(this), uniTokenId);
    IERC721(uniV3Address).safeTransferFrom(msg.sender, address(this), uniTokenId);

    // approves wrapper uniV3 to nafta pool and adds it to the pool this will mint a naftaNFT to the contract
    IERC721(address(this)).approve(naftaAddress, uniTokenId);
    nafta.addNFT(address(this), uniTokenId, flashFee, pricePerBlock, maxLongtermBlocks);

    // send a newly minted lender naftaNFT back to msg.sender
    IERC721(naftaAddress).safeTransferFrom(address(this), msg.sender, naftaNFTId);
  }

  /// @notice Removes a wrapped uniV3 NFT from a Nafta pool and returns the unwrapped NFT to the owner
  /// @param naftaAddress Address of Nafta
  /// @param uniTokenId The ID of the uniswap NFT wrapped version also has the same ID
  /// @param naftaNFTId The ID of the Nafta NFT one receives when they added to the pool
  function unwrapAndRemoveFromNafta(
    address naftaAddress,
    uint256 uniTokenId,
    uint256 naftaNFTId
  ) external {
    require(nftOwners[uniTokenId] == msg.sender, "Only owner can unwrap NFT");

    // Transfer the nafta NFT to this contract
    IERC721(naftaAddress).safeTransferFrom(msg.sender, address(this), naftaNFTId);

    INafta nafta = INafta(naftaAddress);
    // removes the wrapped uniswap LP from nafta
    nafta.removeNFT(address(this), uniTokenId);

    // burns the wrapped uniswap LP
    _burn(uniTokenId);
    // transfers the original LP NFT back to the lender
    IERC721(uniV3Address).safeTransferFrom(address(this), msg.sender, uniTokenId);
  }

  function extractUniswapFees(uint256 tokenId, address recipient) external {
    require(ownerOf(tokenId) == msg.sender, "Only holder of wrapper can extract fees");

    INonfungiblePositionManager nonfungiblePositionManager = INonfungiblePositionManager(uniV3Address);

    // get required information about the UNI-V3 NFT position
    (, , address token0, address token1, , , , , , , , ) = nonfungiblePositionManager.positions(tokenId);

    INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
      tokenId: tokenId,
      recipient: recipient,
      amount0Max: type(uint128).max,
      amount1Max: type(uint128).max
    });

    // collect the fee's from the NFT
    (uint256 amount0, uint256 amount1) = nonfungiblePositionManager.collect(params);
    emit FeesCollected(token0, amount0, token1, amount1);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return INonfungiblePositionManager(uniV3Address).tokenURI(tokenId);
  }

  //////////////////////////////////////
  // IFlashNFTReceiver implementation
  //////////////////////////////////////

  event ExecuteCalled(address nftAddress, uint256 nftId, uint256 feeInWeth, address msgSender, bytes data);

  /// @notice Handles Nafta flashloan to Extract UniswapV3 fees
  /// @dev This function is called by Nafta contract.
  /// @dev Nafta gives you the NFT and expects it back, so we need to approve it.
  /// @dev Also it expects feeInWeth fee paid - so should also be approved.
  /// @param nftAddress  The address of NFT contract
  /// @param nftId  The address of NFT contract
  /// @param msgSender address of the account calling the contract
  /// @param data optional calldata passed into the function optional
  /// @return returns a boolean true on success
  function executeOperation(
    address nftAddress,
    uint256 nftId,
    uint256 feeInWeth,
    address msgSender,
    bytes calldata data
  ) external override returns (bool) {
    emit ExecuteCalled(nftAddress, nftId, feeInWeth, msgSender, data);
    require(nftAddress == address(this), "Only Wrapped UNIV3 NFTs are supported");

    // do the uniswap fee extraction thing
    this.extractUniswapFees(nftId, msgSender);

    // Approve NFT back to Nafta to return it
    this.approve(msg.sender, nftId);
    return true;
  }
}
