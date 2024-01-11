/* ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒     ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░.       ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░█████▄   ▄  █ ██ ░▒██▄   ████▄   ▄ ▄ ▪  ░░░ ▄████░░█  ░░████▄ █▄▄▄▄ ██▒▒▒▒░
 ░▒█   ░▒█ █   █ █ █░▒█  █░▒█   █░░█   █  ░░░░▒█▀   ▀ █  ░░█   █ █  ▄▀ █ █▒▒▒░ ░
 ▄░▒▀▀▀▀▄░▒██▀▀█ █▄▄█ █   █░█   █░█ ▄   █  ░░░▒█▀▀ ░░░█ ░░░█   █ █▀▀░░░█▄▄█▒▒░
 ░▒▀▄▄▄▄▀░▒█•• █ █  █▒█  █  ▀████ █  █  █ ░▒ ░▒█  ░░░░███▄ ▀████ █  █░░█  █▒▒░▒
    ░▒░▒ ░▒█•••  █  ░▒███▀   ░▒  ░▒█ █ █ ░░▒▒░▒█ ▒▒▒     ░░▒░░░▒░░░••••░░░▒▒▒░ ░ 
    ▒▒▒▒▒▒ •••• █    ▒▒▒▒    ░▒ ░▒ ▀ ▀  ░░▒▒▒▒▀   ▪  ░░░▒▒░     ░▒░░░▒░▒░░░░▒░▒
     ▒▒▒▒ •••••••   ▪ ▪   @pixlpa    ░░░••••░░▒▒▒▒░░▒▒▒▒▪ ▪  ░░░ ░▒  ░▒.•░▒. ░
  ░▒▒▒░░░▒▒▒▒▒▒▒▒░░░░░░░░••••••••••••░░░░░░░░░░░▒▒▒▒░░••••••░░░░░░░░░░░░░░.   
▒▒▒▒▒ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ ▒▒▒▒▒▒.     .... ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒.  **

Shadow Flora
A series of 250 generative feedback compositions.
Created by Andrew Benson

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IERC2981.sol";
import "./console.sol";

contract ShadowFlora is
    ERC721Enumerable,
    ERC721Burnable,
    IERC2981,
    ReentrancyGuard,
    Ownable
{
    using SafeMath for uint256;
    using Strings for uint256;

    event baseUriUpdated(string newBaseURL);
    address payable public withdrawalAddress;

    constructor(address payable givenWithdrawalAddress) ERC721 ("Shadow Flora", "FLORA") {
        withdrawalAddress = givenWithdrawalAddress;
    }

    bool public mintActive = false;
    uint256 public lastMintedId;
    uint256 public constant MINT_PRICE = 0.2 ether;
    uint256 public constant maxSupply = 250;
    bool public baseLocked = false;
    uint256 public royaltyFeeBp = 750;

    //set to the parked metadata directory on ipfs
    string public baseURI = "ipfs://QmRtyr3qL9eXNXfU6acEJ3mXnQekKH4n1tZvPfxRfcAb5S/";

    //change to reveal the final metadata address
    function setBaseURI(string memory _url) public onlyOwner {
        require(!baseLocked, "ipfs id locked");
        emit baseUriUpdated(_url);
        baseURI = _url;
    }

    //lock metadata post-reveal
    function setBaseLocked() public onlyOwner returns (bool) {
        baseLocked = true;
        return baseLocked;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function buy() public payable nonReentrant {
        require(mintActive, "Minting is not currently active.");
        require(
            lastMintedId < maxSupply,
            "Minting has ended."
        );
        require(MINT_PRICE == msg.value, "Must use correct amount.");
        _mintNFT();
    }

    function _mintNFT() private {
        require(lastMintedId < maxSupply, "Maximum number of mints has been reached");
        uint256 newTokenId = lastMintedId + 1;
        lastMintedId = newTokenId;
        _safeMint(msg.sender, newTokenId);
    }

    // Free mint to create an artist proof if necessary
    function artistMint() public onlyOwner {
        _mintNFT();
    }

    //Trigger to start/pause minting
    function mintState() public onlyOwner returns (bool) {
        mintActive = !mintActive;
        return mintActive;
    }

    function withdraw() public onlyOwner {
        console.log("Withdrawing amount",address(this).balance);
        Address.sendValue( withdrawalAddress, address(this).balance);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");
        return (withdrawalAddress, (salePrice * royaltyFeeBp) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable,IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setRoyaltyFeeBp(uint256 _royaltyFeeBp) public onlyOwner {
        royaltyFeeBp = _royaltyFeeBp;
    }
}
