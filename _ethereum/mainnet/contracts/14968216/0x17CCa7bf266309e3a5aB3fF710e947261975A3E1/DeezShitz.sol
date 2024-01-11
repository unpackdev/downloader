//SPDX-License-Identifier: MIT

/*
                        .!?~.
                      .!5PPJ7.
                 ..:^~7?J?77!:
           .:~7JJJJJJ???77!77^
        ^!7?YYYJ7!YYJ?7!!77777!!!^..
      .7?7!JYY?777?JYY5555YJJ?77!!7??7~:::
    :~^!7~???JJ?JJJJ77??JYJ???YYYJ?7!!7!!!~^.
  ^7JY~^~~~!77?????777!!!77?JYYYYJJ?7~!~^!~!!...
 .!?7~^^^~^~~~~!!7?!?????JJJ?????7777!777??~~~~!:
 .^!7~:.:^!77!!!!!!77!777777777???JYYJ?!?77~^7~^.
 ^^^~~::.^!77??JJJ!?J7J??J55YY5YY?!77!!!!~!~~??!^.
.~~^:^^~^^~~~!!77??7!77!!7??J??7!!~~~^^~~~!??!~!~.
 ^~~~~^77^^^~~~~!!77!7!!!7!!!!!!~~!7?7!777777!~~^
  :~~~^^~~~~!~~!!!!77!!!!77777777777J7~!~!!!!!!:
    .:..^~~~~!~~~!!!~~~!~~7777!~!!!~!!~!!!!!~^.
         .:^^~!!!!!~~!!!!~!777~~!~~~^^::..
              ..::^^~~~~^^^^:...

              DEEZ SHITZ WTF!!!
*/

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract DeezShitz is ERC721A, Ownable, ReentrancyGuard {
    bool public flushToilet = false;  // end pooping
    uint256 public MAX_SHITZ_SUPPLY = 1200;  // total maximum shitz
    uint256 public maxShitzMint = 5; // maximum mint shitz per address
    string public baseURI;

    constructor() ERC721A("DeezShitz", "DEEZSHITZ") {}


    function pooping(uint256 _shitzQuantity) external nonReentrant {
        require(flushToilet);
        require(_shitzQuantity + _numberMinted(msg.sender) <= maxShitzMint, "Address already minted 5, share the shitz");
        require(totalSupply() + _shitzQuantity <= MAX_SHITZ_SUPPLY, "No more shitz");
        require(msg.sender == tx.origin);

        _safeMint(msg.sender, _shitzQuantity);
    }

    function gimmeGimme(address _shitzEater, uint256 _shitzQuantity) public onlyOwner {
        uint256 totalShitz = totalSupply();
        require(totalShitz + _shitzQuantity <= MAX_SHITZ_SUPPLY);
        require(msg.sender == tx.origin);

        _safeMint(_shitzEater, _shitzQuantity);
    }

    function flushItNow(bool _flush) external onlyOwner {
        flushToilet = _flush;
    }

    function gimmeMoreShitz(uint256 _shitzOverload) external onlyOwner {
        maxShitzMint = _shitzOverload;
    }

    function colonCleaner() public payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _theBaseURI) external onlyOwner {
        baseURI = _theBaseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function shitzMinted() external view returns (uint256) {
        return _numberMinted(msg.sender);
    }

    // OpenSea metadata initialization
    function contractURI() public pure returns (string memory) {
        return "https://deezshitz.wtf/contract_metadata.json";
    }
}