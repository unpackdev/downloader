//SPDX-License-Identifier: MIT
/* To claim your autographed print, please contact younggunmotion@gmail.com */
//@dev: @brougkr
pragma solidity ^0.8.11;
import "./ERC721A.sol";
import "./Ownable.sol";

contract Grungibles is ERC721A, Ownable
{
    uint256 immutable MAX_SUPPLY = 25;
    address immutable YOUNG_GUN_MOTION = 0x45C1db3098eA7CAB18C1776eB3B0915a32F04Ad2;
    address immutable SMEARBALLZ = 0x7B6372119198cDbBcA6b04137f5DC0Baa6f92A98;
    string public contact = "To claim your autographed print, please contact younggunmotion@gmail.com";
    string public baseURI = "ipfs://QmWLQ7TmnXMiveJ7SBYCUTdtZByWq2WTio7zYBvK2TLkCS/";

    /**
     * @dev Constructor That Mints Collection And Sets Token Royalties
     */
    constructor() ERC721A("GRNG", "Grungibles") { _safeMint(YOUNG_GUN_MOTION, MAX_SUPPLY); } 

    /**
     * @dev Returns Base URI
     */
    function _baseURI() internal view virtual override returns (string memory) { return baseURI; }

    /**
     * @dev Sets Base URI
     */
    function setBaseURI(string calldata newBaseURI) public onlyOwner { baseURI = newBaseURI; }

    /**
     * @dev Withdraws Ether From Contract To Message Sender
     */
    function __withdraw() public onlyOwner { payable(msg.sender).transfer(address(this).balance); }
}
