// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "./IStanceRKLCollection.sol";
import "./IMinterController.sol";
import "./IStanceRKLBoxesCollection.sol";
import "./ISocksMinter.sol";
import "./IERC721.sol";

import "./Bitmaps.sol";
import "./Ownable.sol";
import "./MintGuard.sol";
import "./Constants.sol";

import "./ERC721.sol";

/// @title Each Stance RKL Box acts as a unique key for RKL <> Stance collaboration
contract StanceRKLBoxesCollection is ERC721, IStanceRKLBoxesCollection, Ownable, MintGuard, Constants {
    using BitMaps for BitMaps.BitMap;

    /// @notice testnet address: 0xC83664c31616dE95345a4Bd0c6dEa9C9350935b4
    ///        ethereum address: 0xEf0182dc0574cd5874494a120750FD222FdB909a
    IERC721 public RKL_KONGS_COLLECTION;
    string private baseUri = "ipfs://QmYjGPXWbnmXpb5gSBM8MDao8Q5jTXJeVTKA9t3i65Ys7S/";
    /// @notice we use this to check if a given kong minted the socks in this contract
    /// this information is used to determine what metadata to show (open box or closed)
    ISocksMinter private socksMinter;
    /// @notice tracks last minted token id
    uint256 private lastTokenId;
    /// @notice tracks which kongs minted boxes
    BitMaps.BitMap kongsThatMinted;

    constructor(address rklKongsCollection) {
        admin = msg.sender;
        RKL_KONGS_COLLECTION = IERC721(rklKongsCollection);
        // UTC: Monday, 4 September 2023 17:00:00, which is 1PM ET
        mintOpenOnTimestamp = 1693846800;
    }

    // =====================================================================//
    //                          Collection Meta                             //
    // =====================================================================//

    function name() public pure override returns (string memory) {
        return "RKL x Stance Boxes";
    }

    function symbol() public pure override returns (string memory) {
        return "RKLSB";
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (socksMinter.getBoxesThatMinted(id) == true) {
            return string(abi.encodePacked(baseUri, "openbox.json"));
        }
        return string(abi.encodePacked(baseUri, "closedbox.json"));
    }

    // =====================================================================//
    //                          Utils & Mint                                //
    // =====================================================================//

    function checkKongCanClaim(uint256[] calldata kongIds) public view returns (bool[] memory) {
        bool[] memory kongCanClaim = new bool[](kongIds.length);
        for (uint256 i = 0; i < kongIds.length;) {
            if (kongsThatMinted.get(kongIds[i]) == true) {
                kongCanClaim[i] = false;
            } else {
                kongCanClaim[i] = true;
            }
            unchecked {
                ++i;
            }
        }
        return kongCanClaim;
    }

    function checkKongCanClaimReverts(uint256[] calldata kongIds) private view {
        for (uint256 i = 0; i < kongIds.length;) {
            if (kongsThatMinted.get(kongIds[i]) == true) {
                revert KongAlreadyClaimed(kongIds[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    function checkCallerOwnerOfKongs(uint256[] calldata kongIds) private view {
        for (uint256 i = 0; i < kongIds.length;) {
            if (msg.sender != RKL_KONGS_COLLECTION.ownerOf(kongIds[i])) {
                revert CallerNotOwner(kongIds[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    function getTokensOwnedByAddress(address owner, uint256 offset, uint256 limit)
        external
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(owner);

        if (balance == 0 || offset >= balance) {
            // return empty array if no tokens owned or offset is out of bounds
            return new uint256[](0);
        }

        // ensure that we don't fetch more than the balance or exceed the limit
        uint256 balanceMinusOffset = balance - offset;
        uint256 resultsCount = (balanceMinusOffset > limit) ? limit : balanceMinusOffset;

        uint256[] memory ownedTokens = new uint256[](resultsCount);
        uint256 counter = 0;
        uint256 tokenId = 0;

        while (counter < resultsCount) {
            try this.ownerOf(tokenId) returns (address tokenOwner) {
                if (tokenOwner == owner) {
                    if (tokenId >= offset) {
                        ownedTokens[counter] = tokenId;
                        counter++;
                    }
                }
                // catch and do nothing if ownerOf reverts
            } catch {}
            tokenId++;
        }

        return ownedTokens;
    }

    function mint(address to, uint256[] calldata kongIds) external {
        checkIfMintOpen();
        checkKongCanClaimReverts(kongIds);
        checkCallerOwnerOfKongs(kongIds);
        kongsThatMinted.batchSet(kongIds);
        for (uint256 i = 0; i < kongIds.length;) {
            super._mint(to, lastTokenId);
            unchecked {
                ++i;
                ++lastTokenId;
            }
        }
    }

    // =====================================================================//
    //                              Admin                                   //
    // =====================================================================//

    function setSocksMinter(address _socksMinter) external onlyOwner {
        socksMinter = ISocksMinter(_socksMinter);
    }

    function setBaseUri(string calldata newBaseUri) external onlyOwner {
        baseUri = newBaseUri;
    }
}
