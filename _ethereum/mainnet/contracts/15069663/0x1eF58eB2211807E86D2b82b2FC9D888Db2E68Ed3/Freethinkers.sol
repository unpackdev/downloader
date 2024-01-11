//SPDX-License-Identifier: MIT

/*
 * ███████╗██████╗░███████╗███████╗████████╗██╗░░██╗██╗███╗░░██╗██╗░░██╗███████╗██████╗░░██████╗
 * ██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝██║░░██║██║████╗░██║██║░██╔╝██╔════╝██╔══██╗██╔════╝
 * █████╗░░██████╔╝█████╗░░█████╗░░░░░██║░░░███████║██║██╔██╗██║█████═╝░█████╗░░██████╔╝╚█████╗░
 * ██╔══╝░░██╔══██╗██╔══╝░░██╔══╝░░░░░██║░░░██╔══██║██║██║╚████║██╔═██╗░██╔══╝░░██╔══██╗░╚═══██╗
 * ██║░░░░░██║░░██║███████╗███████╗░░░██║░░░██║░░██║██║██║░╚███║██║░╚██╗███████╗██║░░██║██████╔╝
 * ╚═╝░░░░░╚═╝░░╚═╝╚══════╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═════╝░
 */

pragma solidity 0.8.15;

import "./ERC721.sol";

// ===== Error BEGIN ===== //

error NonExistentToken();
error Unauthorized();
error TransferToZeroAddress();

// ===== Error END ===== //

contract Freethinkers is ERC721 {
    using Strings for uint256;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address private _owner;

    uint256 private _currentIndex = 0;

    string private _blindBoxURI;
    string private _baseTokenURI;
    mapping(uint256 => string) private _tokenURIs;

    constructor(address ownerAddress) ERC721("Freethinkers", "FTKRS") {
        _transferOwnership(ownerAddress);
    }

    // ===== Ownership BEGIN ===== //

    modifier onlyOwner() {
        if (owner() != _msgSender()) revert Unauthorized();
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert TransferToZeroAddress();
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // ===== Ownership END ===== //

    //

    // ===== Mint BEGIN ===== //

    function totalSupply() public view returns (uint256) {
        return _currentIndex;
    }

    function ownerMint(address to) public onlyOwner {
        _safeMint(to, ++_currentIndex);
    }

    function ownerBatchMint(address[] calldata addresses) public onlyOwner {
        for (uint256 i; i < addresses.length; ) {
            _safeMint(addresses[i], ++_currentIndex);
            unchecked {
                i++;
            }
        }
    }

    // ===== Mint END ===== //

    //

    // ===== Token URI BEGIN ===== //

    function setBlindBoxURI(string calldata uri) public onlyOwner {
        _blindBoxURI = uri;
    }

    function setTokenURI(uint256 tokenId, string calldata uri) public onlyOwner {
        if (!_exists(tokenId)) revert NonExistentToken();

        _tokenURIs[tokenId] = uri;
    }

    function setBaseURI(string calldata uri) public onlyOwner {
        _baseTokenURI = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert NonExistentToken();

        string memory baseURI = _baseTokenURI;
        if (bytes(baseURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }

        string memory _tokenURI = _tokenURIs[tokenId];
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        return _blindBoxURI;
    }

    // ===== Token URI END ===== //
}
