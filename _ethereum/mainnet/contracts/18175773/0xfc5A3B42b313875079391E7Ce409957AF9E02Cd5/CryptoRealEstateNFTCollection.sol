//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

/**
 * @title Crypto Real Estate NFT Collection
 * @dev A contract for minting ERC721 NFTs with a maximum supply limit and fixed price.
 */
contract CryptoRealEstateNFTCollection is ERC721, ERC721URIStorage, Ownable {
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant NFT_PRICE = 2000 * 10**6;

    using SafeERC20 for IERC20;
    IERC20 public immutable usdt;

    bool public isLocked;
    uint256 public currentId;
    string private _baseURIextended;

    event EtherWithdrawn(address to, uint256 amount);
    event ERC20Withdrawn(IERC20 token, address to, uint256 amount);
    event BaseURIChanged(string newBaseURI);
    event Locked();
    event Unlocked();

    modifier whenUnlocked() {
        require(!isLocked, "You can by, only when unlocked");
        _;
    }

    /**
     * @dev Initializes the contract by setting the ERC721 name and symbol.
     */
    constructor(IERC20 _usdt) ERC721("Crypto Real Estate NFT", "CRENFT") {
        usdt = _usdt;
        isLocked = true;
    }

    /**
     * @dev Receives ETH payments.
     */
    receive() external payable {}

    /**
     * @dev Sets the base URI for token metadata.
     * @param baseURI_ The base URI to be set.
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
        emit BaseURIChanged(baseURI_);
    }

    /**
     * @notice Locks the minting functionality of the contract.
     * @dev This function can only be called by the contract owner.
     */
    function lock() external onlyOwner {
        isLocked = true;
        emit Locked();
    }

    /**
     * @notice Unlocks the minting functionality of the contract.
     * @dev This function can only be called by the contract owner.
     */
    function unlock() external onlyOwner {
        isLocked = false;
        emit Unlocked();
    }

    /**
     * @dev Safely mints a specified number of NFTs and transfers the corresponding USDT tokens from the sender to the contract.
     *
     * Requirements:
     * - The total number of minted NFTs, when added to the current count, must not exceed the maximum token supply.
     * - Sufficient USDT tokens must be approved for transfer from the sender to this contract before calling this function.
     *
     * @param to The address to which the minted NFTs will be transferred.
     * @param nftAmount The number of NFTs to mint.
     */

    function mint(address to, uint256 nftAmount) external whenUnlocked {
        require(
            nftAmount + currentId <= MAX_SUPPLY,
            "Exceeds maximum token supply"
        );
        uint256 usdtAmount = nftAmount * NFT_PRICE;
        usdt.safeTransferFrom(msg.sender, address(this), usdtAmount);
        for (uint256 i = 0; i < nftAmount; ++i) {
            ++currentId;
            _safeMint(to, currentId);
        }
    }

    /**
     * @dev Withdraws ETH from the contract.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawETH(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient founds");
        address payable to = payable(msg.sender);
        to.transfer(amount);
        emit EtherWithdrawn(to, amount);
    }

    /**
     * @dev Allows the contract owner to withdraw a specified amount of ERC20 tokens from the contract.
     * @param tokenAddress The address of the ERC20 token to withdraw.
     * @param amount The amount of ERC20 tokens to withdraw.
     */
    function withdrawERC20(
        IERC20 tokenAddress,
        uint256 amount
    ) external onlyOwner {
        tokenAddress.safeTransfer(msg.sender, amount);
        emit ERC20Withdrawn(tokenAddress, msg.sender, amount);
    }

    /**
     * @dev Retrieves the token URI for a given token ID.
     * @param tokenId The ID of the token.
     * @return The token URI.
     */
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        _requireMinted(tokenId);
        return _baseURIextended;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}
