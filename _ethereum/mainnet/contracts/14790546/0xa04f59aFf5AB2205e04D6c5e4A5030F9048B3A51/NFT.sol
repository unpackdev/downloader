// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./OwnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./Initializable.sol";
import "./WhitelistManager.sol";

/**
 *
 */
contract NFT is Initializable, OwnableUpgradeable, ERC721EnumerableUpgradeable, WhitelistManager {
    using AddressUpgradeable for address;
    using StringsUpgradeable for string;

    /* Events **************************************************************************************************************************/

    event SetMintAccessMode(MintAccessMode _mintAccessMode, uint256 _price);
    event MintingPaused();
    event MintingUnpaused();

    /* General configuration ***********************************************************************************************************/

    // max NFT supply
    uint256 public maxSupply;

    // price for minting a single NFT
    uint256 price;

    // the wallet receiving the NFT payment
    address payable public mainWallet;

    // the wallet receiving a part of the payment
    address payable public wallet2;

    // percentage going to wallet2
    uint256 percentageToWallet2;

    // base token uri
    string public baseTokenURI;

    /* Minting configuration ***********************************************************************************************************/

    // if true, minting is paused
    bool mintingPaused;

    // number of tokens minted so far, by anyone
    uint256 public mintedCount;

    // how many NFT a user can mint at once
    uint256 public maxCountPerMint;

    /*
     * How many NFT a user can mint overall (useful during whitelist)
     * Notes:
     *  - if >= 0, limit is applied
     *  - if < 0 (in particular -1), there's no limit on how many NFTs a user can mint (overall, not in a single mint)
     *  - if mintAccessMode is Whitelist, it considers the number of minted NFTs during that whitelist
     */
    int256 private maxMintablePerUser;

    /*
     * Pause automatically the minting when a given number of minted tokens is reached
     * eg. if 100: when 100 tokens are minted the minting is automatically paused
     *
     * Notes:
     *  - if >= 0, it pauses the minting as soon as mintedCount reaches the limit
     *    (if the minting is active and the limit was previously reached, it does nothing)
     *  - if < 0 (in particular -1 is used to indicate there's no limit), automatic pausing will never be applied
     */
    int256 public pauseAfterMintingTokenCount;

    // minting access mode (DEFAULT = open minting, WHITELIST = with whitelist)
    enum MintAccessMode{ DEFAULT, WHITELIST }
    MintAccessMode mintAccessMode;

    /************************************************************************************************************************************
     * INITIALIZER
     ***********************************************************************************************************************************/

    /**
     *
     */
    function initialize(string memory _name, string memory _symbol, uint256 _price, uint256 _maxSupply, address payable _mainWallet, address payable _wallet2) public initializer {
        OwnableUpgradeable.__Ownable_init();
        ERC721Upgradeable.__ERC721_init(_name, _symbol);

        // initial values
        maxCountPerMint = 10;
        maxMintablePerUser = -1;
        pauseAfterMintingTokenCount = -1;
        percentageToWallet2 = 600;

        //
        maxSupply = _maxSupply;
        setMainWallet(_mainWallet);
        setWallet2(_wallet2);

        // minting is initially paused
        _pauseMinting();

        // default Mode is set
        setMintAccessModeDefault(_price, -1, -1, false);
    }

    /************************************************************************************************************************************
     * MINT
     ***********************************************************************************************************************************/

    /**
     * Mint of NFTs
     *
     * @param _count number of NFT to mint
     * @param merkleProof used only when mintAccessMode is WHITELIST, can be anything (eg. empty string) otherwise
     */
    function mint(uint256 _count, bytes32[] calldata merkleProof) public payable {
        address _to = msg.sender;
        uint256 _previousMintedCount = mintedCount;
        int256 _maxMintableTokensCountPerUser = getMaxMintableTokensCountPerUser(_to);

        // check number of NFT to mint
        _checkMintableCount(_count);
        require(_count <= maxCountPerMint, "Cannot mint more than allowed at once.");

        // check collection supply limit
        require(_count <= countRemainingTokens(), "There are not so many NFTs available to mint.");

        // handle mode "whitelist"
        if (isMintAccessModeWhitelist()) {
            require(WhitelistManager._isMsgSenderWhitelisted(merkleProof), "You are not whitelisted.");
        }

        // check minting paused after limit
        if (pauseAfterMintingTokenCount >= 0 && _previousMintedCount < uint256(pauseAfterMintingTokenCount)) {
            require(uint256(pauseAfterMintingTokenCount) >= mintedCount + _count, "Minting would be paused before completion.");
        }

        // check per user limit
        if (_maxMintableTokensCountPerUser >= 0) {
            require(_count <= uint256(_maxMintableTokensCountPerUser), "You cannot mint more NFT currently.");
        }

        /**
         * calculate total price
         */
        uint256 _mintingPrice = calculatePricePerMint(_count);
        require(msg.value >= _mintingPrice, "Insufficient amount of ETH.");

        /**
         * mint
         */
        _mintMultiple(_count, _to);

        /**
         * handle payment
         */
        _handleNFTPayment(_mintingPrice);

        /**
         * if msg.value is larger than the amount to pay, give the exceeding back to sender
         */
        uint256 _exceedingAmount = msg.value - _mintingPrice;

        if (_exceedingAmount > 0) {
            _transferToWallet(_exceedingAmount, payable(_to));
        }

        // pause minting if minted count is greater then limit to pause
        if (pauseAfterMintingTokenCount > 0 && _previousMintedCount < uint256(pauseAfterMintingTokenCount) && mintedCount >= uint256(pauseAfterMintingTokenCount)) {
            _pauseMinting();
        }
    }

    /**
     * Mint enabled to Smart Contract owner only
     */
    function mintByOwner(uint256 _count, address _receiver) public onlyOwner {
        _checkMintableCount(_count);

        // handle "paused" status
        bool _initiallyPaused = isMintingPaused();

        if (_initiallyPaused) {
            _unpauseMinting();
        }

        // mint
        _mintMultiple(_count, _receiver);

        // restore "paused" status
        if (_initiallyPaused && !isMintingPaused()) {
            _pauseMinting();
        }
    }

    /**
     * Mint multiple NFT at a time
     */
    function _mintMultiple(uint256 _count, address _to) internal {
        for (uint i = 0; i < _count; i++) {
            _mintSingle(_to);
        }
    }

    /**
     * Mint a single NFT
     */
    function _mintSingle(address _to) internal mintingNotPaused {
        // check collection supply limit
        require(maxSupply >= mintedCount + 1, "Max supply reached.");

        // generate token id and mint
        uint256 _tokenId = mintedCount++;
        _safeMint(_to, _tokenId);

        // handle mode "whitelist"
        if (isMintAccessModeWhitelist()) {
            // keep track of minted NFT for each user
            WhitelistManager._incrementTokensBalanceOfCurrentWhitelist(_to);
        }
    }

    /**
     * Check the number of NFT to mint
     */
    function _checkMintableCount(uint256 _count) internal view {
        require(_count > 0, "Cannot mint 0 NFTs.");
        require(maxSupply > mintedCount, "Max supply reached.");
        require(maxSupply >= mintedCount + _count, "Minting would exceed max supply.");
    }

    /**
     * Calculate the minting price for a given number of NFTs
     */
    function calculatePricePerMint(uint256 _count) public view returns (uint256) {
        return price * _count;
    }

    /**
     * Return the number of tokens left before reaching the total supply
     */
    function countRemainingTokens() public view returns (uint256) {
        if (pauseAfterMintingTokenCount > 0 && mintedCount <= uint256(pauseAfterMintingTokenCount)) {
            return uint256(pauseAfterMintingTokenCount) - mintedCount;
        }

        return maxSupply - mintedCount;
    }

    /**
     * Return the number of tokens that a single user can still mint overall (not in a single mint)
     */
    function getMaxMintableTokensCountPerUser(address _user) public view returns (int256) {
        if (maxMintablePerUser < 0) {
            return maxMintablePerUser;
        }

        uint256 _balance = balanceOf(_user);

        if (isMintAccessModeWhitelist()) {
            _balance = WhitelistManager._getTokenBalanceInCurrentWhitelist(_user);
        }

        //
        int256 _output = maxMintablePerUser - int256(_balance);

        if (_output <= 0) {
            return 0;
        }

        return _output;
    }

    /**
     * Return the list of Token IDs owned by _owner
     */
    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint _tokenCount = balanceOf(_owner);
        uint[] memory _tokensId = new uint256[](_tokenCount);

        for (uint i = 0; i < _tokenCount; i++) {
            _tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return _tokensId;
    }

    /**
     * Set the Mint access mode to DEFAULT
     */
    function setMintAccessModeDefault(uint256 _price, int256 _maxMintablePerUser, int256 _pauseAfterMintingTokenCount, bool _setMintingAsUnpaused) public onlyOwner {
        mintAccessMode = MintAccessMode.DEFAULT;

        _updateMintingConfiguration(_price, _maxMintablePerUser, _pauseAfterMintingTokenCount, _setMintingAsUnpaused);

        emit SetMintAccessMode(mintAccessMode, _price);
    }

    /**
     * Set the Mint access mode to WHITELIST
     */
    function setMintAccessModeWhitelist(uint256 _price, int256 _maxMintablePerUser, int256 _pauseAfterMintingTokenCount, bool _setMintingAsUnpaused, bool _startNewWhitelist) public onlyOwner {
        mintAccessMode = MintAccessMode.WHITELIST;

        _updateMintingConfiguration(_price, _maxMintablePerUser, _pauseAfterMintingTokenCount, _setMintingAsUnpaused);

        if (_startNewWhitelist == true) {
            startNewWhitelist();
        }

        emit SetMintAccessMode(mintAccessMode, _price);
    }

    /**
     * Update Minting configuration with various parameters
     */
    function _updateMintingConfiguration(uint256 _price, int256 _maxMintablePerUser, int256 _pauseAfterMintingTokenCount, bool _setMintingAsUnpaused) internal {
        price = _price;
        maxMintablePerUser = _maxMintablePerUser;
        pauseAfterMintingTokenCount = _pauseAfterMintingTokenCount;

        // unpause minting
        if (_setMintingAsUnpaused == true && isMintingPaused()) {
            _unpauseMinting();
        }
    }

    /************************************************************************************************************************************
     * PAYMENT UTILS
     ***********************************************************************************************************************************/

    /**
     * Handle the NFT payment
     */
    function _handleNFTPayment(uint256 _amount) internal {
        uint256 subtotalToWallet2 = _calculatePercentage(_amount, percentageToWallet2);
        uint256 subtotalToMainWallet = _amount - subtotalToWallet2;

        // transfer to main wallet
        if (subtotalToMainWallet > 0) {
            _transferToWallet(subtotalToMainWallet, mainWallet);
        }

        // transfer to wallet2
        if (subtotalToWallet2 > 0) {
            _transferToWallet(subtotalToWallet2, wallet2);
        }
    }

    /**
     * Perform an ETH transfer of a given amount
     */
    function _transferToWallet(uint256 _amount, address payable receiver) internal {
        (bool success, ) = receiver.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    /************************************************************************************************************************************
     * UTILS
     ***********************************************************************************************************************************/

    /**
     * Calculate the percentage of an amount
     *
     * @param percentage eg. 600 = 6%
     */
    function _calculatePercentage(uint256 amount, uint256 percentage) internal pure returns (uint256) {
        return amount * percentage / 10000;
    }

    /**
     * Check that minting is not paused at the moment
     */
    modifier mintingNotPaused {
        require(!isMintingPaused(), "Minting is paused.");
        _;
    }

    /**
     * Set the parameter "maxMintablePerUser"
     */
    function setMaxMintablePerUser(int256 _value) public onlyOwner {
        maxMintablePerUser = _value;
    }

    /************************************************************************************************************************************
     * WHITELIST UTILS
     ***********************************************************************************************************************************/

    /**
     * Return true if _address is whitelisted
     */
    function isWhitelisted(bytes32[] calldata merkleProof, address _address) public view returns(bool) {
        return WhitelistManager._isWhitelisted(merkleProof, _address);
    }

    /**
     * Update the whitelisted addresses
     */
    function setWhitelist(bytes32 _merkleRoot) external onlyOwner {
        WhitelistManager._setWhitelist(_merkleRoot);
    }

    /**
     * Start a new empty whitelist
     */
    function startNewWhitelist() public onlyOwner {
        WhitelistManager._startNewWhitelist();
    }

    /************************************************************************************************************************************
     * NFT
     ***********************************************************************************************************************************/

    /**
     * Return the token baseUri (internal)
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * Return the token baseUri
     */
    function getBaseURI() public view returns (string memory) {
        return _baseURI();
    }

    /**
     * Update the token baseUri
     */
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /**
     * Set the parameter "mainWallet"
     */
    function setMainWallet(address payable _address) public onlyOwner {
        mainWallet = _address;
    }

    /**
     * Set the parameter "wallet2"
     */
    function setWallet2(address payable _address) public onlyOwner {
        wallet2 = _address;
    }

    /**
     * Set the parameter "percentageToWallet2"
     */
    function setPercentageToWallet2(uint256 _value) public onlyOwner {
        require(_value <= 10000, "Percentage cannot exceed 100%.");

        percentageToWallet2 = _value;
    }

    /************************************************************************************************************************************
     * Minting
     ***********************************************************************************************************************************/

    /**
     * Set the parameter "price"
     */
    function setPrice(uint256 _amount) public onlyOwner {
        price = _amount;
    }

    /**
     * Set the parameter "maxCountPerMint"
     */
    function setMaxCountPerMint(uint256 _amount) public onlyOwner {
        maxCountPerMint = _amount;
    }

    /**
     * Set the parameter "pauseAfterMintingTokenCount"
     */
    function setPauseAfterMintingTokenCount(int256 _value) public onlyOwner {
        pauseAfterMintingTokenCount = _value;
    }

    /**
     * Return true if Minting is paused at the moment
     */
    function isMintingPaused() public view returns (bool) {
        return mintingPaused;
    }

    /**
     * Pause Minting
     */
    function pauseMinting() public onlyOwner {
        _pauseMinting();
    }

    /**
     * Pause Minting (internal)
     */
    function _pauseMinting() internal {
        mintingPaused = true;

        emit MintingPaused();
    }

    /**
     * Unpause Minting
     */
    function unpauseMinting() public onlyOwner {
        _unpauseMinting();
    }

    /**
     * Unpause Minting (internal)
     */
    function _unpauseMinting() internal {
        mintingPaused = false;

        emit MintingUnpaused();
    }

    /**
     * Return true if Mint access mode is DEFAULT
     */
    function isMintAccessModeDefault() public view returns (bool) {
        return mintAccessMode == MintAccessMode.DEFAULT;
    }

    /**
     * Return true if Mint access mode is WHITELIST
     */
    function isMintAccessModeWhitelist() public view returns (bool) {
        return mintAccessMode == MintAccessMode.WHITELIST;
    }

    /************************************************************************************************************************************
     *
     ***********************************************************************************************************************************/

    /**
     * Return a handy array of information about the configured values
     */
    function getInfo() public view returns (bool, bool, bool, uint256, uint256, uint256, uint256) {
        return (
            isMintAccessModeDefault(),
            isMintAccessModeWhitelist(),
            isMintingPaused(),
            maxSupply,
            mintedCount,
            countRemainingTokens(),
            maxCountPerMint
        );
    }
}
