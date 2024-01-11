// SPDX-License-Identifier: MIT

// *********************         DRIPPERZ CYBER CLUB        ***********************
// ********************************************************************************
// ********************************************************************************
// ********************************************************************************
// ********************************************************************************
// ********************************************************************************
// ********************************************************************************
// ******************** ******************************************* ***************
// *******************  ******************************************  ***************
// ******************   *****************************************   ***************
// *****************     ***************************************    ***************
// *****************     **************************************     ***************
// *****************      *************************************     ***************
// *****************       ***********************************      ***************
// *****************        *********************************       %**************
// ******************        *******************************        ***************
// ******************         *****************************         ***************
// *******************         ***************************         ****************
// ********************         *************************         *****************
// *********************         ***********************         ******************
// **********************         ********************          *******************
// ***********************         ******************         *********************
// *************************        *****************        **********************
// ***************************       ***************       ************************
// ****************************      **************      **************************
// ******************************     *************    ****************************
// ********************************    ***********   ******************************
// **********************************  *********** ********************************
// ************************************ *******************************************
// ********************************************************************************
// ********************************************************************************
// ********************************************************************************

pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract Drippers is Ownable, ERC721A , ReentrancyGuard{
    using Strings for uint;

    enum Step {
        Before,
        WhitelistSale,
        PublicSale ,
        Reveal
    }

    address payable immutable public teamAddress;

    uint constant public MAX_MINT     = 5;
    uint constant public MAX_WL_MINT  = 3;
    uint constant public MAX_SUPPLY   = 5555;
    uint constant public TOKEN_PRICE  = 0.15 ether;
    uint constant public WL_PRICE     = 0.12 ether;
    uint constant public MAX_RESERVE  = 55;

    uint    public  locker = MAX_SUPPLY;
    uint    public  reserved = 0;
    bytes32 private merkleRoot;
    string  private baseURI;

    Step    public  sellingStep;

    mapping(address => uint) public userWlMintNb;

    constructor(string memory _baseURI, address payable _teamAddress) ERC721A("Drippers Cyber Club", "DCC") {
        baseURI = _baseURI;
        teamAddress = _teamAddress;
    }

    function whitelistMint(uint _nb, bytes32[] calldata _proof) external payable nonReentrant {
        require(sellingStep == Step.WhitelistSale, "Whitelist sale is not activated");
        require(_verify(_proof), "Not whitelisted");
        require(totalSupply() + _nb <= locker , "Exceed available supply");
        require(userWlMintNb[msg.sender] + _nb <= MAX_WL_MINT, "Exceeded max Whitelist Mint");
        require(msg.value >= WL_PRICE * _nb, "Not enough funds");
        userWlMintNb[msg.sender] += _nb;
        _safeMint(msg.sender, _nb);
    }


    function publicSaleMint(uint _nb) external payable nonReentrant {
        require(sellingStep == Step.PublicSale, "Public sale is not activated");
        require(totalSupply() + _nb <= locker , "Exceed available supply");
        require( _nb <= MAX_MINT , "Max mint per tx exceeded");
        require(msg.value >= TOKEN_PRICE * _nb, "Not enough funds");
        _safeMint(msg.sender, _nb);
    }

    function setLocker(uint16 _lock) external onlyOwner {
        require(_lock >= totalSupply(), "Cannot lock minted tokens");
        locker = _lock;
    }
    function reserve(uint _nb) external onlyOwner nonReentrant {
        require(totalSupply() + _nb <= MAX_SUPPLY , "Max supply exceeded");
        require(reserved + _nb <= MAX_RESERVE , "Exceed max reserve");
        _safeMint(msg.sender, _nb);
        reserved += _nb;
    }
    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function _verify(bytes32[] calldata _proof) internal view returns(bool) {
        return MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }

    //ReleaseALL
    function withdraw() external {
        uint balance = address(this).balance;
        (bool success, ) = teamAddress.call{value : balance}("");
        require(success, "withdraw error");
    }
}