// SPDX-License-Identifier: MIT
// Developed by itxToledo

pragma solidity 0.8.11;

import "./Ownable.sol";
import "./MerkleProof.sol";

/**
 * @notice Represents MetaGodsERC721 Smart Contract
 */
contract IMetaGodsERC721 {
    /**
     * @dev ERC-721 INTERFACE
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}

    /**
     * @dev CUSTOM INTERFACE
     */
    function mintTo(uint256 amount, address _to) external {}

    function maxMintPerTransaction() public returns (uint256) {}
}

/**
 * @title NFTPreSaleContract.
 *
 * @author itxToledo
 *
 * @notice This Smart Contract can be used to sell any fixed amount of NFTs where only permissioned
 * wallets are allowed to buy. Buying is limited to a certain time period.
 *
 * @dev The primary mode of verifying permissioned actions is through Merkle Proofs
 * which are generated off-chain.
 */
contract NFTPreSale is Ownable {
    /**
     * @notice The Smart Contract of the NFT being sold
     * @dev ERC-721 Smart Contract
     */
    IMetaGodsERC721 public immutable nft;

    /**
     * @dev MINT DATA
     */
    uint256 public publicMintPrice = 0.0888 * 1e16;
    uint256 public publicMaxMintPerWallet = 2;
    bool public isPublicSale = false;

    uint256 public maxSupply = 888;
    uint256 public minted = 0;

    mapping(address => uint256) public addressToMints;

    /**
     * @dev MERKLE ROOTS
     */
    bytes32 public merkleRoot = "";

    /**
     * @dev Events
     */
    event ReceivedEther(address indexed sender, uint256 indexed amount);
    event Purchase(address indexed buyer, uint256 indexed amount);
    event setMaxSupplyEvent(uint256 indexed maxSupply);
    event setMerkleRootEvent(bytes32 indexed merkleRoot);
    event WithdrawAllEvent(address indexed to, uint256 amount);
    event setPublicMintPriceEvent(uint256 indexed publicMintPrice);
    event setPublicMaxMintPerWalletEvent(
        uint256 indexed publicMaxMintPerWallet
    );
    event setIsPublicSaleEvent(bool indexed isPublicSale);

    constructor(address _nftaddress) Ownable() {
        nft = IMetaGodsERC721(_nftaddress);
    }

    /**
     * @dev SALE
     */

    modifier canMint(uint256 amount) {
        require(address(nft) != address(0), "NFT SMART CONTRACT NOT SET");
        require(amount > 0, "HAVE TO BUY AT LEAST 1");
        require(
            amount <= nft.maxMintPerTransaction(),
            "CANNOT MINT MORE PER TX"
        );
        require(
            minted + amount <= maxSupply,
            "MINT AMOUNT GOES OVER MAX SUPPLY"
        );
        _;
    }

    /// @dev Updates contract variables and mints `amount` NFTs to users wallet
    function computeNewPurchase(uint256 amount) internal {
        minted += amount;
        addressToMints[msg.sender] += amount;
        nft.mintTo(amount, msg.sender);

        emit Purchase(msg.sender, amount);
    }

    /**
     * @notice Function to buy one or more NFTs.
     * @dev First the Merkle Proof is verified.
     * Then the mint is verified with the data embedded in the Merkle Proof.
     * Finally the NFTs are minted to the user's wallet.
     *
     * @param amount. The amount of NFTs to buy.
     * @param mintStart. The start date of the mint.
     * @param mintEnd. The end date of the mint.
     * @param mintPrice. The mint price for the user.
     * @param mintMaxAmount. The max amount the user can mint.
     * @param proof. The Merkle Proof of the user.
     */
    function buy(
        uint256 amount,
        uint256 mintStart,
        uint256 mintEnd,
        uint256 mintPrice,
        uint256 mintMaxAmount,
        bytes32[] calldata proof
    ) external payable canMint(amount) {
        /// @dev Verifies Merkle Proof submitted by user.
        /// @dev All mint data is embedded in the merkle proof.

        bytes32 leaf = keccak256(
            abi.encodePacked(
                msg.sender,
                mintStart,
                mintEnd,
                mintPrice,
                mintMaxAmount
            )
        );
        require(MerkleProof.verify(proof, merkleRoot, leaf), "INVALID PROOF");

        /// @dev Verifies that user can mint based on the provided parameters.

        require(merkleRoot != "", "PERMISSIONED SALE CLOSED");

        require(block.timestamp >= mintStart, "SALE HASN'T STARTED YET");
        require(block.timestamp < mintEnd, "SALE IS CLOSED");

        require(
            addressToMints[_msgSender()] + amount <= mintMaxAmount,
            "MINT AMOUNT EXCEEDS MAX FOR USER"
        );

        require(msg.value == mintPrice * amount, "ETHER SENT NOT CORRECT");

        computeNewPurchase(amount);
    }

    /**
     * @notice Function to buy one or more NFTs in public sale.
     * @param amount. The amount of NFTs to buy.
     */
    function publicBuy(uint256 amount) external payable canMint(amount) {
        require(isPublicSale == true, "PUBLIC SALE IS DISABLED");
        require(
            msg.value == publicMintPrice * amount,
            "ETHER SENT NOT CORRECT"
        );

        require(
            addressToMints[_msgSender()] + amount <= publicMaxMintPerWallet,
            "MINT AMOUNT EXCEEDS MAX FOR USER"
        );

        computeNewPurchase(amount);
    }

    /**
     * @dev OWNER ONLY
     */

    /**
     * @notice Change the maximum supply of NFTs that are for sale.
     *
     * @param newMaxSupply. The new max supply.
     */
    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
        emit setMaxSupplyEvent(newMaxSupply);
    }

    /**
     * @notice Change the merkleRoot of the sale.
     *
     * @param newRoot. The new merkleRoot.
     */
    function setMerkleRoot(bytes32 newRoot) external onlyOwner {
        merkleRoot = newRoot;
        emit setMerkleRootEvent(newRoot);
    }

    /**
     * @notice Change the public mint price per NFT.
     *
     * @param newPublicMintPrice. The new public mint price per NFT.
     */
    function setPublicMintPrice(uint256 newPublicMintPrice) external onlyOwner {
        publicMintPrice = newPublicMintPrice;
        emit setPublicMintPriceEvent(publicMintPrice);
    }

    /**
     * @notice Change the public max mint amount per user.
     *
     * @param newPublicMaxMintPerWallet. The new public max mint amount per user.
     */
    function setPublicMaxMintPerWallet(uint256 newPublicMaxMintPerWallet)
        external
        onlyOwner
    {
        publicMaxMintPerWallet = newPublicMaxMintPerWallet;
        emit setPublicMaxMintPerWalletEvent(newPublicMaxMintPerWallet);
    }

    /**
     * @notice Change the public sale state.
     *
     * @param newIsPublicSale. The new public sale state.
     */
    function setIsPublicSale(bool newIsPublicSale) external onlyOwner {
        isPublicSale = newIsPublicSale;
        emit setIsPublicSaleEvent(newIsPublicSale);
    }

    /**
     * @dev FINANCE
     */

    /**
     * @notice Allows owner to withdraw funds generated from sale.
     *
     * @param _to. The address to send the funds to.
     */
    function withdrawAll(address _to) external onlyOwner {
        require(_to != address(0), "CANNOT WITHDRAW TO ZERO ADDRESS");

        uint256 contractBalance = address(this).balance;

        require(contractBalance > 0, "NO ETHER TO WITHDRAW");

        payable(_to).transfer(contractBalance);

        emit WithdrawAllEvent(_to, contractBalance);
    }

    /**
     * @dev Fallback function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}
