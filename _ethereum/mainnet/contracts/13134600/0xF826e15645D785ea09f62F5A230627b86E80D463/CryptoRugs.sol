// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract CryptoRugs is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    uint public constant MAX_RUGS = 10000;
    uint public constant MAX_LIMIT = 10;

    constructor() ERC721("CryptoRugs", "RUG") {}

    function mint(uint _num) public payable whenNotPaused {
        require(
            _tokenIdCounter.current() < MAX_RUGS,
            "TOO LATE. all rugs have been sold."
        );
        require(
            _tokenIdCounter.current() + _num < MAX_RUGS,
            "TOO MANY. there aren't this many rugs left."
        );
        require(
            msg.value >= howMuchForNextNumRugs(_num),
            "TOO LITTLE. pls send moar eth."
        );

        _mint(_num);
    }

    function _mint(uint _num) internal {
        require(
            _num <= MAX_LIMIT,
            "TOO MANY. ERC721 gas limits how much fun we can have."
        );
        for (uint i = 0; i < _num; i++) {            
            uint newTokenId = _tokenIdCounter.current();
            _safeMint(msg.sender, newTokenId);
            _tokenIdCounter.increment();
        }
    }

    function howMuchForARug(uint _rugIndex) public pure returns (uint) {
            return 0.06 ether;

    }

    function howMuchForNextNumRugs(uint _num) public view returns (uint) {        
        require(
            _tokenIdCounter.current()+_num < MAX_RUGS,
            "TOO MANY. there aren't this many rugs left."
        );

        uint _cost;
        uint _index;

        for (_index; _index < _num; _index++) {
            uint currTokenId = _tokenIdCounter.current();
            _cost += howMuchForARug(currTokenId + _index);
        }

        return _cost;
    }

    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function reserveTokens(uint256 amount) public onlyOwner {    
        for (uint i; i < amount; i++) {
            safeMint(msg.sender);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://4666ojbz1i.execute-api.eu-central-1.amazonaws.com/main/metadata/";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
