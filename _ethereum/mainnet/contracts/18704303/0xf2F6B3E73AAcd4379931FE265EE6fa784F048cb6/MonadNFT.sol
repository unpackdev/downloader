// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./AccessControl.sol";
import "./PermissionManager.sol";
import "./SolidStateERC1155.sol";
import "./ERC1155MetadataStorage.sol";
import "./Pausable.sol";

contract MonadNFT is SolidStateERC1155, Pausable  {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    PermissionManager public permissionManager;

    enum AirdropType{ TRANSFER, MINTING }

    uint256 public collectionId;
    uint256 public latestTokenId;

    event TokenURISet(uint256 indexed tokenId, string uri);
    event Airdropped(uint256 indexed tokenId, uint256 receiverAmount, uint airdropType);

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 assignCollectionId,
        address permissionManagerAddress
    )  {
        _name = name_;
        _symbol = symbol_;
        permissionManager = PermissionManager(permissionManagerAddress);
        collectionId = assignCollectionId;
        _setSupportsInterface(type(IERC165).interfaceId, true);
        _setSupportsInterface(type(IERC1155).interfaceId, true);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function setTokenURI(uint256 tokenId_, string memory uri_) public onlyAdmin(){
        ERC1155MetadataStorage.layout().tokenURIs[tokenId_] = uri_;
        if(latestTokenId < tokenId_){
            latestTokenId = tokenId_;
        }
        emit TokenURISet(tokenId_, uri_);
    }

    function getNextTokenId() public view returns(uint256 next) {
        next = latestTokenId + 1;
        while(!checkTokenURIAvailable(next)){
            next = next + 1;
        }
    }

    function checkTokenURIAvailable(uint256 tokenId_) public view returns(bool isAvailable){
        ERC1155MetadataStorage.Layout storage l = ERC1155MetadataStorage
            .layout();
        string memory tokenIdURI = l.tokenURIs[tokenId_];
        isAvailable = bytes(tokenIdURI).length == 0;
    }

    function pause() public onlyAdmin() {
        _pause();
    }

    function unpause() public onlyAdmin() {
        _unpause();
    }

    /**
     * @dev airdrop from wallet allow general user to use this function (not only minter)
     */
    function airdrop(
        address from,
        address[] memory tos,
        uint256 id,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        require(tos.length == amounts.length, "ERC1155: tos and amounts length mismatch");
        address operator = _msgSender();

        for (uint256 i = 0; i < tos.length; i++) {
            address to = tos[i];
            uint256 amount = amounts[i];
            safeTransferFrom(operator, to, id, amount, data);
        }

        emit Airdropped(id, tos.length, uint(AirdropType.TRANSFER));
    }

    /**
    * @dev mint to wallet
     */
    function airdropByMinting(
        address from,
        address[] memory tos,
        uint256 id,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyMinter() {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        require(tos.length == amounts.length, "ERC1155: tos and amounts length mismatch");
        for (uint256 i = 0; i < tos.length; i++) {
            address to = tos[i];
            uint256 amount = amounts[i];
            _mint(to, id, amount, data);
        }
        emit Airdropped(id, tos.length, uint(AirdropType.MINTING));
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
    public
    onlyMinter()
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    public
    onlyMinter()
    {
        _mintBatch(to, ids, amounts, data);
    }


    function getPermissionManagerAddress() public view returns(address){
        return address(permissionManager);
    }

    /// @dev this function is for smart contract testing
    function ping() public pure returns(bool){
        return true;
    }

    modifier onlyMinter() {
        require(permissionManager.isMinter(_msgSender()), "Caller is not minter");
        _;
    }

    modifier onlyAdmin() {
        require(permissionManager.isAdmin(_msgSender()), "Caller is not admin");
        _;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if(!permissionManager.isMinter(_msgSender())){
            require(!paused(), "ERC1155Pausable: token transfer while paused");
        }
    }

}
