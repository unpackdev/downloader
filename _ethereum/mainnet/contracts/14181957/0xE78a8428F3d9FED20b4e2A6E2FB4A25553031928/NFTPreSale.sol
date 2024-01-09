// SPDX-License-Identifier: MIT
// Developed by itxToledo

pragma solidity 0.8.11;

import "./Ownable.sol";

/**
 * @notice Represents CriptoMentor Smart Contract
 */
contract INFTERC721 {
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
 */
contract NFTPreSale is Ownable {
    /**
     * @notice The Smart Contract of the NFT being sold
     * @dev ERC-721 Smart Contract
     */
    INFTERC721 public immutable nft;

    /**
     * @dev MINT DATA
     */
    uint256 public maxSupply = 50;
    uint256 public minted = 0;

    uint256 public constant mintPrice = 0.12 * 10**18;
    uint256 public constant mintStart = 1644465520;
    uint256 public constant mintEnd = 1645243120;
    uint256 public constant maxMintPerWallet = 1;

    mapping(address => uint256) public addressToMints;

    /**
     * @dev Events
     */
    event ReceivedEther(address indexed sender, uint256 indexed amount);
    event Purchase(address indexed buyer, uint256 indexed amount);
    event setMaxSupplyEvent(uint256 indexed maxSupply);
    event WithdrawAllEvent(address indexed to, uint256 amount);

    constructor(address _nftaddress) Ownable() {
        nft = INFTERC721(_nftaddress);
    }

    /**
     * @dev SALE
     */

    /**
     * @notice Function to buy one or more NFTs.
     *
     * @param amount. The amount of NFTs to buy.
     */
    function buy(uint256 amount) external payable {
        /// @dev Verifies that user can mint based on the provided parameters.

        require(address(nft) != address(0), "NFT SMART CONTRACT NOT SET");

        require(block.timestamp >= mintStart, "SALE HASN'T STARTED YET");
        require(block.timestamp < mintEnd, "SALE IS CLOSED");
        require(amount > 0, "HAVE TO BUY AT LEAST 1");

        require(
            amount <= nft.maxMintPerTransaction(),
            "CANNOT MINT MORE PER TX"
        );
        require(
            addressToMints[_msgSender()] + amount <= maxMintPerWallet,
            "MINT AMOUNT EXCEEDS MAX FOR USER"
        );
        require(
            minted + amount <= maxSupply,
            "MINT AMOUNT GOES OVER MAX SUPPLY"
        );
        require(msg.value == mintPrice * amount, "ETHER SENT NOT CORRECT");

        /// @dev Updates contract variables and mints `amount` NFTs to users wallet

        minted += amount;
        addressToMints[msg.sender] += amount;
        nft.mintTo(amount, msg.sender);

        emit Purchase(msg.sender, amount);
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
