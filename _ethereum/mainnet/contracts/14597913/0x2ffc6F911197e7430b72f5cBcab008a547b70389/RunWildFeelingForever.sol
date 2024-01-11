/*
@#%@#%@#$@#$%@#%
PLZ&TY - Run Wild Feeling Forever
^#%(*@##@$&#$#$)
*/

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

import "./console.sol";

contract RunWildFeelingForever is ERC721A, Pausable, Ownable, AccessControl {
    using Strings for uint256;
    using SafeMath for uint256;

    bool public saleOpen = false;
    uint256 public maxSupply = 250;
    uint256 public mintPrice = .15 ether;

    string public _BaseURI = "ipfs://";
    string public _ContractURI = "ipfs://QmSkbirvTgEDSi8yatRBFQKx58J168SaCJyCNhiJWGX6mG";

    address public receivingWallet = 0x91aDcd7Dc079C014493FE0617f56e3Eefd1291e0;
 
    event PermanentURI(string _value, uint256 indexed _id);

    constructor(string memory baseURI)
        ERC721A("Run Wild / Feeling Forever by PLS&TY", "PLSANDTYRWFF")
    {
        _BaseURI = baseURI;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(uint256 quantity) external payable {
        require(!paused(), "Mint: minting is paused");
        require(isSaleOpen(), "Sale: Not open");
        require(quantity > 0, "Sale: Must send quantity");
        require(
            msg.value >= quantity.mul(mintPrice),
            "Sale: Ether value incorrect"
        );
        require(
            totalSupply() + quantity <= maxSupply,
            "Sale: Purchase would exceed max supply"
        );

        payable(receivingWallet).transfer(msg.value);
        _safeMint(msg.sender, quantity);
        lockMetadata(quantity);
    }

     function setReceivingWallet(address _receivingWallet)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        receivingWallet = _receivingWallet;
    }

    function setSaleOpen(bool _saleOpen)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        saleOpen = _saleOpen;
    }

    function isSaleOpen() public view returns(bool){
        if(totalSupply() < maxSupply){
            return saleOpen;
        }
        else{
            return false;
        }
        
    }

    function setSupply(uint256 _maxSupply)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxSupply = _maxSupply;
    }

     function setPrice(uint256 _mintPrice)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        mintPrice = _mintPrice;
    }

     function setBaseURI(string memory _uri)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _BaseURI = _uri;
    }

     function setContractURI(string memory _uri)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _ContractURI = _uri;
    }

    function lockMetadata(uint256 quantity) internal {
        for (uint256 i = quantity; i > 0; i--) {
            uint256 tid = totalSupply() - i;
            emit PermanentURI(tokenURI(tid), tid);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function contractURI() public view returns (string memory) {
        return _ContractURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _BaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_BaseURI, tokenId.toString(), '.json'));
    }   

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }    

    
}
