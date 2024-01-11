//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Ownable.sol";

import "./ISevenOfFew.sol";
import "./ISevenOfFewEmblems.sol";

contract SevenOfFewEmblems is ERC721, Ownable, ISevenOfFewEmblems {
    using Counters for Counters.Counter;
    using Strings for uint256;

    ISevenOfFew private immutable _sevenOfFew;

    Counters.Counter private _tokenIds;

    string private _myBaseURI;

    mapping(uint256 => uint256) private _puzzles;
    // tokenId -> puzzle : 0 - game winner
    // tokenId -> puzzle : 1 - puzzle 1 completed
    // tokenId -> puzzle : 2 - puzzle 2 completed
    // tokenId -> puzzle : 3 - puzzle 3 completed
    // tokenId -> puzzle : 4 - puzzle 4 completed
    // tokenId -> puzzle : 5 - puzzle 5 completed
    // tokenId -> puzzle : 6 - puzzle 6 completed
    // tokenId -> puzzle : 7 - puzzle 7 completed
    // tokenUd -> puzzle : 8 - all puzzles completed

    mapping(address => mapping(uint256 => bool)) private _mintedPuzzleToken;

    constructor(address _deployer, string memory baseURI_)
        ERC721("Seven Of Few Emblems", "SOFBADGE")
    {
        _sevenOfFew = ISevenOfFew(msg.sender);

        _myBaseURI = baseURI_;

        _transferOwnership(_deployer);
    }

    function sevenOfFew() external view override returns (address) {
        return address(_sevenOfFew);
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIds.current();
    }

    function completedGame(address addr) public view override returns (bool) {
        for (uint256 i = 1; i <= 7; i++) {
            if (!_mintedPuzzleToken[addr][i]) return false;
        }
        return true;
    }

    function mintPuzzleEmblem(address to, uint256 puzzleId) external override {
        require(
            !_mintedPuzzleToken[to][puzzleId],
            "Already minted puzzle emblem"
        );
        require(
            _sevenOfFew.completedPuzzle(to, puzzleId),
            "Address has not completed puzzle"
        );

        _mintEmblem(to, puzzleId);
    }

    function mintGameWinnerEmblem(address to) external override {
        require(
            completedGame(to),
            "Address has not minted all puzzles emblems"
        );

        if (!_exists(0)) {
            // mint token #0 -> first game winner
            _safeMint(to, 0);
        }

        // mint game completion emblem
        _mintEmblem(to, 0);
    }

    function _mintEmblem(address to, uint256 puzzle) private {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _safeMint(to, newItemId);

        _puzzles[newItemId] = puzzle;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token id does not exist");
        return
            string(abi.encodePacked(_myBaseURI, tokenId.toString(), ".json"));
    }

    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked(_myBaseURI, "collection.json"));
    }

    function puzzleOf(uint256 tokenId)
        external
        view
        override
        returns (uint256)
    {
        require(_exists(tokenId), "Token id does not exist");
        return _puzzles[tokenId];
    }

    function mintedPuzzleEmblem(address addr, uint256 puzzleId)
        external
        view
        override
        returns (bool)
    {
        return _mintedPuzzleToken[addr][puzzleId];
    }

    // Non transferable

    // all transfer functions
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal pure override {
        revert("Emblems cannot be transfered");
    }

    // approve functions

    function approve(address to, uint256 tokenId) public pure override {
        revert("Emblems cannot be transfered");
    }

    function setApprovalForAll(address operator, bool approved)
        public
        pure
        override
    {
        revert("Emblems cannot be transfered");
    }
}
