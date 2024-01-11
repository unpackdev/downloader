// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <0.9.0;

import "./ERC721ACommon.sol";
import "./ERC2981.sol";

interface ITokenURIGenerator {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// @author divergence.xyz
contract IABM is
    ERC721ACommon,
    ERC2981
{
    uint256 per_price = 0.05 ether;
    string defaultURI = "";
    string baseURI = "";

    constructor(
        string memory name,
        string memory symbol,
        string memory _default,
        string memory _base
    )
        ERC721ACommon(name, symbol)
    {
        setURI(_default, _base);
        _setDefaultRoyalty(msg.sender, 1000);
        _mint(msg.sender, 1);
    }

    function _baseURI()
        internal
        view
        override(ERC721A)
        returns (string memory)
    {
        return baseURI;
    }

    function publicMint(
        uint256 number
    ) external payable {
        require(msg.value >= per_price * number, "insufficient balance");
        _safeMint(msg.sender, number);
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721ACommon, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setURI(string memory _default, string memory _base) public onlyOwner {
        defaultURI = _default;
        baseURI = _base;
    }

    function withdraw() external onlyOwner {
        (bool scc, ) = payable(msg.sender).call{ value: address(this).balance }("");
        require(scc);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 20001;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if(tokenId <= 20000) {
            return defaultURI;
        }
        return bytes(_baseURI()).length != 0 ? string(abi.encodePacked(_baseURI(), _toString(tokenId - 20000))) : '';
    }

}
