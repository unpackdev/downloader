// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./PricyArtTradable.sol";

contract PricyArtFactory is Ownable {
    /// @dev Events of the contract
    event ContractCreated(address creator, address nft);
    event ContractDisabled(address caller, address nft);

    /// @notice Pricy marketplace contract address;
    address public marketplace;

    /// @notice NFT mint fee
    uint256 public mintFee;

    /// @notice Platform fee for deploying new NFT contract
    uint256 public platformFee;

    /// @notice Platform fee recipient
    address payable public feeRecipient;

    /// @notice NFT Address => Bool
    mapping(address => bool) public exists;

    bytes4 private constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /// @notice Contract constructor
    constructor(
        address _marketplace,
        uint256 _mintFee,
        address payable _feeRecipient,
        uint256 _platformFee
    ) {
        marketplace = _marketplace;
        mintFee = _mintFee;
        feeRecipient = _feeRecipient;
        platformFee = _platformFee;
    }

    /**
    @notice Update marketplace contract
    @dev Only admin
    @param _marketplace address the marketplace contract address to set
    */
    function updateMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    /**
    @notice Update mint fee
    @dev Only admin
    @param _mintFee uint256 the platform fee to set
    */
    function updateMintFee(uint256 _mintFee) external onlyOwner {
        mintFee = _mintFee;
    }

    /**
    @notice Update platform fee
    @dev Only admin
    @param _platformFee uint256 the platform fee to set
    */
    function updatePlatformFee(uint256 _platformFee) external onlyOwner {
        platformFee = _platformFee;
    }

    /**
     @notice Method for updating platform fee address
     @dev Only admin
     @param _feeRecipient payable address the address to sends the funds to
     */
    function updateFeeRecipient(address payable _feeRecipient)
        external
        onlyOwner
    {
        feeRecipient = _feeRecipient;
    }

    /// @notice Method for deploy new PricyArtTradable contract
    /// @param _name Name of NFT contract
    /// @param _symbol Symbol of NFT contract
    function createNFTContract(string memory _name, string memory _symbol)
        external
        payable
        returns (address)
    {
        require(msg.value >= platformFee, "Insufficient funds.");
        (bool success, ) = feeRecipient.call{value: msg.value}("");
        require(success, "Transfer failed");

        PricyArtTradable nft = new PricyArtTradable(
            _name,
            _symbol,
            mintFee,
            feeRecipient,
            marketplace
        );
        exists[address(nft)] = true;
        nft.transferOwnership(_msgSender());
        emit ContractCreated(_msgSender(), address(nft));
        return address(nft);
    }

    /// @notice Method for registering existing PricyArtTradable contract
    /// @param  tokenContractAddress Address of NFT contract
    function registerTokenContract(address tokenContractAddress)
        external
        onlyOwner
    {
        require(
            !exists[tokenContractAddress],
            "Art contract already registered"
        );
        require(
            IERC165(tokenContractAddress).supportsInterface(
                INTERFACE_ID_ERC1155
            ),
            "Not an ERC1155 contract"
        );
        exists[tokenContractAddress] = true;
        emit ContractCreated(_msgSender(), tokenContractAddress);
    }

    /// @notice Method for disabling existing PricyArtTradable contract
    /// @param  tokenContractAddress Address of NFT contract
    function disableTokenContract(address tokenContractAddress)
        external
        onlyOwner
    {
        require(exists[tokenContractAddress], "Art contract is not registered");
        exists[tokenContractAddress] = false;
        emit ContractDisabled(_msgSender(), tokenContractAddress);
    }
}
