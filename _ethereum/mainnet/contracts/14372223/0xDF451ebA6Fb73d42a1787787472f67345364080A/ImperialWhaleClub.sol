//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract ImperialWhaleClub is ERC721Enumerable, Ownable {
    //Constants
    uint256 public constant MAX_SUPPLY = 9999; 
    uint256 public constant MAX_LIMIT_PER_ADDRESS = 3; 
    uint256 public MINT_PRICE = 0.25 ether;
    address public constant WITHDRAWALL_ADDRESS =
        address(0x1f8655E56E00124C1376Ed456AE6F121d65E32B8); 

    //Mappings
    mapping(address => uint256) BOUGHTLIST;
    mapping(address => bool) WHITELIST;

    //Members
    string private BASEURI;
    string private BLINDBASEURI;

    bool private ISACTIVE;
    bool private ISREVEALED;

    constructor() ERC721("IMPERIALWHALECLUB", "IWC") {}

    //*********************Minting*********************/

    /** @dev Mints NFTs
     * @param quantity The quantity of tokens to mint
     */
    function mintNft(uint256 quantity) external payable {
        //check is revealed
        require(ISACTIVE, "Not active yet");
        //check whitelist
        require(WHITELIST[msg.sender], "You're not whitelisted");
        //check bought-tokens + new quantity not bigger than max limit per address
        require(
            BOUGHTLIST[msg.sender] + quantity <= MAX_LIMIT_PER_ADDRESS,
            "Max limit per address exceeded"
        );
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

        //set NFTs bought count
        BOUGHTLIST[msg.sender] = BOUGHTLIST[msg.sender] + quantity;
    }

    /** @dev Mints NFTs for owner (giveaways, etc)
     * @param quantity The quantity of tokens to mint
     */
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

    /*function _baseURI() internal view virtual override returns (string memory) {
        return BASEURI;
    }*/

    function setURIs(string memory blindURI, string memory baseUri)
        external
        onlyOwner
    {
        BLINDBASEURI = blindURI;
        BASEURI = baseUri;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance should be more then zero");
        payable(WITHDRAWALL_ADDRESS).transfer(balance);
    }

    //*********************Whistlisting*********************/
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    /**
     * @dev set a list of adresses to the whitelist
     */
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
        emit AddedToWhitelist(_address);
    }

    function removeAddresFromWhitelist(address _address) external onlyOwner {
        WHITELIST[_address] = false;
        emit RemovedFromWhitelist(_address);
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


    /*
     * Function to get token URI of given token ID
     * URI will be blank untill totalSupply reaches MAX_NFT_PUBLIC
     */
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
