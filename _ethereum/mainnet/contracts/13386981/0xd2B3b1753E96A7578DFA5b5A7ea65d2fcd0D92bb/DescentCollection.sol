// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./IERC20.sol";


//
//
//
//      ░▓▓▓▓▓▓▓▓▓▓▓▓░░░—————░░░░░░░░░░░▓▓▓▓▓▓▓░———░░▓▓▓░░░░░░░░—███—░░░
//      ░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░————░░░░░░░░░░░░▓▓▓▓▓░░—░░░░░▓▓░░░░░░░——███—
//      ░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░————░░░░░░░░░░░▓▓▓▓▓▓░░░░░▓▓░░░░░░░░░——░
//      ░░—░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓░░░—░░░░░░░░░░░░░░▓▓▓▓▓░░—░▓░░░░░░░░░░░
//      ░░░—░░░░░———░——░░░░░░▓▓▓▓▓▓▓▓░░░—░░░░░░░░░░░░░▓▓▓▓▓░░░░░░░——————
//      —░░░░░░——————█————░—░░░░░▓▓▓▓▓▓▓░░———░░░░░░░░░░░░▓▓▓▓▓░░—░░░░░—█
//      ░░░░░░░░—█████—————░░░░░░░░░░▓▓▓▓▓▓░░░——░░░——░░░░░░░▓▓▓▓░░——░░░—
//      ░░░░░░░░░░░░░░░———————░░░░░░░░░░░▓▓▓▓▓░░———░░░░░░░░░░░░▓▓▓▓░░———
//      ░░░░░░░▓▓▓▓▓▓▓▓▓▓░░————————░░░░░░░░░▓▓▓▓▓░░░——░░░░░░░░░░░▓▓▓▓▓░░
//      ░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓░░———————░░░░░░░░░░▓▓▓▓▓░░░——░—░░░░░░░░░▓▓▓▓
//      ░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓░░░———░░░░░░░░░░░░░▓▓▓▓░░░—░░░░░░░░░░░▓░
//      ░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░▓░░░░░▓▓▓▓░░░░░░░░—░░░░░
//      ░░░░░░░░░░░——░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░—░░░░░░░░░░░░░▓▓▓▓░░░░░░░░—░░
//      ▓▓▓░░░░░░░░░░░░———░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░—░░░░░░░░░░░░▓▓▓▓▓░░░░░░░░
//      —░▓▓▓░░░░░░░░░░░————░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░▓▓▓▓░░░░░░
//      ———░▓▓▓░░░░░░░░░░░————░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░▓▓▓▓▓░░░░
//      ░————░▓▓▓░░░░░░░░░░░░——█—░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░—░░░░░░░░░░░▓▓▓▓▓░
//      ░░░░░———░▓▓░░░░░░░░░░░░░—█—░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░——░░░░░░░░░░░▓▓▓▓
//      ░▓░░░░░———░▓▓░░░░░░░░░░░░░——█—░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░——░░░░░░░░░░░░░
//      ░░░░░░░░░——█—░▓▓░░░░░░░░░░░░░—██—░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░—░░░░░░░░░░░
//      ░░░░░░░░░░░░———░░▓▓░░░▓░░░░░░░░░—███—░░▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░
//      ░░░░░░░░░░░░░░░———░▓▓░░░░░░░░░░░░░——████—░░▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░
//      —░▓▓▓░░░░░░░░░░░░————░▓▓▓░░░░░░░░░░░————██████——░░▓▓▓▓▓░░░░░░░░—
//      ————░▓▓░░░░░░░░░░░░░————░▓▓▓░░░░░░░░░——————█—██████—░▓▓▓▓░░░░——░
//      —░░—█—░░▓░░░░░░░░░░░░░——██—░▓▓▓░░░░░░░░░░░———————░░—░░░▓▓▓░░░░░░
//      —░░░░░———░░▓░░░░░░░░░░░░░░—██—░░▓▓░░░░░░░░░░░░—————░░░▓▓▓▓░░░░░░
//      ░░░░░░░░——█—░░▓░░░░░░░░░░░░░░—██—░░▓▓▓▓░░░░░░░░░░——███——░░░░░░—█
//      —█—░░░░░░░░—██—░▓▓░░░░░░░░░░░░░░——██—░▓▓▓▓░░░░░░░░░————░░░——————
//      ░░————░░░░░░░——██—░▓▓░░░░░░░░░░░░░———██—░░▓▓▓▓▓░░░░░—░░░░░░░░░░░
//      ———░░░░░░░░░░▓░░░—██—░▓▓▓░░░░░░░░░░░░———███—░░▓▓▓▓▓▓▓▓░░░░░░░░░░
//      ░░░——░░—░░░░░▓▓▓▓▓░—███—░▓▓▓░░░░░░░░░░—————████—░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//      ▓▓▓▓░░░—░░░▓░░░▓▓▓▓░░—████—░▓▓▓░░░░░░░░░———————████—░░▓▓▓▓▓▓▓▓▓▓  
//                                                                                         
//
//     Descent, 2021
//
//     Martin Houra
//     
//     https://martinhoura.net/
//
//
//

