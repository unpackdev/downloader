// SPDX-License-Identifier: MIT

// *********************         DRIPPERZ CYBER CLUB  V2      *********************
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
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract Dripperz is Ownable, ERC721A , ReentrancyGuard{
    using Strings for uint;

    enum Step {
        Before,
        WhitelistSale,
        PublicSale ,
        Reveal
    }

    address payable immutable public teamAddress;

    uint constant public MAX_SUPPLY   = 1111;
    uint constant public TOKEN_PRICE  = 0.075 ether;

    uint    public  locker = MAX_SUPPLY;
    bytes32 private merkleRoot;
    string  private baseURI;
    Step    public  sellingStep;



    constructor(string memory _URI, address payable _teamAddress) ERC721A("Dripperz Cyber Club", "DCC") {
        baseURI = _URI;
        teamAddress = _teamAddress;
    }

    function whitelistMint(uint _nb, bytes32[] calldata _proof) external payable nonReentrant {
        require(sellingStep == Step.WhitelistSale, "Whitelist sale is not activated");
        require(_verify(_proof), "Not whitelisted");
        require(totalSupply() + _nb <= locker , "Exceed available supply");
        require(msg.value >= TOKEN_PRICE * _nb, "Not enough funds");
        _safeMint(msg.sender, _nb);
    }


    function publicSaleMint(uint _nb) external payable nonReentrant {
        uint ts = totalSupply();
        require(sellingStep == Step.PublicSale, "Public sale is not activated");
        require(ts + _nb <= locker , "Exceed available supply");
        require(msg.value >= TOKEN_PRICE * _nb, "Not enough funds");
        _safeMint(msg.sender, _nb);
    }

    function setLocker(uint16 _lock) external onlyOwner {
        require(_lock >= totalSupply(), "Cannot lock minted tokens");
        locker = _lock;
    }
    function giveBack(address[] calldata to, uint8[] calldata _nb) external onlyOwner nonReentrant {
        require(sellingStep == Step.Before, "Just use it to give back");
        uint _length = to.length;
        require(_length == _nb.length, "Size of arrays differs");
        for(uint i = 0; i < _length;){
            _safeMint(to[i], _nb[i]);
            unchecked {++i;}
        }
    }
    function setBaseUri(string memory _URI) external onlyOwner {
        baseURI = _URI;
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
    function withdraw() external {
        uint balance = address(this).balance;
        (bool success, ) = teamAddress.call{value : balance}("");
        require(success, "withdraw error");
    }
}