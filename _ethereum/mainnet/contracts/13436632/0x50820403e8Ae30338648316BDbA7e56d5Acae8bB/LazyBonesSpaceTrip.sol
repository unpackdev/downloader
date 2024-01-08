// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract LazyBonesSpaceTrip is ERC721Enumerable, Ownable, AccessControl {
    using SafeMath for uint256;

    uint256 public constant PreMintPrice = 0.04 ether;
    uint256 public constant PublicMintPrice = 0.06 ether;
    uint256 public constant TOTAL_NUMBER_OF_LAZY_BONES = 10000;
    uint[TOTAL_NUMBER_OF_LAZY_BONES] internal indices;
    uint internal nonce = 0;

    uint256 public giveaway_reserved = 100;
    uint256 public pre_mint_limit = 3;

    mapping(address => bool) private _pre_sale_minters;

    bool public mintIsPaused = true;
    bool public preMintIsPaused = true;
    bool public reveal = false;

    //withdraw addresses
    address splitter;

    //initial team
    address LazyDescartes = 0x8D6d8E912880e2fC9dC174F18b033F9619c0F63A;
    address LazyGeek = 0x36A59A0B623a4B9EF9d4b4bb11F2aAC40B2dc239;
    address LazyDraws = 0x0077044aE65E5E43F10101d9432b763AFdCe540D;
    address LazyFlownee = 0x66318D2E71e1DDbE2cC769bacA169463E54B8519;
    address LazyElf = 0x5C6b5F156Cb3154442e4B486320A0A5916312C92;
    address LazyBrah = 0x09E7C871E020f74D1EE1E30034a90082C435Bece;
    address LazyHoodie = 0x797074BC5051d705DFe4004482783381e1ab1222;
    //investors
    address LazyInvestor1 = 0x694461DCC47900B2716E4c10322e76737733F782;
    address LazyInvestor2 = 0xE8e38EB9C16C17681d26522685B381ea659CAc98;
    
    string private _baseUrl = "https://lazybonesspacetrip.s3.eu-north-1.amazonaws.com/";

    constructor() ERC721("LazyBonesSpaceTrip", "LBST") {
        _setupRole(DEFAULT_ADMIN_ROLE, LazyDescartes);
    }

    modifier WhenPreMintIsAllowed() {
        require(!preMintIsPaused, "LazyBones SpaceTrip: Premint is paused!");
        _;
    }
    modifier WhenMintIsAllowed() {
        require(!mintIsPaused, "LazyBones SpaceTrip: Mint is paused");
        _;
    }
    //Checks for preminters
    function is_pre_mint_allowed(address account) public view  returns (bool) {
        return _pre_sale_minters[account];
    }
    modifier IsPreMintAllowed(address account) {
        require(is_pre_mint_allowed(account), "LazyBones SpaceTrip: You are not in pre mint list!");
        _;
    }
  
    //EVENTS
    event ReedemedPreMint(address account);

    //Construction
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUrl;
    }
    function getBaseURI() public view returns (string memory) {
      return _baseUrl;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
            require(_exists(tokenId), "LazyBonesSpaceTrip: URI query for nonexistent token");
            string memory baseURI = getBaseURI();

            return bytes(baseURI).length > 0 ? reveal ? string(abi.encodePacked(baseURI, '/', Strings.toString(tokenId), ".json")) : "https://lazybonesnft.io/api/lazybones.json" : '';
    }

    function ownerOf(uint8 index) public view returns(address) {
        return ownerOf(uint256(index)-1);
    }
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    function randomIndex() internal returns (uint256) {
        //   uint256 totalSize = TOTAL_NUMBER_OF_LAZY_BONES - (pre_mint_reserved + giveaway_reserved);
        uint256 totalSize = TOTAL_NUMBER_OF_LAZY_BONES - totalSupply();
        uint256 index = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % totalSize;
        uint256 value = 0;

            if (indices[index] != 0) {
            value = indices[index];
            } else {
            value = index;
            }

            if (indices[totalSize - 1] == 0) {
            indices[index] = totalSize - 1;
            } else {
            indices[index] = indices[totalSize - 1];
            }

            nonce++;

            return value.add(1);
    }
    fallback() external payable { }
    receive() external payable { }
    //Minting
    function mint(uint256 numberOfTokens) public payable WhenMintIsAllowed() {
        uint256 supply = totalSupply();
        uint256 tokenCount = balanceOf(msg.sender);
        require(numberOfTokens <= 20, "LazyBonesSpaceTrip: You can mint a maximum of 20 Lazy Bones");
        require(tokenCount + numberOfTokens <= 20, "LazyBonesSpaceTrip: You can mint a maximum of 20 Lazy Bones");
        require(supply + numberOfTokens <= TOTAL_NUMBER_OF_LAZY_BONES - giveaway_reserved, "LazyBonesSpaceTrip: Exceeds maximum Lazy Bones supply");
        require( msg.value >= PublicMintPrice * numberOfTokens, "LazyBonesSpaceTrip: Ether sent is less than PRICE * num" );

        for(uint256 i; i < numberOfTokens; i++){
            _safeMint( msg.sender, randomIndex() );
        }
    }
    function preMint(uint256 numberOfTokens) public payable WhenPreMintIsAllowed() IsPreMintAllowed(msg.sender) {
        uint256 buyerBalance = balanceOf(msg.sender);
        require(msg.value >= numberOfTokens * PreMintPrice, "LazyBonesSpaceTrip: Ether sent is less than PreMintPrice");
        require(numberOfTokens + buyerBalance <= pre_mint_limit, "LazyBonesSpaceTrip: You can mint a maximum of 20 Lazy Bones");
        if(buyerBalance + numberOfTokens >= pre_mint_limit) {
            _pre_sale_minters[msg.sender] = false;
        }
        
        for(uint256 i; i < numberOfTokens; i++){
            _safeMint( msg.sender, randomIndex() );
        }
    }
    //Checks if minter reached limit for public sale
    function limitReached(address account, uint256 amount) public view returns(bool) {
        return balanceOf(account) + amount <= 20;
    }
    //Checks if minter in white list
    function preMintAvailable(address account) public view returns(bool) {
        return _pre_sale_minters[account];
    }
    //Checks if minter in giveaway white list
    //Only owner
    function toggleReveal() public onlyOwner {
        reveal = !reveal;
    }
    function addToPreMinters(address[] calldata account) public onlyOwner {
        for(uint256 i = 0; i < account.length; i++) {
            _pre_sale_minters[account[i]] = true;
        }
    }
    function unpauseMint() public onlyOwner {
        mintIsPaused = false;
    }
    function pauseMint() public onlyOwner {
        mintIsPaused = true;
    }
    function unpausePreMint() public onlyOwner {
        preMintIsPaused = false;
    }
    function pausePreMint() public onlyOwner {
        preMintIsPaused = true;
    }
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseUrl = baseURI;
    }
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    function withdrawSplitter() public onlyOwner {
        uint balance = address(this).balance;
        //Initial team split
        payable(LazyGeek).transfer((balance * 10) / 100);
        payable(LazyDraws).transfer((balance * 5) / 100);
        payable(LazyFlownee).transfer((balance * 6) / 100);
        payable(LazyElf).transfer((balance * 3) / 100);
        payable(LazyBrah).transfer((balance * 3) / 100);
        payable(LazyHoodie).transfer((balance * 1) / 100);
        //Investors split 
        payable(LazyInvestor1).transfer((balance * 12) / 100);
        payable(LazyInvestor2).transfer((balance * 10) / 100);
        payable(LazyDescartes).transfer(address(this).balance);
    }
    function mintToGiftWinners(address[] calldata accounts) public onlyOwner {
        require(giveaway_reserved > 0, "All giveaway tokens are minted");
        for(uint i = 0; i < accounts.length; i++) {
            _safeMint(accounts[i], randomIndex());
            giveaway_reserved--;
        }
    }
}