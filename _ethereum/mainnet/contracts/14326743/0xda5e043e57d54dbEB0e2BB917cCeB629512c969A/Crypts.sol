// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./ERC721Optimized.sol";
import "./Ownable.sol";

/// @title Graveyard NFT Project's Graveyard Interface
/// @author @0xyamyam
interface IGraveyard {
    function releaseStage() external returns (uint256);
    function isWhitelisted(address from, uint256 qty) external returns (bool);
    function updateWhitelist(address from, uint256 qty) external;
    function updateClaimable(address to, uint256 amount) external;
}

/// @title Graveyard NFT Project's Data Contract Interface
/// @author @0xyamyam
interface ICryptData {
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getRewardRate(uint256 tokenId) external view returns (uint256);
}

/// @title Graveyard NFT Project's CRYPT Token
/// @author @0xyamyam
/// CRYPT's are the centerpiece of the Graveyard NFT project.
contract Crypts is ERC721Optimized, ReentrancyGuard, Ownable(5, true, true) {
    using SafeMath for uint256;

    /// Fixed variables set on deployment
    address public immutable GRAVEYARD_ADDRESS;

    /// Data address
    address public _dataAddress;

    /// Team Accounts
    address[] private _addresses;
    uint256[] private _shares;

    /// @param graveyardAddress The address of the IGraveyard contract
    /// @param addresses List of team wallets for payouts
    /// @param shares List of percentages for team wallets
    constructor(address graveyardAddress, address[] memory addresses, uint256[] memory shares) ERC721Optimized("Graveyard CRYPTS", "CRYPT", 6969) {
        require(graveyardAddress != address(0), "Missing graveyard address");
        require(addresses.length == shares.length, "Invalid args");
        GRAVEYARD_ADDRESS = graveyardAddress;
        _addresses = addresses;
        _shares = shares;
    }

    /// Mint tokens when the release stage is whitelist (2).
    /// @param qty Number of tokens to mint (max 3)
    function whitelistMint(uint256 qty) external payable nonReentrant {
        IGraveyard graveyard = IGraveyard(GRAVEYARD_ADDRESS);
        address sender = _msgSender();
        require(graveyard.releaseStage() == 2, "Whitelist inactive");
        require(qty > 0 && graveyard.isWhitelisted(sender, qty), "Invalid whitelist address/qty");

        graveyard.updateClaimable(sender, 1e18 * 1000 * qty);
        _mintTo(sender, qty);
        graveyard.updateWhitelist(sender, qty);
    }

    /// Mint tokens when the release stage is public (>= 3).
    /// @param qty Number of tokens to mint (max 3)
    function mint(uint256 qty) external payable nonReentrant {
        IGraveyard graveyard = IGraveyard(GRAVEYARD_ADDRESS);
        address sender = _msgSender();
        require(graveyard.releaseStage() >= 3, "Mint inactive");
        require(qty > 0 && qty < 4, "Max 3 per tx");

        graveyard.updateClaimable(sender, 1e18 * 1000 * qty);
        _mintTo(sender, qty);
    }

    /// @dev Here we simply extract to reuse the actual minting across multiple methods.
    function _mintTo(address to, uint256 qty) internal {
        require(0.025 ether * qty <= msg.value, "Insufficient ether");
        _mint(to, qty);
    }

    /// Sets the data address for reveal.
    /// @param dataAddress The token data address
    function setDataAddress(address dataAddress) external onlyOwner {
        _dataAddress = dataAddress;
    }

    /// @param maxSupply alter the max supply, used to prevent new mints should all crypts not mint out during public sale
    function setMaxSupply(uint256 maxSupply) external onlyOwner {
        _setMaxSupply(maxSupply);
    }

    /// Claim tokens for team/giveaways.
    /// @param addresses An array of addresses to mint tokens for
    /// @param quantities An array of quantities for each respective address to mint
    /// @dev This method does NOT increment an addresses minting total
    function ownerClaim(address[] calldata addresses, uint256[] calldata quantities) external onlyOwner nonReentrant {
        require(addresses.length == quantities.length, "Invalid args");
        IGraveyard graveyard = IGraveyard(GRAVEYARD_ADDRESS);
        for (uint256 a = 0;a < addresses.length;a++) {
            graveyard.updateClaimable(addresses[a], 1e18 * 1000 * quantities[a]);
            _mint(addresses[a], quantities[a]);
        }
    }

    /// Set team shares, required should an address be compromised, team members change etc.
    /// @param addresses List of team wallets for payouts
    /// @param shares List of percentages for team wallets
    /// @notice Verify the addresses supplied, you wouldn't want to send to a contract or incorrect address
    function setShares(address[] memory addresses, uint256[] memory shares) external onlyOwner {
        require(addresses.length == shares.length, "Invalid args");
        _addresses = addresses;
        _shares = shares;
    }

    /// Withdraw funds for the team.
    /// @notice Overrides the default withdraw method to divide between team members
    function withdraw() external override onlyOwner {
        uint256 balance = address(this).balance;
        for (uint256 i = 0;i < _addresses.length;i++) {
            payable(_addresses[i]).call{value: balance.mul(_shares[i]).div(100)}("");
        }
    }

    /// @dev tokenURI is handled by the data contract
    /// @inheritdoc ERC721Optimized
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Invalid tokenId");

        if (_dataAddress == address(0)) return "https://graveyardnft.com/unrevealed.json";

        return ICryptData(_dataAddress).tokenURI(tokenId);
    }

    /// Returns rewards for address for committal actions.
    /// Multiplier of 1000 * token balance.
    /// @param from The address to calculate committal rewards for
    function getCommittalReward(address from) external view returns (uint256) {
        return 1e18 * 1000 * balanceOf(from);
    }

    /// Returns rewards for address for reward actions.
    /// Multiplier of 10 * token balance + multiplier if set.
    /// @param from The address to calculate reward rate for
    function getRewardRate(address from) external view returns (uint256) {
        uint256 balance = balanceOf(from);
        if (_dataAddress == address(0)) return 1e18 * 10 * balance;
        ICryptData data = ICryptData(_dataAddress);
        uint256 rate = 0;
        for (uint256 i = 0;i < balance;i++) {
            rate += data.getRewardRate(tokenOfOwnerByIndex(from, i));
        }
        return rate;
    }

    /// @dev triggers reward updates before transferring tokens for both addresses
    /// @dev we DONT do this during mint (0 address) as we can optimize by doing it in the mint function
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        if (from != address(0)) {
            IGraveyard graveyard = IGraveyard(GRAVEYARD_ADDRESS);
            graveyard.updateClaimable(from, 0);
            if(to != address(0)) graveyard.updateClaimable(to, 0);
        }
    }
}
