// SPDX-License-Identifier: MIT
/**

                 ___====-_  _-====___
           _--^^^#####//      \\#####^^^--_
        _-^##########// (    ) \\##########^-_
       -############//  |\^^/|  \\############-
     _/############//   (@::@)   \\############\_
    /#############((     \\//     ))#############\
   -###############\\    (oo)    //###############-
  -#################\\  / VV \  //#################-
 -###################\\/      \//###################-
_#/|##########/\######(   /\   )######/\##########|\#_
|/ |#/\#/\#/\/  \#/\##\  |  |  /##/\#/  \/\#/\#/\#| \|
`  |/  V  V  `   V  \#\| |  | |/#/  V   '  V  V  \|  '
   `   `  `      `   / | |  | | \   '      '  '   '
                    (  | |  | |  )
                   __\ | |  | | /__
                  (vvv(VVV)(VVV)vvv)

**/
pragma solidity ^0.8.4;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";

import "./ERC721APausable.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";
import "./ERC721AOwnersExplicit.sol";

contract DreadedDragons is ERC721A, ERC721APausable, ERC721ABurnable, ERC721AQueryable, ERC721AOwnersExplicit, Ownable, PaymentSplitter, ReentrancyGuard {

    bool public   mintEnabled       = false;

    uint public   price             = 0.025 ether;
    uint public   totalAvailable    = 555;
    uint public   maxPerTx          = 10;
    uint public   maxPerWallet      = 10;

    string public baseURI;

    constructor(address[] memory addresses, uint256[] memory shares)
        ERC721A("DreadedDragons", "DD")
        PaymentSplitter(addresses, shares)
      {}

    function mintDragon(uint256 quantity) external payable {
      require(mintEnabled, "no mint yet");
      require(msg.value == quantity * price,"Please send the right amount");
      require(numberMinted(msg.sender) + quantity <= maxPerWallet,"minting too many on this wallet");
      require(totalSupply() + quantity < totalAvailable + 1, "SOLD OUT!");
      require( msg.sender == tx.origin, "You need to be who you say you are.");
      require(quantity < maxPerTx + 1, "Too many in this transaction!");

      _safeMint(msg.sender, quantity);
    }

    function reserveDragons(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity < totalAvailable + 1, 'Sorry do not have that many');
        _safeMint(msg.sender, quantity);
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function setCost(uint256 price_) external onlyOwner {
        price = price_;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function burn(uint256 tokenId, bool approvalCheck) public {
        _burn(tokenId, approvalCheck);
    }

    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
        maxPerWallet = maxPerWallet_;
    }

    function setMaxPerTx(uint256 maxPerTx_) external onlyOwner {
        maxPerTx = maxPerTx_;
    }

    function setTotalAvailable(uint256 totalAvailable_) external onlyOwner {
        totalAvailable = totalAvailable_;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A, ERC721APausable) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function enableMint() external {
        mintEnabled = true;
    }

    function disableMint() external {
        mintEnabled = false;
    }

    function pauseAllTransactions() external {
        _pause();
    }

    function unpauseAllTransactions() external {
        _unpause();
    }
}
