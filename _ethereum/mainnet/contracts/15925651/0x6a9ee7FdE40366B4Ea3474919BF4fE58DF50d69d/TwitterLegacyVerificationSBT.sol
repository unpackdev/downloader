// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./IERC721.sol";
import "./ECDSA.sol";
import "./Ownable.sol";

contract TwitterLegacyVerificationSBT is ERC721, Ownable {
    using ECDSA for bytes32;

    error CannotTransferSBT();

    event Verified(address indexed wallet);

    address public signerPublicAddress;
    uint256 public totalSupply;

    mapping(uint256 => bool) public twitterIds;
    mapping(string => bool) public twitterHandles;
    mapping(uint256 => string) public urls;

    constructor(address _signerPublicAddress) ERC721("Twitter Legacy Verification SBT", "TLVSBT") {
        signerPublicAddress = _signerPublicAddress;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    function mint(uint256 twitterId, string memory twitterHandle, string memory url, bytes calldata signature) external {
        require(
            keccak256(abi.encodePacked(msg.sender, twitterId, twitterHandle, url))
            .toEthSignedMessageHash().recover(signature) == signerPublicAddress,
            "Invalid signature"
        );
        require(twitterIds[twitterId] == false, "Twitter id already used");
        require(twitterHandles[twitterHandle] == false, "Twitter handle already used");
        require(balanceOf(msg.sender) == 0, "Wallet already used");
        // Update data before mint to prevent reentrancy
        twitterIds[twitterId] = true;
        twitterHandles[twitterHandle] = true;
        urls[totalSupply] = url;
        _safeMint(msg.sender, totalSupply++);
        emit Verified(msg.sender);
    }

    function decentralize() external onlyOwner {
        signerPublicAddress = address (0);
        renounceOwnership();
    }

    function isVerifiedByTwitterId(uint256 id) public view returns (bool) {
        return twitterIds[id];
    }

    function isVerifiedByTwitterHandle(string memory handle) public view returns (bool) {
        return twitterHandles[handle];
    }

    function isVerified(address wallet) public view returns (bool) {
        return balanceOf(wallet) > 0;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return urls[tokenId];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override virtual {
        if (from != address(0)) {
            revert CannotTransferSBT();
        }
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal override virtual {
        revert CannotTransferSBT();
    }

    function _approve(address to, uint256 tokenId) internal override virtual {
        revert CannotTransferSBT();
    }
}
