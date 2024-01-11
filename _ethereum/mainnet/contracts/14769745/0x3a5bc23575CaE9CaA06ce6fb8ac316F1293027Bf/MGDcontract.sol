//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

import "./Ownable.sol";

interface MGDcontract {
    /**
@notice unlockPlatform allows for owner of this contract to open up the platforms listings to
          non MGD NFT types
*/
    function unlockPlatform() external;

    /**
  @notice setMintFee allows the owner to set the fee for minting and listing through the orderbook
  @param _fee is the value representing the percentage of a sale taken as a platform fee
*/
    function setMintFee(uint256 _fee) external;

    /**
  @notice setListingFee allows the owner to set the fee for secondary listings through the orderbook
  @param _fee is the value representing the percentage of a sale taken as a platform fee
*/
    function setListingFee(uint256 _fee) external;

    /**
    @notice setFeeAdd allows the owner to set the fee address
    @param _add is the address that will receive the fee's
    */
    function setFeeAdd(address _add) external;
}
