// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Strings.sol";
import "./IFamilyMaker.sol";

contract FamilyMakerWrapper is ERC721, Ownable {
    using Address for address;
    using Strings for uint256;

    IFamilyMaker public familyMaker;

    uint8 constant SUPPLY = 88;

    /**
     * @dev Initialize the contract by setting the address of the original
     * *family maker* contract.
     *
     */
    constructor(address _familyMakerAddr)
        ERC721("left gallery familymaker", "lgfm")
    {
        familyMaker = IFamilyMaker(_familyMakerAddr);
    }

    /**
     * @dev Custom {IERC721Metadata-tokenURI} method that takes the URI from the
     * original *family maker* contract.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return familyMaker.tokenURI(tokenId);
    }

    /**
     * @dev Custom {IERC721Receiver-onERC721Received} method to **wrap** tokens
     * from the original *family maker* contract.
     *
     * The old token is owned by this contract and can be released by
     * transferring it to the original contract (see
     * {FamilyMakerWrapper-_transfer}).
     */
    function onERC721Received(
        address from,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        require(msg.sender == address(familyMaker), "FMW: Invalid contract");
        super._transfer(address(familyMaker), from, tokenId);
        return this.onERC721Received.selector;
    }

    /**
     * @dev Custom {ERC721-_safeTransfer} method. If the token receiver is the
     * original *family token* contract it ignores the `ERC721Receiver` check.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal override {
        _transfer(from, to, tokenId);
        if (to != address(familyMaker)) {
            require(
                _checkOnERC721Received(from, to, tokenId, _data),
                "ERC721: transfer to non ERC721Receiver implementer"
            );
        }
    }

    /**
     * @dev Custom {ERC721-_transfer} method that **unwrap** tokens if `to` is
     * the original *family token*.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._transfer(from, to, tokenId);
        if (to == address(familyMaker)) {
            // Transfer the legacy token to the user
            familyMaker.transferFrom(address(this), from, tokenId);
        }
    }

    /**
     * @dev Mint and wrap multiple tokens while keeping provenance and enforcing
     * the total supply.
     */
    function mintAll(
        address to,
        uint8 start,
        uint8 end
    ) external onlyOwner {
        require(end <= SUPPLY, "FMW: supply exceeded");
        for (uint256 tokenId = start; tokenId <= end; tokenId++) {
            try familyMaker.ownerOf(tokenId) {
                _mint(address(familyMaker), tokenId);
            } catch {
                familyMaker.createWork(
                    address(this),
                    string(
                        abi.encodePacked(
                            "https://left.gallery/tokens/metadata/family-maker/",
                            tokenId.toString()
                        )
                    )
                );
                _mint(to, tokenId);
            }
        }
    }

    function transferOwnershipLegacy(address newOwner) public onlyOwner {
        familyMaker.transferOwnership(newOwner);
    }
}
