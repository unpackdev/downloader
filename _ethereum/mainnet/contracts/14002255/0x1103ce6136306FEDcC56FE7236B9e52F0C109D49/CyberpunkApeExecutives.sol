// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Signer.sol";

contract CyberpunkApeExecutives is ERC721, Ownable, ReentrancyGuard {
    constructor(
        uint16 maxSupply,
        uint16 maxPresale,
        uint16 publicTransactionMax,
        uint256 price,
        address signer,
        uint256 presaleMintStart,
        uint256 presaleMintEnd,
        uint256 publicMintStart
    ) ERC721("Cyberpunk Ape Executives", "CAE") {
        require(maxSupply > 0, "Zero supply");

        mintSigner = signer;
        totalSupply = maxSupply;
        mintPrice = price;

        // CONFIGURE PRESALE Mint
        presaleMint.startDate = presaleMintStart;
        presaleMint.endDate = presaleMintEnd;
        presaleMint.maxMinted = maxPresale;

        // CONFIGURE PUBLIC MINT
        publicMint.startDate = publicMintStart;
        publicMint.maxPerTransaction = publicTransactionMax;
    }

    event Paid(address sender, uint256 amount);
    event Withdraw(address recipient, uint256 amount);

    struct WhitelistedMint {
        /**
         * The start date in unix seconds
         */
        uint256 startDate;
        /**
         * The end date in unix seconds
         */
        uint256 endDate;
        /**
         * The total number of tokens minted in this whitelist
         */
        uint16 totalMinted;
        /**
         * The maximum number of tokens minted in this whitelist
         */
        uint16 maxMinted;
        /**
         * The minters in this whitelisted mint
         * mapped to the number minted
         */
        mapping(address => uint16) minted;
    }

    struct PublicMint {
        /**
         * The start date in unix seconds
         */
        uint256 startDate;
        /**
         * The maximum per transaction
         */
        uint16 maxPerTransaction;
    }

    string baseURI;

    uint16 public totalSupply;
    uint16 public minted;

    address private mintSigner;
    mapping(address => uint16) public lastMintNonce;
    uint256 public mintPrice;

    /**
     * An exclusive mint for members granted
     * presale
     */
    WhitelistedMint public presaleMint;

    /**
     * The public mint for everybody.
     */
    PublicMint public publicMint;

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Sets the base URI for all tokens
     *
     * @dev be sure to terminate with a slash
     * @param uri - the target base uri (ex: 'https://google.com/')
     */
    function setBaseURI(string calldata uri) public onlyOwner {
        baseURI = uri;
    }

    /**
     * Sets the signer for presale transactions
     *
     * @param signer - the new signer's address
     */
    function setSigner(address signer) public onlyOwner {
        mintSigner = signer;
    }

    /**
     * Burns the provided token id if you own it.
     * Reduces the supply by 1.
     *
     * @param tokenId - the ID of the token to be burned.
     */
    function burn(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "You do not own this token");

        _burn(tokenId);
    }

    // ------------------------------------------------ MINT STUFFS ------------------------------------------------

    function getPresaleMints(address user) external view returns (uint16) {
        return presaleMint.minted[user];
    }

    /**
     * Updates the presale mint's characteristics
     *
     * @param startDate - the start date for that mint in UNIX seconds
     * @param endDate - the end date for that mint in UNIX seconds
     */
    function updatePresaleMint(
        uint256 startDate,
        uint256 endDate,
        uint16 maxMinted
    ) public onlyOwner {
        presaleMint.startDate = startDate;
        presaleMint.endDate = endDate;
        presaleMint.maxMinted = maxMinted;
    }

    /**
     * Updates the public mint's characteristics
     *
     * @param maxPerTransaction - the maximum amount allowed in a wallet to mint in the public mint
     * @param startDate - the start date for that mint in UNIX seconds
     */
    function updatePublicMint(uint16 maxPerTransaction, uint256 startDate)
        public
        onlyOwner
    {
        publicMint.maxPerTransaction = maxPerTransaction;
        publicMint.startDate = startDate;
    }

    /**
     * Sets the mint price for whitelist and public mints.
     * @param price - the cost for the mints in WEI
     * @dev only for the contract owner
     */
    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    function getPremintHash(
        address minter,
        uint16 quantity,
        uint16 nonce
    ) public pure returns (bytes32) {
        return VerifySignature.getMessageHash(minter, quantity, nonce);
    }

    /**
     * Mints in the premint stage by using a signed transaction from a centralized whitelist.
     * The message signer is expected to only sign messages when they fall within the whitelist
     * specifications.
     *
     * @param quantity - the number to mint
     * @param nonce - a random nonce which indicates that a signed transaction hasn't already been used.
     * @param signature - the signature given by the centralized whitelist authority, signed by
     *                    the account specified as mintSigner.
     */
    function premint(
        uint16 quantity,
        uint16 nonce,
        bytes calldata signature
    ) public payable nonReentrant {
        uint256 remaining = totalSupply - minted;

        require(remaining > 0, "Mint over");
        require(quantity >= 1, "Zero mint");
        require(quantity <= remaining, "Not enough");
        require(lastMintNonce[msg.sender] < nonce, "Nonce used");

        require(
            presaleMint.startDate <= block.timestamp &&
                presaleMint.endDate >= block.timestamp,
            "No mint"
        );
        require(
            VerifySignature.verify(
                mintSigner,
                msg.sender,
                quantity,
                nonce,
                signature
            ),
            "Invalid sig"
        );
        require(mintPrice * quantity == msg.value, "Bad value");
        require(
            presaleMint.totalMinted + quantity <= presaleMint.maxMinted,
            "Limit exceeded"
        );

        presaleMint.minted[msg.sender] += quantity;
        presaleMint.totalMinted += quantity;
        lastMintNonce[msg.sender] = nonce; // update nonce

        // DISTRIBUTE THE TOKENS
        uint16 i;
        for (i; i < quantity; i++) {
            minted += 1;
            _safeMint(msg.sender, minted);
        }
    }

    /**
     * Mints the given quantity of tokens provided it is possible to.
     *
     * @notice This function allows minting in the public sale
     *         or at any time for the owner of the contract.
     *
     * @param quantity - the number of tokens to mint
     */
    function mint(uint16 quantity) public payable {
        mintTo(msg.sender, quantity);
    }

    /**
     * Mints the given quantity of tokens provided it is possible to.
     *
     * @notice This function allows minting in the public sale
     *         or at any time for the owner of the contract.
     *
     * @param quantity - the number of tokens to mint
     * @param user - the recipient of the mint
     */
    function mintTo(address user, uint16 quantity) public payable nonReentrant {
        uint256 remaining = totalSupply - minted;

        require(remaining > 0, "Mint over");
        require(quantity >= 1, "Zero mint");
        require(quantity <= remaining, "Not enough");

        if (owner() == msg.sender) {
            // OWNER MINTING FOR FREE
            require(msg.value == 0, "Owner paid");
        } else if (block.timestamp >= publicMint.startDate) {
            // PUBLIC MINT
            require(quantity <= publicMint.maxPerTransaction, "Exceeds max");
            require(quantity * mintPrice == msg.value, "Invalid value");
        } else {
            // NOT ELIGIBLE FOR PUBLIC MINT
            revert("No mint");
        }

        // DISTRIBUTE THE TOKENS
        uint16 i;
        for (i; i < quantity; i++) {
            minted += 1;
            _safeMint(user, minted);
        }
    }

    /**
     * Withdraws balance from the contract to the owner (sender).
     * @param amount - the amount to withdraw, much be <= contract balance.
     */
    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Invalid amt");

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Trans failed");
        emit Withdraw(msg.sender, amount);
    }

    /**
     * The receive function, does nothing
     */
    receive() external payable {
        emit Paid(msg.sender, msg.value);
    }
}
