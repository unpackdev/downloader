// SPDX-License-Identifier: UNLICENSED
// https://twitter.com/_probably_nft
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./IERC2981.sol";
import "./ERC721A.sol";

/**********************************************
 * Nothing free here, probably
 * Only blackhole here
 **********************************************/

contract ProbablyNothing is ERC721A, IERC2981, Ownable {
    bool public explosion;
    bool public void;
    string public position;
    address public kaprekar;
    uint256 public constant blackhole_value = 0.01 ether;
    uint256 public constant blackhole = 6174;
    uint256 public constant maxMint = 5;
    mapping(address => bool) public astronaut;

    constructor() ERC721A("ProbablyNothing", "PROBABLY") {
        kaprekar = owner();
    }


    function explosionFirst(uint _amount) payable external {
        uint256 nothings = _totalMinted();

        require(msg.value == blackhole_value, "nothing free here");
        require(msg.sender == tx.origin, "must be human");
        require(explosion, "must be explosion");
        require(!astronaut[msg.sender], "explosion happened");
        require(_amount <= maxMint, "too much");
        require(nothings + _amount <= blackhole, "too much");

        _safeMint(msg.sender, _amount);
        astronaut[msg.sender] = true;
    }


    function kaprekarMint(address someplace, uint256 some) external onlyOwner {
        uint256 nothings = _totalMinted();
        require(nothings + some <= blackhole, "too much");

        _safeMint(someplace, some);
    }


    function happen(bool _explosion) external onlyOwner {
        explosion = _explosion;
    }

    function findTheTruth(string calldata _position) external onlyOwner {
        position = _position;
    }

    function becomeKaprekar(address _kaprekar) external onlyOwner {
        kaprekar = _kaprekar;
    }

    function answer(bool _void) external onlyOwner {
        void = _void;
    }

    function alchemy() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success);
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return position;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "nothing there");
        return (kaprekar, (salePrice * 7) / 100);
    }
}