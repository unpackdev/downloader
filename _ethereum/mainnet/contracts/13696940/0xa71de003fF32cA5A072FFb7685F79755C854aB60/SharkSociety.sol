// SPDX-License-Identifier: MIT
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";

pragma solidity ^0.8.0;

/**
 * @title Shark Society contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract SharkSociety is ERC721, ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    string public PROVENANCE;
    uint256 public constant MAX_TOKENS = 5000;
    uint256 public constant MAX_TOKENS_PLUS_ONE = 5001;

    uint256 public sharkPrice = 0.04 ether;
    uint256 public presaleSharkPrice = 0.03 ether;

    uint public constant maxSharksPlusOne = 6;
    uint public constant maxOwnedPlusOne = 9;
    uint public constant maxForPresalePlusOne = 3;


    bool public saleIsActive = false;

    // Metadata base URI
    string public metadataBaseURI;

    // Whitelist and Presale
    mapping(address => bool) Whitelist;
    bool public presaleIsActive = false;

    /**
    @param name - Name of ERC721 as used in openzeppelin
    @param symbol - Symbol of ERC721 as used in openzeppelin
    @param provenance - The sha256 string of concatenated sha256 of all images in their natural order - AKA Provenance.
    @param baseUri - Base URI for token metadata
     */
    constructor(string memory name,
                string memory symbol,
                string memory provenance,
                string memory baseUri) ERC721(name, symbol) {
        PROVENANCE = provenance;
        metadataBaseURI = baseUri;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(0x4d7183Eb8A51FE8803c8c38Bf989E659Bd4536AA).transfer(balance.mul(100).div(1000));
        payable(0x8A7fA1106068DD75427525631b086208884111a5).transfer(balance.mul(200).div(1000));
        payable(0x0Cf7d58A50d5b3683Fd38c9f3934723DeC75A3c0).transfer(balance.mul(240).div(1000));
        payable(0xfc9DA6Edc4ABB3f3E4Ec2AD5B606514Ce1DE0dA4).transfer(balance.mul(280).div(1000));
        payable(0xC68b81FBDff9587c3a024e7179a29329Ee9c1C8e).transfer(balance.mul(140).div(1000));
        payable(0xC3B964D1DFD77f1d7294EAC29243bEFc3C9DE0e5).transfer(balance.mul(15).div(1000));
        payable(0x91c3f3Dc5ed67b11cacd74Faf35dE50ff766A30E).transfer(balance.mul(15).div(1000));
        payable(0x38dE2236b854A8E06293237AeFaE4FDa94b2a2c3).transfer(balance.mul(10).div(1000));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
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

    /**
     * Reserve Sharks for future marketing and the team
     */
    function reserveSharks(uint256 amount, address to) public onlyOwner {
        uint supply = totalSupply();
        require(supply.add(amount) < MAX_TOKENS_PLUS_ONE, "Reserving would exceed supply.");
        uint i;
        for (i = 0; i < amount; i++) {
            _safeMint(to, supply + i);
        }
    }

    /*     
    * Set provenance hash - just in case there is an error
    * Provenance hash is set in the contract construction time,
    * ideally there is no reason to ever call it.
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE = provenanceHash;
    }

    /**
     * @dev Pause sale if active, activate if paused
     */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
     * @dev Pause presale if active, activate if paused
     */
    function flipPresaleState() public onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    /**
     * @dev Adds addresses to the whitelist
     */
    function addToWhitelist(address[] calldata addrs) external onlyOwner {
        for (uint i=0; i<addrs.length; i++) {
            Whitelist[addrs[i]] = true;
        }
    }

    /**
     * @dev Removes addresses from the whitelist
     */
    function removeFromWhitelist(address[] calldata addrs) external onlyOwner {
        for (uint i=0; i<addrs.length; i++) {
            Whitelist[addrs[i]] = false;
        }
    }

    function registerForPresale() external {
        require(!presaleIsActive, "The presale has already begun!");
        Whitelist[msg.sender] = true;
    }

    /**
     * @dev Checks if an address is in the whitelist
     */
    function isAddressInWhitelist(address addr) public view returns (bool) {
        return Whitelist[addr];
    }

    /**
     * @dev Checks if the sender's address is in the whitelist
     */
    function isSenderInWhitelist() public view returns (bool) {
        return Whitelist[msg.sender];
    }

    /**
     * @dev Sets the mint price
     */
     function setPrice(uint256 price) external onlyOwner {
         require(price > 0, "Invalid price.");
         sharkPrice = price;
     }

/**
     * @dev Sets the mint price
     */
     function setPresalePrice(uint256 price) external onlyOwner {
         require(price > 0, "Invalid price.");
         presaleSharkPrice = price;
     }

     /**
     * @dev Sets the Base URI for computing {tokenURI}.
     */
    function setMetadataBaseURI(string memory newURI) public onlyOwner {
        metadataBaseURI = newURI;
    }

    /**
     * @dev Returns the tokenURI if exists.
     * See {IERC721Metadata-tokenURI} for more details.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory sequenceId = tokenId.toString();

        return bytes(metadataBaseURI).length > 0 ? string( abi.encodePacked(metadataBaseURI, sequenceId) ) : "";
    }

    /**
    * @dev Returns the base URI. Overrides empty string returned by base class.
    * Unused because we override {tokenURI}.
    * Included for completeness-sake.
    */
    function _baseURI() internal view override(ERC721) returns (string memory) {
        return metadataBaseURI;
    }

    /**
    * @dev Returns the base URI. Public facing method.
    * Included for completeness-sake and folks that want just the base.
    */
    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    /**
    * @dev Actual function that performs minting
    */
    function _mintSharks(uint numberOfTokens, address sender) internal {
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(sender, mintIndex);
            }
        }
    }

    /**
    * @dev Mints Sharks
    * Ether value sent must exactly match.
    */
    function mintSharks(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Sharks.");
        require(numberOfTokens < maxSharksPlusOne, "Can only mint 5 Sharks at a time.");
        require(balanceOf(msg.sender).add(numberOfTokens) < maxOwnedPlusOne , "Purchase would exceed presale limit of 8 Sharks per address.");
        require(totalSupply().add(numberOfTokens) < MAX_TOKENS_PLUS_ONE, "Purchase would exceed max supply of Sharks.");
        require(sharkPrice.mul(numberOfTokens) == msg.value, "Ether value sent is not correct.");
        _mintSharks(numberOfTokens, msg.sender);
    }

    /**
    * @dev Mints Sharks during the presale.
    * Ether value sent must exactly match -
    * and only addresses in {Whitelist} are allowed to participate in the presale.
    */
    function presaleMintSharks(uint numberOfTokens) public payable {
        require(presaleIsActive && !saleIsActive, "Presale is not active.");
        require(isSenderInWhitelist(), "Your address is not in the whitelist.");
        require(balanceOf(msg.sender).add(numberOfTokens) < maxForPresalePlusOne, "Purchase would exceed presale limit of 2 Sharks per address.");
        require(totalSupply().add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply of Sharks.");
        require(presaleSharkPrice.mul(numberOfTokens) == msg.value, "Ether value sent is not correct.");
        _mintSharks(numberOfTokens, msg.sender);
    }

    /**
     * @dev Do not allow renouncing ownership
     */
    function renounceOwnership() public override(Ownable) onlyOwner {}
}
