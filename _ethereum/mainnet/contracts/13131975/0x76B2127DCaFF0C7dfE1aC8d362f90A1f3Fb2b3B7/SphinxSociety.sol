//                              /^\
//           L L               /   \               L L
//        __/|/|_             /  .  \             _|\|\__
//       /_| [_[_\           /     .-\           /_]_] |_\
//       /__\  __`-\_____    /    .    \    _____/-`__  /__\
//      /___] /=@>  _   {>  /-.         \  <}   _  <@=\ [___\
//     /____/     /` `--/  /      .      \  \--` `\     \____\
//    /____/  \____/`-._> /               \ <_.-`\____/  \____\
//   /____/    /__/      /-._     .   _.-  \      \__\    \____\
//  /____/    /__/      /         .         \      \__\    \____\
// |____/_  _/__/      /          .          \      \__\_  _\____|
//  \__/_ ``_|_/      /      -._  .        _.-\      \_|_`` _\___/
//    /__`-`__\      <_         `-;        NDT_>      /__`-`__\
//       `-`           `-._       ;       _.-`           `-`
//                         `-._   ;   _.-`
//                             `-._.-`         awaken the sphinx
// (ascii.co.uk)                                   -the sphinx society

// SPDX-License-Identifier: MIT

// This contract was inspired in part by 2 proven deployments:
//    Forgotten Runes // On-chain wizard NFTs // https://www.forgottenrunes.com/wtf
//      0x521f9C7505005CFA19A8E5786a9c3c9c9F5e6f42
//
//    Bored Apes // Needs no introduction // https://boredapeyachtclub.com
//      0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D

pragma solidity ^0.8.6;

import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract SphinxSociety is ERC721Enumerable, Ownable {

    //////////// initialize stuff ////////////

    // sale properties
    uint256 public constant MAX_SPHINX = 7777;
    uint256 public constant MAX_PER_TX = 25;
    uint256 public constant PRICE = 70000000000000000; // 0.07 ETH
    uint256 public THE_AWAKENING = 0x0B00B1350B00B1350B00B1350B00B1350B00B1350B00B1350B00B1350B00B135;
    address public overseer;

    // inspired by FRWC @dotta
    string public constant MAAT = 
        'Those who live today will die tomorrow, those who die tomorrow will be born again; Those who live MAAT will not die.';

    // not for you
    string private _uri;

    // also not for you
    constructor() ERC721("SphinxSociety", "SPHINX") {}

    //////////// public functions ////////////

    // release based on block
    function awakeningBegun() public view returns (bool) {
        return block.number >= THE_AWAKENING;
    }

    // are you worthy ?
    function awaken(uint256 sphinxes) public payable {
        require(awakeningBegun(), 'The awakening is not yet here');
        require(sphinxes <= MAX_PER_TX, 'Even Ra cannot tame 25+ Sphinx');
        require(sphinxes + totalSupply() <= MAX_SPHINX, 'All Sphinx have already awoken');
        require(sphinxes * PRICE <= msg.value, 'You sacrifice too little Ether');

        // call storage outside loop. IDs start at 1
        uint256 idx = totalSupply() + 1;

        for (uint256 i; i < sphinxes; i++) {
            _safeMint(msg.sender, idx + i);
        }
    }

    // convenient lookup
    function tokensOfOwner(address addr) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(addr);
        if (balance == 0) {
            return new uint256[](0);
        }

        uint256[] memory tokens = new uint256[](balance);
        for (uint256 i; i < balance; i++) {
            tokens[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokens;
    }

    //////////// owner functions ////////////
    
    // set base uri
    function setBaseURI(string calldata uri) external onlyOwner {
        _uri = uri;
    }

    // set starting block
    function setAwakeningBlock(uint256 newBlock) external onlyOwner {
        THE_AWAKENING = newBlock;
    }

    // set money address
    function setOverseer(address newOverseer) external onlyOwner {
        overseer = newOverseer;
    }

    // get some money
    function withdraw(uint256 amt) external onlyOwner {
        require(address(overseer) != address(0), 'No overseer');
        payable(overseer).transfer(amt);
    }

    // get all money
    function withdraw() external onlyOwner {
        require(address(overseer) != address(0), 'No overseer');
        payable(overseer).transfer(address(this).balance);
    }

    // wait till someone sends usdt by accident
    function withdrawToken(address erc20Addr, uint256 amt) external onlyOwner {
        require(address(overseer) != address(0), 'No overseer');
        IERC20 token = IERC20(erc20Addr);
        token.transfer(overseer, amt);
    }

    // reserve first 9 for team
    function _awaken(uint256 sphinxes) public onlyOwner {
        require(!awakeningBegun(), 'Public minting has started');
        require(sphinxes + totalSupply() <= 27);

        uint256 idx = totalSupply() + 1;

        for (uint256 i; i < sphinxes; i++) {
            _safeMint(overseer, idx + i);
        }
    }

    // what if ?
    function mut(bytes calldata redacted) external onlyOwner {}

    //////////// internal functions ////////////
    
    // override so that ERC721.tokenURI() uses our base uri
    function _baseURI() internal view virtual override returns (string memory) {
        return _uri;
    }
}