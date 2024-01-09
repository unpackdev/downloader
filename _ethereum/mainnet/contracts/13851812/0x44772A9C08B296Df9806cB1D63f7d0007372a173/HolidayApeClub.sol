// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Counters.sol";

contract holidayapeclub is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    /**
     * Max Token Supply
     */

    uint256 public maxTokenSupply = 333;

    /**
     * Current mint price
     */

    uint256 public mintPrice = 100000000 gwei; // 0.1 ETH

    /**
     * Pre-sale mint price
     */

    uint256 public preSaleMintPrice = 50000000 gwei; // 0.05 ETH

    /**
     * Is sale active?
     */

    bool public saleIsActive = false;

    /**
     * Is pre-sale active?
     */

    bool public preSaleIsActive = false;
    
    /**
     * BaseURI
     */

    string public baseURI;

    /**
     * Provenance hash
     */

    string public provenance;

    mapping(address => bool) private _allowList;
    mapping(address => uint256) private _allowListClaimed;

    constructor() ERC721("Holiday Ape Club - Christmas 2021", "HAXmas") {}

    /**
     * Change max total supply
     */

    function setMaxTokenSupply(uint256 maxSupply) public onlyOwner {
        maxTokenSupply = maxSupply;
    }

    /**
     * Set mint price
     */

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    /**
     * Add address to presale list
     */

    function addToAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _allowList[addresses[i]] = true;
            /**
             * @dev We don't want to reset _allowListClaimed count
             * if we try to add someone more than once.
             */
            _allowListClaimed[addresses[i]] > 0
                ? _allowListClaimed[addresses[i]]
                : 0;
        }
    }

    /**
     * Remove address from presale list
     */

/*    function removeFromAllowList(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            /// @dev We don't want to reset possible _allowListClaimed numbers.
            _allowList[addresses[i]] = false;
        }
    }
*/
    /**
     * Check if address has been added to presale list
     */

    function onAllowList(address addr) external view returns (bool) {
        return _allowList[addr];
    }

    /**
     * View amount claimed by address
     */

    function allowListClaimedBy(address owner) external view returns (uint256) {
        require(owner != address(0), "Zero address not on Allow List");

        return _allowListClaimed[owner];
    }

    /**
     * Reserve tokens for developers
     */

    function reserveMint(uint256 reservedAmount) public onlyOwner {
        uint256 supply = _tokenIdCounter.current();
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _safeMint(msg.sender, supply + i);
            _tokenIdCounter.increment();
        }
    }

    /**
     * Mint to giveaway winners address
     */

    function giveawayMint(uint256 reservedAmount, address mintAddress)
        public
        onlyOwner
    {
        uint256 supply = _tokenIdCounter.current();
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _safeMint(mintAddress, supply + i);
            _tokenIdCounter.increment();
        }
    }

    /**
     * Flip sale status
     */

    function flipSaleStatus() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
     * Flip pre-sale status
     */

    function flipPreSaleStatus() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }   
    
    /**
     * Mint Tokens
     */

    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint");
        require(
            totalSupply() + numberOfTokens <= maxTokenSupply,
            "Purchase would exceed max available"
        );
        require(
            mintPrice * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = _tokenIdCounter.current() + 1;
            if (mintIndex <= maxTokenSupply) {
                _safeMint(msg.sender, mintIndex);
                _tokenIdCounter.increment();
            }
        }
    }

    /**
     * Pre Sale mint
     */

    function preSaleMint(uint256 numberOfTokens) public payable {
        require(_allowList[msg.sender], "You are not on the Allow List");
        require(preSaleIsActive, "Sale must be active to mint");
        require(
            totalSupply() + numberOfTokens <= maxTokenSupply,
            "Purchase would exceed max available"
        );
        require(
            preSaleMintPrice * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = _tokenIdCounter.current() + 1;
            if (mintIndex <= maxTokenSupply) {
                _safeMint(msg.sender, mintIndex);
                _tokenIdCounter.increment();
            }
        }
    }

    /**
     * View baseURI
     */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Set baseURI
     */

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * set proveance hash
     */

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        provenance = provenanceHash;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
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
     * Withdraw funds from contract address to owner
     */

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }
}
