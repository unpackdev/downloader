// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./IERC721Enumerable.sol";
import "./ERC165Checker.sol";
import "./base64.sol";
import "./ISyncxColors.sol";
import "./ITheColors.sol";
import "./IERC721MetaData.sol";
import "./AirNFTStorage.sol";

/** 

 █████╗ ██╗██████╗     ███╗   ██╗███████╗████████╗
██╔══██╗██║██╔══██╗    ████╗  ██║██╔════╝╚══██╔══╝
███████║██║██████╔╝    ██╔██╗ ██║█████╗     ██║   
██╔══██║██║██╔══██╗    ██║╚██╗██║██╔══╝     ██║   
██║  ██║██║██║  ██║    ██║ ╚████║██║        ██║   
╚═╝  ╚═╝╚═╝╚═╝  ╚═╝    ╚═╝  ╚═══╝╚═╝        ╚═╝   
                                                  

AIR NFT Rental Contract (Version 1.0):
- Supports staking for all ERC721 NFTs, with stakers generating royalties each time they are lent out via flashloan;
- Implements Sync x Colors minting and recoloring functionality using staked THE_COLORS primitive NFTs;
- Mints receipt tokens as ERC721 on stake;
- Burns receipt tokens and transfers receipt back to owner on unstake.
*/

