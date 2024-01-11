// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721A.sol";
import "./Ownable.sol";

// ██╗  ██╗ ██████╗ ██████╗ ██████╗ ██╗████████╗███████╗    ████████╗ ██████╗ ██╗    ██╗███╗   ██╗
// ██║  ██║██╔═══██╗██╔══██╗██╔══██╗██║╚══██╔══╝██╔════╝    ╚══██╔══╝██╔═══██╗██║    ██║████╗  ██║
// ███████║██║   ██║██████╔╝██████╔╝██║   ██║   ███████╗       ██║   ██║   ██║██║ █╗ ██║██╔██╗ ██║
// ██╔══██║██║   ██║██╔══██╗██╔══██╗██║   ██║   ╚════██║       ██║   ██║   ██║██║███╗██║██║╚██╗██║
// ██║  ██║╚██████╔╝██████╔╝██████╔╝██║   ██║   ███████║       ██║   ╚██████╔╝╚███╔███╔╝██║ ╚████║
// ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═════╝ ╚═╝   ╚═╝   ╚══════╝       ╚═╝    ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝


contract HobbitsTown is ERC721A, Ownable {
    uint256 public MAX_SUPPLY = 10000;

    uint256 public MAX_PER_WALLET = 40;

    uint256 public MAX_PER_TX = 20;

    uint256 public _price = 0.009 ether;

    uint256 public _freeSupply = 2000;

    bool public activated;

    string public unrevealedTokenURI = 'ipfs://QmQN94n1cJwo1ip8M8ANdAnWZMteDk7KPu9iNhwuKYH5RL';

    string public baseURI = '';

    mapping(uint256 => string) private _tokenURIs;

    address private _devWallet = 0x7B9DbE2Aa1Df8a11aE5FD46f2b4D36EC0a4F3Dce;

    address private _ownerWallet = 0x56B38414Cfa11Db9D6c238DF2e387D3166a56D46;

    constructor(string memory name, string memory symbol, address devWallet, address ownerWallet ) ERC721A(name, symbol) {
      _devWallet = devWallet;
      _ownerWallet = ownerWallet;
    }

    ////  OVERIDES
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId),'ERC721Metadata: URI query for nonexistent token');
       return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), '.json')) : unrevealedTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    ////  MINT
    function mint(uint256 numberOfTokens) external payable {
        require(activated, 'Inactive');
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, 'All minted');
        require(numberOfTokens <= MAX_PER_TX, 'Too many for Tx');
        require(_numberMinted(msg.sender) + numberOfTokens <= MAX_PER_WALLET, 'Too many for address');
        if(totalSupply()  + numberOfTokens > _freeSupply){
          require(_price * numberOfTokens <= msg.value, 'ETH inadequate');
        }
        _safeMint(msg.sender, numberOfTokens);
    }

    ////  SETTERS
    function setTokenURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    function setUnrevealedTokenURI(string calldata newURI) external onlyOwner {
        unrevealedTokenURI = newURI;
    }

    function setIsActive(bool _isActive) external onlyOwner {
        activated = _isActive;
    }

    function setFreeSupply(uint256 freeSupply) external onlyOwner{
      _freeSupply = freeSupply;
    }
    function setPrice(uint256 newPrice) external onlyOwner{
      _price = newPrice;
    }

    ////  WITHDRAW
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_devWallet).transfer(balance * 15/100);
        payable(_ownerWallet).transfer(balance * 85/100);
    }
}
