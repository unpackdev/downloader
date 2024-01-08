// https://cryptomasterclub.com
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Pausable.sol";
import "./ERC721Enumerable.sol";
import "./IERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract CryptoMonsterClub is ERC721Enumerable, ERC721Pausable, Ownable {
    using SafeMath for uint;
    
    uint constant public MONSTER_TOTAL_SUPPLY = 7777;
    uint MONSTER_RESERVED = 200; 
    
    uint constant public PORTAL_PER_USER_ALLOWED = 1;
    uint constant public PRE_MINT_LIMIT_PER_TOKEN = 3;
    uint constant public PUB_MINT_LIMIT_PER_TX = 10;
    
    uint private basePrice = 0.055 ether;
    
    bool public isPreMintOpen = true;
    bool public isPublicMintOpen = false;
    bool public canSacrifice = false;
    
    string _baseTokenURI;
    address public portalAddress = 0x118461022A2F99EF65BeE1Dd93eF62FB49D974FC;
    
    mapping(uint => uint) public mintedPerTokenTracker;
    
    event Mint(address owner, uint tokenId);
    event Sacrifice(address owner, uint monsterId);
    
    constructor() ERC721("Crypto Monster Club", "CMC") {
        MONSTER_RESERVED = MONSTER_RESERVED.sub(3);
        for (uint monster = 0; monster < 3; monster ++) {
            _safeMint(_msgSender(), totalSupply().add(1));
            emit Mint(_msgSender(), totalSupply());
        }
    }
    
    function premint() external payable {
        require(isPreMintOpen, "CryptoMonsterClub: Pre-mint not yet open.");
        
        uint tokenId = IERC721Enumerable(portalAddress).tokenOfOwnerByIndex(_msgSender(), 0);
        uint balanceOfUser = IERC721Enumerable(portalAddress).balanceOf(_msgSender());
        require(balanceOfUser > 0, "CryptoMonsterClub: Only portal holder allowed.");
        require(balanceOfUser == PORTAL_PER_USER_ALLOWED, "CryptoMonsterClub: Allowed 1 portal per address only.");
        
        uint remainder = msg.value.mod(basePrice); // make sure that it divisible by 0.055
        require(remainder == 0, "CryptoMonsterClub: eth should be divisible by 0.055.");
        
        uint numberOfTokenToBeMinted = msg.value.div(basePrice);
        mintedPerTokenTracker[tokenId] = mintedPerTokenTracker[tokenId].add(numberOfTokenToBeMinted);
        uint numberOfMintedInToken = mintedPerTokenTracker[tokenId];
        require(numberOfMintedInToken <= PRE_MINT_LIMIT_PER_TOKEN, "CryptoMonsterClub: Only 3 monster can be minted per portal.");
        require(numberOfTokenToBeMinted > 0 && numberOfTokenToBeMinted <= PRE_MINT_LIMIT_PER_TOKEN, "CryptoMonsterClub: min 1 and max is 3 per portal");
        require(totalSupply().add(numberOfTokenToBeMinted) <= MONSTER_TOTAL_SUPPLY.sub(MONSTER_RESERVED), "CryptoMonsterClub: Sold out.");
        require(msg.value >= numberOfTokenToBeMinted.mul(basePrice), "CryptoMonsterClub: Insuffient Eth");
        
        for (uint256 num = 0; num < numberOfTokenToBeMinted; num ++) {
            _safeMint(_msgSender(), totalSupply().add(1));
            emit Mint(_msgSender(), totalSupply());
        }
    }
    
    function mint() external payable {
        require(isPublicMintOpen, "CryptoMonsterClub: Public mint not yet open.");
        
        uint remainder = msg.value.mod(basePrice);
        uint numberOfTokenToBeMinted = msg.value.div(basePrice);
        uint allSupply = totalSupply().add(numberOfTokenToBeMinted);
        require(remainder == 0, "CryptoMonsterClub: eth should be divisible by 0.055.");
        require(numberOfTokenToBeMinted > 0 && numberOfTokenToBeMinted <= PUB_MINT_LIMIT_PER_TX, "CryptoMonsterClub: min 1 and max 10 per tx.");
        require(allSupply <= MONSTER_TOTAL_SUPPLY.sub(MONSTER_RESERVED), "CryptoMonsterClub: Sold out.");
        for (uint i = 0; i < numberOfTokenToBeMinted; i++) {
            _safeMint(_msgSender(), totalSupply().add(1));
            emit Mint(_msgSender(), totalSupply());
        }
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function getReserveSupply() external view returns(uint) {
        return MONSTER_RESERVED;
    }
    
    function sacrifice(uint256 _monsterId) public {
        require(canSacrifice, "CryptoMonsterClub: sacrifice monster not enable.");
        require(
            _isApprovedOrOwner(_msgSender(), _monsterId),
            "CryptoMonsterClub: caller is not the owner nor approved address."
        );
        _burn(_monsterId);
        emit Sacrifice(_msgSender(), _monsterId);
    }

    function airdrop(address[] memory _airdropAddrs) external onlyOwner() {
        require(totalSupply().add(_airdropAddrs.length) <= MONSTER_TOTAL_SUPPLY, "CryptoMonsterClub: exceed supply.");
        require(MONSTER_RESERVED.sub(_airdropAddrs.length) > 0);
        MONSTER_RESERVED = MONSTER_RESERVED.sub(_airdropAddrs.length);
        for (uint i = 0; i < _airdropAddrs.length; i++) {
            _safeMint(_airdropAddrs[i], totalSupply().add(1));
            emit Mint(_airdropAddrs[i], totalSupply());
        }
    }
    
    function mintAndTransfer(address _to, uint numberOfToken) external onlyOwner() {
        require(totalSupply().add(numberOfToken) <= MONSTER_TOTAL_SUPPLY, "CryptoMonsterClub: mint exceed supply.");
        for (uint i = 0; i < numberOfToken; i++) {
            _safeMint(_to, totalSupply().add(1));
        }
    }
    
    function setCanSacrifice(bool _isCanSacrifice) external {
        canSacrifice = _isCanSacrifice;
    }
    
    function setPreMintState(bool _isOpen) external onlyOwner() {
        isPreMintOpen = _isOpen;
    }
    
    function setPubMintState(bool _isOpen) external onlyOwner() {
        isPublicMintOpen = _isOpen;
    }
    
    function pause() external onlyOwner() {
        _pause();
    }
    
    function unpause() external onlyOwner() {
        _unpause();
    }
    
    function updateBaseUri(string memory _newUri) external onlyOwner() {
        _baseTokenURI = _newUri;
    }
    
    function updatePortal(address _portal) external onlyOwner() {
        portalAddress = _portal;
    }
    
    function withdrawAll() external onlyOwner() {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
    
}

