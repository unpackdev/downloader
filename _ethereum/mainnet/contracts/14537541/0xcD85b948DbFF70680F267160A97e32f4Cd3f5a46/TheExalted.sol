// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

////////////////////////////////////////////////////////////////////////////////
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&      #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&    #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@( ,@ ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,    %.     &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@(        &&        *@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@&.     (@@*   /*  @@%      #@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@/     ,@@&,            .%@@/     ,&@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@/    (@(   .**&@@@&@/*,   ,@&    .@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@#    @/.&@@@# &@.*@@@@*,@.   /@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@.  .@@@@@@,  %@   @@@@@@/   &@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@   *@@@(@@,  #@   @@(@@@#   %@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@%   (@@@*%@(  /&  ,@@.@@@&   /@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@(   %@&. *@&  *%  (@#  %@@   ,@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@*    @@  &@  ,/  %@. %@*   .@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@,   ,@#(@* .,  @%/@/    &@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@.   *@@(  . ,@@#    %@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@#@&    @&    #@,   %@%%@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@&. *@%  %@    &@  (@( .#@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,@%/@*   @%/@,*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(&@#  *@&(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@. &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
/////////////////////////////////////////////////////////////////////@ExaltedNFT

error SaleHasntStarted();
error InsufficientFunds();
error InsufficientRemainingSupply();
error InsufficientRemainingAllotment();
error NotWhitelisted();
error SupplyRemaining();
error ReserveMinted();
error TransferFailed();

/// @author Alexander J. Chun (@alexanderjchun)
/// @title The Exalted Genesis Collection
/// @notice An epic collection of 5,000 unique avatars split between two opposing factions at war for glory, power, and survival.
/// @dev A special thanks to vectorized.eth (@optimizoor) for formally auditing our contract and to the Azuki team for ERC721A and their efforts towards bettering the space. IKZ.
contract TheExalted is ERC721A, Ownable {
    uint256 public constant PUBLIC_MINT_SIZE = 4900;
    uint256 public constant TEAM_MINT_SIZE = 100;
    uint256 public constant PRICE = 0.08 ether;
    uint256 public constant MAX_PER_WALLET = 2;
    uint256 public constant WL_START_TIME = 1649361600;
    uint256 public constant PUBLIC_START_TIME = 1649448000;
    uint256 public constant RESERVE_START_TIME = 1649534400;
    bytes32 public constant MERKLE_ROOT =
        0xd2558a264639afbf2f19f9a9828df5a2744e469bce8caa64ac4d12cf3dcbec13;
    bool private teamAndReserveTokensMinted;
    string private baseTokenURI;

    constructor() ERC721A("The Exalted", "EXLTD") {}

    /// @notice Mints tokens for whitelisted users.
    /// @dev Requires a Merkle proof that corresponds with the whitelisted user's address.
    /// @param merkleProof Matching Merkle proof passed in by the minting website after looking up the user's address.
    /// @param quantity Quantity of tokens the whitelisted user chooses to mint limited to MAX_PER_WALLET.
    function whitelistMint(bytes32[] calldata merkleProof, uint256 quantity)
        external
        payable
    {
        if (block.timestamp < WL_START_TIME) revert SaleHasntStarted();

        if (msg.value != PRICE * quantity) revert InsufficientFunds();

        if (_totalMinted() + quantity > PUBLIC_MINT_SIZE)
            revert InsufficientRemainingSupply();

        if (_numberMinted(msg.sender) + quantity > MAX_PER_WALLET)
            revert InsufficientRemainingAllotment();

        bytes32 sender = keccak256(abi.encodePacked(msg.sender));

        if (!MerkleProof.verify(merkleProof, MERKLE_ROOT, sender))
            revert NotWhitelisted();

        _mint(msg.sender, quantity, "", false);
    }

    /// @notice Mints tokens for the public.
    /// @dev Starts 24 hours after the whitelist sale.
    /// @param quantity Quantity of tokens a user chooses to mint limited to MAX_PER_WALLET.
    function publicMint(uint256 quantity) external payable {
        if (block.timestamp < PUBLIC_START_TIME) revert SaleHasntStarted();

        if (msg.value != PRICE * quantity) revert InsufficientFunds();

        if (_totalMinted() + quantity > PUBLIC_MINT_SIZE)
            revert InsufficientRemainingSupply();

        if (_numberMinted(msg.sender) + quantity > MAX_PER_WALLET)
            revert InsufficientRemainingAllotment();

        _mint(msg.sender, quantity, "", false);
    }

    /// @notice Withdraw funds to the contract owner's wallet.
    /// @dev This will send the ETH entirely and doesn't allow specific amounts or accepts a toAddress. Can only be called by the owner.
    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");

        if (!success) revert TransferFailed();
    }

    /// @notice Sets the base token URI.
    /// @dev Can only be called by the owner.
    /// @param baseURI The new base token URI.
    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    /// @notice Mint remaining tokens for the reserve.
    /// @dev Can only be called by the owner 24 hours after the public sale at the earliest. To only be used if there are remaining tokens to mint. Tokens to be used as an addition to the reserve.
    function mintRemainingSupply() external onlyOwner {
        if (block.timestamp < RESERVE_START_TIME) revert SaleHasntStarted();

        uint256 remainingSupply = PUBLIC_MINT_SIZE - _totalMinted();

        _mint(msg.sender, remainingSupply, "", false);
    }

    /// @notice Mint the tokens for the team and reserve.
    /// @dev Can only be called once by the owner if the total number of tokens allocated to sales have beeen minted by either the public or through mintRemainingSupply().
    function teamAndReserveMint() external onlyOwner {
        if (PUBLIC_MINT_SIZE != _totalMinted()) revert SupplyRemaining();

        if (teamAndReserveTokensMinted) revert ReserveMinted();

        teamAndReserveTokensMinted = true;

        _mint(msg.sender, TEAM_MINT_SIZE, "", false);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @notice Override to start tokenId at 1.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
