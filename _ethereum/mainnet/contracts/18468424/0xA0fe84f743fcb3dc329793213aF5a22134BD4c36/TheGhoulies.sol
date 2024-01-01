// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

/**

______________ ______________   ________  ___ ___ ________   ____ ___.____    .______________ _________
\__    ___/   |   \_   _____/  /  _____/ /   |   \\_____  \ |    |   \    |   |   \_   _____//   _____/
  |    | /    ~    \    __)_  /   \  ___/    ~    \/   |   \|    |   /    |   |   ||    __)_ \_____  \ 
  |    | \    Y    /        \ \    \_\  \    Y    /    |    \    |  /|    |___|   ||        \/        \
  |____|  \___|_  /_______  /  \______  /\___|_  /\_______  /______/ |_______ \___/_______  /_______  /
                \/        \/          \/       \/         \/                 \/           \/        \/ 
                                                         
 */

import "./ERC721A.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./Pausable.sol";

error InvalidMintQuantity();
error SoldOut();

contract TheGhoulies is ERC721A, ERC2981, Ownable, Pausable {
    address private constant _FOUNDER = 0xFCAc180d7971Ed91131BcC2Ae69752b0BC8Cc3f5;
    uint256 public constant MAX_SUPPLY = 2480;

    string private _tokenBaseURI;
    uint256 public maxMintsPerWallet = 3;

    constructor() ERC721A("TheGhoulies", "THEGHOULIES") Ownable(msg.sender) {
        _setDefaultRoyalty(address(this), 500);
        _pause();
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    function mint(uint256 quantity) external whenNotPaused {
        if (quantity + _numberMinted(msg.sender) > maxMintsPerWallet) revert InvalidMintQuantity();
        if (quantity + _totalMinted() > MAX_SUPPLY) revert SoldOut();
        _safeMint(msg.sender, quantity);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId)
            || ERC2981.supportsInterface(interfaceId);
    }
    
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setDefaultRoyalty(uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(address(this), feeNumerator);
    }

    function setMaxMintsPerWallet(uint256 _maxMintsPerWallet) external onlyOwner {
        maxMintsPerWallet = _maxMintsPerWallet;
    }

    function setTokenBaseURI(string memory tokenBaseURI_) external onlyOwner {
        _tokenBaseURI = tokenBaseURI_;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool withdrawal, ) = _FOUNDER.call{value: balance}("");
        require(withdrawal, "Withdrawal failed");
    }

    receive() external payable { } 
}
