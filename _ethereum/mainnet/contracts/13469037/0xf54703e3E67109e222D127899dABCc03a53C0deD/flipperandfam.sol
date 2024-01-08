pragma solidity ^0.8.7;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract flipperandfam is ERC721Enumerable, Ownable, ReentrancyGuard{
    uint256 public mintPrice = 0.01 ether;
    uint256 public constant maxSupply = 15000;

    mapping(address => uint256) public TotalMinted;
    string public BaseURI;

    constructor (string memory baseUri) public ERC721("flipperandfam", "flip"){
        BaseURI = baseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return BaseURI;
    }

    function Mint(uint nr) nonReentrant external payable{
        require(msg.value >= mintPrice * nr, "Not enough eth send");
        _mint(nr);
    }

    function _mint(uint nr) private{
        require(totalSupply() < maxSupply, "All tokens have been minted");
        require((totalSupply() + nr) <= maxSupply, "You cannot exceed max supply");
        for(uint256 i = 0; i < nr; i++)
        {
            TotalMinted[_msgSender()] += 1;
            _safeMint(_msgSender(), totalSupply() + 1);
        }
    }

    function TransferEth() onlyOwner external{
        require(address(this).balance > 0, "No eth present");
        (bool onwerTransfer, ) = owner().call{value: address(this).balance}('');
        require(onwerTransfer, "Transfer to owner address failed.");
    }

    function SetBaseUri(string memory baseUri) onlyOwner external{
        BaseURI = baseUri;
    }

    function setPrice(uint256 _newPrice) onlyOwner external{
        mintPrice = _newPrice;
    }
}