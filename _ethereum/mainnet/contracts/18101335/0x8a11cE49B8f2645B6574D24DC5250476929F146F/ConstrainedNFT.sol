// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";

contract ConstrainedNFT is ERC721, Ownable {
    string private _baseTokenURI;
    address public marketplaceAddress;

    // Defining error codes
    error ApproveCallerIsNotOwner();
    error ApproveForAllNotAllowed();
    error ApproveNotAllowed();
    error ApproveToCurrentOwner();
    error ApproveNotToMarketplace();
    error CallerIsNotOwner();
    error MarketplaceAddressAlreadySet();
    error MarketplaceAddressNotSet();
    error OnlyMarketplaceContractCanInitiateTransfers();

    constructor(string memory baseURI) ERC721("Black Tulip NFT", "BTNFT") {
        // Mint the NFT
        _mint(msg.sender, 1);

        // Set the NFT base URI
        _baseTokenURI = baseURI;

        // Set the marketplace address to the zero address
        marketplaceAddress = address(0);
    }

    function approve(address _to, uint256 _tokenId) public pure override {
        // solhint-disable-next-line unused-state
        _to;
        // solhint-disable-next-line unused-state
        _tokenId;
        
        revert ApproveNotAllowed();
    }

    function _approve(address to, uint256 tokenId) internal override {
        address owner = ERC721.ownerOf(tokenId);

        if (to == owner) {
            revert ApproveToCurrentOwner();
        }

        if (_msgSender() != owner && _msgSender() != marketplaceAddress) {
            revert ApproveCallerIsNotOwner();
        }

        // Custom logic to constrain approval to the marketplace contract
        if (to != marketplaceAddress) {
            revert ApproveNotToMarketplace();
        }

        super._approve(to, tokenId);
    }

    function setApprovalForAll(
        address _operator,
        bool _approved
    ) public virtual override {
        // solhint-disable-next-line unused-state
        _operator;
        // solhint-disable-next-line unused-state
        _approved;

        revert ApproveForAllNotAllowed();
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (marketplaceAddress == address(0)) {
            revert MarketplaceAddressNotSet();
        }

        if (msg.sender != marketplaceAddress) {
            revert OnlyMarketplaceContractCanInitiateTransfers();
        }

        // Call parent function
        super._transfer(from, to, tokenId);
        _approve(marketplaceAddress, 1);
    }

    function setMarketplaceAddress(address _marketplaceAddress) external {
        // Why did I write msg.sender != marketplaceAddress?
        if (
            marketplaceAddress != address(0) && msg.sender != marketplaceAddress
        ) {
            revert MarketplaceAddressAlreadySet();
        }

        if (msg.sender != owner() && msg.sender != marketplaceAddress) {
            revert CallerIsNotOwner();
        }

        marketplaceAddress = _marketplaceAddress;

        _approve(_marketplaceAddress, 1);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}
