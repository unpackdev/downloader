// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./ApparelArtTradable.sol";

contract ApparelArtFactory is AccessControl {
    /// @dev Events of the contract
    event ContractCreated(address creator, address nft);
    event ContractDisabled(address caller, address nft);

    /// @notice Apparel marketplace contract address;
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

    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    /// @notice Contract constructor
    constructor(
        address _marketplace,
        uint256 _mintFee,
        address payable _feeRecipient,
        uint256 _platformFee
    ) public {
        marketplace = _marketplace;
        mintFee = _mintFee;
        feeRecipient = _feeRecipient;
        platformFee = _platformFee;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addModerator(address _moderator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(MODERATOR_ROLE, _moderator);
    }

    function removeModerator(address _moderator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MODERATOR_ROLE, _moderator);
    }

    /**
    @notice Update marketplace contract
    @dev Only admin
    @param _marketplace address the marketplace contract address to set
    */
    function updateMarketplace(address _marketplace) external onlyRole(DEFAULT_ADMIN_ROLE) {
        marketplace = _marketplace;
    }

    /**
    @notice Update mint fee
    @dev Only admin
    @param _mintFee uint256 the platform fee to set
    */
    function updateMintFee(uint256 _mintFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintFee = _mintFee;
    }

    /**
    @notice Update platform fee
    @dev Only admin
    @param _platformFee uint256 the platform fee to set
    */
    function updatePlatformFee(uint256 _platformFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        platformFee = _platformFee;
    }

    /**
     @notice Method for updating platform fee address
     @dev Only admin
     @param _feeRecipient payable address the address to sends the funds to
     */
    function updateFeeRecipient(address payable _feeRecipient)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        feeRecipient = _feeRecipient;
    }

    /// @notice Method for deploy new ApparelArtTradable contract
    /// @param _name Name of NFT contract
    /// @param _symbol Symbol of NFT contract
    function createNFTContract(string memory _name, string memory _symbol)
        external
        payable
        returns (address)
    {
        require(msg.value >= platformFee, "Insufficient funds.");
        (bool success,) = feeRecipient.call{value: msg.value}("");
        require(success, "Transfer failed");

        ApparelArtTradable nft = new ApparelArtTradable(
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

    /// @notice Method for registering existing ApparelArtTradable contract
    /// @param  tokenContractAddress Address of NFT contract
    function registerTokenContract(address tokenContractAddress)
        external
        onlyRole(MODERATOR_ROLE)
    {
        require(!exists[tokenContractAddress], "Art contract already registered");
        require(IERC165(tokenContractAddress).supportsInterface(INTERFACE_ID_ERC1155), "Not an ERC1155 contract");
        exists[tokenContractAddress] = true;
        emit ContractCreated(_msgSender(), tokenContractAddress);
    }

    /// @notice Method for disabling existing ApparelArtTradable contract
    /// @param  tokenContractAddress Address of NFT contract
    function disableTokenContract(address tokenContractAddress)
        external
        onlyRole(MODERATOR_ROLE)
    {
        require(exists[tokenContractAddress], "Art contract is not registered");
        exists[tokenContractAddress] = false;
        emit ContractDisabled(_msgSender(), tokenContractAddress);
    }
}