contract AirNFT is
  Initializable,
  OwnableUpgradeable,
  UUPSUpgradeable,
  ERC721EnumerableUpgradeable,
  ERC721HolderUpgradeable,
  ERC1155HolderUpgradeable,
  PausableUpgradeable,
  AirNFTStorage
{
  using StringsUpgradeable for uint256;

  /** Events
   */
  event stakeEvent(
    address sender,
    uint16[] rentedTokenIds,
    uint80[] rentalFees
  );

  event unstakeEvent(address sender, uint16[] rentedTokenIds);

  event mintEvent(
    address sender,
    uint16[] rentedTokenIds,
    uint256 mintAmount,
    uint256 rentalFee
  );

  event recolorEvent(
    address sender,
    uint16[] rentedTokenIds,
    uint16[] syncTokenIds,
    uint256 rentalFee
  );

  /**
   * @dev Contract initializations.
   */
  function initialize() public initializer {
    platformFeeRate = 1000;
    __Ownable_init();
    __UUPSUpgradeable_init();
    __ERC721_init('AirNFT', 'AIR');

    // Include THE_COLORS as initial supported NFT
    addSupportedNFT(THE_COLORS, 0.003 ether); // Minimum royalty preset as 0.003 eth
  }

  /**
   * @dev Overriden function for authorization of upgrades to proxy.
   * @param newImplementation Address of new proxy contract
   */
  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {}

  /**
   * @dev Transfers tokenIds to rental pool and returns an ERC721 receipt to owner
   * @param erc721Address Address of supported ERC721 NFT (only erc721 is supported in v1)
   * @param tokenIds TokenIds to be staked within the contract
   * @param rentalFees Fees charged per token rental (in gwei)
   */
  function addStaked(
    address erc721Address,
    uint16[] calldata tokenIds,
    uint80[] calldata rentalFees
  ) external whenNotPaused {
    uint256 _nftIndex = getAirSupportIndex(erc721Address);
    require(tokenIds.length == rentalFees.length, 'Token and fee mismatch');

    // Verify ownership and fees, Update storage; Transfer staked colors; Issue Receipt
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(
        msg.sender == IERC721Enumerable(erc721Address).ownerOf(tokenIds[i]),
        'Token not owned by caller'
      );

      verifyFee(erc721Address, rentalFees[i]);

      AirNFTStorage
        .flashableNFT[_nftIndex + tokenIds[i]]
        .rentalFee = rentalFees[i];

      IERC721Enumerable(erc721Address).transferFrom(
        msg.sender,
        address(this),
        tokenIds[i]
      );

      _safeMint(msg.sender, _nftIndex + tokenIds[i]);
    }
    emit stakeEvent(msg.sender, tokenIds, rentalFees);
  }

  /**
   * @dev Removes tokenIds from rental pool and returns them to owner + burns receipt token
   * @param erc721Address Address of ERC721 NFT (only erc721 is supported in v1)
   * @param tokenIds tokens staked within the contract
   * @param claimRoyalties supplied boolean true will claim royalties for those tokens removed from staking
   */
  function removeStaked(
    address erc721Address,
    uint16[] calldata tokenIds,
    bool claimRoyalties
  ) external whenNotPaused {
    uint256 _nftIndex = getAirSupportIndex(erc721Address);

    // Withdraw accruals (optional)
    if (claimRoyalties) {
      claim(erc721Address, tokenIds);
    }

    // Verify receipt holder; Transfer tokens; burn receipt
    for (uint256 i = 0; i < tokenIds.length; i++) {
      verifyReceiptOwnership(_nftIndex + tokenIds[i]);

      IERC721Enumerable(erc721Address).safeTransferFrom(
        address(this),
        msg.sender,
        tokenIds[i]
      );

      _burn(_nftIndex + tokenIds[i]);
    }
    emit unstakeEvent(msg.sender, tokenIds);
  }

  /**
   * @dev Updates rental fee for supplied tokenIds
   * @param nftAddress Address of supported NFT
   * @param tokenIds TokenIds staked within the contract
   * @param rentalFees Fees charged per token rental (in gwei)
   */
  function updateRentalFees(
    address nftAddress,
    uint16[] calldata tokenIds,
    uint80[] calldata rentalFees
  ) public whenNotPaused {
    uint256 _nftIndex = getAirSupportIndex(nftAddress);
    require(tokenIds.length == rentalFees.length, 'Token and fee mismatch');

    // Verify receipt + fees; Update storage
    for (uint256 i = 0; i < tokenIds.length; i++) {
      verifyReceiptOwnership(_nftIndex + tokenIds[i]);

      verifyFee(nftAddress, rentalFees[i]);

      AirNFTStorage
        .flashableNFT[_nftIndex + tokenIds[i]]
        .rentalFee = rentalFees[i];
    }
  }

  /**
   * @dev Verifies that supplied fee meets platform criteria
   * @param nftAddress Address of supported NFT
   * @param fee The fee requested by staker, in gwei
   */
  function verifyFee(address nftAddress, uint80 fee) internal view {
    require(
      fee >= minimumFlashFee[nftAddress],
      'Require Fee >= minimumFlashFee'
    );
    require(fee <= 10 ether, 'Require Fee <= 10 ether');
  }

  /**
   * @dev Verifies that msg.sender owns supplied receipt tokenId
   * @param tokenId Receipt tokenId to verify ownership against
   */
  function verifyReceiptOwnership(uint256 tokenId) internal view {
    require(ownerOf(tokenId) == msg.sender, 'Staking receipt not found');
  }

  /**
   * @dev Verifies that NFT is supported by platform and returns assigned index
   * @param nftAddress Address of supported NFT
   * @return AirNFT support index
   */
  function getAirSupportIndex(address nftAddress)
    internal
    view
    returns (uint256)
  {
    uint256 _nftIndex = AirNFTStorage.airSupportIndex[nftAddress];
    require(_nftIndex != 0, 'NFT unsupported');
    return _nftIndex;
  }

  /**
   * @dev Mints Sync x Colors NFT with staked COLORS NFT tokens.
   * @param mintAmount Amount to mint
   * @param tokenIds tokenIds of COLORS NFT to apply to mint
   */
  function mintSyncsWithRentedTokens(
    uint16 mintAmount,
    uint16[] calldata tokenIds
  ) external payable whenNotPaused {
    require(tokenIds.length <= 3, 'Num COLORS must be <=3');

    uint256 mintPrice = 0.05 ether;
    uint256 _nftIndex = 10**16; // Avoid an MLoad here since the Colors contract is predetermined to be within slot 1

    // Calculte fees; Update accrued royalties
    uint256 totalRentalFee = updateRoyalties(
      _nftIndex,
      tokenIds,
      uint80(mintAmount)
    );

    require(
      msg.value == mintAmount * mintPrice + totalRentalFee,
      'Insufficient funds.'
    );

    // Mint to contract address
    ISYNC(SYNCXCOLORS).mint{value: mintAmount * mintPrice}(
      mintAmount,
      tokenIds
    );

    // Transfer NFTs to the sender
    uint256 new_supply = IERC721Enumerable(SYNCXCOLORS).totalSupply();
    for (uint256 i = new_supply - mintAmount; i < new_supply; i++) {
      IERC721Enumerable(SYNCXCOLORS).safeTransferFrom(
        address(this),
        msg.sender,
        i
      );
    }

    emit mintEvent(msg.sender, tokenIds, mintAmount, totalRentalFee);
  }

  /**
   * @dev Updates colors of Sync x Colors NFT with staked COLORS NFT tokens
   * @param tokenIds Sync x Colors tokens to recolor
   * @param colorsTokenIds COLORS NFT tokenIds to apply to recolor
   */
  function updateSyncColors(
    uint16[] calldata tokenIds,
    uint16[] calldata colorsTokenIds
  ) external payable whenNotPaused {
    require(colorsTokenIds.length <= 3, 'Num COLORS must be <=3');

    uint256 resyncPrice = 0.005 ether;
    uint256 _nftIndex = 10**16; // Avoid an MLoad here since the Colors contract is predetermined to be at first airSupportIndex

    // Verify ownership,
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(
        msg.sender == IERC721Enumerable(SYNCXCOLORS).ownerOf(tokenIds[i]),
        'SYNC not owned by sender'
      );
    }

    // Verify staked colors; update storage; calculate fees
    uint96 totalRentalFee = updateRoyalties(
      _nftIndex,
      colorsTokenIds,
      uint80(tokenIds.length)
    );

    require(
      msg.value == tokenIds.length * resyncPrice + totalRentalFee,
      'Insufficient funds'
    );

    // Transfer sync, updateColors, transfer sync back to sender
    for (uint256 i = 0; i < tokenIds.length; i++) {
      IERC721Enumerable(SYNCXCOLORS).transferFrom(
        msg.sender,
        address(this),
        tokenIds[i]
      );
      ISYNC(SYNCXCOLORS).updateColors{value: 0.005 ether}(
        tokenIds[i],
        colorsTokenIds
      );
      IERC721Enumerable(SYNCXCOLORS).transferFrom(
        address(this),
        msg.sender,
        tokenIds[i]
      );
    }
    emit recolorEvent(msg.sender, tokenIds, colorsTokenIds, totalRentalFee);
  }

  /**
   * @dev Update royalty balances and calculate total fees for the loan 
   * @param _nftIndex NFT index
   * @param tokenIds Tokens to be loaned
   * @param size Number of uses to be applied to each loaned token
   # @return airSupportIndex of NFT represented by receipt token ID
   */
  function updateRoyalties(
    uint256 _nftIndex,
    uint16[] memory tokenIds,
    uint80 size
  ) internal returns (uint96) {
    uint96 royaltyFee;
    flashableNFTStruct memory rentalNFT;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(_exists(_nftIndex + tokenIds[i]), 'COLORS tokenId unavailable');

      rentalNFT = AirNFTStorage.flashableNFT[_nftIndex + tokenIds[i]];
      AirNFTStorage.flashableNFT[_nftIndex + tokenIds[i]].allTimeAccruals =
        rentalNFT.allTimeAccruals +
        rentalNFT.rentalFee *
        size;
      AirNFTStorage.flashableNFT[_nftIndex + tokenIds[i]].accruals =
        rentalNFT.accruals +
        rentalNFT.rentalFee *
        size;
      AirNFTStorage.flashableNFT[_nftIndex + tokenIds[i]].allTimeLends =
        rentalNFT.allTimeLends +
        uint16(size);
      royaltyFee += rentalNFT.rentalFee;
    }

    uint96 totalRentalFee = (royaltyFee * uint96(size) * platformFeeRate) /
      1000;

    AirNFTStorage.platformAccruals +=
      totalRentalFee -
      royaltyFee *
      uint96(size);

    return totalRentalFee;
  }

  /**
   * @dev tokenURI function
   * @param tokenId tokenId of receipt
   * @return returns URI of receipt token
   */
  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      'ERC721Metadata: URI query for nonexistent token..'
    );
    uint256 nftIndex = receiptIndex(tokenId);
    uint256 nftTokenId = tokenId - nftIndex;
    address nftAddress = AirNFTStorage.airSupportNFTAddress[nftIndex];
    string memory nftName = IERC721MetaData(nftAddress).name();
    bytes memory nftColor = getReceiptColor(nftAddress, nftTokenId);

    string memory receiptImage = Base64.encode(
      printReceipt(nftName, nftTokenId, nftColor)
    );

    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{',
                '"image":"',
                'data:image/svg+xml;base64,',
                receiptImage,
                '",',
                '"description":"AIR NFT Lender Staking Receipt"',
                ',',
                '"attributes":[',
                '{"trait_type":"Collection","value":"',
                nftName,
                '"},',
                '{"trait_type":"tokenID","value":"',
                tokenId.toString(),
                '"}]}'
              )
            )
          )
        )
      );
  }

  /**
   * @dev Produces the receipt token image for tokenURI
   * @param nftName Name of NFT to be printed on the receipt
   * @param tokenId tokenId to be printed on the receipt
   * @return returns SVG as bytes
   */
  function printReceipt(
    string memory nftName,
    uint256 tokenId,
    bytes memory color
  ) internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" width="320" height="450" viewbox="0 0 320 450" style="background-color:#FFFFFF">',
        '<g id= "2"> <path d = "M20 400L20 30L40 30L60 60L100 30L120 30L140 60L180 30L200 30L220 60L260 30L280 30L300 60L300 220" ',
        'stroke="black" fill="',
        color,
        '" stroke-width="15"/><path d = "M300 60L300 400" stroke="black" stroke-width="30"/>',
        '</g><use href="#2" x="0" y="0" transform="scale(1,-1) translate(0,-450)"/>',
        '<path d = "M60 310L260 310" stroke="black" stroke-width="15"/><path d = "M60 260L260 260" stroke="black" stroke-width="15"/>',
        '<text x="50" y="180" font-size="8em">AIR</text><text x="60" y="245" font-size="1em">',
        nftName,
        '</text><text x="60" y="295" font-size="1em">TokenID #',
        tokenId.toString(),
        '</text><text x="60" y="355" font-size="1em">Redeemable at SyncxColors.xyz</text>',
        '<text x="60" y="375" font-size="1em">Powered by AirNFT</text></svg>'
      );
  }

  /**
   * @dev Get color for receipt
   * @param nftAddress Address of NFT for receipt
   * @param tokenId tokenId of NFT for receipt
   * @return returns hex color string as bytes
   */
  function getReceiptColor(address nftAddress, uint256 tokenId)
    internal
    view
    returns (bytes memory)
  {
    if (nftAddress == THE_COLORS) {
      return bytes(ITheColors(THE_COLORS).getHexColor(tokenId));
    } else {
      return '#DDDDDD'; // Future: For other collections, generate colors by hash of uri.
    }
  }

  /**
   * @dev Parses the NFT airSupportIndex from receipt ID (stored in bits 64-17)
   * @param receiptTokenId Receipt token ID)
   # @return airSupportIndex of NFT represented by receipt token ID
   */
  function receiptIndex(uint256 receiptTokenId) private pure returns (uint256) {
    return receiptTokenId & 0xFFFFFFFFFFFF0000;
  }

  /**
   * @dev Withdraws all royalties accrued by the calling address (based on receipts held)
   * @param nftAddress Nft address
   */
  function claimAllContract(address nftAddress) public whenNotPaused {
    uint256 _nftIndex = getAirSupportIndex(nftAddress);

    uint256 royalties;
    uint256 bal = balanceOf(msg.sender);
    uint256 receiptTokenId;
    for (uint256 i = 0; i < bal; i++) {
      receiptTokenId = tokenOfOwnerByIndex(msg.sender, i);
      if (receiptIndex(receiptTokenId) == _nftIndex) {
        royalties += AirNFTStorage.flashableNFT[receiptTokenId].accruals;
        AirNFTStorage.flashableNFT[receiptTokenId].accruals = 0;
      }
    }
    _claim(royalties);
  }

  /**
   * @dev External Facing: Withdraws royalties accrued for the supplied tokenIds (based on receipts held)
   * @param nftAddress Address of NFT
   * @param tokenIds tokenIds staked within the contract
   */
  function claim(address nftAddress, uint16[] calldata tokenIds)
    public
    whenNotPaused
  {
    uint256 _nftIndex = getAirSupportIndex(nftAddress);

    uint256 royalties;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      verifyReceiptOwnership(_nftIndex + tokenIds[i]);
      royalties += AirNFTStorage.flashableNFT[_nftIndex + tokenIds[i]].accruals;
      AirNFTStorage.flashableNFT[_nftIndex + tokenIds[i]].accruals = 0;
    }
    _claim(royalties);
  }

  /**
   * @dev Withdraw royalties to sender
   * @param royalties royalties in eth
   */
  function _claim(uint256 royalties) internal {
    bool sent;
    (sent, ) = payable(msg.sender).call{value: royalties}('');
    require(sent);
  }

  /**
   * @dev Returns total rental cost for supplied tokenIds
   * @param nftAddress Address of NFT
   * @param tokenIds tokens staked within the contract
   * @return Total rental cost (in gwei)
   */
  function getRentalCost(address nftAddress, uint16[] calldata tokenIds)
    public
    view
    returns (uint256)
  {
    uint256 _nftIndex = getAirSupportIndex(nftAddress);

    uint256 rentalFee = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      rentalFee += AirNFTStorage
        .flashableNFT[_nftIndex + tokenIds[i]]
        .rentalFee;
    }
    return (rentalFee * platformFeeRate) / 1000;
  }

  /**
   * @dev Convenience function which returns supported ERC721 tokenIds owned by calling address
   * @param erc721Address Address of ERC721 NFT
   * @param request Address of owner queried
   * @return Array of tokenIds
   */
  function getOwnedERC721ByAddress(address erc721Address, address request)
    public
    view
    returns (uint256[] memory)
  {
    require(
      AirNFTStorage.airSupportIndex[erc721Address] != 0,
      'NFT unsupported'
    );

    uint256 bal = IERC721Enumerable(erc721Address).balanceOf(request);
    uint256[] memory tokenIds = new uint256[](bal);
    for (uint256 i = 0; i < bal; i++) {
      tokenIds[i] = IERC721Enumerable(erc721Address).tokenOfOwnerByIndex(
        request,
        i
      );
    }
    return tokenIds;
  }

  /**
   * @dev Returns NFT tokenIds staked by calling address (based on receipts held)
   * @param nftAddress Address of ERC721 NFT
   * @param stakerAddress Address of staker
   * @return Array of tokenIds
   */
  function getStakedByAddress(address nftAddress, address stakerAddress)
    public
    view
    returns (uint256[] memory)
  {
    uint256 _nftIndex = getAirSupportIndex(nftAddress);

    uint256 bal = balanceOf(stakerAddress);
    uint256[] memory staked = new uint256[](bal);
    uint256 receiptTokenId;
    uint256 index;
    for (uint256 i = 0; i < bal; i++) {
      receiptTokenId = tokenOfOwnerByIndex(stakerAddress, i);
      if (receiptIndex(receiptTokenId) == _nftIndex) {
        staked[index] = receiptTokenId - _nftIndex;
        index++;
      }
    }
    // Trim the array before returning it
    return trimmedArray(staked, index);
  }

  /**
   * @dev Returns all ERC721 tokenIds currently staked
   * @param nftAddress Address of ERC721 NFT
   * @return Array of tokenIds
   */
  function getStaked(address nftAddress)
    public
    view
    returns (uint256[] memory)
  {
    uint256 _nftIndex = getAirSupportIndex(nftAddress);

    uint256 supply = totalSupply();
    uint256[] memory staked = new uint256[](supply);
    uint256 receiptTokenId;
    uint256 index;
    for (uint256 i = 0; i < supply; i++) {
      receiptTokenId = tokenByIndex(i);
      if (receiptIndex(receiptTokenId) == _nftIndex) {
        staked[index] = receiptTokenId - _nftIndex;
        index++;
      }
    }

    // Trim the array before returning it
    return trimmedArray(staked, index);
  }

  /**
   * @dev Returns royalty accruals by address of Staker (based on receipts held)
   * @param stakerAddress Address of token staker
   * @return Total royalties accrued (in gwei)
   */
  function getAccruals(address stakerAddress) public view returns (uint256) {
    uint256 royalties;
    uint256 bal = balanceOf(stakerAddress);
    for (uint256 i = 0; i < bal; i++) {
      royalties += AirNFTStorage
        .flashableNFT[tokenOfOwnerByIndex(stakerAddress, i)]
        .accruals;
    }
    return royalties;
  }

  /**
   * @dev Returns statistics for the staked ERC721 tokenId
   * @param nftAddress Address of ERC721 NFT
   * @param tokenIds tokenIds
   * @return Array of flashableNFTStruct structs
   */
  function stakedNFTData(address nftAddress, uint256[] calldata tokenIds)
    public
    view
    returns (flashableNFTStruct[] memory)
  {
    uint256 _nftIndex = getAirSupportIndex(nftAddress);

    flashableNFTStruct[] memory stakedStructs = new flashableNFTStruct[](
      tokenIds.length
    );

    for (uint256 i = 0; i < tokenIds.length; i++) {
      stakedStructs[i] = AirNFTStorage.flashableNFT[_nftIndex + tokenIds[i]];
    }
    return stakedStructs;
  }

  /**
   * @dev Update platform fee rate
   * @param feeRate New fee-rate
   */
  function updatePlatformFeeRate(uint64 feeRate) public onlyOwner {
    require(feeRate >= 1000);
    platformFeeRate = feeRate;
  }

  /**
   * @dev Withdraws platform fees charged by the contract since last withdraw
   */
  function withdrawPlatformAccruals() external onlyOwner {
    uint256 balance = AirNFTStorage.platformAccruals;
    AirNFTStorage.platformAccruals = 0;

    bool sent;
    (sent, ) = payable(AirNFTStorage.TREASURY).call{value: balance}('');
    require(sent);
  }

  /**
   * @dev Returns value of platform fees accrued
   */
  function getPlatformAccruals() external view onlyOwner returns (uint256) {
    return AirNFTStorage.platformAccruals;
  }

  /**
   * @dev Adds NFT contract address to supported staking NFTs
   * @param nftAddress Address of NFT
   */
  function addSupportedNFT(address nftAddress, uint96 _minimumFlashFee)
    public
    onlyOwner
  {
    require(
      AirNFTStorage.airSupportIndex[nftAddress] == 0,
      'NFT already supported'
    );
    // Each additional NFT index is incremented by 10**16
    uint64 index = AirNFTStorage.currentIndex + 10**16;
    AirNFTStorage.currentIndex = index;
    AirNFTStorage.airSupportIndex[nftAddress] = index;
    AirNFTStorage.airSupportNFTAddress[index] = nftAddress;
    minimumFlashFee[nftAddress] = _minimumFlashFee;
  }

  /**
   * @dev Sets minimum royalty for token
   * @param nftAddress Address of NFT
   * @param _minimumFlashFee Minimum royalty, in gwei
   */
  function setMinimumFlashFee(address nftAddress, uint96 _minimumFlashFee)
    public
    onlyOwner
  {
    require(AirNFTStorage.airSupportIndex[nftAddress] != 0, 'NFT unsupported');
    minimumFlashFee[nftAddress] = _minimumFlashFee;
  }

  /**
   * @dev Required to manage inherited functions from ERC1155 and ERC721
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155ReceiverUpgradeable, ERC721EnumerableUpgradeable)
    returns (bool)
  {
    return
      interfaceId == type(ERC1155ReceiverUpgradeable).interfaceId ||
      interfaceId == type(ERC721EnumerableUpgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev Trims inputArray to size length
   */
  function trimmedArray(uint256[] memory inputArray, uint256 length)
    internal
    pure
    returns (uint256[] memory)
  {
    uint256[] memory outputArray = new uint256[](length);
    for (uint256 i = 0; i < length; i++) {
      outputArray[i] = inputArray[i];
    }
    return outputArray;
  }
}
