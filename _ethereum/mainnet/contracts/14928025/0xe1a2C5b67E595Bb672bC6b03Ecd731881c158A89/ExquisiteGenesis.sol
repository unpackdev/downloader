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

    string public name = "Exquisite Genesis";
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

    /// @notice returns the SVG for Exquisite Genesis
    function svg() public view returns (string memory) {
        return _svg();
    }

    /// @notice The TokenURI. It is rendered fully on chain via Exquisite Graphics
    function uri(uint256 id) public view override returns (string memory) {
        if (id > 0) revert TokenIDInvalid();

        // Get the SVG string from Exquisite Graphics and Base64 encode it
        string memory encodedSVG = Base64.encode(bytes(_svg()));
        string memory metadata = string.concat(
            "data:application/json,",
            "%7B%22name%22:%20%22Exquisite%20Graphics%20Genesis",
            "%22,%20%22description%22:%20%22An%20SVG%20-%2064x64%20in%20256%20Colors.%20This%20is%20one%20of%20the%20toughest%20images%20for%20Exquisite%20Graphics%20to%20render.%20It%20ensures%20that%20anyone%20will%20be%20able%20to%20render%20high%20resolution%20on-chain%20art%20with%20Exquisite%20Graphics.%22",
            ",%20%22attributes%22:%20%5B%7B%22trait_type%22:%22Width%22,%20%22value%22:%2264%22%7D,%7B%22trait_type%22:%22Height%22,%20%22value%22:%2264%22%7D,%20%7B%22trait_type%22:%22Colors%22,%20%22value%22:%22256%22%7D,%20%7B%22trait_type%22:%22Number%20of%20Pixels%22,%20%22value%22:%224096%22%7D%5D",
            ",%20%22image%22:%20%22data:image/svg+xml;base64,",
            encodedSVG,
            "%22%7D"
        );

        return metadata;
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

    /// @notice returns the SVG from Exquisite Graphics
    function _svg() private view returns (string memory) {
        return gfx.draw(SSTORE2.read(art));
    }
}
