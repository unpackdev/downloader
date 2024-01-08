// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ITendies.sol";

/**
 * @notice - This is the Wagies NFT contract
 */
contract WagiesNFT is
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // Max Supply
    uint256 public constant MAX_GENESIS_WAGIES_SUPPLY = 3333;
    uint256 public constant MAX_CHILD_WAGIES_SUPPLY = 6667;

    // Mint Price for each token
    uint256 public genesisWagiesPrice = 0.08 ether;

    // PreSale Active
    bool public isPresaleActive;

    // Sale Active
    bool public isSaleActive;

    // Tendies token contract address
    address private _tendies;

    // Counter
    Counters.Counter private _genesisIdCounter;
    Counters.Counter private _childIdCounter;

    // Mapping from token ID to token name
    mapping(uint256 => string) private _tokenNames;

    // Mapping wallet address to token reserved count for presale
    mapping(address => uint256) public presaleWhitelist;

    // Number of free tokens owned by contract owner 
    uint256 public balanceOfOwner;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        isSaleActive = false;
        isPresaleActive = false;
        balanceOfOwner = 0;
    }

    /**
     * @dev Returns the number of genesis wagies in ``owner``'s account.
     */
    function balanceOfGenesisWagies(address owner) public view returns (uint256) {
        uint256 length = ERC721.balanceOf(owner);
        uint256 balance;
        for (uint256 i; i < length; i ++) {
            if (tokenOfOwnerByIndex(owner, i) < MAX_GENESIS_WAGIES_SUPPLY) {
                balance ++;
            }
        }
        return balance;
    }

    function mintGenesisNFT(uint256 numOfMints) public payable {
        require(isSaleActive, "WagiesNFT: Sale must be active to mint");
        require(
            _genesisIdCounter.current().add(numOfMints) < MAX_GENESIS_WAGIES_SUPPLY - 30,
            "WagiesNFT: Purchase would exceed the maximum supply of Wagies NFT"
        );
        require(
            genesisWagiesPrice.mul(numOfMints) == msg.value,
            "WagiesNFT: Ether value is not correct"
        );

        for (uint256 i; i < numOfMints; i++) {
            uint256 _newTokenId = _genesisIdCounter.current();
            _safeMint(_msgSender(), _newTokenId);
            _genesisIdCounter.increment();
        }
    }

    function mintChildNFT(uint256 numOfMints) public payable {
        require(isSaleActive, "WagiesNFT: Sale must be active to mint");
        require(
            _childIdCounter.current().add(numOfMints) < MAX_CHILD_WAGIES_SUPPLY,
            "WagiesNFT: Purchase would exceed the maximum supply of Wagies NFT"
        );
        require(
            balanceOfGenesisWagies(_msgSender()) >= 2, 
            "WagiesNFT: At least 2 genesis wagies must be held"
        );
        require(_tendies != address(0), "WagiesNFT: Tendies contract address is not correct");
        require(
            ITendies(_tendies).balanceOf(_msgSender()) > 200 * 10*18, 
            "WagiesNFT: At least 200 NLT must be held"
        );

        for (uint256 i; i < numOfMints; i++) {
            uint256 _newTokenId = _childIdCounter.current().add(MAX_GENESIS_WAGIES_SUPPLY);
            _safeMint(_msgSender(), _newTokenId);
            _childIdCounter.increment();
        }

        ITendies tendies = ITendies(_tendies);
        tendies.burnFrom(_msgSender(), 200 * 10**18);
    }

    function premintGenesisNFT(uint256 numOfMints) public payable {
        uint256 reserved = presaleWhitelist[msg.sender];

        require(isPresaleActive, "Presale must be active to mint");
        require(numOfMints > 0 && numOfMints <= 3, "Invalid mintable amount");
        require(reserved > 0, "No tokens reserved fro this address");
        require(reserved >= numOfMints, "Cannot mint more than reserved");
        require(
            _genesisIdCounter.current().add(numOfMints) < MAX_GENESIS_WAGIES_SUPPLY,
            "WagiesNFT: Purchase would exceed the maximum supply of Wagies NFT"
        );
        require(
            genesisWagiesPrice.mul(numOfMints) == msg.value,
            "WagiesNFT: Ether value is not correct"
        );

        presaleWhitelist[msg.sender] = reserved.sub(numOfMints);

        for (uint256 i; i < numOfMints; i++) {
            uint256 _newTokenId = _genesisIdCounter.current();
            _safeMint(msg.sender, _newTokenId);
            _genesisIdCounter.increment();
        }
    }

    function mintByOwner(uint256 numOfMints) public onlyOwner {
        require(isSaleActive, "WagiesNFT: Sale must be active to mint");
        require(
            _genesisIdCounter.current().add(numOfMints) < MAX_GENESIS_WAGIES_SUPPLY - 30,
            "WagiesNFT: Purchase would exceed the maximum supply of Wagies NFT"
        );
        require(balanceOfOwner.add(numOfMints) <= 30, "WagiesNFT: Purchase would exceed the maximum limit of owner");

        for (uint256 i; i < numOfMints; i++) {
            uint256 _newTokenId = _genesisIdCounter.current();
            _safeMint(_msgSender(), _newTokenId);
            _genesisIdCounter.increment();
        }
    }

    function mintLastTokens() public onlyOwner {
        require(
            _genesisIdCounter.current() == MAX_GENESIS_WAGIES_SUPPLY - 30,
            "WagiesNFT: Wait until the other tokens are minted"
        );

        for (uint256 i; i < 30; i++) {
            uint256 _newTokenId = _genesisIdCounter.current();
            _safeMint(_msgSender(), _newTokenId);
            _genesisIdCounter.increment();
        }
    }

    function editPresale(
        address[] calldata presaleAddresses,
        uint256[] calldata amounts
    ) external onlyOwner {
        for (uint256 i; i < presaleAddresses.length; i++) {
            presaleWhitelist[presaleAddresses[i]] = amounts[i];
        }
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "WagiesNFT: caller is not owner nor approved"
        );
        _setTokenURI(tokenId, _tokenURI);
    }

    function setTokenName(uint256 tokenId, string memory _tokenName) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "WagiesNFT: caller is not owner nor approved"
        );
        require(_tendies != address(0), "WagiesNFT: Tendies contract address is not correct");
        require(ITendies(_tendies).balanceOf(_msgSender()) > 91 * 10*18, "WagiesNFT: At least 91 NLT must be held");

        _setTokenName(tokenId, _tokenName);

        ITendies tendies = ITendies(_tendies);
        tendies.burnFrom(msg.sender, 91 * 10**18);
    }

    function getTokenName(uint256 tokenId) public view returns (string memory) {
        require(
            _exists(tokenId),
            "WagiesNFT: URI set of nonexistent token"
        );

        return _tokenNames[tokenId];
    }

    function togglePresale() public onlyOwner {
        isPresaleActive = !isPresaleActive;
    }

    function toggleSale() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setGenesisWagiesPrice(uint256 _genesisWagiesPrice) public onlyOwner {
        genesisWagiesPrice = _genesisWagiesPrice;
    }

    function setTendies(address addr) public onlyOwner {
        require(addr != address(0), "WagiesNFT: Tendies contract address is not correct");

        _tendies = addr;
    }

    function _setTokenName(uint256 tokenId, string memory _tokenName) internal {
        require(
            _exists(tokenId),
            "WagiesNFT: URI set of nonexistent token"
        );

        uint256 length = totalSupply();
        for (uint256 i; i < length; i ++) {
            require(
                keccak256(abi.encodePacked(_tokenName)) != keccak256(abi.encodePacked(_tokenNames[tokenByIndex(i)])), 
                "WagiesNFT: Same name exists"
            );
        }

        _tokenNames[tokenId] = _tokenName;
    }

    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "WagiesNFT: caller is not owner nor approved");
        require(_tendies != address(0), "WagiesNFT: Tendies contract address is not correct");
        
        address owner = ERC721.ownerOf(tokenId);

        _burn(tokenId);

        ITendies tendies = ITendies(_tendies);
        tendies.mint(owner, 183 * 10**18);
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
    */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _safeMint(address to, uint256 tokenId) internal override(ERC721) {
        super._safeMint(to, tokenId);

        _setTokenName(
            tokenId,
            string(abi.encodePacked("Wagies #", Strings.toString(tokenId)))
        );
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "_";
    }
}
