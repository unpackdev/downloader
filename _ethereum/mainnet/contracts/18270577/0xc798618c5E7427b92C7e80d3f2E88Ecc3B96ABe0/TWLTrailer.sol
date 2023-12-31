// SPDX-License-Identifier: MIT

/*
 TTT  W   W L
  T   W W W L
  T   W W W L
  T   W W W LLL
*/

pragma solidity ^0.8.20;

// Importing dependencies
import "./Strings.sol";
import "./Ownable2Step.sol";
import "./Pausable.sol";
import "./ERC721A.sol";

/**
 * @title TWLTrailer Contract
 * @notice This contract handles the creation and management of NFT frames.
 */
contract TWLTrailer is Ownable2Step, Pausable, ERC721A("TWL Trailer", "TWLT") {
    using Strings for uint256; // Utility library for converting uint256 to string

    // Constants and state variables
    uint256 public constant MAX_MINTABLE_AT_ONCE = 1000;
    uint256 public constant MINT_PRICE = 0.0007e18; // Set mint price
    uint16 public constant MAX_FRAME_WIDTH = 3840; // Max frame width allowed
    uint256 public currentTokenId; // Keeps track of the number of tokens minted
    bool public closed = false;

    // Base URI for the token metadata.
    string private _contractURI = "https://theworldslargest.com/api/nft/metadata";
    string private _nftURI = "https://theworldslargest.com/api/nft/";
    address payable public fundsReceiver;

    // Events
    event FramesMinted(
        uint256 startTokenId,
        uint256 endTokenId,
        uint256 timeInMS,
        uint256 x,
        uint256 y,
        uint256 dimension,
        address indexed recipient
    );

    // Custom errors to provide clarity during failure conditions
    error InvalidETHAmountForQuantity();
    error MaximumFramesAtOnce();
    error QuantityShouldBeGreaterThanZero();
    error InvalidXOrDimension();
    error InvalidTokenId();
    error Unauthorized();
    error Closed();

    modifier whenNotClosed() {
        if (closed) revert Closed();
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () Ownable(msg.sender){}

    /**
     * @notice Allows the owner to pause the contract during emergencies.
     */
    function pause() external onlyOwner {
        _pause();
    }

    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }

    function setFundsReceiver(address payable _fundsReceiver) external onlyOwner {
        fundsReceiver = _fundsReceiver;
    }

    /**
     * @notice Allows the owner to unpause the contract.
     * The contract can't be unpaused once it's closed.
     */
    function unpause() external onlyOwner {
        require(!closed, "Contract is closed and can't be reopened.");
        _unpause();
    }

    /**
     * @notice Allows the owner to close the contract.
     * Once closed, the contract can't be reopened.
     */
    function close() external onlyOwner {
        closed = true;
        _pause(); // Pausing the contract once it's closed
    }

    /**
     * @notice Allows the owner to set a new base URI.
     * @param newBaseURI The new base URI.
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _nftURI = newBaseURI;
    }

    function baseURI() external view returns (string memory) {
        return _nftURI;
    }

    function _baseURI() internal override view returns (string memory) {
        return _nftURI;
    }

    /**
     * @notice Allows the owner to set the contract-level URI.
     * @param newContractURI The new contract URI.
     */
    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractURI = newContractURI;
    }

    /**
     * @notice Provides the contract-level URI.
     * @return The contract URI string.
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @notice Provides the URI for a specific token ID.
     * @param tokenId The ID of the token to fetch the URI for.
     * @return The complete URI string.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (tokenId == 0 || tokenId > currentTokenId) {
            revert InvalidTokenId(); // Ensure tokenId is valid
        }

        return string(abi.encodePacked(_nftURI, tokenId.toString()));
    }

    /**
     * @notice Allows users to mint multiple frames by providing their details.
     * @param timeInMS The timestamp of the frame.
     * @param x X-coordinate of the frame.
     * @param y Y-coordinate of the frame.
     * @param dimension Side length of the square frame.
     * @param recipient Address to receive the minted frame.
     * @param quantity Number of frames to mint.
     * @return Quantity of frames minted.
     */
    function mintFrames(
        uint192 timeInMS,
        uint16 x,
        uint16 y,
        uint16 dimension,
        address recipient,
        uint256 quantity
    ) external whenNotClosed whenNotPaused payable returns (uint256)  {
        // Validate conditions for minting
        if (quantity > MAX_MINTABLE_AT_ONCE) {
            revert MaximumFramesAtOnce();
        }
        if (msg.value != MINT_PRICE * quantity) {
            revert InvalidETHAmountForQuantity();
        }
        if (x + dimension > MAX_FRAME_WIDTH) {
            revert InvalidXOrDimension();
        }
        if (dimension == 0) {
            revert InvalidXOrDimension();
        }

        // Mint tokens
        _mint(recipient, quantity);

        // Transfer the funds to the owner
        payable(fundsReceiver).transfer(msg.value);

        uint256 startTokenId = currentTokenId + 1;
        currentTokenId += quantity;

        emit FramesMinted(startTokenId, currentTokenId, timeInMS, x, y, dimension, recipient);

        return quantity;
    }
}