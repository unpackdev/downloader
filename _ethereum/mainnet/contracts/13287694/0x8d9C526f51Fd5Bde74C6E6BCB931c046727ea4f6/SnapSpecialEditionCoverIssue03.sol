pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT License

import "./ERC20.sol";
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Pausable.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract SnapSpecialEditionCoverIssue03 is ERC721URIStorage, ERC721Pausable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint public fee;

    address payable private cashOutWallet = payable(0xE52894D7187903EF634eE9B115a1F6B7334BfE7c);
    address private constant _deadWalletAddress = 0x000000000000000000000000000000000000dEaD;
    address private snapAddress = 0x4c5813b8c6FbbAC76CAA148aAf8910f236B56fDF;

    mapping (address => uint8) private mintedTokens;

    string private _baseURIPrefix;

    event PriceUpdated(uint newPrice);

    receive() external payable {}

    constructor() ERC721("SNAP UNIVERSE special edition cover, Issue 03", "SNAPCOVER3") {
        fee = 4000000000000000000; //4,000,000,000 SNAP!
        _baseURIPrefix = "ipfs://QmRspwSE8xG4uT8iDJ679T7rSCXV9nHXJ7vNjUA9DGp1SB/";

        mintOwner(msg.sender);
        _pause();
    }

    function setBaseURI(string memory baseURIPrefix) external onlyOwner {
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

    function mint(address wallet, uint8 numberOfMints) whenNotPaused external returns (uint256) {
        require(_tokenIds.current() >= 20, "Need to mint reserved nfts first");
        require(_tokenIds.current() + numberOfMints <= 300, "Maximum amount of tokens already minted");
        require(numberOfMints <= 2, "You cant mint more than 2 at a time");

        require(ERC20(snapAddress).transferFrom(msg.sender, address(this), fee * numberOfMints), "Could not transfer tokens.");

        mintedTokens[wallet] += numberOfMints;
        require(mintedTokens[wallet] <= 4, "You cant mint more than 4 for one wallet.");

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

    function mintOwner(address wallet) private onlyOwner returns (uint256) {
        require(_tokenIds.current() == 0);

        doMint(wallet, 20);

        return _tokenIds.current();
    }

    function mintSpecial(address wallet) external onlyOwner returns (uint256) {
        doMint(wallet, 1);

        return _tokenIds.current();
    }

    function updateFee(uint newFee) external onlyOwner{
      fee = newFee;

      emit PriceUpdated(newFee);
    }

    function setSnapAddress(address _snapAddress) external onlyOwner{
        snapAddress =_snapAddress;
    }

    function getFee() external view returns (uint) {
      return fee;
    }

    function cashOut() external onlyOwner {
        cashOutWallet.call{value: address(this).balance}("");
    }

    function burnOut() external onlyOwner {
        ERC20 snap = ERC20(snapAddress);
        snap.transfer(_deadWalletAddress, snap.balanceOf(address(this)));
    }

    function currentTokenId() external view returns (uint256) {
        return _tokenIds.current();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
