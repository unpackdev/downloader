/*
*         ━┳━　 ┏━┓　 ┏┓┃　 ┏━┓　 ┏━━　 ┳　 ┏┓┃┏┓┃
*  　       ┃　 　 ╋━╋　 ┃┃┃　 ╋━╋　 ┗━┓　 ┃　 ┃┃┃┃┃┃
*  　       ┃　 ┗┛　 ┗┛┃┗┛┗┛　 ┗┛━━┛　 ┻　 ┃┗┛┃┗┛
*
*
*  TANASINN IS AN INTERNET CULTURE CONSPIRACY THEORY, JOKE, AND MEME 
*  ORIGINATED IN 2003 ON THE 2CH MESSAGE BOARDS. TANASINN IS FURTHER CORRUPTED, 
*  DOCUMENTED, ARCHIVED, REMIXED, AND EXTENDED IN THIS 2023 EDITION.
* 
*  DON'T THINK. FEEL AND YOU'LL BE TANASINN.
*  NO NO CLUB IS WATCHING YOU.
*  ：(･)∴∴.(･)∵.*/
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.19;

import "./ERC2981Royalties.sol";
import "./MintLimits.sol";

contract Tanasinn is ERC2981A, MintLimits {
    constructor() ERC2981A() { }
    // solhint-disable-previous-line no-empty-blocks

    function mint(uint256 quantity) external payable onlyUnderLimit(quantity) {
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender != tx.origin) revert NoBots();
        if (!mintStarted) revert MintNotStarted();
        if (quantity + totalSupply() > TOTAL_SUPPLY) revert MaxSupply();
        if (msg.value != MINT_PRICE * quantity) revert IncorrectEthValue();

        _trackMints(quantity);
        _mint(msg.sender, quantity);
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        if (baseURIFrozen) revert URIFrozen();
        baseURI = _newBaseURI;
    }

    function freezeBaseURI() external onlyOwner {
        baseURIFrozen = true;
    }

    function startMint() external onlyOwner {
        mintStarted = true;
    }

    function withdrawFunds() external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        require(ADMIN_WALLET != address(0), "Admin wallet not set");
        (bool teamSuccess,) = ADMIN_WALLET.call{ value: address(this).balance }("");
        require(teamSuccess, "Transfer failed.");
    }

    /// @notice Overrides ERC721A start tokenId to 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @notice Overrides ERC721A baseURI function to concat baseURI+tokenId
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
