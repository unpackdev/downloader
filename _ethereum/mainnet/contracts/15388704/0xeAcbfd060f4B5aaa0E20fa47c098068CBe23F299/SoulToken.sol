// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract SoulOni is ERC721, Ownable {
    using Counters for Counters.Counter;

    event Attest(address indexed to, uint256 indexed tokenId);
    event Revoke(address indexed to, uint256 indexed tokenId);
    event purchase(string indexed DiscordID);

    Counters.Counter public supply;
    uint256 public Price = 0.065 ether;
    uint256 MAX_SUPPLY = 100;
    string public uri = "https://vegalabs.mypinata.cloud/ipfs/QmP5fCXe57zZMoXvtmw9DnCr24aaafZMgDehzy8aqokZUt";

    constructor() ERC721("SoulOni", "SLO") {supply.increment();}

    function OwnerMint(address to) public onlyOwner {
        uint256 tokenId = supply.current();
        supply.increment();
        _mint(to, tokenId);
    }

    function setPrice(uint256 price) public onlyOwner {
        Price = price;
    }

    function burn(uint256 tokenId) external{

        require(ownerOf(tokenId) == msg.sender, "only owner can burn");
        _burn(tokenId);
    }

    function revoke(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function Buy(string memory DiscordID) payable external {
        
        require(msg.value == Price,"wrong value");
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        uint256 tokenId = supply.current();
        require(supply.current() < MAX_SUPPLY, "max supply reached");
        supply.increment();
        _mint(msg.sender, tokenId);
        emit purchase(DiscordID);

    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override virtual {

        require(from == address(0) || to == address(0),"no transfer");
        
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override virtual {

        if(from == address(0)){
            emit Attest(to, tokenId);

        } else if(to == address(0)){
            emit Revoke(to, tokenId);
        }
    }


    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return uri;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
