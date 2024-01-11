// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "./ERC1155.sol";
import "./AccessControl.sol";

contract FlypeNFT is ERC1155, AccessControl {
    /// @notice Last used NFT id 
    uint256 public tokenCounter;
    /// @notice Maximum amount of NFTs
    uint256 public maxSupply;
    /// @notice True if minting is paused 
    bool public onPause;

    /// @notice List of users who can mint
    /// @dev user => isAllowed
    mapping (address => bool) public allowList;
    /// @notice List of users who have minted 
    /// @dev user => areadyMinted
    mapping (address => bool) public minted;

    /// @notice Restricts from calling function when sale is on pause
    modifier OnPause(){
        require(!onPause, "Mint is on pause");
        _;
    }

    modifier onlyOwner(){
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _;
    }

    constructor (string memory _tokenURI) ERC1155(_tokenURI) {
        _setURI(_tokenURI);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @notice Function that allows contract owner to update maximum supply of NFTs
    /// @param _newMaxSupply new masximum supply of NFTs
    function setMaxSupply(uint _newMaxSupply) external onlyOwner{
        maxSupply = _newMaxSupply;
    }

    /// @notice Function that allows contract owner to pause minting
    /// @param _onPause new state of pause
    function setOnPause(bool _onPause) external onlyOwner{
        onPause = _onPause;
    }

    /// @notice Function that allows contract owner to give permission to mint NFT for a user
    /// @param allowedUser address of user who whould be addeded to allowlist
    function addToAllowList(address allowedUser) external onlyOwner{
        _addToAllowList(allowedUser);
    }

    /// @notice Function that allows contract owner to give permission to mint NFT for multiple users
    /// @param allowedUsers addresses of users who whould be addeded to allowlist
    function multipleAddToAllowList(address[] memory allowedUsers) external onlyOwner{
        for(uint i; i < allowedUsers.length; i++){
            _addToAllowList(allowedUsers[i]);
        }
    }

    /// @notice Function that allows contract owner to remove permission to mint NFT from a user
    /// @param removedUser address of user who whould be addeded to allowlist
    function removeFromAllowList(address removedUser) external onlyOwner{
        _removeFromAllowList(removedUser); 
    }

    /// @notice Function that allows contract owner to remove permission to mint NFT for multiple users
    /// @param removedUsers addresses of users who whould be removed to allowlist
    function multipleRemoveFromAllowList(address[] memory removedUsers) external onlyOwner{
        for(uint i; i < removedUsers.length; i++){
            _removeFromAllowList(removedUsers[i]);
        }
    }

    /// @notice Function that create new NFT for the caller
    /// @dev Caller must be previously addede to allowlist 
    function mint() public OnPause returns (uint256) {
        require(allowList[_msgSender()], "Only allowed addresses can mint");
        require(!minted[_msgSender()], "Already minted");
        require(tokenCounter <= maxSupply, "All NFT's are already minted");
        uint256 newItemId = tokenCounter;
        minted[_msgSender()] = true;
        _mint(_msgSender(), newItemId, 1, new bytes(0));
        tokenCounter = tokenCounter + 1;
        return newItemId;
    }


    /// @notice Function that give permission to mint NFT for a user
    /// @param allowedUser address of user who whould be addeded to allowlist
    function _addToAllowList(address allowedUser) internal {
        allowList[allowedUser] = true;
        minted[allowedUser] = false;
    }

    /// @notice Function that remove permission to mint NFT from a user
    /// @param removedUser address of user who whould be addeded to allowlist
    function _removeFromAllowList(address removedUser) internal {
        allowList[removedUser] = false;
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override{
        revert("Non-transferable");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override{
        revert("Non-transferable");
    }

    
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC1155) returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }
}