pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ClaimableByPreviousOwners.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract CrumliasbakeryMinting is ERC721Enumerable {
    function _mintToken(address owner, uint256 startingIndex, uint16 number) internal {
        for (uint i = 0; i < number; i++) {
            _safeMint(owner, startingIndex + i);
        }
    }
}

abstract contract CrumliasbakerySelling is CrumliasbakeryMinting, Pausable, ContextMixin, NativeMetaTransaction, ClaimableByPreviousOwners, PausableClaim {
    uint256 constant maxToken = 5555;
    uint constant sellableTokensStartingIndex = 1101;
    uint constant giveawayTokenStartingIndex = 1001;
    uint constant claimTokenStartingIndex  = 1;
    uint16 constant maxTokensToBuyAtOnce = 20;

    uint constant singleTokenPrice = 50000000 gwei;  // 0.05 eth for one crumlia

    uint256 public nextTokenForSale;
    uint public nextTokenToGiveaway;
    uint public nextClaimToken;

    constructor() {
        nextTokenForSale = sellableTokensStartingIndex;
        nextTokenToGiveaway = giveawayTokenStartingIndex;
        nextClaimToken    = claimTokenStartingIndex;
    }

    function claim() public whenClaimNotPaused {
        uint16 tokensToMint = howManyFreeTokens();

        require(tokensToMint > 0, "You cannot claim tokens");
        require(leftForClaim() >= tokensToMint, "Not enough tokens left for claim");
        _mintToken(msg.sender, nextClaimToken, tokensToMint);
        cannotClaimAnymore(msg.sender);

        nextClaimToken += tokensToMint;
    }

    function buy(uint16 tokensToBuy) public payable whenNotPaused {
        require(tokensToBuy > 0, "Cannot buy 0 tokens");
        require(leftForSale() >= tokensToBuy, "Not enough tokens left on sale");
        require(tokensToBuy <= maxTokensToBuyAtOnce, "Cannot buy that many tokens at once");
        require(msg.value >= singleTokenPrice * tokensToBuy, "Insufficient funds sent.");
        _mintToken(msg.sender, nextTokenForSale, tokensToBuy);

        nextTokenForSale += tokensToBuy;
    }

    function leftForSale() public view returns(uint256) {
        return maxToken - nextTokenForSale;
    }

    function leftForGiveaway() public view returns(uint) {
        return sellableTokensStartingIndex - nextTokenToGiveaway;
    }

    function leftForClaim() public view returns(uint) {
        return giveawayTokenStartingIndex - nextClaimToken;
    }

    function giveaway(address to) public onlyOwner {
        require(leftForGiveaway() >= 1);
        _mintToken(to, nextTokenToGiveaway++, 1);
    }

    function startSale() public onlyOwner whenPaused {
        _unpause();
    }

    function pauseSale() public onlyOwner whenNotPaused {
        _pause();
    }

    function pauseClaim() public onlyOwner whenClaimNotPaused {
        _pauseClaim();
    }

    function unpauseClaim() public onlyOwner whenClaimPaused {
        _unpauseClaim();
    }
}

contract Crumliasbakery is CrumliasbakerySelling {
    string _provenanceHash;
    string baseURI_;
    address proxyRegistryAddress;
    string _contractURI;
    address devsAddress;

    constructor(address _proxyRegistryAddress) ERC721("Crumlias Bakery", "CB") {
        proxyRegistryAddress = _proxyRegistryAddress;
        _pause();
        setBaseURI("https://crumliasbakery.herokuapp.com/api/metadata/");
        setContractURI("https://crumliasbakery.herokuapp.com/contract");
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory contractURI_) public onlyOwner {
        _contractURI = contractURI_;
    }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        uint forDevs = balance / 2;  // 50% for devs
        uint forOwner = balance - forDevs;
        payable(msg.sender).transfer(forOwner);
        payable(devsAddress).transfer(forDevs);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        _provenanceHash = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseURI_ = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI_;
    }

    function isApprovedOrOwner(address target, uint256 tokenId) public view returns (bool) {
        return _isApprovedOrOwner(target, tokenId);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function tokensInWallet(address wallet) public view returns (uint256[] memory) {
        uint256[] memory tokens = new uint256[](balanceOf(wallet));

        for (uint i = 0; i < tokens.length; i++) {
            tokens[i] = tokenOfOwnerByIndex(wallet, i);
        }

        return tokens;
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Crumliasbakery: caller is not owner nor approved");
        _burn(tokenId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}
