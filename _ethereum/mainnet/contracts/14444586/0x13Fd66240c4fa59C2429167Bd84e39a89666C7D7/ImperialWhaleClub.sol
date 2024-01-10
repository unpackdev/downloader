//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract ImperialWhaleClub is ERC721Enumerable, Ownable {
    //Constants
    uint256 public constant MAX_SUPPLY = 8999; 
    uint256 public MINT_PRICE = 0.12 ether;
    address public constant WITHDRAWALL_ADDRESS =
        address(0x1f8655E56E00124C1376Ed456AE6F121d65E32B8);

    //Mappings
    mapping(address => bool) WHITELIST;

    //Members
    string private BASEURI;
    string private BLINDBASEURI;
    bool private WHITELISTACTIVE = true;

    bool private ISACTIVE;
    bool private ISREVEALED;

    constructor() ERC721("IMPERIALWHALECLUB", "IWC") {}

    //*********************Minting*********************/

    function mintNft(uint256 quantity) external payable {
        //check is revealed
        require(ISACTIVE, "Not active yet");
        //check whitelist
        require(!WHITELISTACTIVE || WHITELIST[msg.sender], "You're not whitelisted");
        /// block transactions that would exceed the maxSupply
        require(totalSupply() + quantity <= MAX_SUPPLY, "Supply is exhausted");
        // block transactions that don't provide enough ether
        require(
            msg.value >= MINT_PRICE * quantity,
            "Insufficient ether sent for mint"
        );

        /// mint the requested quantity
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = totalSupply() + 1;
            _safeMint(msg.sender, tokenId);
        }
    }

    function mintOwner(address to, uint256 quantity) external onlyOwner {
        /// block transactions that would exceed the maxSupply
        require(totalSupply() + quantity <= MAX_SUPPLY, "Supply is exhausted");

        /// mint the requested quantity
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = totalSupply() + 1;
            _safeMint(to, tokenId);
        }
    }

    //*********************BaseUri*********************/

    function setURIs(string memory blindURI, string memory baseUri)
        external
        onlyOwner
    {
        BLINDBASEURI = blindURI;
        BASEURI = baseUri;
    }

    //*********************Whitelist*********************/

      function setWhitelistInactive()
        external
        onlyOwner
    {
        WHITELISTACTIVE = false;
    }

    //*********************Withdraw*********************/
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance should be more then zero");
        payable(WITHDRAWALL_ADDRESS).transfer(balance);
    }

    //*********************Whistlisting*********************/


    function addAdressesToWhitelist(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            WHITELIST[addresses[i]] = true;
        }
    }

    function addAddressToWhitelist(address _address) external onlyOwner {
        WHITELIST[_address] = true;
    }

    function removeAddresFromWhitelist(address _address) external onlyOwner {
        WHITELIST[_address] = false;
    }

    function isWhitelisted(address _address) external view returns (bool) {
        return WHITELIST[_address];
    }

    //*********************REVEALING*********************/

    function setActive() external onlyOwner {
        ISACTIVE = true;
    }

    function setRevealed() external onlyOwner {
        ISREVEALED = true;
    }


    function setPrice(uint256 percentage ) external onlyOwner {
        MINT_PRICE = 1 ether *  percentage / 100;
    }

    function tokenURI(uint256 _tokenId) public view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (!ISREVEALED) {
            return string(abi.encodePacked(BLINDBASEURI));
        } else {
            return
                string(abi.encodePacked(BASEURI, Strings.toString(_tokenId), ".json"));
        }
    }
}
