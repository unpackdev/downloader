// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721A.sol";

import "./Ownable.sol";
import "./Pausable.sol";

import "./base64.sol";

/**
 * @title MHOUSE LINKED Collectors Pass
 */
contract LinkedCollectorsPass is ERC721A, Ownable, Pausable {
    address DEVELOPER_ADDRESS;
    address SAFE_ADDRESS;
    address SIGNER_ADDRESS;

    address[] public admins;
    mapping(address => uint256) adminsIndex;

    mapping(bytes32 => bool) _nonceUsed;
    mapping(address => TokensPrice) _tokensPrice;

    string collectionDescription = "The LINKED Collectors Pass is a new way to collect blockchain art. The more LINKED Collectors Pass NFTs you mint, the more benefits you get. To mint your LINKED Collectors Pass NFTs and for more information, visit ";
    string collectionImageHash = "QmSdZfHbbXxRtx4qeysvf76ctWq172nVViiw88h75kPeja";
    string collectionURL = "https://mhouse.club/linked-collectors-pass";

    string tokenDescription = "The LINKED Collectors Pass gives you early access to LINK NFT drops in the LINKED collection. The more you mint, the greater the utility. You can burn this pass during the minting of a LINK NFT for a 50% discount - just like exchanging a gift voucher during a store checkout. For a full breakdown of utility, visit ";
    string tokenImageHash = "QmSp3553iYoa1QPZbZNkPLfzsW7zofkdoDuTLTPGyw9rRV";
    
    struct TokensPrice {
        uint256 minQuantity;
        uint256 perToken;
    }

    uint256 public tokenPrice = 0.5 ether;

    uint256 COMMISSION_BPS = 250;
    uint256 MAX_SUPPLY;

    constructor(
        address admin1,
        address admin2,
        address developer,
        address safe,
        address signer,
        uint256 maxSupply
    ) ERC721A("LINKED Collectors Pass", "LINKCP") {
        _addAdmin(admin1);
        _addAdmin(admin2);

        DEVELOPER_ADDRESS = developer;
        SAFE_ADDRESS = safe;
        SIGNER_ADDRESS = signer;

        MAX_SUPPLY = maxSupply;

        _safeMint(admin1, 3);
        _safeMint(admin2, 3);
        _safeMint(developer, 3);
        _safeMint(safe, 3);
    }

    modifier onlyAdmin() {
        require(
            isAdmin(_msgSender()),
            "LINKCP: caller is not an admin"
        );
        _;
    }

    modifier onlySafe() {
        require(
            msg.sender == SAFE_ADDRESS,
            "LINKCP: caller is not the current safe address"
        );
        _;
    }

    // EXTERNAL

    function burn(uint256 tokenId) external {
        require(
            tx.origin == ownerOf(tokenId),
            "LINKCP: pass does not belong to the transaction origin address"
        );
        _burn(tokenId);
    }

    // PAYABLE

    receive() external payable {}

    /**
     * Mint Collectors Pass
     * @dev allows an account with a valid signature to mint a quantity of tokens
     * @param quantity the quantity of tokens to mint
     * @param nonce the nonce used in the server signed message
     * @param v signature v value
     * @param r signature r value
     * @param s signature s value
     */
    function mint(
        uint256 quantity,
        string memory nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable whenNotPaused {
        require(
            quantity + _totalMinted() <= MAX_SUPPLY,
            "LINKCP: not enough supply remaining"
        );
        _verifyMintSignature(nonce, v, r, s);

        TokensPrice memory price = tokensPrice(_msgSender());

        if (quantity < price.minQuantity) {
            require(
                msg.value >= quantity * tokenPrice,
                "LINKCP: not enough ether sent"
            );
        } else {
            require(
                msg.value >= quantity * price.perToken,
                "LINKCP: not enough ether sent"
            );
            _tokensPrice[_msgSender()] = TokensPrice(0, tokenPrice);
        }

        _safeMint(_msgSender(), quantity);
    }

    // PUBLIC VIEWS

    /**
     * Admin Count
     */
    function adminCount() public view returns (uint256) {
        return admins.length;
    }

    /**
     * Contract URI
     */
    function contractURI() public view returns (string memory) {
        string memory metadata = string(
            abi.encodePacked(
                '{"name":"LINKED Collectors Pass',
                '","description":"', collectionDescription, collectionURL,
                '","image":"ipfs://', collectionImageHash,
                '","external_link":"', collectionURL,
                '"}'
            )
        );

        string memory json = Base64.encode(bytes(metadata));

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function isAdmin(address admin) public view returns (bool) {
        if (admins.length == 0) { return false; }
        return admins[adminsIndex[admin]] == admin;
    }

    /**
     * Token URI
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory metadata = string(
            abi.encodePacked(
                '{"name":"LINKED Collectors Pass #', Strings.toString(tokenId),
                '","description":"', tokenDescription, collectionURL,
                '","image":"ipfs://', tokenImageHash,
                '"}'
            )
        );

        string memory json = Base64.encode(bytes(metadata));

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /**
     * Tokens Price
     * @dev gets the price available to the specified address
     * @param collector the address of the collector
     * @return TokensPrice the tokens price details for the collector
     */
    function tokensPrice(address collector) public view returns (TokensPrice memory) {
        TokensPrice memory price = _tokensPrice[collector];
        if (price.minQuantity == 0) {
            return TokensPrice(1, tokenPrice);
        }
        return price;
    }

    // ADMIN

    /**
     * Add Admin
     * @dev allows existing contract admins to add additional addresses to the admin list
     * @param admin address to add
     */
    function addAdmin(address admin) public onlyAdmin {
        _addAdmin(admin);
    }

    /**
     * Remove Admin
     * @dev allows existing contract admins to remove addresses from the admin list, must have at least 2 admins remaining
     * @param admin address to remove
     */
    function removeAdmin(address admin) public onlyAdmin {
        require(isAdmin(admin), "LINKCP: address is not an admin");
        require(admins.length > 2, "LINKCP: there must be at least 2 admins");

        uint256 index = adminsIndex[admin];
        
        if (index == admins.length - 1) {
            admins.pop();
        } else {
            address lastAdmin = admins[admins.length - 1];
            adminsIndex[lastAdmin] = index;
            admins[index] = lastAdmin;
            admins.pop();
        }

        adminsIndex[admin] = 0;
    }

    /**
     * Transfer Ownership
     * @dev allows an admin to transfer ownership of the contract
     * @param newOwner the address to transfer ownership to
     */
    function adminTransferOwnership(address newOwner) public onlyAdmin {
        _transferOwnership(newOwner);
    }

    /**
     * Pause Minting
     */
    function pause() public onlyAdmin {
        _pause();
    }

    /**
     * Unpause Minting
     */
    function unpause() public onlyAdmin {
        _unpause();
    }

    // ADDRESSES

    /**
     * Set Developer Address
     * @dev sets the developer address to use for commission transfer
     * @param address_ the address of the developer
     */
    function setDeveloperAddress(address address_) public {
        require(msg.sender == DEVELOPER_ADDRESS, "LINKCP: only the developer can update their address");
        DEVELOPER_ADDRESS = address_;
    }

    /**
     * Set Signer Address
     * @dev sets the signer address used to sign server messages
     * @param address_ the address of the signer account
     */
    function setSignerAddress(address address_) public onlyAdmin {
        SIGNER_ADDRESS = address_;
    }

    /**
     * Set Token Price
     * @dev allows an admin to change the default token price for the contract only when paused
     * @param price the new token price
     */
    function setTokenPrice(uint256 price) public onlyAdmin whenPaused {
        tokenPrice = price;
    }

    /**
     * Set Tokens Price
     * @dev set price override for a specific address ahead of minting
     * @param collector the address of the collector
     * @param quantity the minimum mint quantity to receive the price
     * @param pricePerToken the price per token if the minimum quantity is met when minting
     */
    function setTokensPrice(
        address collector,
        uint256 quantity,
        uint256 pricePerToken
    ) public onlyAdmin {
        if (pricePerToken != tokenPrice) {
            require(quantity >= 25, "LINKCP: quantity must be at least 25");
        } else {
            require(quantity == 0, "LINKCP: quantity must be 0 when setting the default price");
        }
        _tokensPrice[collector] = TokensPrice(quantity, pricePerToken);
    }

    // METADATA

    function setCollectionDescription(string memory description) public onlyAdmin {
        collectionDescription = description;
    }

    function setCollectionImageHash(string memory ipfsHash) public onlyAdmin {
        collectionImageHash = ipfsHash;
    }

    function setCollectionURL(string memory url) public onlyAdmin {
        collectionURL = url;
    }

    function setTokenDescription(string memory description) public onlyAdmin {
        tokenDescription = description;
    }

    function setTokenImageHash(string memory ipfsHash) public onlyAdmin {
        tokenImageHash = ipfsHash;
    }

    // SAFE

    /**
     * Set Safe Address
     * @dev sets a new Safe address, only callable by the current safe
     * @param safeAddress the address of the new safe
     */
    function setSafeAddress(address safeAddress) public onlySafe {
        SAFE_ADDRESS = safeAddress;
    }

    function withdraw() public onlySafe {
        uint256 balance = address(this).balance;
        uint256 devCommission = (balance * COMMISSION_BPS) / 10000;
        payable(SAFE_ADDRESS).transfer(address(this).balance - devCommission);
        payable(DEVELOPER_ADDRESS).transfer(devCommission);
    }

    // INTERNAL

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // PRIVATE

    function _addAdmin(address admin) private {
        require(!isAdmin(admin), "LINKCP: already an admin");

        adminsIndex[admin] = admins.length;
        admins.push(admin);
    }

    function _verifyMintSignature(
        string memory nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private {
        bytes32 message = keccak256(abi.encodePacked('LINKCP', nonce, _msgSender()));

        require(!_nonceUsed[message], "LINKCP: nonce already used");

        _verifySignatureMessage(message, v, r, s);
        _nonceUsed[message] = true;
    }

    function _verifySignatureMessage(
        bytes32 message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
        );
        require(
            ecrecover(hash, v, r, s) == SIGNER_ADDRESS,
            "LINKCP: invalid signature"
        );
    }
}
