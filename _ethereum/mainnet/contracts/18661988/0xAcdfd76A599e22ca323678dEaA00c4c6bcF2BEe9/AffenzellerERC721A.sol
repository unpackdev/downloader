// SPDX-License-Identifier: MIT
// developed by Ahoi Kapptn! - https://ahoikapptn.com

/**
     _    _           _   _  __                 _         _ 
    / \  | |__   ___ (_) | |/ /__ _ _ __  _ __ | |_ _ __ | |
   / _ \ | '_ \ / _ \| | | ' // _` | '_ \| '_ \| __| '_ \| |
  / ___ \| | | | (_) | | | . \ (_| | |_) | |_) | |_| | | |_|
 /_/   \_\_| |_|\___/|_| |_|\_\__,_| .__/| .__/ \__|_| |_(_)
                                   |_|   |_|                                                                                                             
 */

pragma solidity 0.8.19;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";

/// @author ahoikapptn.com
/// @title Peter Affenzeller NFT
contract PeterAffenzellerNFT is ERC721A, Ownable, Pausable {
    /**
     @dev number of total minted NFTs - start must match MAX_RESERVED
     */
    uint16 public mintedPublic = 0;
    /**
     @dev maximum number of NFTs
     */
    uint16 public constant MAX_MINT = 321;
    /**
    //@dev open sale on  CET (UTC+1)
     */
    uint32 public openSaleTimestamp = 2;
    //time in future: 1794532941
    /**
     @dev the currentPrice of the NFT
     */
    uint128 public currentPrice = 0.16 ether;
    /**
     @dev the base url
     */
    string public baseURIString =
        "ipfs://Qmeg1BKXVvupCzN5ko8H2nMhBnP2F5i8ZiHGhZovqzZ1xS/";

    /**
     @dev events
     */
    event ReceivedETH(address, uint256);

    error NoAmount();
    error MaxAmountReached();
    error NotEnoughEther();
    error SaleNotOpen();
    error ContractIsPaused();
    error TransferFailed();

    constructor() ERC721A("Peter Affenzeller NFT", "AFFENZELLER NFT") {}

    function mintNFT(address to, uint16 amount) external payable {
        // Check
        if (amount < 1) revert NoAmount();
        if (msg.value < currentPrice * amount) revert NotEnoughEther();
        if (mintedPublic + amount > MAX_MINT) revert MaxAmountReached();
        if (!saleIsOpen()) revert SaleNotOpen();

        // Effects
        mintedPublic += amount;

        // Interaction
        _mint(to, amount);
    }

    function setNewURI(string memory _newURI) external onlyOwner {
        baseURIString = _newURI;
    }

    function setOpenSaleTimestamp(uint32 _timestamp) external onlyOwner {
        openSaleTimestamp = _timestamp;
    }

    function setCurrentPrice(uint128 _newPrice) external onlyOwner {
        currentPrice = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURIString;
    }

    /**
    @dev withdraw all eth from contract to owner address
    */
    function withdrawAll() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function saleIsOpen() public view returns (bool open) {
        return !paused() && (block.timestamp >= openSaleTimestamp);
    }

    /**
     * @dev override ERC721A
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        if (paused()) revert ContractIsPaused();
    }

    /**
    @dev receive ether if sent directly to this contract
    */
    receive() external payable {
        if (msg.value > 0) {
            emit ReceivedETH(msg.sender, msg.value);
        }
    }
}
