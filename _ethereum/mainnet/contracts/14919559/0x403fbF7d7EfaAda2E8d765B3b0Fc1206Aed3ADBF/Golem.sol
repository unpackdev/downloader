import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

pragma solidity ^0.8.2;

contract GolemWTF is ERC721A, Ownable, ReentrancyGuard {  
    using Strings for uint256;
    string public _partslink;
    bool public byebye = false;
    uint256 public golems = 9999;
    uint256 public golembyebye = 1; 
    mapping(address => uint256) public howmanygolems;
   
	constructor() ERC721A("golem", "GOLEM") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _partslink;
    }

 	function makingolem() external nonReentrant {
  	    uint256 totalgolems = totalSupply();
        require(byebye);
        require(totalgolems + golembyebye <= golems);
        require(msg.sender == tx.origin);
    	require(howmanygolems[msg.sender] < golembyebye);
        _safeMint(msg.sender, golembyebye);
        howmanygolems[msg.sender] += golembyebye;
    }

 	function makegolemfly(address lords, uint256 _golems) public onlyOwner {
  	    uint256 totalgolems = totalSupply();
	    require(totalgolems + _golems <= golems);
        _safeMint(lords, _golems);
    }

    function makegolembyebye(bool _bye) external onlyOwner {
        byebye = _bye;
    }

    function spredgolems(uint256 _byebye) external onlyOwner {
        golembyebye = _byebye;
    }

    function makegolemhaveparts(string memory parts) external onlyOwner {
        _partslink = parts;
    }

    function sumthinboutfunds() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
      require(success);
	}
}