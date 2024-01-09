// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";
import "./Counters.sol";

import "./ERC721Tradable.sol";


/**
 * @title ARA NFTs
 * Base contract to create and distribute rewards to the ARA community
 */
contract ARA is ERC721Tradable {
    using Address for address;
    using Counters for Counters.Counter;

    // ============================== Variables ===================================
    address ownerAddress;

    // Count of tokenID
    Counters.Counter private tokenIdCount;
    Counters.Counter private giveAwayIdCount;

    // Metadata setter and locker
    string private metadataTokenURI;
    uint256 immutable mvpMintStartDate;
    uint256 immutable giveAwayIndexStart;
    uint256 immutable mvpPassword;
    bool private lock;    

    // ============================== Constants ===================================
    /// @notice Price to mint the NFTs
    uint256 public constant price = 1e17;

    /// @notice Max tokens supply for this contract
    uint256 public constant maxSupply = 10000;

    /// @notice Max tokens per transactions
    uint256 public constant maxPerTx = 20;

    /// @notice Max number of tokens available during first round
    uint256 public constant roundOneSupply = 1000;

    /// @notice Max number of tokens available during second round
    uint256 public constant roundTwoSupply = 4000;

    /// @notice Start of the early sale period (in Unix second)    
    uint256 public constant mintStartDate = 1642784400;

    // ============================== Constructor ===================================

    /// @notice Constructor of the NFT contract
    /// Takes as argument the OpenSea contract to manage sells
    constructor(address _proxyRegistryAddress, uint256 mvpMintStart, uint256 giveAwayIndex, uint256 mvpPasswordInsert) 
        ERC721Tradable("ApeRacingAcademy", "ARA", _proxyRegistryAddress) {
        
        giveAwayIndexStart = giveAwayIndex;
        giveAwayIdCount._value = giveAwayIndex;
        
        metadataTokenURI = "https://aperacingacademy-metadata.herokuapp.com/metadata/";
        
        mvpMintStartDate = mvpMintStart;
        mvpPassword = mvpPasswordInsert;

        lock = false;        
    }

    // ============================== Functions ===================================

    /// @notice Returns the url of the servor handling token metadata
    /// @dev Can be changed until the boolean `lock` is set to true
    function baseTokenURI() public view override returns (string memory) {
        return metadataTokenURI;
    }

    // ============================== Public functions ===================================

    /// Return the amount of token minted, taking into account for the boost
    /// @param amount of token the msg.sender paid for
    function nitroBoost(uint256 amount) internal view returns (uint256) {
        uint256 globalAmount = amount;
        if (tokenIdCount._value < roundOneSupply) {
            globalAmount = uint256((globalAmount * 150) / 100);
        } else if (tokenIdCount._value < roundTwoSupply) {
            globalAmount = uint256((globalAmount * 125) / 100);
        }

        return globalAmount;
    }

    /// @notice Mints `tokenId` and transfers it to message sender
    /// @param amount Number tokens to mint
    function mint(uint256 amount) external payable {
        require(msg.value >= price * amount, "Incorrect amount sent");
        require(block.timestamp > mintStartDate, "Public Minting not opened yet");
        require(amount <= maxPerTx, "Limit to 20 tokens per transactions");

        uint256 boostedAmount = nitroBoost(amount);
        for (uint256 i = 0; i < boostedAmount; i++) {
            if (tokenIdCount._value < giveAwayIndexStart) {
                tokenIdCount.increment();
                _mint(msg.sender, tokenIdCount.current());
            }
        }
    }


    /// @notice Mints `tokenId` and transfers it to message sender
    /// @param amount Number tokens to mint
    function mvpMint(uint256 password, uint256 amount) external payable {
        require(msg.value >= price * amount, "Incorrect amount sent");
        require(block.timestamp > mvpMintStartDate, "MVP Minting not opened yet");
        require(amount <= maxPerTx, "Limit to 20 tokens per transactions");
        require(password == mvpPassword, "Wrong Password !");
        
        uint256 boostedAmount = nitroBoost(amount);
        for (uint256 i = 0; i < boostedAmount; i++) {
            if (tokenIdCount._value < giveAwayIndexStart) {
                tokenIdCount.increment();
                _mint(msg.sender, tokenIdCount.current());
            }           
        }
    }


    // ============================== Governor ===================================

    /// @notice Change the metadata server endpoint to final ipfs server
    /// @param ipfsTokenURI url pointing to ipfs server
    function serve_IPFS_URI(string memory ipfsTokenURI) external onlyOwner {
        require(!lock, "Metadata has been locked and cannot be changed anymore");
        metadataTokenURI = ipfsTokenURI;
    }

    /// @notice Lock the token URI, no one can change it anymore
    function lock_URI() external onlyOwner {
        lock = true;
    }

    /// @notice Mints several tokens for various addresses.
    /// @param to Array of addresses of token future owners
    function giveAway(address[] memory to) external onlyOwner {
        for (uint256 i = 0; i < to.length; i++) {
            giveAwayIdCount.increment();
            _mint(to[i], giveAwayIdCount.current());
        }
    }   


    /// @notice Recovers any ERC20 token (wETH, USDC) that could accrue on this contract
    /// @param tokenAddress Address of the token to recover
    /// @param to Address to send the ERC20 to
    /// @param amountToRecover Amount of ERC20 to recover
    function withdrawERC20(
        address tokenAddress,
        address to,
        uint256 amountToRecover
    ) external onlyOwner {
        IERC20(tokenAddress).transfer(to, amountToRecover);
    }

    /// @notice Recovers any ETH that could accrue on this contract
    /// @param to Address to send the ETH to
    function withdraw(address payable to) external onlyOwner {
      
        address investor = 0x59f1AFBD895eFF95d0D61824C16287597AF2D0E7;        
        uint256 shareInvestor;
        uint256 threshold = 30 ether;
        if (address(this).balance > threshold){
            shareInvestor = (5 * (address(this).balance - threshold)) / 100;
            payable(investor).transfer(shareInvestor);
        }                
        to.transfer(address(this).balance);
    }

    /// @notice Makes this contract payable
    receive() external payable {}

    // ============================== Internal Functions ===================================

    /// @notice Mints a new token
    /// @param to Address of the future owner of the token
    /// @param tokenId Id of the token to mint
    /// @dev Checks that the totalSupply is respected, that
    function _mint(address to, uint256 tokenId) internal override {
        require(tokenId < maxSupply, "Reached minting limit");
        super._mint(to, tokenId);
    }
}
