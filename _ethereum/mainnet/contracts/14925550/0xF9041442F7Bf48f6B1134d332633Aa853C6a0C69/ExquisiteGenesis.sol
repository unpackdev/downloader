// SPDX-License-Identifier: MIT
// Project assets are CC0
pragma solidity ^0.8.13;

// Import Exquisite Graphics Interface
import "./IExquisiteGraphics.sol";

import "./IERC20.sol";
import "./ERC1155.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SSTORE2.sol";
import "./Base64.sol";

contract ExquisiteGenesis is ERC1155, Ownable, ReentrancyGuard {
    /* -------------------------------------------------------------------------- */
    /*                              STATE VARIABLES                               */
    /* -------------------------------------------------------------------------- */

    string public name = "Exquisite Graphics Genesis";
    string public symbol = "XGEN";
    uint256 public constant MINT_PRICE = 0.064 ether;
    uint256 public constant MAX_MINT = 1011; // 64.64 / .064 = 1010 + 1
    address public art;
    uint256 public numMinted;

    // Initialize Exquisite Graphics to be used in the URI function
    IExquisiteGraphics public gfx =
        IExquisiteGraphics(payable(0xDf01A4040493B514605392620B3a0a05Eb8Cd295));

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */

    error ArtDataExists();
    error TokenIDInvalid();
    error PaymentAmountInvalid();
    error MaxMintReached();
    error MintZeroQuantity();
    error NoBalance();
    error WithdrawFailed();

    /* -------------------------------------------------------------------------- */
    /*                                 MODIFIERS                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Requires quantity of mint to be non-zero
    modifier onlyIfQuantity(uint256 quantity) {
        if (quantity == 0) revert MintZeroQuantity();
        _;
    }

    /// @notice Requires the maximum number of mints to never exceed MAX_MINT
    modifier onlyIfSupplyAvailable(uint256 quantity) {
        if (numMinted + quantity > MAX_MINT) revert MaxMintReached();
        _;
    }

    /// @notice Requires msg.value be exactly the mint amount.
    modifier onlyIfPaymentAmountValid(uint256 value) {
        if (msg.value != value) revert PaymentAmountInvalid();
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                                CONSTRUCTOR                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice initializes. stores the data in .xqst format into the contract
    constructor() ERC1155("") {
        // Initialize Exquisite Graphics to the V1 Contract
        gfx = IExquisiteGraphics(
            payable(0xDf01A4040493B514605392620B3a0a05Eb8Cd295)
        );

        _transferOwnership(0xD286064cc27514B914BAB0F2FaD2E1a89A91F314);
        _mint(0xD286064cc27514B914BAB0F2FaD2E1a89A91F314, 1);
    }

    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Public mint function
    function mint(uint256 quantity)
        external
        payable
        onlyIfQuantity(quantity)
        onlyIfSupplyAvailable(quantity)
        onlyIfPaymentAmountValid(quantity * MINT_PRICE)
    {
        _mint(msg.sender, quantity);
    }

    /// @notice The TokenURI. It is rendered fully on chain via Exquisite Graphics
    function uri(uint256 id) public view override returns (string memory) {
        if (id > 0) revert TokenIDInvalid();

        // Get the SVG string from Exquisite Graphics and Base64 encode it
        string memory base64SVG = Base64.encode(
            bytes(gfx.draw(SSTORE2.read(art)))
        );

        bytes memory metadata = abi.encodePacked(
            '{"name": "Exquisite Graphics Genesis',
            '", "description": "An SVG - 64x64 in 256 Colors. This is one of the toughest images for Exquisite Graphics to render. It ensures that anyone will be able to render high resolution on-chain art with Exquisite Graphics."',
            ', "attributes": [{"trait_type":"Width", "value":"64"},{"trait_type":"Height", "value":"64"}, {"trait_type":"Colors", "value":"256"}, {"trait_type":"Number of Pixels", "value":"4096"}]',
            ', "image": "data:image/svg+xml;base64,',
            base64SVG,
            '"}'
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(metadata)
                )
            );
    }

    /// @notice get the data out from the contract. can be composed due to CC0
    function artData() public view returns (bytes memory) {
        return SSTORE2.read(art);
    }

    /// @notice allows owner to set the art data one time
    function setArtData(bytes memory data) public onlyOwner {
        if (art != address(0x0)) revert ArtDataExists();
        // Write the .xqst data to Storage via SSTORE2 to save on gas
        art = SSTORE2.write(data);
    }

    /// @notice Be able to update Exquisite Graphics to another address later on
    function updateExquisiteGraphics(address addr) public onlyOwner {
        gfx = IExquisiteGraphics(payable(addr));
    }

    /// @notice allow the owner to withdraw the funds to an address
    function withdraw(address to) public onlyOwner nonReentrant {
        uint256 b = address(this).balance;
        if (b == 0) revert NoBalance();
        (bool success, ) = to.call{value: b}("");
        if (!success) revert WithdrawFailed();
    }

    /// @notice allow the owner to withdraw ERC20 based funds to an address
    function withdrawERC20(IERC20 token) public nonReentrant {
        uint256 b = token.balanceOf(address(this));
        if (b == 0) revert NoBalance();
        bool success = token.transfer(owner(), b);
        if (!success) revert WithdrawFailed();
    }

    receive() external payable {}

    /* -------------------------------------------------------------------------- */
    /*                            INTERNAL FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    /// @notice a helper mint function
    function _mint(address to, uint256 quantity) private {
        _mint(to, 0, quantity, bytes(""));
        unchecked {
            numMinted += quantity;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     *
     * From ERC721A
     */
    function _toString(uint256 value)
        internal
        pure
        returns (string memory ptr)
    {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }
}
