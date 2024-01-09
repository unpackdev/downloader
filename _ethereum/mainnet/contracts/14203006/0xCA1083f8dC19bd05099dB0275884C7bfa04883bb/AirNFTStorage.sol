// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** 
@dev AIR NFT Contract Storage
*/
contract AirNFTStorage {
  // Constants
  /** @dev Treasury address */
  address internal constant TREASURY =
    address(0x263853ef2C3Dd98a986799aB72E3b78334EB88cb);

  /** @dev SyncxColors NFT Address (for mint and recolor functionality) */
  address internal constant SYNCXCOLORS =
  address(0x6F69141C0419B1D94C29bD5972F99213C2CE7b92); // Mainet
  //address(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512); // local
  //address internal SYNCXCOLORS = address(0xdcc77c2c29280a262C6A9AB7dd3cfD317B86ab4f); // ROP
  //address internal SYNCXCOLORS = address(0x6F69141C0419B1D94C29bD5972F99213C2CE7b92); // Mainet

  /** @dev COLORS NFT Address (proof of concept implementation) */
  address internal constant THE_COLORS =
  address(0x9fdb31F8CE3cB8400C7cCb2299492F2A498330a4); // Mainet
  //address(0x5FbDB2315678afecb367f032d93F642f64180aa3); // local
  //address internal constant THE_COLORS =
  //  address(0x3C4CfA9540c7aeacBbB81532Eb99D5E870105CA9); // ROP
  //address internal constant THE_COLORS =
  //  address(0x9fdb31F8CE3cB8400C7cCb2299492F2A498330a4); // Mainet

  // Storage
  /** @dev Platform accruals in gwei */
  uint96 internal platformAccruals;
  /** @dev Platform fee rate (base 1000) */
  uint96 public platformFeeRate;
  /** @dev Track current index for adding support for additional NFTs */
  uint64 internal currentIndex;

  /** @dev Stores lending information for each staked flashable token*/
  struct flashableNFTStruct {
    uint80 rentalFee;
    uint80 accruals;
    uint80 allTimeAccruals;
    uint16 allTimeLends;
  }

  // Mappings
  /** @dev Supported NFT addresses mapped to an index */
  mapping(address => uint256) internal airSupportIndex;
  /** @dev Maintain reference to NFT address for each index */
  mapping(uint256 => address) internal airSupportNFTAddress;
  /** @dev Minimum royalty for flashable NFT, in gwei */
  mapping(address => uint96) public minimumFlashFee;
  /** @dev Staked NFTs mapped to Receipt tokenIds (ERC721) */
  mapping(uint256 => flashableNFTStruct) internal flashableNFT; //

  //* Note: Variables newly declared in Future contract
  //  upgrades MUST be located below
  // ----------------------------------------*/
}
