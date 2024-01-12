// SPDX-License-Identifier: MIT
//((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
//((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
//((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
//((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
//((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
//(((((((((((((((((((((((((((((#&&&&&&&&&&&&&&&&&&&&&(((((((((((((((((((((((((((((
//(((((((((((((((((((((&&&&&&&&#.....................&&&&&&&&&((((((((((((((((((((
//((((((((((((((((%&&&& ..................................... &&&&((((((((((((((((
//((((((((((((((&&/    ........................................   &&&(((((((((((((
//((((((((((((&&....................................................,&&(((((((((((
//((((((((((&&.........................................................&&(((((((((
//((((((((((&&.........................................................&&(((((((((
//((((((((((&&.........................................................&&(((((((((
//((((((((((&&.........................................................&&(((((((((
//((((((((((&&.........................................................&&(((((((((
//((((((((((&&...... ..................................................&&(((((((((
//((((((((##&&....,**&&&&((**..........................,**&&&&((**.....&&##(((((((
//(((((&&& .&&..&&&&&&&&&&&&&@&#.....................&&@&&&&&&&&&&&&%..&&..&&(((((
//(((((&&&. &&..&&&&&&&&&&&&&&&#.....................&&&&&&&&&&&&&&&%..&& .&&(((((
//(((((&&&,,&&..&&&&&&&&&&&&&&&#.....................&&&&&&&&&&&&&&&%..&&,,&&(((((
//(((((&&&,,&&....(&&  &&&&&&........................../&&  &&&&&&.....&&,,&&(((((
//((((((((@@&&..... .&&&&&&...............................&&&&&&.......&&&&(((((((
//((((((((((&&..........................&&&&&..........................&&(((((((((
//((((((((((&&.. ......................................................&&(((((((((
//((((((((((((&&,,................................................,,*&&(((((((((((
//((((((((((((((&&(,,,,,,...................................,,,,,,&&&(((((((((((((
//((((((((((((((((%&&&&&&,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&&&&&&((((((((((((((((
//(((((((((((((((((((((((&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&((((((((((((((((((((((
//((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
//((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
//((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
//((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Punko.sol";

contract PunkoPixel is ERC721Punko, Ownable, ReentrancyGuard {

    address public tokenContract;
    using SafeERC20 for IERC20;
    mapping (address => uint256) public walletPunko;
    mapping(uint256 => uint256) public PunkoTokenUpgrade;
    string public baseURI;  
    bool public mintPunkolistedEnabled  = false;
    bool public mintPublicPunkoEnabled  = false;
    bytes32 public merkleRoot;
    uint public freePunko = 1;
    uint public maxPankoPerTx = 2;  
    uint public maxPerWallet = 2;
    uint public maxPanko = 777;
    uint public pankoPrice = 77000000000000000; //0.077 ETH
    uint public PriceETHpunkoUpgrade = 0;
    uint public PricePuncoinPunkoUpgrade = 0;

    constructor() ERC721Punko("Punko Pixel", "Punko",10,777){}

    function PunkolistedMint(uint256 qty, bytes32[] calldata _merkleProof) external payable
    { 
        require(mintPunkolistedEnabled , "Punko Pixel: Minting Whitelist Pause");
        require(walletPunko[msg.sender] + qty <= maxPerWallet,"Punko Pixel: Max Per Wallet");
        require(qty <= maxPankoPerTx, "Punko Pixel: Max Per Transaction");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Punko Pixel: Not in whitelisted");
        require(totalSupply() + qty <= maxPanko,"Punko Pixel: Soldout");
        walletPunko[msg.sender] += qty;
        _mint(qty);
    }

    function PublicPankoMint(uint256 qty) external payable
    {
        require(mintPublicPunkoEnabled , "Punko Pixel: Minting Public Pause");
        require(walletPunko[msg.sender] + qty <= maxPerWallet,"Punko Pixel: Max Per Wallet");
        require(qty <= maxPankoPerTx, "Punko Pixel: Max Per Transaction");
        require(totalSupply() + qty <= maxPanko,"Punko Pixel: Soldout");
        _mint(qty);
    }

    function Upgrading(uint256 tokenId) external payable{
        require(msg.value >= PriceETHpunkoUpgrade ,"Pixelated: Insufficient Eth");
        IERC20(tokenContract).safeTransferFrom(msg.sender, address(this), PricePuncoinPunkoUpgrade);
        PunkoTokenUpgrade[tokenId] = PunkoTokenUpgrade[tokenId]++;
    }

    function _mint(uint qty) internal {
        if(walletPunko[msg.sender] < freePunko) 
        {
           if(qty < freePunko) qty = freePunko;
           require(msg.value >= (qty - freePunko) * pankoPrice,"Punko Pixel: Claim Free");
           walletPunko[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
        else
        {
           require(msg.value >= qty * pankoPrice,"Punko Pixel: Normal");
           walletPunko[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function airdropPunko(address to ,uint256 qty) external onlyOwner
    {
        _safeMint(to, qty);
    }

    function PunkoOwnerMint(uint256 qty) external onlyOwner
    {
        _safeMint(msg.sender, qty);
    }

    function togglePublicPunkoMinting() external onlyOwner {
        mintPublicPunkoEnabled  = !mintPublicPunkoEnabled ;
    }
    function toggleWhitelistPunkoMinting() external onlyOwner {
        mintPunkolistedEnabled  = !mintPunkolistedEnabled ;
    }

    function setTokenContract(address _tokenContract) external onlyOwner{
        tokenContract = _tokenContract;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        pankoPrice = price_;
    }

    function setmaxPankoPerTx(uint256 maxPankoPerTx_) external onlyOwner {
        maxPankoPerTx = maxPankoPerTx_;
    }

    function setmaxFreePankoPerTx(uint256 freePunko_) external onlyOwner {
        freePunko = freePunko_;
    }

    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
        maxPerWallet = maxPerWallet_;
    }

    function setmaxPanko(uint256 maxPanko_) external onlyOwner {
        maxPanko = maxPanko_;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

}