// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./RandomlyAssigned.sol";
import "./WithContractMetaData.sol";
import "./WithIPFSMetaData.sol";
import "./WithWithdrawals.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./SafeMath.sol";

// ================================================
//         _____ ____   ___  _   _ ___ ____
//        |_   _|  _ \ / _ \| \ | |_ _/ ___|
//          | | | |_) | | | |  \| || | |
//          | | |  _ <| |_| | |\  || | |___
//          |_| |_| \_\\___/|_| \_|___\____|
//               __  __ ___ _   _ ___
//              |  \/  |_ _| \ | |_ _|
//              | |\/| || ||  \| || |
//              | |  | || || |\  || |
//              |_|  |_|___|_| \_|___|
//       ____      _    ____ _____ ____  ____
//      |  _ \    / \  / ___| ____|  _ \/ ___|
//      | |_) |  / _ \| |   |  _| | |_) \___ \
//      |  _ <  / ___ \ |___| |___|  _ < ___) |
//      |_| \_\/_/   \_\____|_____|_| \_\____/
//
// ================================================
//    Mini cars and mint passes to Tronic Racing.
//    Race with us! https://discord.gg/A4sFesmFUq
// ================================================

contract TronicMiniRacer is ERC721, Ownable, RandomlyAssigned, WithIPFSMetaData, WithContractMetaData, WithWithdrawals {
    using SafeMath for uint256;
    uint256 public constant maxPerMint = 2;
    uint256 public saleStarted = 0;

    constructor(string memory _cid, string memory _contractMetaDataURI)
        ERC721("TronicMiniRacer", "TRONICMINI")
        RandomlyAssigned(100, 1)
        WithIPFSMetaData(_cid)
        WithContractMetaData(_contractMetaDataURI)
    {}

    function mint(uint256 amount) external payable ensureAvailabilityFor(amount) {
        require(saleStarted == 1, "Sale has not started");
        require(amount <= maxPerMint, "You can only mint 2 tokens at a time");
        require(amount > 0, "You need to mint at least 1 token");
        for (uint256 index = 0; index < amount; index++) {
            _safeMint(msg.sender, nextToken());
        }
    }

    // Note: There is no way to stop the sale once it starts
    function startSale() external onlyOwner {
        saleStarted = 1;
    }

    // Get the tokenURI for a specific token
    function tokenURI(uint256 tokenId) public view override(WithIPFSMetaData, ERC721) returns (string memory) {
        return WithIPFSMetaData.tokenURI(tokenId);
    }

    /// Set the content identifier for this collection.
    /// @param _cid the new content identifier
    function setCID(string memory _cid) external onlyOwner {
        cid = _cid;
    }

    // Configure the baseURI for the tokenURI method.
    function _baseURI() internal view override(WithIPFSMetaData, ERC721) returns (string memory) {
        return WithIPFSMetaData._baseURI();
    }
}
