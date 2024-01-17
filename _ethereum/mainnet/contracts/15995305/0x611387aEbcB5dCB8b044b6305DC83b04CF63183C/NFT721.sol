// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./AccessControl.sol";
import "./ERC721Base.sol";


/**
 * @title NFT721
 * @dev anyone can mint token.
 */
contract NFT721 is AccessControl, Ownable, ERC721Base {

    bytes4 private _MINT_WITH_ADDRESS = bytes4(keccak256('MINT_WITH_ADDRESS'));

    address public transferProxy;

    constructor (string memory name, string memory symbol, address signer, string memory contractURI, string memory tokenURIPrefix) ERC721Base(name, symbol, contractURI, tokenURIPrefix) {
        // _registerInterface(bytes4(keccak256('MINT_WITH_ADDRESS')));
        _setupRole(DEFAULT_ADMIN_ROLE, signer);
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721Base) returns (bool) {
        return 
            _MINT_WITH_ADDRESS == interfaceId ||
            super.supportsInterface(interfaceId);
    }


    function addSigner(address account) public onlyOwner {
        _setupRole(DEFAULT_ADMIN_ROLE, account);
    }

    function removeSigner(address account) public onlyOwner {
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    function mint(uint256 tokenId, uint8 v, bytes32 r, bytes32 s, Fee[] memory _fees, string memory tokenURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(this, tokenId)))), v, r, s)), "owner should sign tokenId");
        // require(isSigner(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(this, tokenId)))), v, r, s)), "owner should sign tokenId");
        _mint(msg.sender, tokenId, _fees);
        _setTokenURI(tokenId, tokenURI);

        // Approve self to support airdrop for token from airdrop()
        approve(address(this), tokenId);
    }

    function setTokenURIPrefix(string memory tokenURIPrefix) public onlyOwner {
        _setTokenURIPrefix(tokenURIPrefix);
    }

    function setContractURI(string memory contractURI) public onlyOwner {
        _setContractURI(contractURI);
    }

    function setTransferProxy(address _transferProxy) public onlyOwner {
        require(transferProxy != _transferProxy, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        transferProxy = _transferProxy;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        // bypass checking for mint case
        if (creators[tokenId] == from && creators[tokenId] != address(0)) {
            if (to == address(0)) { // burn case
                return;
            }
            if (transferProxy == address(0)) { // no transferProxy set then let minter airdrop and do other transfer directly
                return;
            }
            if (_msgSender() == address(this)) { // trigger by this contract, should be by airdrop
                return;
            }
            require(transferProxy==_msgSender(), "MINTER_NOT_ALLOWED_TO_TRANSFER_OUT_OF_MARKETPLACE");
        }
    }

    function airdrop(
        address from,
        address to,
        uint256 tokenId
    ) public virtual onlyOwner {
        require(creators[tokenId] == from, "NFT721: airdrop must be from minter");

        // _transfer does not have restriction for sender.
        NFT721(this).safeTransferFrom(from, to, tokenId);
    }
}
