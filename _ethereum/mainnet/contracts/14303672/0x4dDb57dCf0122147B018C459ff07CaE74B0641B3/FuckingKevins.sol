/*@#%@#%@#$@#$%@#%
fucking kevin's ascii art
^#%(*@##@$&#$#$)*/

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract FuckingKevins is ERC721A, Pausable, Ownable, AccessControl {
    using SafeMath for uint256;

    bool public isSaleOpen = true;
    uint256 public maxSupply = 10000;
    uint256 public mintPrice = 30000000000000000;

    string public _BaseURI;
    string public _ContractURI;

    event PermanentURI(string _value, uint256 indexed _id);

    constructor(string memory baseURI)
        ERC721A("Fucking Kevins", "FUCKINGKEVINS")
    {
        _ContractURI = "ipfs://Qmeyuozgc55EmUmf4Ju2K5P9Badmne4Fu6B84wG42iJip3";
        _BaseURI = baseURI;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
       
    }

    function mint(uint256 quantity) external payable {
        require(!paused(), "Mint: minting is paused");
        require(isSaleOpen, "Sale: Not open");
        require(quantity > 0, "Sale: Must send quantity");
        require(
            msg.value >= quantity.mul(mintPrice),
            "Sale: Ether value incorrect"
        );
        require(
            totalSupply() + quantity <= maxSupply,
            "Sale: Purchase would exceed max supply"
        );

        _safeMint(msg.sender, quantity);
        lockMetadata(quantity);
    }

    function setSaleOpen(bool _isSaleOpen)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        isSaleOpen = _isSaleOpen;
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

      function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }     
}
