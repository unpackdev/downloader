// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./AccessControl.sol";

pragma solidity ^0.8.0;

/*
    KnightsOfDegen.io
    Presale Ticket grants user access to the Knights of Degen restricted presale mint.
    Presale Tickets cost 0.088ETH and guarantee one Knight minted in the presale for free.
*/
contract PresaleTicket is ERC721, ERC721Enumerable, AccessControl, ERC721URIStorage {
    using Counters for Counters.Counter;
    address private constant TREASURY_ADDRESS = 0xbfCF42Ef3102DE2C90dBf3d04a0cCe90eddA6e3F;

    // Role for treasury to airdrop as needed
    bytes32 public constant AIRDROPPER = keccak256("AIRDROP_ROLE");

    // Limit to 2088 presale mints. Up to 10 per address.
    Counters.Counter private _presaleMintCounter;
    uint256 public constant MAX_PRESALE_TICKETS_MINTABLE = 2088;
    uint256 public constant MAX_PRESALE_PER_ADDRESS = 10;
    mapping(address => uint) private presaleAddressMintMappings;

    // Set an airdrop hard stop
    Counters.Counter private _airdropCounter;
    uint256 public constant AIRDROP_HARD_STOP = 1000;

    // Set when the presale is open or closed
    bool private _presaleOpen = false;

    // Default price for the drop
    uint256 private _defaultPrice = 88 * 10**15; // This is .088 eth

    // Base token URI
    string private _baseTokenURI;

    // Is the art and metadata revealed?
    bool private _isRevealed = false;

    // Starting index to offset the random generation for even more randomness.
    uint256 private _startingIndex;
    uint256 private _blockStartNumber;

    // Address of the Knights Contract that we will link to later during the presale
    address private knightsContract;
    
    constructor() ERC721("Knights of Degen - Mint Pass", "SHIELD") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(AIRDROPPER, msg.sender);
    }

    // Set the Knights Contract address. Limit to only an admin role.
    function setKnightsContract(address _knightsContract) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must be an admin to set this");
        knightsContract = _knightsContract;
    }

    function getKnightsContractAddress() public view returns (address) {
        return knightsContract;
    }

    // Allow the Knights Contract to burn this NFT during redemption of a Knight token.
    function burnForRedemption(uint256 tokenId) external {
        require(msg.sender == knightsContract, "Invalid burn address");
        _burn(tokenId);
    }

    /*
        Support Knights of Degen the ability to grant additional airdrops of 
        presale tickets.
    */
    function airdropPresaleTicket(address _target, uint256 _count) public {
        require(hasRole(AIRDROPPER, msg.sender), "Must be approved in order to airdrop");
        require(_count != 0, "Must drop something");
        uint256 totalSupply = totalSupply();
        require(_airdropCounter.current() + _count <= AIRDROP_HARD_STOP, "Airdrop Hard Stop Reached");
         for (uint256 index; index < _count; index++) {
            _safeMint(_target, totalSupply + index+1);
            _airdropCounter.increment();
        }
    }

   
    /*
        Knights will mint up to 2088 Knight Tickets in a stealth drop opportunity.
        You must be in our discord (https://discord.gg/knightsofdegen) to know of the drop announcement.
        We will stop the drop at a random time. However to ensure we do not oversell, we have set a hard limit at 2088 presale tickets.
    */
    function mint(uint256 _count) public payable {
        uint256 totalSupply = totalSupply();

        /*
            Requirements:
                Presale is open
                No more than the allotted ammount per address
                No more than the max number of presale mints
                Sender has provided a value that is priced at presale value times quantity
                The total supply should never exceed the max supply

        */
        require(_presaleOpen == true, "Presale must be open in order to do the presale");
        require(_count <= MAX_PRESALE_PER_ADDRESS, "Minting amount is larger than presale ticket mint limit");
        require(presaleAddressMintMappings[msg.sender] + _count <= MAX_PRESALE_PER_ADDRESS, "You can only mint 10 tickets per address in presale ticket reservation");
        require(_presaleMintCounter.current() + _count <= MAX_PRESALE_TICKETS_MINTABLE, "No more than the max number of presale ticket mints allowed");

        require(
            msg.value >= _defaultPrice * _count,
            "The value submitted with this transaction is too low."
        );

        require(
            totalSupply + _count <= MAX_PRESALE_TICKETS_MINTABLE + AIRDROP_HARD_STOP,
            "A transaction of this size would surpass the max token limit."
        );

        for (uint256 index; index < _count; index++) {
            _safeMint(msg.sender, totalSupply + index+1);
            // Increment the presale mint counter
            _presaleMintCounter.increment();
        }
        presaleAddressMintMappings[msg.sender] = presaleAddressMintMappings[msg.sender] + _count;
    }

    function getPrice() public view returns (uint256) {
        return _defaultPrice;
    }

    function getPresaleCount() public view returns (uint256) {
        return _presaleMintCounter.current();
    }

    function isPresaleOpen() public view returns (bool) {
        return _presaleOpen;
    }

    function setBaseURI(string memory baseURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must be an admin to set the base URI");
        require(_isRevealed == false, "Can no longer set the base URI after reveal");
        _baseTokenURI = baseURI;
    }

    // Set that we have revealed the final base token URI, and lock the reveal so that the token URI is permanent
    function setRevealed() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only an admin can finalize the reveal");
        require(_isRevealed != true, "Can no longer set the reveal once it has been revealed");
        _isRevealed = true;
    }

    function setPresaleOpen(bool _isOpen) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only an admin can finalize the presale openness");
        _presaleOpen = _isOpen;
    }

    function isRevealed() public view returns (bool) {
        return _isRevealed;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
   
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        }

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // Always withdraw to the treasury address. Allow anyone to withdraw, such that there can be no issues with keys.
    function withdrawAll() public payable {
        require(payable(TREASURY_ADDRESS).send(address(this).balance));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function setStartingIndex() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must be an admin to set starting index");
        require(_startingIndex == 0, "Starting index can only be set once from the default value of 0");
        _startingIndex = calculateStartingIndex(_blockStartNumber, MAX_PRESALE_TICKETS_MINTABLE);
        if(_startingIndex == 0) {
            _startingIndex++;
        }
    }

    function getStartingIndex() public view returns (uint256) {
        return _startingIndex;
    }

    function calculateStartingIndex(uint256 blockNumber, uint256 collectionSize)
        internal
        view
        returns (uint256)
    {
        return uint256(blockhash(blockNumber)) % collectionSize;
    }

}