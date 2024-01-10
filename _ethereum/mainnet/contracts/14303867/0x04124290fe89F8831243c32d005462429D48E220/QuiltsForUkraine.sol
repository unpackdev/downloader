//SPDX-License-Identifier: Unlicense
/// @title: Quilts for Ukraine
/// @author: Sam King (cozyco.eth)

/*
++++++ -  - - - - - - - - - - - - - - +++ - - - - - - - - - - - - - - - - ++++++
.                                                                              .
.                            We stand with Ukraine!                            .
.                                cozyco.studio                                 .
.                                                                              .
++++++ -  - - - - - - - - - - - - - - +++ - - - - - - - - - - - - - - - - ++++++
.                                                                              .
.                                                                              .
.           =##%%%%+    +%%%%%%+    +%%%%%%+    +%%%%%%+    +%%%%##=           .
.          :%%%%%%%%%%%+%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*%%%%%%%%%%%%:          .
.        :#%%%%%%%%%%%+-%%%%%%%%%%%%%%+-%%%%%%%%%%%%%%+-%%%%%%%%%%%%%#.        .
.     -%%%%%%%%%%%%%%=--%%%%%%%%%%%%%=--%%%%%%%%%%%%%=--%%%%%%%%%%%%%+#%%-     .
.     %%%%%%%%%%%%%#=---%%%%%%%%%%%#=---%%%%%%%%%%%#=---%%%%%%%%%%%#=-%%%%     .
.     %%%%%%%%%%%%#-----%%%%%%%%%%#-----%%%%%%%%%%#-----%%%%%%%%%%#---%%%%     .
.     *%%%%%%%%%%*------%%%%%%%%%*------%%%%%%%%%*------%%%%%%%%%*----#%%*     .
.       %%%%%%%%*-------%%%%%%%%*-------%%%%%%%%*-------%%%%%%%%*-------       .
.       %%%%%%%+--------%%%%%%%+--------%%%%%%%+--------%%%%%%%+--------       .
.     *%%%%%%%+---------%%%%%%+---------%%%%%%+---------%%%%%%+-------*%%*     .
.     %%%%%%%=----------%%%%%=----------%%%%%=----------%%%%%=--------%%%%     .
.     %%%%%#=-----------%%%#=-----------%%%#=-----------%%%#=---------%%%%     .
.     %%%%#-------------%%#-------------%%#-------------%%#-----------%%%%     .
.     *%%*--------------%*--------------%*--------------%*------------*%%*     .
.       *---------------*---------------*---------------*---------------       .
.                                                                              .
.     *%%*                                                            *%%*     .
.     %%%%                                                            %%%%     .
.     %%%%                                                            %%%%     .
.     %%%%                                                            %%%%     .
.     *%%*           -+**+-                          -+**+-           *%%*     .
.                   *%%%%%%*                        *%%%%%%*                   .
.                   *%%%%%%*                        *%%%%%%*                   .
.     *%%*           -+**+-                          -+**+-           *%%*     .
.     %%%%                                                            %%%%     .
.     %%%%                                                            %%%%     .
.     -%%*                                                            *%%-     .
.                                                                              .
.           *%%%%%%+    +%%%%%%+    +%%%%%%+    +%%%%%%+    +%%%%%%*           .
.           =##%%%%+    +%%%%%%+    +%%%%%%+    +%%%%%%+    +%%%%##=           .
.                                                                              .
.                                                                              .
++++++ -  - - - - - - - - - - - - - - +++ - - - - - - - - - - - - - - - - ++++++
*/

pragma solidity ^0.8.10;

import "./ERC721BatchMinting.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Base64.sol";
import "./QuiltGeneratorUKR.sol";

