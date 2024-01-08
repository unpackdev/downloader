pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT License

// WE ARE SELLING DOGSHIT ON THE BLOCKCHAIN
// Check https://www.dogshitnfts.com/
//
//  ........................................
//  ........................................
//  ..................'.............'.......
//  ........'''''..''''.............'''..'''
//  ..................................'...'.
//  ................   ..   ..........'..''.
//  ................  .::;.   ..............
//  ..'......'...    .,:::,.    ......'.....
//  llllllllcc:.  .,;;:;;,..      ':llllcccl
//  dddddol,... .,;:::,'..  ..'.   .:ooooood
//  dddddo, .......','......;:;..   'lododdd
//  dddddl'.,::;'.';;;;;;;;;;,..     ,oddddd
//  dddo:.  ';:;:::::;::::;,..        .:odod
//  dddl. ..........',,,,,'......',.   .lddd
//  dddl..;;;,'....',;;;;;;;;;;;;,'.   .clll
//  dddl..';:;;:;;::;;;:::;;:;,''..    .:ccc
//  dddoc'.....................       .;cccc
//  dddool:;'.    ..    ....      ..';cccllo
//  ooooooodollllllllllllllllllllllooooooodd
//  looodddodddddddddddddddddddddodddddddddd

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Pausable.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract DogShitNfts is ERC721URIStorage, ERC721Pausable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint public fee;

    address payable private cashOutWallet = payable(0x26121df02555a5292ccc5472153eBEEb0e78A192);
    address[] private cashOutCallers = [0xdbD8BeDceBFA5F98FAb28B6643D98A71A0FCD2d3, 0xA93Cd53a4735fCfA2CB4082Ee8C8cDF3A5cA0114];

    string private _baseURIPrefix;

    event PriceUpdated(uint newPrice);

    receive() external payable {}

    constructor() ERC721("DOGSHIT", "DOGSHIT") {
        fee = 30000000000000000 wei; //0.03 ETH
        _baseURIPrefix = "ipfs://QmPGM5qJ4UJxUnY4z76dgiqVBFy4yZ3vmW37G856Z1usuT/";
    }

    function setBaseURI(string memory baseURIPrefix) public onlyOwner {
        _baseURIPrefix = baseURIPrefix;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function mint(address wallet, uint numberOfMints) whenNotPaused public payable returns (uint256) {
        require(_tokenIds.current() >= 10, "Need to mint reserved nfts first");
        require(_tokenIds.current() + numberOfMints <= 2500, "Maximum amount of tokens already minted.");
        require(msg.value >= fee * numberOfMints, "Fee is not correct.");  //User must pay set fee.
        require(numberOfMints <= 30, "You cant mint more than 30 at a time.");

        doMint(wallet, numberOfMints);

        return _tokenIds.current();
    }

    function doMint(address wallet, uint numberOfMints) private {
        for(uint i = 0; i < numberOfMints; i++) {
            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();
            _safeMint(wallet, tokenId);

            string memory tokenURISuffix = string(abi.encodePacked(toString(tokenId),  ".json"));
            _setTokenURI(tokenId, tokenURISuffix);
        }
    }

    function mintOwner(address wallet) public onlyOwner returns (uint256) {
        require(_tokenIds.current() == 0);

        doMint(wallet, 10);

        return _tokenIds.current();
    }

    function updateFee(uint newFee) public onlyOwner{
      fee = newFee;

      emit PriceUpdated(newFee);
    }

    function getFee() public view returns (uint) {
      return fee;
    }

    function cashOut() public {
        require(msg.sender == cashOutCallers[0] || msg.sender == cashOutCallers[1], "Should be called with whitelisted wallet");
        cashOutWallet.call{value: address(this).balance}("");
    }

    function currentTokenId() public view returns (uint256) {
        return _tokenIds.current();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
