// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract ArtOfChoice is Ownable, Pausable, ERC721A {
    string internal _baseMetadataURI;

    address public withdrawalAddress;

    struct TokenAllocation {
        uint32 collectionSize;
        uint32 mintsPerTransaction;
    }

    TokenAllocation public tokenAllocation;

    struct FlatMintConfig {
        bool isEnabled;
        uint72 price;
        uint32 startTime;
        uint32 endTime;
    }

    FlatMintConfig public flatMintConfig;

    constructor() ERC721A("ArtOfChoice", "AOC") {}

    /**
     * -----EVENTS-----
     */

    /**
     * @dev Emit on calls to flatMint().
     */
    event FlatMint(address indexed to, uint256 quantity, uint256 price, uint256 totalMinted, uint256 timestamp);

    /**
     * @dev Emit on calls to airdropMint().
     */
    event AirdropMint(address indexed to, uint256 quantity, uint256 price, uint256 totalMinted, uint256 timestamp);

    /**
     * @dev Emits on calls to setBaseMetadataURI()
     */
    event BaseMetadataURIChange(string baseMetadataURI, uint256 timestamp);

    /**
     * @dev Emits on calls to setWithdrawalAddress()
     */
    event WithdrawalAddressChange(address withdrawalAddress, uint256 timestamp);

    /**
     * @dev Emits on calls to withdraw()
     */
    event Withdrawal(address indexed to, uint256 amount, uint256 timestamp);

    /**
     * @dev Emits on calls to setTokenAllocation()
     */
    event TokenAllocationChange(uint256 collectionSize, uint256 mintsPerTransaction, uint256 timestamp);

    /**
     * @dev Emits on calls to setFlatMintConfig()
     */
    event FlatMintConfigChange(uint256 price, uint256 startTime, uint256 endTime, uint256 timestamp);

    /**
     * -----MODIFIERS-----
     */

    /**
     * @dev Check that a given mint transaction follows guidelines,
     * like not putting us over our total supply or minting too many NFTs in a single transaction,
     * (which is bad for 721A NFTs).
     */
    modifier checkMintLimits(uint256 quantity) {
        require(quantity > 0, "Mint quantity must be > 0");
        require(_totalMinted() + quantity <= tokenAllocation.collectionSize, "Exceeds total supply");
        require(quantity <= tokenAllocation.mintsPerTransaction, "Cannot mint this many in a single transaction");
        _;
    }

    /**
     * -----OWNER FUNCTIONS-----
     */

    /**
     * @dev Wrap the _pause() function from OpenZeppelin/Pausable
     * To allow preventing any mint operations while the project is paused.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Allow unpausing the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets `baseMetadataURI` for computing tokenURI().
     */
    function setBaseMetadataURI(string calldata baseMetadataURI) external onlyOwner {
        emit BaseMetadataURIChange(baseMetadataURI, block.timestamp);

        _baseMetadataURI = baseMetadataURI;
    }

    /**
     * @dev Sets `withdrawalAddress` for withdrawal of funds from the contract.
     */
    function setWithdrawalAddress(address withdrawalAddress_) external onlyOwner {
        require(withdrawalAddress_ != address(0), "withdrawalAddress_ cannot be the zero address");

        emit WithdrawalAddressChange(withdrawalAddress_, block.timestamp);

        withdrawalAddress = withdrawalAddress_;
    }

    /**
     * @dev Sends all ETH from the contract to `withdrawalAddress`.
     */
    function withdraw() external onlyOwner {
        require(withdrawalAddress != address(0), "withdrawalAddress cannot be the zero address");

        emit Withdrawal(withdrawalAddress, address(this).balance, block.timestamp);

        (bool success, ) = withdrawalAddress.call{value: address(this).balance}("");
        require(success, "Withdrawal transfer failed");
    }

    /**
     * @dev Sets `tokenAllocation` for mint phases.
     */
    function setTokenAllocation(uint32 collectionSize, uint32 mintsPerTransaction) external onlyOwner {
        require(collectionSize > 0, "collectionSize must be > 0");
        require(mintsPerTransaction > 0, "mintsPerTransaction must be > 0");
        require(mintsPerTransaction <= collectionSize, "mintsPerTransaction must be <= collectionSize");

        emit TokenAllocationChange(collectionSize, mintsPerTransaction, block.timestamp);

        tokenAllocation.collectionSize = collectionSize;
        tokenAllocation.mintsPerTransaction = mintsPerTransaction;
    }

    /**
     * @dev Sets configuration for the flat mint.
     */
    function setFlatMintConfig(
        uint72 price,
        uint32 startTime,
        uint32 endTime
    ) external onlyOwner {
        require(startTime >= block.timestamp, "startTime must be >= block.timestamp");
        require(startTime < endTime, "startTime must be < endTime");

        emit FlatMintConfigChange(price, startTime, endTime, block.timestamp);

        flatMintConfig.price = price;
        flatMintConfig.startTime = startTime;
        flatMintConfig.endTime = endTime;

        flatMintConfig.isEnabled = true;
    }

    /**
     * @dev Mints tokens to given address at no cost.
     */
    function airdropMint(address to, uint256 quantity) external payable onlyOwner checkMintLimits(quantity) {
        emit AirdropMint(to, quantity, 0, _totalMinted() + quantity, block.timestamp);

        _mint(to, quantity);
    }

    /**
     * -----INTERNAL FUNCTIONS-----
     */

    /**
     * @dev Base URI for computing tokenURI() (from the 721A contract). If set, the resulting URI for each
     * token will be the concatenation of the `baseMetadataURI` and the token ID. Overridden from the 721A contract.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseMetadataURI;
    }

    /**
     * EXTERNAL FUNCTIONS
     */

    /**
     * @dev Mints `quantity` of tokens and transfers them to the sender.
     * If the sender sends more ETH than needed, it refunds them.
     *
     * Note that flatMint() has no reserve, so it has the potential to mint
     * out the whole collection if called before the other mint phases!
     */
    function flatMint(uint256 quantity) external payable whenNotPaused checkMintLimits(quantity) {
        require(flatMintConfig.isEnabled && block.timestamp >= flatMintConfig.startTime, "Flat mint has not started");
        require(block.timestamp < flatMintConfig.endTime, "Flat mint has ended");

        // We explicitly want to use tx.origin to check if the caller is a contract
        // solhint-disable-next-line avoid-tx-origin
        require(tx.origin == msg.sender, "Caller must be user");

        uint256 cost = flatMintConfig.price * quantity;
        require(msg.value >= cost, "Insufficient payment");

        emit FlatMint(msg.sender, quantity, flatMintConfig.price, _totalMinted() + quantity, block.timestamp);

        // Contracts can't call this function so we don't need _safeMint()
        _mint(msg.sender, quantity);

        if (msg.value > cost) {
            (bool success, ) = msg.sender.call{value: msg.value - cost}("");
            require(success, "Refund transfer failed");
        }
    }
}
