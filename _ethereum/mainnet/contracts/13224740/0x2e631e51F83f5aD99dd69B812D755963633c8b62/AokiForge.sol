// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Steve Aoki
/// @author: manifold.xyz

import "./ERC721BurnRedeem.sol";
import "./ERC721OwnerEnumerableSingleCreatorExtension.sol";
import "./IERC20.sol";
import "./Strings.sol";
import "./ICreatorExtensionTokenURI.sol";

contract AokiForge is
    ERC721BurnRedeem,
    ERC721OwnerEnumerableSingleCreatorExtension,
    ICreatorExtensionTokenURI
{
    using Strings for uint256;

    address public creator;
    mapping(uint256 => bool) private canClaim;
    event forgeWith(uint16 _checkToken, uint16 _burnToken);

    int256 private _offset = 0;

    string private _endpoint =
        "https://client-metadata.ether.cards/api/aoki/BridgeOverTroubledWater/";

    uint256 public forge_start = 1631638800; // 10:30pm - 1631629824 . 1am- 1631638800

    modifier forgeActive() {
        require(block.timestamp >= forge_start, "forge not started.");
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721BurnRedeem, IERC165 ,ERC721CreatorExtensionApproveTransfer)
        returns (bool)
    {
        return
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            super.supportsInterface(interfaceId) ||
            ERC721CreatorExtensionApproveTransfer.supportsInterface(
                interfaceId
            );
    }

    constructor(
        address _creator, //  0x01Ba93514e5Eb642Ec63E95EF7787b0eDd403ADd
        uint16 redemptionRate, // 1
        uint16 redemptionMax // 83
    )
        ERC721OwnerEnumerableSingleCreatorExtension(_creator)
        ERC721BurnRedeem(_creator, redemptionRate, redemptionMax)
    {
        creator = _creator;
    }

    function checkClaim(uint256 _tokenID) public view returns (bool) {
        return (canClaim[_tokenID]);
    }

    function setup() external onlyOwner {
        super._activate();

        uint256 baseFormat = 708;
        for (uint256 i = 0; i <= 84; i++) {
            canClaim[baseFormat + i] = true;
        }
    }

    function forge(uint16 _checkToken, uint16 _burnToken) public forgeActive() {
        // Attempt Burn
        // Check that we can burn
        require(redeemable(creator, _burnToken), "BurnRedeem: Invalid NFT");
        require(canClaim[_checkToken] == true, "Forged");
        canClaim[_checkToken] = false;

        try IERC721(creator).ownerOf(_checkToken) returns (
            address ownerOfAddress
        ) {
            require(
                ownerOfAddress == msg.sender,
                "checkTokenRedeem: Caller must own NFTs"
            );
        } catch (bytes memory) {
            revert("checkTokenRedeem: Bad token contract");
        }

        try IERC721(creator).ownerOf(_burnToken) returns (
            address ownerOfAddress
        ) {
            require(
                ownerOfAddress == msg.sender,
                "BurnRedeem: Caller must own NFTs"
            );
        } catch (bytes memory) {
            revert("BurnRedeem: Bad token contract");
        }

        try IERC721(creator).getApproved(_burnToken) returns (
            address approvedAddress
        ) {
            require(
                approvedAddress == address(this),
                "BurnRedeem: Contract must be given approval to burn NFT"
            );
        } catch (bytes memory) {
            revert("BurnRedeem: Bad token contract");
        }

        // Then burn
        try
            IERC721(creator).transferFrom(
                msg.sender,
                address(0xdEaD),
                _burnToken
            )
        {} catch (bytes memory) {
            revert("BurnRedeem: Burn failure");
        }

        // Mint reward
        _mintRedemption(msg.sender);
        emit forgeWith(_checkToken, _burnToken);
    }

    // tokenURI extension
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_mintNumbers[tokenId] != 0, "Invalid token");
        return
            string(
                abi.encodePacked(
                    _endpoint,
                    uint256(int256(_mintNumbers[tokenId]) + _offset).toString()
                )
            );
    }

    function tokenURI(address creator, uint256 tokenId) public view override returns (string memory) {
        return tokenURI(tokenId);
    }
    function drain(IERC20 _token) external onlyOwner {
        if (address(_token) == 0x0000000000000000000000000000000000000000) {
            payable(owner()).transfer(address(this).balance);
        } else {
            _token.transfer(owner(), _token.balanceOf(address(this)));
        }
    }

    function retrieve721(address _tracker, uint256 _id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, _id);
    }

    function how_long_more()
        public
        view
        returns (
            uint256 Days,
            uint256 Hours,
            uint256 Minutes,
            uint256 Seconds
        )
    {
        require(block.timestamp < forge_start, "Started");
        uint256 gap = forge_start - block.timestamp;
        Days = gap / (24 * 60 * 60);
        gap = gap % (24 * 60 * 60);
        Hours = gap / (60 * 60);
        gap = gap % (60 * 60);
        Minutes = gap / 60;
        Seconds = gap % 60;
        return (Days, Hours, Minutes, Seconds);
    }
}
