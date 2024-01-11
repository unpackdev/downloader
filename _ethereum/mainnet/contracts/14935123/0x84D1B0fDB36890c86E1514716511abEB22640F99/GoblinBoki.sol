//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "Ownable.sol";
import "Pausable.sol";
import "PaymentSplitter.sol";
import "ERC721A.sol";


contract GoblinBoki is ERC721A, Ownable, Pausable, PaymentSplitter {

    // maximum number of items in the collection
    uint256 constant public COLLECTION_MAX_ITEMS = 5555;
    // number of items that can be minted for free
    uint256 constant public FREE_MINT = 1111;

    // maximum number of mints per transaction during free minting...
    uint256 public maxMintsPerTxFree = 2;
    // ... and after.
    uint256 public maxMintsPerTxPostFree = 5;

    // price of one NFT in wei after free minting period
    uint256 public price = 0.006 ether;

    // UTC timestamp when minting starts
    uint256 public startingTime;

    // when `true`, `specialMint` cannot longer be called
    bool public specialMintLocked;

    // URI used to prefix token URI
    string internal __baseURI;


    constructor(string memory name_,
                string memory symbol_,
                uint256 startingTime_,
                string memory _baseURI_,
                address[] memory payees_,
                uint256[] memory shares_)
                ERC721A(name_, symbol_)
                PaymentSplitter(payees_, shares_) {
        startingTime = startingTime_;
        __baseURI = _baseURI_;
    }


    /**
     * Unrestricted functions.
     */

    /**
     * Returns the total amount of tokens minted in the contract.
     */
     function totalMinted() external view returns(uint256) {
         return _totalMinted();
     }


    /**
     * @dev Safely mints an amount of tokens equal to `_numToMint` to `msg.sender`.
     */
    function mint(uint256 _numToMint) external payable whenNotPaused {
        require(block.timestamp >= startingTime, "!grrr");

        require(_numToMint > 0, "cannot mint 0");
        require(_numToMint + _totalMinted() <= COLLECTION_MAX_ITEMS,
                        "would exceed max supply");

        // free and post-free minting cannot overlap.
        if (_totalMinted() < FREE_MINT){
            // free mint
            require(_numToMint <= maxMintsPerTxFree, "limit on minting too many free items at once");
            require(_numToMint + _totalMinted() <= FREE_MINT, "free and post-free mint cannot overlap");
        } else {
            // post-free mint
            require(_numToMint <= maxMintsPerTxPostFree, "limit on minting too many items at a time");
            require((_numToMint * price) <= msg.value, "!value");
        }

        _safeMint(msg.sender, _numToMint);
    }


    /**
     * @dev Burns `tokenId`. See {ERC721A-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    /**
     * @dev Returns `__baseURI`.
     */
    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }


    /**
     * Restricted functions.
     */

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public override {
        require(msg.sender == address(account), "msg.sender != account");
        super.release(account);
    }

     /**
     * @dev Minting, at no cost, a quantity of items as defined by the array `amounts`
     * to an array of `recipients`. This function can only be called by the `owner`
     * while `specialMintLocked` evaluates to `false`.
     */
    function specialMint(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(!specialMintLocked, "special mint permanently locked");
        require(recipients.length == amounts.length, "arrays have different lengths");

        for(uint256 i=0; i < recipients.length; i++){
            _safeMint(recipients[i], amounts[i]);
        }

        require(_totalMinted() <= COLLECTION_MAX_ITEMS, "would exceed max supply");
    }


    /**
     * @dev Sets the starting time of the minting period.
     */
    function setStartingTime(uint256 _startingTime) external onlyOwner {
        startingTime = _startingTime;
    }


    /**
     * @dev Sets the maximum number of items that can be minted at once during the free mint period.
     */
    function setMaxMintsPerTxFree(uint256 _newMaxMintsPerTxFree) external onlyOwner {
        maxMintsPerTxFree = _newMaxMintsPerTxFree;
    }


    /**
     * @dev Sets the maximum number of items that can be minted at once post free mint period.
     */
    function setMaxMintsPerTxPostFree(uint256 _newMaxMintsPerTxPostFree) external onlyOwner {
        maxMintsPerTxPostFree = _newMaxMintsPerTxPostFree;
    }

    /**
     * @dev Permanently prevents the `owner` from calling `specialMint`.
     */
    function lockSpecialMint() external onlyOwner {
        specialMintLocked = true;
    }

    /**
     * @dev Sets the base URI.
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        __baseURI = _newBaseURI;
    }

    /**
     * @dev Pauses functions modified with `whenNotPaused`.
     */
    function pause() external virtual whenNotPaused onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses functions modified with `whenNotPaused`.
     */
    function unpause() external virtual whenPaused onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets the price in wei per item. Price can be 0.
     */
    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }
}