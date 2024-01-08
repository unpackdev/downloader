// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Pausable.sol";
import "./Address.sol";
import "./RewilderNFT.sol";

contract RewilderDonationCampaign is Pausable, Ownable {

    using Address for address payable;

    RewilderNFT private _nft;
    address payable private _wallet;

    event DonationReceived(address indexed donor, uint256 amount, uint256 indexed tokenID);

    constructor(RewilderNFT nftAddress, address payable wallet) {
        _nft = nftAddress;
        _wallet = wallet;

        // give ownership of campaign to wallet (allows pausing and finalizing campaign)
        transferOwnership(_wallet);
    }

    /**
     * @dev Returns the address of the NFT contract.
     */
    function getRewilderNft() public view virtual returns (RewilderNFT) {
        return _nft;
    }

    /**
     * @dev Receives donation and mints new NFT for donor
     */
    function receiveDonation() public whenNotPaused payable {
        require(msg.value >= 1 ether, "Minimum donation is 1 ETH");
        require(msg.value <= 100 ether, "Maximum donation is 100 ETH");

        uint256 tokenId =_nft.safeMint(msg.sender);
        _wallet.sendValue(msg.value);
        emit DonationReceived(msg.sender, msg.value, tokenId);
    }

    /**
     * @dev finalize campaign and transfer NFT ownership after donation campaign ends
     */
    function finalize() public onlyOwner {
        _pause();
        _nft.transferOwnership(_wallet);
        renounceOwnership();
    }

    /**
     * @dev pause the campaign
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev unpause the campaign
     */
    function unpause() public onlyOwner {
        _unpause();
    }


}
