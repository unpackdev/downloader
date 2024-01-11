// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**************************************

    security-contact:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io

**************************************/

// OpenZeppelin
import "./Ownable.sol";
import "./IERC721Receiver.sol";

// Local
import "./IAbNFT.sol";

/**************************************

    Vesting of AB NFT for Claim

 **************************************/

contract VestedClaim is IERC721Receiver, Ownable {

    // structs
    struct VestingTranche {
        uint256 availableFrom;
        uint256 cap;
    }

    // contracts
    IAbNFT public immutable abNFT;

    // storage
    VestingTranche[] public tranches;
    uint256[] public nftsToClaim;
    uint256 public claimed;

    // errors
    error InvalidTranches();
    error SenderNotAbNFT(address sender);
    error NftAlreadyMinted(address owner);
    error NotEnoughNFTAvailableToClaim(uint256 toClaim, uint256 available);

    /**************************************

        Constructor

     **************************************/

    constructor(address _abNFT, VestingTranche[] memory _tranches)
    Ownable() {

        // check length
        uint256 length_ = _tranches.length;
        if (length_ == 0) revert InvalidTranches();

        // storage
        abNFT = IAbNFT(_abNFT);

        // memory -> storage
        for (uint256 i = 0; i < length_; i++) {
            tranches.push(_tranches[i]);
        }

    }

    /**************************************

        Receive

     **************************************/

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes memory
    ) public override
    returns (bytes4) {

        // check NFT address
        if (msg.sender != address(abNFT)) {
            revert SenderNotAbNFT(msg.sender);
        }

        // allow only minted
        if (from != address(0)) {
            revert NftAlreadyMinted(from);
        }

        // storage
        nftsToClaim.push(tokenId);

        // return
        return this.onERC721Received.selector;

    }

    /**************************************

        Queue for Claim

     **************************************/

    function getTotalQueueForClaim() public view
    returns (uint256) {

        // return
        return nftsToClaim.length;

    }

    /**************************************

        Available for Claim

     **************************************/

    function getAvailableForClaim() public view
    returns (uint256) {

        // tx.members
        uint256 now_ = block.timestamp;

        // check tranches
        for (uint256 i = tranches.length; i > 0; i--) {

            // tranche
            VestingTranche memory tranche_ = tranches[i - 1];

            // check availability
            if (tranche_.availableFrom <= now_) {

                // get all queued
                uint256 all_ = getTotalQueueForClaim();

                // use cap or all of nfts
                uint256 min_ = (tranche_.cap < all_) ? tranche_.cap : all_;

                // return available
                return min_ - claimed;

            }

        }

        // return
        return 0;

    }

    /**************************************

        Claim NFT

     **************************************/

    function claim(uint256 _amount) external
    onlyOwner() {

        // tx.members
        address self_ = address(this);

        // check tranches
        uint256 availableForClaim_ = getAvailableForClaim();
        if (availableForClaim_ < _amount || _amount == 0) {
            revert NotEnoughNFTAvailableToClaim(_amount, availableForClaim_);
        }

        // index
        uint256 index_ = claimed;

        // storage
        claimed += _amount;

        // loop
        do {

            // claim nft
            abNFT.transferFrom(self_, owner(), nftsToClaim[index_++]);

        } while (index_ < claimed);

    }

}
