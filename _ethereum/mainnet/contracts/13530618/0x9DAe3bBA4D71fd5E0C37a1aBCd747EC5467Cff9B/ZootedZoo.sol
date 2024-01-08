// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Address.sol";

contract ZootedZoo is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public constant maxTokens = 4200;
    uint256 public tokenPrice = 69420000000000000; //0.069420 ether
    bool public devMintLocked = false;
    bool public whitelistOnly = true;
    string private _baseURIVar = "https://www.zootedzoo.com/api/";
    bytes32 immutable public root;

    constructor(bytes32 merkleroot) ERC721("Zooted Zoo", "ZOOT") {
      root = merkleroot;
      _tokenIdCounter.increment();
      _pause();
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal view returns (bool)
    {
      return MerkleProof.verify(proof, root, leaf);
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIVar;
    }


    //Set Contract-level URI
    function setBaseURI(string memory baseURI_)
        external
        onlyOwner
    {
        _baseURIVar = baseURI_;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //Public minting
    function mint(uint256 quantity)
        external
        whenNotPaused
        payable
    {
        require(!whitelistOnly, "Whitelist only");
        require(
            _tokenIdCounter.current() -1 + quantity <= maxTokens ,
            "Minting this many would exceed supply!"
        );
        require(
            msg.value >= tokenPrice * quantity,
            "Not enough ether sent!"
        );
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    //Whitelist minting
    function whitelistMint(uint256 quantity, bytes32[] calldata proof)
        external
        whenNotPaused
        payable
    {
        require(_verify(_leaf(msg.sender), proof), "Invalid merkle proof");
        require(
            _tokenIdCounter.current() -1 + quantity <= maxTokens ,
            "Minting this many would exceed supply!"
        );
        require(
            msg.value >= tokenPrice * quantity,
            "Not enough ether sent!"
        );
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function nextTokenId() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    //Dev mint special tokens
    function mintSpecial(address [] memory recipients, uint256 [] memory specialId)
        external
        onlyOwner
    {
      require (!devMintLocked, "Dev Mint Permanently Locked");
      for (uint256 i = 0; i < recipients.length; i++) {
        require (specialId[i]!=0);
        _safeMint(recipients[i],specialId[i]*1000000);
      }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function disableWhitelist()
        public
        onlyOwner
    {
        whitelistOnly=false;
    }

    function lockDevMint()
        public
        onlyOwner
    {
        devMintLocked=true;
    }

    function release(address payable account) public onlyOwner {
        uint256 total = address(this).balance;
        require(total != 0, "Account has zero balance");
        Address.sendValue(account, total);
    }

    receive() external payable {
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

