// contracts/Vero.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./IVero.sol";
import "./VeroStatuses.sol";

/// @title Smart contract for Virtual Equivalents of Real Objects, or VEROs for short
/// @author Joe Cora
/// @notice Supports all of the conditions in order to assure that this NFT can be confirmed
///  to become a VERO. Find additional details at https://vero-nft.org. Also, supports pausing the smart contract
///  for better security and easier contract migrations.
/// @dev Leverages the OpenZeppelin library to implement a contract that contains all of the
///  standard NFT (ERC-721) functions. Using some ERC-721 optional extension contracts to make
///  a VERO more usable on the blockchain and to have token metadata stored off the blockchain.
contract Vero is ERC721Enumerable, ERC721URIStorage, Pausable, IVero {
    // Tracks VERO status for all NFTs minted against this contract
    mapping(uint256 => VeroStatuses) private _veroStatuses;

    // Tracks uniqueness of VERO token URIs, which are stored off-chain
    string[] private _tokenUris;
    mapping(string => bool) private _tokenUriExists;

    // Define the VERO admin roles (who can only change the VERO status - not any NFT behavior)
    address private _veroAdminAddress;

    /// @notice Sets up the VERO admin roles that will only be able to modify the VERO status
    ///  and not any attributes that affect this token to exist as an NFT
    constructor() ERC721("VERO", "VRO") {
        // The VERO admin address is the one that creates this contract
        _veroAdminAddress = msg.sender;
    }

    // VERO-specific events ///////////////////////////////////////////////////////////////////////

    /// @dev Emitted when new VERO admin address is set, excluding when the contract is created
    event VeroAdminChanged(address indexed previousAdmin, address indexed newAdmin);

    /// @dev Emitted when the VERO status of an NFT minted against this contract changes outside
    ///  of the initial minting
    event VeroStatusChanged(address indexed _admin, uint256 indexed _tokenId,
        VeroStatuses previousStatus, VeroStatuses newStatus
    );

    // VERO-specific modifiers and functions //////////////////////////////////////////////////////

    /// @dev Access modifier to limit calling from the VERO admin address alone
    modifier onlyVeroAdmin() {
        require(msg.sender == _veroAdminAddress);
        _;
    }

    /// @notice Pauses the contract so no additional smart contract state changes can occur. Helps stop active exploits
    ///  from continuing unimpeded and also helps facilitate smart contract migrations
    /// @dev Will throw an error if tried by an account outside of the VERO admin account or if the contract is already
    ///  paused
    function pause() external onlyVeroAdmin override {
        _pause();
    }

    /// @notice Unpauses the contract so smart contract state changes can occur. Unpausing returns things to normal
    /// @dev Will throw an error if tried by an account outside of the VERO admin account or if the contract is not
    ///  paused
    function unpause() external onlyVeroAdmin override {
        _unpause();
    }

    /// @notice Retrieves the VERO admin address for anyone to see which account is the admin
    /// @return tokenId for the newly minted NFT
    function getVeroAdmin() external view override returns (address) {
        return _veroAdminAddress;
    }

    /// @notice Changes the VERO admin address to a new address, which changes admin ownership.
    ///  The VERO admin should only call this with a high level of intentionality and care.
    /// @dev Will throw errors on changes to the null address or this contract address. The
    ///  existing VERO admin account is the only one that can call this method. Throws an error when contract is
    ///  paused. Emits a "VeroAdminChanged" event upon changing the admin address.
    /// @param newAdmin The address for the account that will become the new admin
    function changeVeroAdmin(address newAdmin) external onlyVeroAdmin whenNotPaused override {
        require(newAdmin != address(0), "VERO: cannot change admin to null address");
        require(newAdmin != address(this), "VERO: cannot change admin to this contract address");
        require(newAdmin != msg.sender, "VERO: cannot change admin to current admin");

        _veroAdminAddress = newAdmin;
        emit VeroAdminChanged(msg.sender, newAdmin);
    }

    /// @notice Creates an NFT with token metadata stored off-chain for sender, who should be the
    ///  owner, and stores the VERO status as PENDING. This does not create a VERO as a VERO must
    ///  be approved before it is classified as such.
    /// @dev Throws error on already used token URI or token ID overflow. Throws an error when paused.
    /// @param _tokenURI The token URI, stored off-chain, to use to mint the NFT
    /// @return tokenId for the newly minted NFT
    function createAsPending(string memory _tokenURI) external virtual whenNotPaused override
        returns (uint256)
    {
        require(msg.sender != address(0), "VERO: cannot mint against null address");
        require(msg.sender != address(this), "VERO: cannot mint against this contract address");

        uint256 newTokenId = _consumeTokenUri(_tokenURI);
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);
        _setDefaultVeroStatus(newTokenId);

        return newTokenId;
    }

    /// @notice Retrieves the VERO status for an NFT minted against the VERO smart contract
    /// @dev Throws error when token does not exist
    /// @param _tokenId The token upon which to set the default status
    /// @return VERO status for the NFT using VeroStatuses enum value
    function getVeroStatus(uint256 _tokenId) external view virtual override returns (VeroStatuses) {
        require(_exists(_tokenId), "VERO: operator query for nonexistent token");
        return _getVeroStatus(_tokenId);
    }

    /// @notice Approves the VERO status for the token from the VERO admin address only.
    /// @dev Emits a "VeroStatusChanged" event upon changing the VERO status. Throws error
    ///  when token does not exist. Throws an error when paused.
    /// @param _tokenId The token to approve as a VERO
    function approveAsVero(uint256 _tokenId) external virtual onlyVeroAdmin whenNotPaused override {
        require(_exists(_tokenId), "VERO: operator query for nonexistent token");
        VeroStatuses currentStatus = _getVeroStatus(_tokenId);
        VeroStatuses newStatus = VeroStatuses.APPROVED;
        require(currentStatus != newStatus, "VERO: cannot approve an already approved VERO");
        _setVeroStatus(_tokenId, newStatus);
        emit VeroStatusChanged(msg.sender, _tokenId, currentStatus, newStatus);
    }

    /// @notice Rejects the VERO status for the token from the VERO admin address only. Must
    ///  be in a PENDING status to reject
    /// @dev Emits a "VeroStatusChanged" event upon changing the VERO status. Throws error
    ///  when token does not exist. Throws an error when paused.
    /// @param _tokenId The token to reject as a VERO
    function rejectAsVero(uint256 _tokenId) external virtual onlyVeroAdmin whenNotPaused override {
        require(_exists(_tokenId), "VERO: operator query for nonexistent token");
        VeroStatuses currentStatus = _getVeroStatus(_tokenId);
        VeroStatuses newStatus = VeroStatuses.REJECTED;
        require(currentStatus == VeroStatuses.PENDING,
            "VERO: cannot reject a VERO that is not in a PENDING status"
        );
        _setVeroStatus(_tokenId, newStatus);
        emit VeroStatusChanged(msg.sender, _tokenId, currentStatus, newStatus);
    }

    /// @notice Revokes the VERO status for the token from the VERO admin address only. Must
    ///  be in an APPROVED status to revoke
    /// @dev Emits a "VeroStatusChanged" event upon changing the VERO status. Throws error
    ///  when token does not exist. Throws an error when paused.
    /// @param _tokenId The token to revoke as a VERO
    function revokeAsVero(uint256 _tokenId) external virtual onlyVeroAdmin whenNotPaused override {
        require(_exists(_tokenId), "VERO: operator query for nonexistent token");
        VeroStatuses currentStatus = _getVeroStatus(_tokenId);
        VeroStatuses newStatus = VeroStatuses.REVOKED;
        require(currentStatus == VeroStatuses.APPROVED,
            "VERO: cannot revoke a VERO that is not in an APPROVED status"
        );
        _setVeroStatus(_tokenId, newStatus);
        emit VeroStatusChanged(msg.sender, _tokenId, currentStatus, newStatus);
    }

    /// @dev Adds the token URI to the list of used token URIs, if unused, so it cannot be reused. Throws an error
    ///  if the tokenId is not greater than 0
    /// @param @param _tokenURI The token URI to not allow for subsequent minting upon
    /// @return tokenId for the token URI
    function _consumeTokenUri(string memory _tokenUri) internal virtual returns (uint256)  {
        require(!_tokenUriExists[_tokenUri], "VERO: cannot mint with an already used token URI");

        _tokenUris.push(_tokenUri);
        uint256 _tokenId = _tokenUris.length;
        require(_tokenId > 0);
        _tokenUriExists[_tokenUri] = true;
        return _tokenId;
    }

    /// @dev Sets the default VERO status for the NFT, which is PENDING
    /// @param _tokenId The token upon which to set the default status
    function _setDefaultVeroStatus(uint256 _tokenId) internal virtual {
        _veroStatuses[_tokenId] = VeroStatuses.PENDING;
    }

    /// @dev Internal function to handle retrieving VERO status
    /// @param _tokenId The token upon which to set the default status
    /// @return VERO status for the NFT using VeroStatuses enum value
    function _getVeroStatus(uint256 _tokenId) internal view virtual returns (VeroStatuses) {
        return _veroStatuses[_tokenId];
    }

    /// @dev Sets the VERO status for the NFT, which can only be run by the VERO admin address
    /// @param _tokenId The token upon which to set the default status
    /// @param newStatus The new status to be assigned to the token
    function _setVeroStatus(uint256 _tokenId, VeroStatuses newStatus) internal virtual
        onlyVeroAdmin
    {
        _veroStatuses[_tokenId] = newStatus;
    }

    // Overridden functions from base contracts (functions clashes) ///////////////////////////////

    /// @notice Checks if the incoming interface ID is supported by this contract. The contract
    ///  supports standard NFT (ERC-721) interface and all of the specifications that that contract
    ///  is extended from. Also supports the VERO interface.
    /// @dev Calls the ERC721Enumerable base method as that method extends from ERC721 and calls
    ///  that base method, too.
    /// @param interfaceId ID for the interface to check for contract support upon
    /// @return Boolean for whether the contract supports the incoming interface
    function supportsInterface(bytes4 interfaceId) public view virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IVero).interfaceId ||
            ERC721Enumerable.supportsInterface(interfaceId);
    }

    /// @notice Retrieves the token URI, which is stored off-chain, for the specified token ID
    /// @dev Calls the ERC721URIStorage base method as that method extends from ERC721 and calls
    ///  that base method, too.
    /// @param tokenId ID for the NFT created against this contract
    /// @return URI for the token
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    /// @dev Calls the ERC721Enumerable base method as that method extends from ERC721 and calls
    ///  that base method, too. Throws an error when paused.
    /// @param from Blockchain address for the account transferring the NFT
    /// @param to Blockchain address for the account to which the NFT is being transferred
    /// @param tokenId ID for the NFT created against this contract
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    /// @dev Calls the ERC721URIStorage base method as that method extends from ERC721 and calls
    ///  that base method, too. Throws an error when paused.
    /// @param tokenId ID for the NFT created against this contract
    function _burn(uint256 tokenId) internal virtual whenNotPaused override(ERC721, ERC721URIStorage) {
        ERC721URIStorage._burn(tokenId);
    }

    // Overridden functions from base contracts (add pausability) /////////////////////////////////

    /// @dev Calls the ERC721 base method. Throws an error when paused.
    /// @param operator Address to allow or disallow approval for on the caller's tokens
    /// @param approved Whether to approve or disallow approval
    function setApprovalForAll(address operator, bool approved) public virtual whenNotPaused override {
        ERC721.setApprovalForAll(operator, approved);
    }

    /// @dev Calls the ERC721 base method. Throws an error when paused.
    /// @param to Address to approve as token surrogate
    /// @param tokenId Token to apply approval to
    function _approve(address to, uint256 tokenId) internal virtual whenNotPaused override {
        ERC721._approve(to, tokenId);
    }
}
