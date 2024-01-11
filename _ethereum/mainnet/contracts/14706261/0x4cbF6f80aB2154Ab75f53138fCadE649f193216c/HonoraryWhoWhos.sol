// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";

contract HonoraryWhoWhos is ERC721A, Ownable {
    address public developer;

    mapping(uint256 => string) public tokenURIs;

    constructor(address _owner, address _developer)
        ERC721A("Honorary WhoWhos TreeHouse", "HONORARYWHOWHO")
    {
        require(_owner != address(0));
        _transferOwnership(_owner);
        developer = _developer;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return tokenURIs[tokenId];
    }

    function mint(address _to, uint256 _amount) public onlyAuthorized {
        _safeMint(_to, _amount);
    }

    function setTokenURI(uint256 _tokenId, string calldata _tokenURI)
        public
        onlyAuthorized
    {
        tokenURIs[_tokenId] = _tokenURI;
    }

    function setDeveloper(address _developer) public onlyAuthorized {
        developer = _developer;
    }

    modifier onlyAuthorized() {
        checkAuthorized();
        _;
    }

    function checkAuthorized() private view {
        require(
            _msgSender() == owner() || _msgSender() == developer,
            "Unauthorized"
        );
    }
}