contract DescentCollection is ERC721Enumerable, ERC721Burnable, ReentrancyGuard, Ownable {

    using SafeMath for uint256;
    using Strings for uint256;

    event DescentMinted(
        address who,
        uint256 indexed tokenId
    );

    bool public isMintingActive;

    constructor() ERC721("Descent", "DESCENT") {}

    uint256 public constant MAX_SUPPLY = 111;
    uint256 private _numOfAvailableTokens = 111;
    uint256[111] private _availableTokens;
    uint256 public constant MAX_MINTABLE_IN_TXN = 3;
    string public baseURI = "ipfs://QmP1Fd6wwLoJ5af7zgciM5FCmfC9m7X5R6hQpNxA61MwzS/";

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://QmVdEPjbMtD4Ucr2Ps365NvHvdbGVi2Ei4ud5c4J2MNwyu";
    }

    function _priceCheck() public view returns (uint256) {
        require(isMintingActive, "Minting has not started yet.");
        require(totalSupply() <= MAX_SUPPLY,"Sale has already ended.");

        uint256 currentSupply = totalSupply();
        uint256 result;

        if (currentSupply >= 1) {
            result = 0.15 ether;
            return result;
        } else {
            result = 0.15 ether;
            return result;
        }
    }

    function mint(uint256 _amountToMint) public payable nonReentrant() {
        require(isMintingActive, "Minting has not started yet.");
        require(totalSupply() <= MAX_SUPPLY, "They are all gone, check OpenSea for secondary.");
        require(_amountToMint > 0 && _amountToMint <= 3, "You can only mint between 1-3 tokens at a time.");
        require(totalSupply().add(_amountToMint) <= MAX_SUPPLY, "There's been too many tokens minted already.");
        require(_priceCheck().mul(_amountToMint) <= msg.value, "Ether value sent too small.");

        _mint(_amountToMint);

    }

    function _mint(uint256 _amountToMint) internal {
        require(_amountToMint > 0 && _amountToMint <= 3, "You can only mint between 1-3 tokens at a time.");
        uint256 updatedNumAvailableTokens = _numOfAvailableTokens;
        for (uint256 i = 0; i < _amountToMint; i++) {
            uint256 RandomTokenId = _useRandomAvailableToken(_amountToMint, i) + 1;
            updatedNumAvailableTokens--;
            _safeMint(msg.sender,RandomTokenId);
            emit DescentMinted(msg.sender, RandomTokenId);
        }
        _numOfAvailableTokens = updatedNumAvailableTokens;

    }

    function reserve(address _toAddress, uint256 tokenId) public onlyOwner {
        _safeMint(_toAddress, tokenId);
    }

    function mintState() public onlyOwner returns(bool) {
        isMintingActive = !isMintingActive;
        return isMintingActive;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function forwardERC20s(IERC20 _token, address _to, uint256 _amount) public onlyOwner {
        require(address(_to) != address(0), "Can't send to a zero address.");
        _token.transfer(_to, _amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
        ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Random token generator
    function _useRandomAvailableToken(uint256 _numberToFetch, uint256 _indexToUse) internal returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encode(
                    msg.sender,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    blockhash(block.number-1),
                    _numberToFetch,
                    _indexToUse
                    )
                )
            );
        uint256 randomIndex = randomNumber % _numOfAvailableTokens;
        return _useAvailableTokenAtIndex(randomIndex);
    }

    function _useAvailableTokenAtIndex(uint256 indexToUse) internal returns (uint256) {
        
        uint256 valAtIndex = _availableTokens[indexToUse];
        uint256 result;
        
        if (valAtIndex == 0) {
            result = indexToUse;
        } else {
            result = valAtIndex;
        }
        uint256 lastIndex = _numOfAvailableTokens - 1;
        if(indexToUse != lastIndex) {
            uint256 lastValInArray = _availableTokens[lastIndex];
            if (lastValInArray == 0) {
                _availableTokens[indexToUse] = lastIndex;
            } else {
                _availableTokens[indexToUse] = lastValInArray;
            }
        }
        _numOfAvailableTokens--;
        return result;
    }
}