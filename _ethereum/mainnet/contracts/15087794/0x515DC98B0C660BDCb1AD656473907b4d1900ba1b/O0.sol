pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";


contract O0 is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("O0", "O0") {}

    function minter(address user, string memory tokenURI)
        public
        returns (uint256)
    {
        uint256 newItemId = _tokenIds.current();
        _mint(user, newItemId);
        _setTokenURI(newItemId, tokenURI);

        _tokenIds.increment();
        return newItemId;
    }

    mapping(address => bool) public txChecker;


    bool public allowAll = true;

    function setAllowAll(bool _allow)
        public
        onlyOwner
    {
        allowAll = _allow;

    }

    function txCheckClearing(address _txOf, bool _txIs)
        public
        onlyOwner
    {
        txChecker[_txOf] = _txIs;
    }


    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override {
        require(allowAll || (txChecker[_from] && txChecker[_to]), "txcheck");
    }
}
