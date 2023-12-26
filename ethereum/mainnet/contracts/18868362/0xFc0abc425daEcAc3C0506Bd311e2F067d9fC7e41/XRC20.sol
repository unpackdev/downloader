// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./ERC20.sol";
import "./Ownable.sol";
import "./PoW.sol";

contract XRC20 is ERC20, PoW, Ownable {
    uint32 public constant VERSION = 1;

    uint256 public MAX_SUPPLY;
    uint256 public MINT_AMOUNT_PER_TX;
    bool public EDITABLE = true;

    uint256 public TOKEN_ID;

    uint8 private _DECIMALS;

    constructor(
        uint256 tokenId,
        address initialOwner,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 maxSupply,
        uint8 decimal,
        uint256 tokenPerMint,
        uint256 miningDifficulty,
        bool editable
    ) ERC20(tokenName, tokenSymbol) Ownable(initialOwner) {
        TOKEN_ID = tokenId;
        MAX_SUPPLY = maxSupply;
        _DECIMALS = decimal;
        MINT_AMOUNT_PER_TX = tokenPerMint;
        DIFFICULTY = miningDifficulty;
        EDITABLE = editable;
    }

    function decimals() public view virtual override returns (uint8) {
        return _DECIMALS;
    }

    function mint(uint256 nonce) external {
        require(
            totalSupply() + MINT_AMOUNT_PER_TX <= MAX_SUPPLY,
            "Max supply reached"
        );

        _verifyPoW(nonce);
        _mint(_msgSender(), MINT_AMOUNT_PER_TX);
    }

    function updateToken(
        uint256 incrSupply,
        uint256 miningDifficulty,
        bool editable
    ) external onlyOwner {
        require(EDITABLE, "Token info is not editable");
        require(DIFFICULTY > 0, "Difficulty can not be zero");

        MAX_SUPPLY += incrSupply;
        DIFFICULTY = miningDifficulty;
        EDITABLE = editable;
    }

    function renounceOwnership() public override onlyOwner {
        EDITABLE = false;
        super.renounceOwnership();
    }
}
