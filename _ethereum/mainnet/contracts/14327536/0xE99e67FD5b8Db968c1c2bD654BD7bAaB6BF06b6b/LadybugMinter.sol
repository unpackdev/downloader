// The tokens of this contract are licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License (https://creativecommons.org/licenses/by-nc-sa/4.0/)
// SPDX-License-Identifier:  CC-BY-NC-SA-4.0
pragma solidity ^0.8.0;

import "./LadybugFinances.sol";


/**
 * @author WrightCode
 * @title Ladybug Minter
 * @dev Controls the information around minting and mint-related data
 */
contract LadybugMinter is LadybugFinances {

    uint private constant DROP_TIME_TOLERANCE = 1728000; // (60*60*24)*20 = 20 days
    uint private constant PRICE_TIME_TOLERANCE = 864000; // (60*60*24)*10 = 10 days

    bool private initialized;

    mapping(uint16 => uint16) private _randomized;

    /**
     * @dev Shuffle the deck, then premint to dev and owner accounts.
     */
    function initialize() external onlyOwner {
        require(!initialized, "Contract already initialized");
        initialized = true;

        // the development team will get a handful of preminted (but random, shuffled) nfts...
        for (uint i = 0; i < _RESERVED_LADYBUGS_DEVELOPMENT; i++) {
            _mintInternal(_developmentTeamAddress);
        }
        // ...as will the owner of the contract
        for (uint i = 0; i < _RESERVED_LADYBUGS_OWNER; i++) {
            _mintInternal(owner());
        }

        // prepare the drops
        _initializeDrops();
    }

    /**
     * @dev Mint the remaining bugs in drop to owner if "stalled out".
     *
     * The drop is considered stalled if the drop began more than DROP_TIME_TOLERANCE days ago,
     * the price is less than 0.01 ETH and has been at that price for more than PRICE_TIME_TOLERANCE days.
     *
     * The idea being that if no one is minting the ladybugs after the price has been lowered,
     * then the owner may mint them.
     *
     * Please do not let them stall out, these ladybugs need new greener gardens.
     *
     * In other words, I will not abandon my ladybugs.
     */
    function mintStalledDropToOwner() external onlyOwner {
        (uint _index, bool _active, ) = _status();
        require (_active, "Drop not active");
        require (drops[_index].price <= 0.01 ether, "Price too high");
        require (drops[_index].date < block.timestamp - DROP_TIME_TOLERANCE, "Drop not active long enough");
        require (drops[_index].priceDate < block.timestamp - PRICE_TIME_TOLERANCE, "Price not active long enough");
        for (uint i = _currentSupplyIndex(); i < drops[_index].startAtIndex + _TOKENS_PER_DROP; i++) {
            _mintStalled(owner());
        }
    }

    /**
     * @dev Count the current number of ladybugs minted.
     */
    function totalMinted() external view returns (uint) {
        return _currentSupplyIndex();
    }

    /**
     * @dev Count the remaning, unminted ladybugs.
     */
    function unminted() external view returns (uint) {
        return uint(_MAX_LADYBUGS) - _currentSupplyIndex();
    }

    /**
     * @dev Mint the ERC 721 ladybug token, transfer it to the recipient.
     * The drop must be active and the payment must be above the specified drop price.
     */
    function mint(address recipient) external payable returns (uint) {
        // if there's no active drop, error is thrown
        (uint _index, bool _active, ) = _status();
        require (_active, "Drop not active");
        require (msg.value >= drops[_index].price, "Offer lower than price");
        return _mintInternal(recipient);
    }

    /**
     * @dev I believe this is necessary for OpenSea, there's no trailing slash.
     * The CID is the directory containing the nft metadata.
     */
    function contractURI() public pure returns (string memory) {
        // todo https://docs.opensea.io/docs/contract-level-metadata
        // this is the pinata directory of the numbers metadata
        return "ipfs://QmP6wnMSYwzEQHWgBZobKF2drEr4GpE66w9jN1p3HDwhUe";
    }

    /**
     * @dev Method used internally to construct the path to the token's metadata (json).
     * This is an ipfs uri with a trailing slash.
     */
    function _baseURI() internal virtual override pure returns (string memory) {
        return "ipfs://QmP6wnMSYwzEQHWgBZobKF2drEr4GpE66w9jN1p3HDwhUe/";
    }

    /**
     * @dev Mint the ERC 721 ladybug token, transfer it to the recipient.
     *
     * This is a very simple distribution of the bugs, they're not part of a great reveal,
     * we're not looking to game anyone, they simply want a good home with someone that'll
     * appreciate them.
     *
     * The goal is to mint the ladybugs in a non-sequential order.  To do so, I'm adding a
     * little "randomness" on each mint.  It's by no means perfect or unpredicatable, but
     * that's the scope of this project.
     *
     * Perhaps my next project, with a larger budget, will merit a more challenging and
     * sophisticted mint.  That would be a lot of fun to work on.
     *
     * Until then, enjoy the bugs as they are, they're ready to fly.
     */
    function _mintInternal(address recipient) internal returns (uint) {
        // the tokens are 1.._MAX_LADYBUGS (i.e. not zero-based)
        uint16 _index = uint16(_currentSupplyIndex() + 1);
        uint newItemId;

        // check if this index is part of the mapping
        if (_randomized[_index] != 0) {
            newItemId = _randomized[_index];
            // it would be nice to remove the entry from _randomized after retrieving the value, 
            // but the gas was too expensive and so i chose not not, on behalf of the minter
        } else {
            uint16 n = uint16(_index + uint256(keccak256(abi.encodePacked(block.timestamp))) % (_MAX_LADYBUGS - _currentSupplyIndex()));
            // if the random number is not already holding a swap, use it ...
            if (_randomized[n] == 0 && _index != n) {
                _randomized[n] = _index;
                newItemId = n;
            } else {
                // ... else just use the index, the random swap (n) already has a value
                newItemId = _index;
            }
        }

        _mint(recipient, newItemId);
        // increment the supply counter
        _incrementCurrentSupplyIndex();
        return newItemId;
    }

    /**
     * @dev Mint the stalled-out ERC 721 ladybug tokens, transfer it to the recipient.
     * Gas is expensive in this process, so we'll look at any previously "randomized"
     * elements and use them, otherwise, we'll just go in order to reduce gas prices.
     */
    function _mintStalled(address recipient) internal returns (uint) {
        // get the mint id from the shuffled array (it's zero based)
        uint16 _index = uint16(_currentSupplyIndex() + 1);
        uint newItemId;

        // check if this index is part of the mapping
        if (_randomized[_index] != 0) {
            newItemId = _randomized[_index];
            // it would be nice to remove the entry from _randomized after retrieving the value, 
            // but the gas was too expensive and so i chose not not, on behalf of the minter
        } else {
            // ... else just use the index, it's too expensive in gas, to randomize here
            newItemId = _index;
        }

        _mint(recipient, newItemId);
        // increment the supply counter
        _incrementCurrentSupplyIndex();
        return newItemId;
    }

}
