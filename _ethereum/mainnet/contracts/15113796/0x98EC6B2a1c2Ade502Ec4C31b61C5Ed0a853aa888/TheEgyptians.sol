//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";

error AlreadyMinted();
error MintedOut();

contract TheEgyptians is ERC721A, Pausable, Ownable {
    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant MINTS_PER_TRANSACTION = 5;

    string private _tokenBaseURI;
    address private _founder1 = 0x5a40867784ae36E8fD284f79a220C217428305c5;
    address private _founder2 = 0x8E7952C18c14C8dD63411482C4bA064c96193fC5;

    constructor(
        string memory tokenBaseURI_,
        uint256 mintQuantity
    ) ERC721A("The Egyptians", "EGYPTS") {
        _tokenBaseURI = tokenBaseURI_;
        _mint(_founder1, mintQuantity);
        _mint(_founder2, mintQuantity);
        _pause();
    }

    /**
     * @dev Mint is Free. Calling this function mints 5 tokens per transaction. 
     * Maximum of 5 tokens per wallet.
     */
    function mint() external whenNotPaused {
        if (_numberMinted(msg.sender) > 0) { revert AlreadyMinted(); }
        if (_totalMinted() + MINTS_PER_TRANSACTION > MAX_SUPPLY) { revert MintedOut(); }
        _mint(msg.sender, MINTS_PER_TRANSACTION);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    function setTokenBaseURI(string memory tokenBaseURI_) external onlyOwner {
        _tokenBaseURI = tokenBaseURI_;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        uint256 half = address(this).balance / 2;
        (bool withdrawal1, ) = _founder1.call{value: half}("");
        require(withdrawal1, "Withdrawal 1 failed");
        (bool withdrawal2, ) = _founder2.call{value: half}("");
        require(withdrawal2, "Withdrawal 2 failed");
    }

    receive() external payable {}
}
