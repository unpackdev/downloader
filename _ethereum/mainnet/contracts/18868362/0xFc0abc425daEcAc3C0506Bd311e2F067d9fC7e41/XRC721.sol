// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./ERC721.sol";
import "./Ownable.sol";
import "./PoW.sol";

contract XRC721 is ERC721, PoW, Ownable {
    uint32 public constant VERSION = 1;

    uint256 public MAX_SUPPLY;
    string public BASE_URI;
    bool public EDITABLE = true;

    uint256 public TOKEN_ID;

    uint256 private _nextTokenId;

    uint256 public circulatingSupply;

    constructor(
        uint256 tokenId,
        address initialOwner,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 maxSupply,
        string memory baseURI,
        uint256 miningDifficulty,
        bool editable
    ) ERC721(tokenName, tokenSymbol) Ownable(initialOwner) {
        TOKEN_ID = tokenId;
        MAX_SUPPLY = maxSupply;
        BASE_URI = baseURI;
        DIFFICULTY = miningDifficulty;
        EDITABLE = editable;
    }

    function mint(uint256 nonce) external {
        require(circulatingSupply < MAX_SUPPLY, "Max supply reached");
        uint256 tokenId = _nextTokenId++;
        circulatingSupply++;
        _verifyPoW(nonce);
        _safeMint(_msgSender(), tokenId);
    }

    function updateToken(
        uint256 incrSupply,
        uint256 miningDifficulty,
        string memory baseURI,
        bool editable
    ) external onlyOwner {
        require(EDITABLE, "Token info is not editable");
        MAX_SUPPLY += incrSupply;
        DIFFICULTY = miningDifficulty;
        require(DIFFICULTY > 0, "Difficulty can not be zero");
        BASE_URI = baseURI;
        EDITABLE = editable;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function renounceOwnership() public override onlyOwner {
        EDITABLE = false;
        super.renounceOwnership();
    }
}
