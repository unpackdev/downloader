// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./OperatorFilterer.sol";

contract SacraFamiglia is
    ERC721,
    Ownable,
    ReentrancyGuard,
    OperatorFilterer,
    ERC2981
{
    // Variables
    // ---------------------------------------------------------------

    using Strings for uint256;

    // - Number Minted
    // - Number Allowlist Minted
    // - Number Gifts Received
    mapping(address => uint256) private _auxAddressData;

    uint256 private _lastMintedId = 0;

    uint256 public numAllowlistMint;
    bytes32 public merkleRootAllowlist;

    bool public isAllowlistMintActive = false;
    bool public isMintActive = false;

    uint256 private collectionSize;
    uint256 private maxAllowlistMint;
    uint256 private allowlistMintPrice = 0.1 ether;
    uint256 private publicMintPrice = 0.1 ether;
    uint256 private maxPerWalletAllowlist;
    uint256 private maxPerWallet;
    address private devAddress;
    string private _baseTokenURI;

    // Helper functions
    // ---------------------------------------------------------------

    /**
     * @dev This function packs three uint64 values into a single uint256 value.
     * @param a: first uint64
     * @param b: second uint64
     * @param c: third uint64
     */
    function pack(
        uint64 a,
        uint64 b,
        uint64 c
    ) internal pure returns (uint256) {
        return (uint256(a) << 128) | (uint256(b) << 64) | uint256(c);
    }

    /**
     * @dev This function unpacks a uint256 value into three uint64 values.
     * @param a: uint256 value
     * @return first uint64 value in the uint256
     * @return second uint64 value in the uint256
     * @return third uint64 value in the uint256
     */
    function unpack(uint256 a) internal pure returns (uint64, uint64, uint64) {
        return (uint64(a >> 128), uint64(a >> 64), uint64(a));
    }

    /**
     * @dev This function increases the number of mints for an address
     * @param account: address to increase mints for
     * @param quantity: number of mints to increase by
     */
    function increaseMints(address account, uint256 quantity) internal {
        (
            uint64 ownerMinted,
            uint64 ownerAllowlistMinted,
            uint64 ownerGiftsReceived
        ) = unpack(_auxAddressData[account]);
        _auxAddressData[account] = pack(
            ownerMinted + uint64(quantity),
            ownerAllowlistMinted,
            ownerGiftsReceived
        );
    }

    /**
     * @dev This function increases the number of allowlist mints for an address
     * @param account: address to increase allowlist mints for
     * @param quantity: number of allowlist mints to increase by
     */
    function increaseAllowlistMints(
        address account,
        uint256 quantity
    ) internal {
        (
            uint64 ownerMinted,
            uint64 ownerAllowlistMinted,
            uint64 ownerGiftsReceived
        ) = unpack(_auxAddressData[account]);
        _auxAddressData[account] = pack(
            ownerMinted,
            ownerAllowlistMinted + uint64(quantity),
            ownerGiftsReceived
        );
    }

    /**
     * @dev This function increases the number of gifts received for an address
     * @param account: address to increase gifts received for
     * @param quantity: number of gifts received to increase by
     */
    function increaseGiftsReceived(address account, uint256 quantity) internal {
        (
            uint64 ownerMinted,
            uint64 ownerAllowlistMinted,
            uint64 ownerGiftsReceived
        ) = unpack(_auxAddressData[account]);
        _auxAddressData[account] = pack(
            ownerMinted,
            ownerAllowlistMinted,
            ownerGiftsReceived + uint64(quantity)
        );
    }

    // Modifiers
    // ---------------------------------------------------------------

    /**
     * @dev This modifier ensures that the caller is a user and not a contract.
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    /**
     * @dev This modifier ensures that allowlist mint is open.
     */
    modifier allowlistMintActive() {
        require(isAllowlistMintActive, "Allowlist mint is not open.");
        _;
    }

    /**
     * @dev This modifier ensures that public mint is open.
     */
    modifier publicMintActive() {
        require(isMintActive, "Mint is not open.");
        _;
    }

    /**
     * @dev This modifier ensures that the caller has sent the correct amount of ETH.
     * @param price The price of the token.
     * @param quantity The number of tokens to be minted.
     */
    modifier isCorrectPayment(uint256 price, uint256 quantity) {
        require(price * quantity == msg.value, "Incorrect amount of ETH sent.");
        _;
    }

    /**
     * @dev This modifier ensures that the token is a positive integer smaller than the collections size, which hasn't been minted yet.
     * @param tokenId The id of the token to be minted.
     */
    modifier isTokenIdValid(uint256 tokenId) {
        require(tokenId > 0 && tokenId <= collectionSize, "Token ID invalid.");
        require(!_exists(tokenId), "Token already minted.");
        _;
    }

    /**
     * @dev This modifier checks that the merkle proof is valid.
     * @param merkleProof The merkle proof bytes32 array.
     */
    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in this allowlist."
        );
        _;
    }

    /**
     * @dev This modifier ensures that there are allowlist mint tokens left.
     * @param quantity The number of tokens to be minted.
     */
    modifier allowlistMintLeft(uint256 quantity) {
        require(
            numAllowlistMint + quantity <= maxAllowlistMint,
            "There are no allowlist mint tokens left."
        );
        _;
    }

    /**
     * @dev This modifier ensures that the caller does not mint more than the max number of allowlist tokens per wallet.
     * @param quantity The number of tokens to be minted.
     */
    modifier lessThanMaxPerWalletAllowlist(uint256 quantity) {
        require(
            getOwnerAllowlistMinted(msg.sender) + quantity <=
                maxPerWalletAllowlist,
            "You have minted the maximum number of allowlist tokens."
        );
        _;
    }

    /**
     * @dev This modifier ensures that the caller does not mint more than the max number of tokens per wallet.
     * @param quantity The number of tokens to be minted.
     */
    modifier lessThanMaxPerWallet(uint256 quantity) {
        require(
            getOwnerMinted(msg.sender) -
                getOwnerAllowlistMinted(msg.sender) +
                quantity <=
                maxPerWallet,
            "You have minted the maximum number of tokens."
        );
        _;
    }

    // Constructor
    // ---------------------------------------------------------------

    /**
     * @dev This function is the constructor for the contract.
     * @param collectionSize_ The number of tokens in the collection.
     * @param maxAllowlistMint_ The number of tokens reserved for allowlist mint.
     * @param maxPerWalletAllowlist_ The maximum number of tokens that can be minted per wallet.
     * @param maxPerWallet_ The maximum number of tokens that can be minted per wallet.
     * @param devAddress_ The address of the developer.
     */
    constructor(
        uint256 collectionSize_,
        uint256 maxAllowlistMint_,
        uint256 maxPerWalletAllowlist_,
        uint256 maxPerWallet_,
        address devAddress_
    ) ERC721("SacraFamiglia", "SACRAFAMIGLIA") {
        collectionSize = collectionSize_;
        maxAllowlistMint = maxAllowlistMint_;
        maxPerWalletAllowlist = maxPerWalletAllowlist_;
        maxPerWallet = maxPerWallet_;
        devAddress = devAddress_;

        // Set royalty receiver to the contract creator,
        // at 7% (default denominator is 10000).
        _setDefaultRoyalty(0x7EE92f4be14b553b64C46bA3d2CB567A2A492c7D, 700);
    }

    // Public minting functions
    // ---------------------------------------------------------------

    /**
     * @notice Mint specific token from allowlist paid mint.
     * @param tokenId The id of the token to be minted.
     * @param merkleProof The merkle proof bytes32 array.
     */
    function allowlistMint(
        uint256 tokenId,
        bytes32[] calldata merkleProof
    )
        external
        payable
        nonReentrant
        callerIsUser
        allowlistMintActive
        isTokenIdValid(tokenId)
        isCorrectPayment(allowlistMintPrice, 1)
        lessThanMaxPerWalletAllowlist(1)
        allowlistMintLeft(1)
        isValidMerkleProof(merkleProof, merkleRootAllowlist)
    {
        numAllowlistMint += 1;
        increaseMints(msg.sender, 1);
        increaseAllowlistMints(msg.sender, 1);
        _safeMint(msg.sender, tokenId);
    }

    /**
     * @notice Mint specific token from public paid mint.
     * @param tokenId The id of the token to be minted.
     */
    function mint(
        uint256 tokenId
    )
        external
        payable
        nonReentrant
        callerIsUser
        publicMintActive
        isTokenIdValid(tokenId)
        isCorrectPayment(publicMintPrice, 1)
        lessThanMaxPerWallet(1)
    {
        increaseMints(msg.sender, 1);
        _safeMint(msg.sender, tokenId);
    }

    /**
     * @notice Mint next token from allowlist paid mint.
     */

    function allowlistMintNext(
        bytes32[] calldata merkleProof
    )
        external
        payable
        nonReentrant
        callerIsUser
        allowlistMintActive
        isCorrectPayment(allowlistMintPrice, 1)
        lessThanMaxPerWalletAllowlist(1)
        allowlistMintLeft(1)
        isValidMerkleProof(merkleProof, merkleRootAllowlist)
    {
        require(_lastMintedId < collectionSize, "All tokens have been minted.");
        for (
            uint256 tokenId = _lastMintedId + 1;
            tokenId <= collectionSize;
            tokenId++
        ) {
            if (!_exists(tokenId)) {
                numAllowlistMint += 1;
                increaseMints(msg.sender, 1);
                increaseAllowlistMints(msg.sender, 1);
                _lastMintedId = tokenId;
                _safeMint(msg.sender, tokenId);
                return;
            }
        }
        revert("No available tokens to mint.");
    }

    /**
     * @notice Mint next token from public paid mint.
     */

    function mintNext()
        external
        payable
        nonReentrant
        callerIsUser
        publicMintActive
        isCorrectPayment(publicMintPrice, 1)
        lessThanMaxPerWallet(1)
    {
        require(_lastMintedId < collectionSize, "All tokens have been minted.");
        for (
            uint256 tokenId = _lastMintedId + 1;
            tokenId <= collectionSize;
            tokenId++
        ) {
            if (!_exists(tokenId)) {
                increaseMints(msg.sender, 1);
                _lastMintedId = tokenId;
                _safeMint(msg.sender, tokenId);
                return;
            }
        }
        revert("No available tokens to mint.");
    }

    /**
     * @notice Mint tokens from public paid mint.
     * @param tokenIds An array of token ids to be minted.
     */
    function mintMultiple(
        uint256[] calldata tokenIds
    )
        external
        payable
        nonReentrant
        callerIsUser
        publicMintActive
        isCorrectPayment(publicMintPrice, tokenIds.length)
        lessThanMaxPerWallet(tokenIds.length)
    {
        increaseMints(msg.sender, tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIds[i] > 0 && tokenIds[i] <= collectionSize,
                "Token ID invalid."
            );
            require(!_exists(tokenIds[i]), "Token already minted.");
            _safeMint(msg.sender, tokenIds[i]);
        }
    }

    // Public read-only functions
    // ---------------------------------------------------------------

    /**
     * @notice Get the address that gets funds distributed to in the withdraw() method.
     * @return The address that receives the funds.
     */
    function getDevAddress() public view returns (address) {
        return devAddress;
    }

    /**
     * @notice Get the mint price for allowlist sale.
     * @return The allowlist mint price.
     */
    function getAllowlistMintPrice() public view returns (uint256) {
        return allowlistMintPrice;
    }

    /**
     * @notice Get the mint price for public sale.
     * @return The public mint price.
     */
    function getPublicMintPrice() public view returns (uint256) {
        return publicMintPrice;
    }

    /**
     * @notice Get the the maximum number of tokens that can be minted in the allowlist.
     * @return The maximum number of tokens that can be minted in the allowlist.
     */
    function getMaxAllowlistMint() public view returns (uint256) {
        return maxAllowlistMint;
    }

    /**
     * @notice Get the the maximum number of tokens that can be minted per wallet in the allowlist.
     * @return The maximum number of tokens that can be minted per wallet in the allowlist.
     */
    function getMaxPerWalletAllowlist() public view returns (uint256) {
        return maxPerWalletAllowlist;
    }

    /**
     * @notice Get the the maximum number of tokens that can be minted per wallet in the public sale.
     * @return The maximum number of tokens that can be minted per wallet in the public sale.
     */
    function getMaxPerWallet() public view returns (uint256) {
        return maxPerWallet;
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * @param tokenId The token ID to query.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token does not exist.");
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    /**
     * @dev Returns the number of minted tokens for `owner`.
     * @param owner The address of the owner.
     * @return ownerMinted The number of minted tokens.
     */
    function getOwnerMinted(address owner) public view returns (uint64) {
        (uint64 ownerMinted, , ) = unpack(_auxAddressData[owner]);
        return ownerMinted;
    }

    /**
     * @dev Returns the number of allowlist minted tokens for `owner`.
     * @param owner The address of the owner.
     * @return ownerAllowlistMinted The number of allowlist minted tokens.
     */
    function getOwnerAllowlistMinted(
        address owner
    ) public view returns (uint64) {
        (, uint64 ownerAllowlistMinted, ) = unpack(_auxAddressData[owner]);
        return ownerAllowlistMinted;
    }

    /**
     * @dev Returns the number of minted tokens for `owner`.
     * @param owner The address of the owner.
     * @return ownerGiftsReceived The number of gift tokens received.
     */
    function getOwnerGiftsReceived(address owner) public view returns (uint64) {
        (, , uint64 ownerGiftsReceived) = unpack(_auxAddressData[owner]);
        return ownerGiftsReceived;
    }

    /**
     * @dev Returns an array of all minted tokens.
     * @return mintedTokens A collectionSize sized array of boolean values where each value represents wether the token has been minted. Because the token ids start at 1, the array index is token id - 1.
     */
    function getMintedTokens() public view returns (bool[] memory) {
        bool[] memory mintedTokens = new bool[](collectionSize);
        for (uint256 i = 1; i <= collectionSize; i++) {
            if (_exists(i)) {
                mintedTokens[i - 1] = true;
            }
        }
        return mintedTokens;
    }

    // Internal read-only functions
    // ---------------------------------------------------------------

    /**
     * @dev Returns base token metadata URI.
     * @return Base token metadata URI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Owner only administration functions
    // ---------------------------------------------------------------

    /**
     * @notice Gift tokens to a set of addresses.
     * @param addresses An n-sized array of addresses to mint to.
     * @param tokenIds An n-sized array of token ids to mint to each corresponding address.
     */
    function giftMultiple(
        address[] calldata addresses,
        uint256[] calldata tokenIds
    ) external nonReentrant onlyOwner {
        // Check to make sure both arrays are the same length
        require(
            addresses.length == tokenIds.length,
            "Arrays must be the same length."
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            require(
                tokenIds[i] > 0 && tokenIds[i] <= collectionSize,
                "Token ID invalid."
            );
            require(!_exists(tokenIds[i]), "Token already minted.");
            increaseMints(addresses[i], 1);
            increaseGiftsReceived(addresses[i], 1);
            _safeMint(addresses[i], tokenIds[i]);
        }
    }

    /**
     * @notice Set allowlist paid mint to active or inactive.
     * @param _isAllowlistMintActive True to set allowlist mint to active, false to set to inactive.
     */
    function setAllowlistMintActive(
        bool _isAllowlistMintActive
    ) external onlyOwner {
        isAllowlistMintActive = _isAllowlistMintActive;
    }

    /**
     * @notice Set public mint to active or inactive.
     * @param _isMintActive True to set mint to active, false to set to inactive.
     */
    function setMintActive(bool _isMintActive) external onlyOwner {
        isMintActive = _isMintActive;
    }

    /**
     * @notice Set the allowlist mint price.
     * @param _allowlistMintPrice The new mint price.
     */
    function setAllowlistMintPrice(
        uint256 _allowlistMintPrice
    ) external onlyOwner {
        allowlistMintPrice = _allowlistMintPrice;
    }

    /**
     * @notice Set the public mint price.
     * @param _publicMintPrice The new mint price.
     */
    function setPublicMintPrice(uint256 _publicMintPrice) external onlyOwner {
        publicMintPrice = _publicMintPrice;
    }

    /**
     * @notice Set the maximum number of tokens that can be minted in the allowlist.
     * @param _maxAllowlistMint The new maximum number of tokens that can be minted in the allowlist.
     */
    function setMaxAllowlistMint(uint256 _maxAllowlistMint) external onlyOwner {
        maxAllowlistMint = _maxAllowlistMint;
    }

    /**
     * @notice Set the maximum number of tokens that can be minted per wallet in the allowlist.
     * @param _maxPerWalletAllowlist The new maximum number of tokens that can be minted per wallet in the allowlist.
     */
    function setMaxPerWalletAllowlist(
        uint256 _maxPerWalletAllowlist
    ) external onlyOwner {
        maxPerWalletAllowlist = _maxPerWalletAllowlist;
    }

    /**
     * @notice Set the maximum number of tokens that can be minted per wallet in the public sale.
     * @param _maxPerWallet The new maximum number of tokens that can be minted per wallet in the public sale.
     */
    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    /**
     * @notice Set the base metadata URI.
     * @param baseURI The new base metadata URI.
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @notice Set the merkle root for the paid mint allowlist.
     * @param _merkleRootAllowlist The new merkle root.
     */
    function setAllowlistMerkleRoot(
        bytes32 _merkleRootAllowlist
    ) external onlyOwner {
        merkleRootAllowlist = _merkleRootAllowlist;
    }

    /**
     * @notice Set the address that gets funds distributed to in the withdraw() method.
     * @param _devAddress The new dev address.
     */
    function setDevAddress(address _devAddress) external onlyOwner {
        devAddress = _devAddress;
    }

    /**
     * @notice Withdraw ETH from the contract.
     * @dev 80% of the contract balance is sent to the owner and 20% is sent to the dev address.
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool ownerWithdrawSuccess, ) = msg.sender.call{
            value: (address(this).balance * 8000) / 10000
        }("");
        require(ownerWithdrawSuccess, "Owner transfer failed");
        (bool devWithdrawSuccess, ) = devAddress.call{
            value: address(this).balance
        }("");
        require(devWithdrawSuccess, "Dev transfer failed");
    }

    /**
     * @notice Withdraw ERC-20 tokens from the contract.
     * @dev In case someone accidentally sends ERC-20 tokens to the contract.
     * @param token The token to withdraw.
     */
    function withdrawTokens(IERC20 token) external onlyOwner nonReentrant {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    // Royalties
    // ---------------------------------------------------------------

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981) returns (bool) {
        return
            ERC721.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}
