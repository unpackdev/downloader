// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./Mintable.sol";
import "./ERC721.sol";
import "./ERC721Pausable.sol";
import "./ERC721URIStorage.sol";
import "./AccessControl.sol";

import "./String.sol";
import "./Fields.sol";

abstract contract Base is
    Fields,
    AccessControl,
    ERC721URIStorage,
    ERC721Pausable,
    Mintable
{
    /**
     * @dev Set the baseURI to a given uri
     * @param baseURI_ string to save
     */
    function changeBaseURI(string memory baseURI_) external {
        require(hasRole(SET_URI_ROLE, msg.sender), "Caller can't change URI");
        _baseTokenURI = baseURI_;
    }

    /**
     * @dev baseURI for computing {tokenURI}. Empty by default, can be overwritten
     * in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        _;
    }

    function setupRole(string memory role, address to) external onlyOwner {
        _setupRole(bytes32(bytes(role)), to);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function setProxyMinter(address imx_) public onlyAdmin {
        imx = imx_;
    }

    function pause() public virtual onlyAdmin {
        _pause();
    }

    function unpause() public virtual onlyAdmin {
        _unpause();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function burn(uint256 tokenId) public {
        require(ERC721.ownerOf(tokenId) == msg.sender, "Base: can't burn");
        _burn(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Pausable) {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Send an amount of value to a specific address
     * @param to_ address that will receive the value
     * @param value to be sent to the address
     */
    function sendValueTo(address to_, uint256 value) internal {
        address payable to = payable(to_);
        (bool success, ) = to.call{value: value}("");
        require(success, "Function call error");
    }

    /**
     * @dev Withdraw remaining contract balance to owner
     */
    function withdrawContractBalance() public onlyOwner {
        sendValueTo(owner(), address(this).balance);
    }
}
