pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT License

import "./ERC20.sol";
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Pausable.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract SnapSpecialEditionCoverIssue01 is ERC721URIStorage, ERC721Pausable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint public fee;

    address payable private cashOutWallet = payable(0xE52894D7187903EF634eE9B115a1F6B7334BfE7c);
    address private immutable _deadWalletAddress = 0x000000000000000000000000000000000000dEaD;
    address private snapAddress = 0x4c5813b8c6FbbAC76CAA148aAf8910f236B56fDF;

    mapping (address => uint256) private mintedTokens;

    string private _baseURIPrefix;

    event PriceUpdated(uint newPrice);

    receive() external payable {}

    constructor() ERC721("SNAP UNIVERSE special edition cover, Issue 01", "SNAPCOVER1") {
        fee = 3000000000000000000; //3,000,000,000 SNAP!
        _baseURIPrefix = "ipfs://QmRBQzBNXzFEM9J9WAkDowUS27ev1wMcaqteUwyCsq1r6N/";
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

    function mint(address wallet, uint numberOfMints) whenNotPaused public returns (uint256) {
        require(_tokenIds.current() >= 20, "Need to mint reserved nfts first");
        require(_tokenIds.current() + numberOfMints <= 300, "Maximum amount of tokens already minted.");
        require(numberOfMints <= 1, "You cant mint more than 1 at a time.");
        require(mintedTokens[wallet] < 4, "You cant mint more than 4 for one wallet.");

        require(ERC20(snapAddress).transferFrom(msg.sender, address(this), fee * numberOfMints), "Could not transfer tokens.");

        mintedTokens[wallet] += numberOfMints;

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

        doMint(wallet, 20);

        return _tokenIds.current();
    }

    function mintSpecial(address wallet) public onlyOwner returns (uint256) {
        doMint(wallet, 1);

        return _tokenIds.current();
    }

    function updateFee(uint newFee) public onlyOwner{
      fee = newFee;

      emit PriceUpdated(newFee);
    }

    function setSnapAddress(address _snapAddress) public onlyOwner{
        snapAddress =_snapAddress;
    }

    function getFee() public view returns (uint) {
      return fee;
    }

    function cashOut() public onlyOwner {
        cashOutWallet.call{value: address(this).balance}("");
    }

    function burnOut() public onlyOwner {
        ERC20 snap = ERC20(snapAddress);
        snap.transfer(_deadWalletAddress, snap.balanceOf(address(this)));
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
