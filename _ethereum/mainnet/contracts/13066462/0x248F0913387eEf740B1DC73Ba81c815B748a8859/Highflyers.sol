// Highflyers.sol
//
// degenerated.io // 2021 // zpm@
//
// SPDX-License-Identifier: MIT
// if you're looking to reuse this contract and have any questions, just lmk

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Counters.sol";

contract Highflyers is ERC721 {

    // counters is a safe way of counting that can only be +/- by one
    // https://docs.openzeppelin.com/contracts/4.x/api/utils#Counters
    using Counters for Counters.Counter;
    Counters.Counter private _tokensIssuedCounter;

    // traditionally we'd include SafeMath here, but safemath is no longer necessary in solidity 0.8.0+
    // https://docs.openzeppelin.com/contracts/4.x/api/utils
    // using SafeMath for uint256;

    uint256 private constant MAX_TOKENS = 6969;
    uint256 private constant MAX_MINTABLE_AT_ONCE = 20; // total tokens, so 10 pair

    // this pricing scheme is degenerate ;)
    // pricing equation is: 0.015E + 0.027E * num_pairs, which results in
    //    1 = (0.015 + 0.027 * 1) = 0.0420
    //    2 = (0.015 + 0.027 * 2) = 0.0690
    //    n = (0.015 + 0.027 * n) = (etc)
    // hehehehe
    uint256 private constant BASE_PRICE_PER_MINT = 15 * 10**15; // .027,000,000,000,000,000 eth in wei
    uint256 private constant PRICE_PER_PAIR = 27 * 10**15; // .027,000,000,000,000,000 eth in wei
    uint256 private constant TOKENS_PER_PAIR = 2; // derp

    // these are private because we write getters for them, no need to make them readable as-is
    string private _baseTokenURI;
    bool private _contractIsPaused;
    address private _ownerAddress;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // core contract logic

    constructor() ERC721("Highflyers", "HIGHFLYERS") {

        _baseTokenURI = "https://degenerated.io/nft/highflyer/";
        _ownerAddress = msg.sender; // deployer is permanent owner
        _contractIsPaused = false;

        // mint the first three tokens to the contract owner
        // (1) we have an odd number of tokens but mint in pairs, so an odd offset is necessary
        // (2) these tokens don't want to be alone, so can't mint just one
        // (3) we'll save these for a special giveaway
        _mintWithChecks(_ownerAddress, 3);

        // after initial mint, ensure we deploy as paused
        _contractIsPaused = true;

    }

    // fyi: this used to have address mintAddress as an argument, but instead, we opted to simplify this function and
    // just mandate that the minted tokens are deposited back into the account that is paying for the mint (msg.sender)
    function mint(uint256 numberOfPairsToMint) public payable {

        // this is the public mint function, so check two things:
        // (1) require contract is not paused
        // (2) that the message contains enough ETH to perform the mint
        require(!_contractIsPaused, "Yo, can't mint while paused");
        require(msg.value >= (BASE_PRICE_PER_MINT + (numberOfPairsToMint * PRICE_PER_PAIR)),
            "Yo, you gotta pay at least the minimum"
        );

        // mint
        _mintWithChecks(msg.sender, numberOfPairsToMint * TOKENS_PER_PAIR);

    }

    // the contract-specific function called by both ownerMintAirdrop() and public payable mint()
    //
    // IMPORTANT: this function takes the ACTUAL number of tokens to mint, notably, it is not aware of any pair minting
    // so the mint() and ownerMintAirdrop() functions MUST do the *2 adjustment in their own functions to mint pairs
    function _mintWithChecks(address mintAddress, uint256 numberOfTokensToMint) internal {

        require(numberOfTokensToMint <= MAX_MINTABLE_AT_ONCE, "Yo, can't mint that many at once");

        for (uint256 mt = 0; mt < numberOfTokensToMint; mt++) {

            // check within the loop to protect against reentrancy
            require(getIssuedTokenCount() < MAX_TOKENS, "Yo, can't mint more than is available");

            // increment before minting: starts token ids at 1 instead of 0 (which is desired)
            // also follows checks-effects-interactions pattern
            _tokensIssuedCounter.increment();

            // use _mint here instead of _safeMint, since _safeMint allows reentrancy into the mint function from the
            // onERC721Received receiver in the remote contract. using _mint means you could mint to a contract address
            // that doesn't accept ERC721 tokens, but if someone mints to a non-ERC721 accepting address, that's on them
            _mint(mintAddress, getIssuedTokenCount());
        }

    }

    // override the _beforeTokenTransfer hook to check our local paused variable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {

        require(!_contractIsPaused, "Yo, can't transfer a token when the contract is paused");
        super._beforeTokenTransfer(from, to, tokenId);

    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // simple getters

    // this overrides the inherited _baseURI(), which is used to construct the token uri. honestly, this seems like a
    // weird way to do this but seems to be a good solution without making the entire contract inherit ERC721URIStorage
    function _baseURI() internal override view returns (string memory) {
        return _baseTokenURI;
    }

    function getIssuedTokenCount() public view returns (uint256) {
        return _tokensIssuedCounter.current();
    }

    function getContractIsPaused() public view returns (bool) {
        return _contractIsPaused;
    }

    // this is necessary to be able to edit the collection on opensea; it's a simple way to enable this functionality
    // without making the entire contract inherit ERC721Ownable, which has a bunch of functions we don't need
    function owner() public view returns (address) {
        return _ownerAddress;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // owner management functions

    modifier ownerOnlyACL() {
        require(msg.sender == _ownerAddress, "Yo, have to be the owner to call this");
        _;
    }

    // set a new base token URI, in case metadata/image provider changes
    function ownerSetBaseTokenURI(string memory newBaseTokenURI) public ownerOnlyACL {
        _baseTokenURI = newBaseTokenURI;
    }

    // set paused state
    function ownerSetPausedState(bool contractIsPaused) public ownerOnlyACL {
        _contractIsPaused = contractIsPaused;
    }

    // owner manual mint (airdrop) ability, for free, regardless if contract is paused or not
    function ownerMintAirdrop(address mintAddress, uint256 numberOfPairsToMint) public ownerOnlyACL {

        bool tempContractIsPaused = _contractIsPaused;
        _contractIsPaused = false;

        _mintWithChecks(mintAddress, numberOfPairsToMint * TOKENS_PER_PAIR);

        _contractIsPaused = tempContractIsPaused;

    }

    // simplified withdraw function callable by only the owner that withdraws to the owner address. there are no
    // internal state changes here, and it can only be called by owner, so this should(?) be safe from reentrancy
    function ownerWithdrawContractBalance() public ownerOnlyACL {

        uint256 balance = address(this).balance;
        require(balance > 0, "Yo, don't waste your gas trying to withdraw a zero balance");

        // withdraw
        (bool withdrawSuccess, ) = msg.sender.call{value: balance}("");

        // this should never happen? but including in case so all state is reverted
        require(withdrawSuccess, "Yo, withdraw failed, reverting");

    }

}