contract QuiltsForUkraine is ERC721BatchMinting, ReentrancyGuard, Ownable {
    /**************************************************************************
     * STORAGE
     *************************************************************************/

    uint256 public constant MIN_PRICE = 0.05 ether;
    uint256 public nextTokenId = 1;
    uint256 public seedFactor;
    bool public isSaleActive;
    IQuiltGeneratorUKR public quiltGenerator;

    struct Donation {
        address payee;
        uint256 share;
    }

    mapping(uint256 => Donation) public donationPayouts;
    uint256 public totalDonationPayees;
    uint256 public totalDonationShares;

    /**************************************************************************
     * ERRORS
     *************************************************************************/

    error SaleNotActive();
    error InsufficientBalance();
    error InvalidDonationConfiguration();
    error TransferFailed();

    /**************************************************************************
     * MINTING
     *************************************************************************/

    /// @notice Mints a quilt and donates proceeds to Ukraine. There's a minimum payment per quilt, but feel free to donate more if you can.
    function mint(uint256 numTokens) public payable virtual nonReentrant {
        if (msg.value < MIN_PRICE * numTokens) revert InsufficientBalance();
        if (!isSaleActive) revert SaleNotActive();

        if (numTokens == 1) {
            _safeMint(msg.sender, nextTokenId);
        } else {
            uint256[] memory ids = new uint256[](numTokens);
            for (uint256 i = 0; i < numTokens; ) {
                ids[i] = nextTokenId + i;
                unchecked {
                    i++;
                }
            }
            _safeMintBatch(msg.sender, ids);
        }

        unchecked {
            nextTokenId += numTokens;
        }
    }

    /**************************************************************************
     * DONATIONS
     *************************************************************************/

    /// @notice Sets the donation addresses where mint proceeds get sent to and what share they get
    function addDonationAddress(address payee, uint256 share) public onlyOwner {
        totalDonationPayees++;
        donationPayouts[totalDonationPayees] = Donation(payee, share);
        totalDonationShares += share;
    }

    /// @notice Updates the share amount for a payee
    function editDonationShares(uint256 id, uint256 newShare) public onlyOwner {
        Donation storage payout = donationPayouts[id];
        payout.share = newShare;
        totalDonationShares = totalDonationShares - payout.share + newShare;
    }

    function _payAddress(address to, uint256 amount) internal {
        (bool success, ) = payable(to).call{value: amount}(new bytes(0));
        if (!success) revert TransferFailed();
    }

    function donateProceeds() external {
        uint256 balance = address(this).balance;
        for (uint256 i = 1; i <= totalDonationPayees; i++) {
            if (donationPayouts[i].share > 0) {
                _payAddress(
                    donationPayouts[i].payee,
                    (balance * donationPayouts[i].share) / totalDonationShares
                );
            }
        }
    }

    /**************************************************************************
     * SALE ADMIN
     *************************************************************************/

    /// @notice Toggles the sale state
    function toggleSale() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    /// @notice Enables or disabled the OpenSea gas free listing (pre-approvals)
    function setOpenSeaGasFreeListing(bool enabled) external onlyOwner {
        openSeaGasFreeListingEnabled = enabled;
    }

    /**************************************************************************
     * ERC721 FUNCTIONS
     *************************************************************************/

    /// @notice Get the total number of minted tokens
    function totalSupply() public view returns (uint256) {
        return nextTokenId - 1;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) revert NonExistent();
        return quiltGenerator.quiltMetadata(tokenId, seedFactor * tokenId);
    }

    constructor(
        address _quiltGenerator,
        uint256 _seedFactor,
        address _govAddress,
        address _daoAddress
    ) ERC721("Quilts for Ukraine", "QLTUKR") {
        quiltGenerator = IQuiltGeneratorUKR(_quiltGenerator);
        seedFactor = _seedFactor;
        addDonationAddress(_govAddress, 50_00); // 0x165CD37b4C644C2921454429E7F9358d18A45e14
        addDonationAddress(_daoAddress, 50_00); // 0x633b7218644b83D57d90e7299039ebAb19698e9C
    }
}
