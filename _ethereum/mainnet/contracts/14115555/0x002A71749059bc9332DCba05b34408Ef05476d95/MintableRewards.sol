// SPDX-License-Identifier: MIT

/**
 * ░█▄ █▒█▀░▀█▀  ▒█▀▄▒██▀░█ ░▒█▒▄▀▄▒█▀▄░█▀▄░▄▀▀
 * ░█▒▀█░█▀ ▒█▒▒░░█▀▄░█▄▄░▀▄▀▄▀░█▀█░█▀▄▒█▄▀▒▄██
 *
 * Made with 🧡 by Kreation.tech
 */
pragma solidity ^0.8.9;

import "./ERC721Upgradeable.sol";
import "./IERC2981Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./StringsUpgradeable.sol";

import "./IMintableEditions.sol";
import "./AllowancesStore.sol";

/**
 * This contract allows dynamic NFT minting.
 * 
 * Operations allow for selling publicly, partial or total giveaways, direct giveaways and rewardings.
 */
contract MintableRewards is ERC721Upgradeable, IERC2981Upgradeable, IMintableEditions, OwnableUpgradeable {
    
    using CountersUpgradeable for CountersUpgradeable.Counter;
    
    event PriceChanged(uint256 amount);
    event EditionSold(uint256 price, address owner);
    event SharesPaid(address to, uint256 amount);

    struct Shares {
        address payable holder;
        uint16 bps;
    }

    struct Allowance {
        address minter;
        uint16 amount;
    }

    struct Info {
        // name of rewards
        string name;
        // symbol of the tokens minted by this contract
        string symbol;
        // content URL of the token editions
        string contentUrl;
        // SHA256 of the token rewards content in bytes32 format (0xHASH)
        bytes32 contentHash;
        // token rewards metadata URL
        string metadataUrl;
    }

    // token id counter
    CountersUpgradeable.Counter private counter;

    // token content URL
    string public contentUrl;
    // hash for the associated content
    bytes32 public contentHash;
    // token metadata URL
    string public metadataUrl;
    
    // the number of editions this contract can mint
    uint64 public size; // 8
    
    // royalties ERC2981 in bps
    uint16 public royalties; // 2

    address public allowancesRef; // 20

    // addresses allowed to mint rewards
    mapping(address => uint16) private allowedMinters;

    // price for sale
    uint256 public price;

    // contract shareholders and shares information
    address[] private shareholders;
    mapping(address => uint16) public shares;

    // shares withdrawals
    uint256 private withdrawn;
    mapping(address => uint256) private withdrawals;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer { }

    /**
     * Creates a new edition and sets the only allowed minter to the address that creates/owns the edition: this can be re-assigned or updated later.
     * 
     * @param _owner can authorize, mint, gets royalties and a dividend of sales, can update the content URL.
     * @param _info token properties
     * @param _size number of NFTs that can be minted from this contract: set to 0 for unbound
     * @param _price sale price in wei
     * @param _royalties perpetual royalties paid to the creator upon token selling
     * @param _shares array of tuples listing the shareholders and their respective shares in bps (one per each shareholder)
     * @param _allowancesRef contract address storing array of tuples listing the allowed minters and their allowances
     */
    function initialize(
        address _owner,
        Info memory _info,
        uint64 _size,
        uint256 _price,
        uint16 _royalties,
        Shares[] memory _shares,
        address _allowancesRef
    ) public initializer {
        __ERC721_init(_info.name, _info.symbol);
        __Ownable_init();

        transferOwnership(_owner); // set ownership
        require(bytes(_info.contentUrl).length > 0, "Empty content URL");
        contentUrl = _info.contentUrl;
        contentHash = _info.contentHash;
        require(bytes(_info.metadataUrl).length > 0, "Empty metadata URL");
        metadataUrl = _info.metadataUrl;
        size = _size;
        price = _price;
        require(_allowancesRef != address(0x0), "Allowances: invalid reference");
        allowancesRef = _allowancesRef;
        counter.increment(); // token ids start at 1

        require(_royalties < 10_000, "Royalties too high");
        royalties = _royalties;
        
        uint16 _totalShares;
        for (uint256 i = 0; i < _shares.length; i++) {
            _addPayee(_shares[i].holder, _shares[i].bps);
            _totalShares += _shares[i].bps;
        }
        require(_totalShares < 10_000, "Shares too high");
        _addPayee(payable(_owner), 10_000 - _totalShares);
    }

    function _addPayee(address payable _account, uint16 _shares) internal {
        require(_account != address(0), "Shareholder is zero address");
        require(_shares > 0 && _shares <= 10_000, "Shares are invalid");
        require(shares[_account] == 0, "Shareholder already has shares");

        shareholders.push(_account);
        shares[_account] = _shares;
    }

    /**
     * Returns the number of tokens minted so far 
     */
     function totalSupply() public view returns (uint256) {
        return counter.current() - 1;
    }

    /**
     * Basic ETH-based sales operation, performed at the given set price.
     * This operation is open to everyone as soon as the salePrice is set to a non-zero value.
     */
    function purchase() external payable returns (uint256) {
        require(price > 0, "Not for sale");
        require(msg.value == price, "Wrong price");
        address[] memory toMint = new address[](1);
        toMint[0] = msg.sender;
        emit EditionSold(price, msg.sender);
        return _mintEditions(toMint);
    }

    /**
     * This operation sets the sale price, thus allowing anyone to acquire a token from this edition at the sale price via the purchase operation.
     * Setting the sale price to 0 prevents purchase of the tokens which is then allowed only to permitted addresses.
     * 
     * @param _wei if sale price is 0, no sale is allowed, otherwise the provided amount of WEI is needed to start the sale.
     */
    function setPrice(uint256 _wei) external onlyOwner {
        price = _wei;
        emit PriceChanged(price);
    }

    function allowanceOf(address minter) public view returns (uint16) {
        if (minter == address(0x0)) return allowedMinters[address(0x0)];
        return AllowancesStore(allowancesRef).allowances(minter) - allowedMinters[minter];
    }

    function allowPublic(bool allow) external onlyOwner {
        allowedMinters[address(0x0)] = allow ? 1 : 0;
    }

    /**
     * Transfers all ETHs from the contract balance to the owner and shareholders.
     */
    function shake() external {
        for (uint i = 0; i < shareholders.length; i++) {
            _withdraw(payable(shareholders[i]));
        }
    }

    /**
     * Transfers `withdrawable(msg.sender)` to the caller.
     */
    function withdraw() external {
        _withdraw(payable(msg.sender));
    }

    /**
     * Returns how much the account can withdraw from this contract.
     */
    function withdrawable(address payable _account) external view returns (uint256) {
        uint256 _totalReceived = address(this).balance + withdrawn;
        return (_totalReceived * shares[_account]) / 10_000 - withdrawals[_account];
    }

    /**
     * INTERNAL: attempts to transfer part of the contract balance to the caller, provided the account is a shareholder and
     * on the basis of its shares and previous withdrawals.
     *
     * @param _account the address of the shareholder to pay out
     */
    function _withdraw(address payable _account) internal {
        uint256 _amount = this.withdrawable(_account);
        require(_amount != 0, "Account is not due payment");
        withdrawals[_account] += _amount;
        withdrawn += _amount;
        AddressUpgradeable.sendValue(_account, _amount);
        emit SharesPaid(_account, _amount);
    }

    /**
     * INTERNAL: checks if the msg.sender is allowed to mint.
     */
    function _isAllowedToMint(uint16 amount) internal view returns (bool) {
        return (owner() == msg.sender) || _isPublicAllowed() || allowedMinters[msg.sender] + amount <= AllowancesStore(allowancesRef).allowances(msg.sender);
    }
    
    /**
     * INTERNAL: checks if the ZeroAddress is allowed to mint.
     */
    function _isPublicAllowed() internal view returns (bool) {
        return (allowedMinters[address(0x0)] > 0);
    }

    function _consumeAllowance(uint16 amount) internal {
        allowedMinters[msg.sender] += amount;
    }

    /**
     * If caller is listed as an allowed minter, mints one NFT for him.
     */
    function mint() external override returns (uint256) {
        require(_isAllowedToMint(1), "Minting not allowed");
        address[] memory toMint = new address[](1);
        toMint[0] = msg.sender;
        if (owner() != msg.sender && !_isPublicAllowed()) {
            _consumeAllowance(1);
        }
        return _mintEditions(toMint);
    }

    /**
     * Mints multiple tokens, one for each of the given list of addresses.
     * Only the edition owner can use this operation and it is intended fo partial giveaways.
     * 
     * @param recipients list of addresses to send the newly minted tokens to
     */
    function mintAndTransfer(address[] memory recipients) external override returns (uint256) {
        require(_isAllowedToMint(uint16(recipients.length)), "Minting not allowed or exceeding");
        if (owner() != msg.sender && !_isPublicAllowed()) {
            _consumeAllowance(uint16(recipients.length));
        }
        return _mintEditions(recipients);
    }

    /**
     * Returns the owner of the collection of rewards.
     */
    function owner() public view override(OwnableUpgradeable, IMintableEditions) returns (address) {
        return super.owner();
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        shares[newOwner] = shares[newOwner] + shares[owner()];
        shares[owner()] = 0;
         _transferOwnership(newOwner);
    }

    function renounceOwnership() public override onlyOwner {
        require(address(this).balance == 0 && price == 0, "Potential loss of funds");
        _transferOwnership(address(0));
    }

    /**
     * Allows for updates of content and metadata urls by the owner.
     * Only URLs can be updated (data-uri are supported), hash cannot be updated.
     */
    function updateEditionsURLs(string memory _contentUrl, string memory _metadataUrl) external onlyOwner {
        require(bytes(_contentUrl).length > 0, "Empty content URL");
        contentUrl = _contentUrl;
        require(bytes(_metadataUrl).length > 0, "Empty metadata URL");
        metadataUrl = _metadataUrl;
    }

    /**
     * Allows owner to update the allowances reference contract use for this rewards.
     */
    function updateAllowancesRef(address _allowancesRef) external onlyOwner {
        require(AddressUpgradeable.isContract(_allowancesRef), "Invalid new reference");
        allowancesRef = _allowancesRef;
    }

    /** 
     * Returns the number of tokens still available for minting (uint64 when open edition)
     */
    function mintable() public view override returns (uint256) {
        // atEditionId is one-indexed hence the need to remove one here
        return ((size == 0) ? type(uint64).max : size + 1) - counter.current();
    }

    /**
     * User burn function for token id.
     * 
     * @param tokenId token edition identifier to burn
     */
    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved");
        _burn(tokenId);
    }

    function airdrop(uint256 start, uint256 end) external returns (uint256) {
        require(uint64(mintable()) >= AllowancesStore(allowancesRef).totalAllowed(), "Sold out");
        uint256 _endAt = end < AllowancesStore(allowancesRef).length() ? end : AllowancesStore(allowancesRef).length();
        for (uint i = start; i < _endAt; i++) {
            address recipient = AllowancesStore(allowancesRef).minters(i);
            uint16 allowance = AllowancesStore(allowancesRef).allowances(recipient) - allowedMinters[recipient];
            allowedMinters[recipient] += allowance; // consumes allowance
            for (uint j = 0; j < allowance; j++) {
                _mint(recipient, counter.current());
                counter.increment();
            }
        }   
        return counter.current();
    }

    /**
     * Private function to mint without any access checks.
     * Called by the public edition minting functions.
     */
    function _mintEditions(address[] memory recipients) internal returns (uint256) {
        require(uint64(mintable()) >= recipients.length, "Sold out");
        for (uint i = 0; i < recipients.length; i++) {
            _mint(recipients[i], counter.current());
             counter.increment();
        }
        return counter.current();
    }

    /**
     * Get URI and hash for edition NFT
     *
     * @return metadataUrl, contentHash
     */
    function getURI() public view returns (string memory, bytes32, string memory) {
        return (contentUrl, contentHash, metadataUrl);
    }

    /**
     * Get URI for given token id
     * 
     * @param tokenId token id to get uri for
     * @return base64-encoded json metadata object
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Edition doesn't exist");
        return string(abi.encodePacked(metadataUrl, "?tokenId=", StringsUpgradeable.toString(tokenId)));
    }
    
    /**
     * ERC2981 - Gets royalty information for token
     *
     * @param _value the sale price for this token
     */
    function royaltyInfo(uint256, uint256 _value) external view override returns (address receiver, uint256 royaltyAmount) {
        if (owner() == address(0x0)) {
            return (owner(), 0);
        }
        return (owner(), (_value * royalties) / 10_000);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, IERC165Upgradeable) returns (bool) {
        return type(IERC2981Upgradeable).interfaceId == interfaceId || ERC721Upgradeable.supportsInterface(interfaceId);
    }
}
