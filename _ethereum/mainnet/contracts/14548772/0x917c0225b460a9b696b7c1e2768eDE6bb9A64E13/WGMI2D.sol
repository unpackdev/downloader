// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract WGMI2D is ERC721, Ownable {
    using Strings for uint256;
    Counters.Counter private supply;
    bool public publicsaleActive = false;
    string private _baseURIextended;
    
    using Counters for Counters.Counter;

    uint256 public constant MAX_SUPPLY = 6969;
    uint256 public constant MAX_PUBLIC_MINT = 20;
    uint256 public constant MAX_CLAIMABLE = 5;
    uint256 public constant PRICE_PER_TOKEN = 0.033 ether;

    bool public revealed;
    string public hiddenMetadataUri = "ipfs://QmcBZzugWkKtDRVysned7YbHx1de2K97GHa7iM4JA8XxD8";
    address t1 = 0xfE993FAA5633709e4845C0b007847330bEE54596;
    address t2 = 0xd0C98B30CD8FE8cBE21f7db5D3Cd67293eB7eCD6; 
    address t3 = 0x3635fb724712486F8e2894D13D8e3Ac32E80879C;

    mapping(address => uint256) public claimCounter;

    constructor() ERC721("WGMI2D", "WGMI") {}

    function mint(uint numberOfTokens) public payable {
      uint256 claimedPerUser = claimCounter[msg.sender];
      require(publicsaleActive, "Sale must be active to mint tokens");
      require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
      if (totalSupply() + numberOfTokens > 555) {
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Maximum 20 per tx!");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");
      } else {
        require(numberOfTokens <= MAX_CLAIMABLE, "Cannot claim more than 5");
        require(claimedPerUser + numberOfTokens <= MAX_CLAIMABLE, "Cannot claim any more");
        claimCounter[msg.sender] = claimedPerUser + numberOfTokens;
      }
      _mintLoop(msg.sender, numberOfTokens); 
    }
   
    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }
 
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function totalSupply() public view virtual returns (uint256) {
      return supply.current();
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token!");
      if (revealed == false) {
        return hiddenMetadataUri;
      }
      string memory baseURI = _baseURI();
      return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
    }

    function setSaleState(bool newState) public onlyOwner {
        publicsaleActive = newState;
    }

    function setRevealStatus(bool newState) public onlyOwner {
        revealed = newState;
    }
    
    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function withdraw() public onlyOwner {
      uint256 _each = address(this).balance / 100;
      require(payable(t1).send(_each * 70));
      require(payable(t2).send(_each * 20));
      require(payable(t3).send(_each * 10));
    }
}
