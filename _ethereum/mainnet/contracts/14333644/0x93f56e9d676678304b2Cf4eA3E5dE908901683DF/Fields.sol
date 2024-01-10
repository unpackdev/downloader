// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

error TooManyToMintInOneTransaction();
error ETHTransferFailed();
error NFTTransferPaused();
error NotEnoughtETH();
error ToManyToMint();
error NotAllowed();
error NoBalanceToWithdraw();
error ToMuchToWithdraw();
error MintingIsNotStarted();

contract Fields {

    // emits BaseURIChanged event when the baseURI changes
    event BaseURIChanged(string initialBaseURI, string finalBaseURI);
    // emits Minted event of how many NFTs were minted by somebody and to who were sent
    event Minted(address minter, address owner, uint8 quantity);
    // emits Minted event of how many NFTs were minted by somebody and to who were sent
    event Airdrop(address owner, uint8 quantity);

    struct TeamMember {
        uint16 percentage;
        uint256 balance;
    }

    // flag to signal that the minting is started
    bool public mintedStarted;

    // number of airdrops already minted 
    uint8 public mintedAirdrops;
    // maximum number of aidrdops that can be minted by the team
    uint8 internal maxAirdrops = 69;
    // maximum batch size at which to send funds
	uint8 internal batchSize = 100;
    // the number of minted NFTs in the current batch
	uint8 public currentBatchMinted;
    // maximum number of NFTs that can be minted in a single transaction
    uint8 internal constant MAX_TOKENS_PER_PURCHASE = 25;
    // maximum number of tokens that can be minted.
    uint16 internal MAX_TOKENS = 6969;

    // the baseURI for token metadata
    string public baseURI;

    // the price to mint one Picasso Mfer
    uint256 internal constant MINT_PRICE = 0.006969 ether;
    // receiver address of the team members
    address[3] public receiverAddresses;
    // details of funds received by team member
    mapping(address => TeamMember) public team;
}
