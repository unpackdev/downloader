// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./MerkleProof.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./Strings.sol";


contract CavernCoresGen0 is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;


    uint256 public constant MAX_SUPPLY = 125;
    bytes32 _merkleRoot;
    uint256 _mintingPrice;
    ERC20 _mintingCurrency;
    uint256 _maxPerMint;
    bool _WLOff;
    string _baseTokenURI;

    mapping(address => bool) public claimedMint;

    constructor() ERC721("CavernCores Gen 0", "CCNFT0") { _tokenIdCounter.increment(); //start at 1
    }

    function next() external view returns (uint256) {
      return _tokenIdCounter.current();
  }
      function mintingPrice() external view returns (uint256) {
        return _mintingPrice;
    }
      function mintingCurrency() external view returns (ERC20) {
        return _mintingCurrency;
    }
      function maxPerMint() external view returns (uint256) {
        return _maxPerMint;
    }
      function merkleRoot() external view returns (bytes32) {
      return _merkleRoot;
    }
      function WLOff() external view returns (bool) {
      return _WLOff;
    }

    function setWLOff(bool newWLOff) onlyOwner external {
        _WLOff = newWLOff;
    }
    function setMerkleRoot(bytes32 newMerkleRoot) onlyOwner external {
        _merkleRoot = newMerkleRoot;
    }
    function setMaxPerMint(uint256 newMaxPerMint) onlyOwner external {
        _maxPerMint = newMaxPerMint;
    }
    function setMintingPrice(uint256 newMintingPrice) onlyOwner external {
        _mintingPrice = newMintingPrice;
    }
    function setMintingCurrency(ERC20 newMintingCurrency) onlyOwner external {
        _mintingCurrency = newMintingCurrency;
    }


    function contractURI() public pure returns (string memory) {
        return "https://caverncores.com/api/v1/getNFT/gen0/contract.json";
    }

    function setBaseTokenURI(string memory newTokenURI) onlyOwner external {
        _baseTokenURI = newTokenURI;
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) public override view returns (string memory) {
      return string(abi.encodePacked(
          baseTokenURI(),
          Strings.toString(_tokenId),
          ".json"
      ));
    }


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mintNFTs(uint256 _count, bytes32[] memory _merkleProof) public whenNotPaused {
        uint256 totalMinted = _tokenIdCounter.current();

        require(totalMinted.add(_count) < MAX_SUPPLY, "Not enough NFTs left!");
        require(_count >0 && _count <= _maxPerMint, "Cannot mint specified number of NFTs.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if ( _WLOff == false ) {
          require(!claimedMint[msg.sender], "Address already claimed.");
          require(MerkleProof.verify(_merkleProof, _merkleRoot, leaf), "Address not whitelisted or invalid proof.");
      }

        require(ERC20(_mintingCurrency).transferFrom(msg.sender, address(this), _mintingPrice.mul(_count)));

        for (uint i = 0; i < _count; i++) {
            safeMint(msg.sender);
        }

        claimedMint[msg.sender] = true;
    }


    function safeMint(address to) private whenNotPaused {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }


    function _getTokenBalance() private view returns (uint256) {
      return _mintingCurrency.balanceOf(address(this));
    }


    function withdraw() public onlyOwner {
      uint256 _balance = _getTokenBalance();
      require(_balance > 0, "None left to withdraw");
      _mintingCurrency.transfer(owner(), _balance);

    }


    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {

        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
