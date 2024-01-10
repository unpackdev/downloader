// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";
import "./ERC721A.sol";


contract HabitatForHumanity is ERC721A, Ownable, PaymentSplitter{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant PRICE = 0.0031 ether;

    string public baseExtension = ".json";
    string private baseURI;


    bool public isRevealed;

    uint private teamLength;


    constructor(
        address[] memory _team,
        uint[] memory _teamShares,
        string memory _initBaseURI) ERC721A("Habitat For Humanity", "HFH")
        PaymentSplitter(_team, _teamShares) {
        setBaseURI(_initBaseURI);
        teamLength = _team.length;
    }

    // reentrancy guard
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Habitat Humanity :: Cannot be called by a contract");
        _;
    }


    function mint(address _account, uint256 _quantity) external payable callerIsUser{
        uint price = PRICE;
        require(price != 0, "price connot be 0");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Habitat Humanity :: Beyond Max Supply");
        require(msg.value >= (PRICE * _quantity), "Habitat Humanity :: not enough funds ");
        _safeMint(_account, _quantity);
    }


    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

    // setBaseURI
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }


    function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
    } 


    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }

    
    function releaseAll() external onlyOwner {
        for(uint i = 0; i < teamLength; i++) {
            release(payable(payee(i)));
        }
    }

    receive() override external payable {
        revert ("Only if you mint");
    }

}

