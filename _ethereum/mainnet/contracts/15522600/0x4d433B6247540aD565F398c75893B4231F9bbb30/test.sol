//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Base64.sol";
import "./Strings.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";

contract MembersNFT is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    Counters.Counter private _tokenIds;
    uint256 mintingPrice = 1000000000000000000; // 1.0 ETH in wei
    string private imageURI = 'ipfs://bafybeieysjbf7dyfrxsw4lczkplitwds7afplqtitbklrxucibbskqom4m';
    string private videoURI = 'ipfs://bafybeicumpdwme3i6rxlgbgkd4umpt7kgbprv5ipdgiddog2gcjfa3cndm';
    string private tokenDesc = 'Welcome to Members. A one-of-a-kind experience fusing music, entertainment, fine cuisine, and wellness. This membership gives you access to exclusive benefits and surprises. Expect the unexpected! More infos at www.members.love/membership';

    event tokenMintedEvent(address receiver, uint256 tokenId, uint256 maxSupply);

    constructor() public ERC721("The Membership by Members", "NFT") {}

    function mintNFT(address recipient) public payable
        returns (uint256)
    {
        require(msg.value >= mintingPrice || msg.sender == owner(), "Not enough ETH sent!");

        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, _buildTokenURI(newItemId));

        payable(owner()).transfer(msg.value);

        emit tokenMintedEvent(recipient, newItemId, 0);

        return newItemId;
    }

    function setTokenURI(uint256 tokenId, string calldata newURI) public onlyOwner
    {
        _setTokenURI(tokenId, newURI);
    }

    function setMintingPrice(uint256 newPrice) public onlyOwner
    {
        mintingPrice = newPrice;
    }

    function setInitDesc(string calldata newDesc) public onlyOwner
    {
        tokenDesc = newDesc;
    }

    function setInitImage(string calldata newImageURI) public onlyOwner
    {
        imageURI = newImageURI;
    }

    function setInitVideo(string calldata newVideoURI) public onlyOwner
    {
        videoURI = newVideoURI;
    }

    function burn(uint256 tokenId) public onlyOwner
    {
        _burn(tokenId);
    }

    function getFormattedId(uint256 tokenId) internal returns (string memory) {
        string memory formatted = tokenId.toString();
        if (bytes(formatted).length < 10) {
          formatted = string.concat('00', formatted);
        } else if (bytes(formatted).length < 100) {
          formatted = string.concat('0', formatted);
        }
        return formatted;
    }

    function _buildTokenURI(uint256 tokenId) internal returns (string memory) {
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name":"Member ', getFormattedId(tokenId), '",',
                '"description":"', tokenDesc, '",'
                '"image":"', imageURI, '",',
                '"animation_url":"', videoURI, '"'
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}