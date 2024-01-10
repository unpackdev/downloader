//SPDX-License-Identifier: Unlicense
/*
 /$$      /$$ /$$$$$$$  /$$        /$$$$$$ 
| $$$    /$$$| $$__  $$| $$       /$$__  $$
| $$$$  /$$$$| $$  \ $$| $$      | $$  \__/
| $$ $$/$$ $$| $$$$$$$/| $$      | $$      
| $$  $$$| $$| $$____/ | $$      | $$      
| $$\  $ | $$| $$      | $$      | $$    $$
| $$ \/  | $$| $$      | $$$$$$$$|  $$$$$$/
|__/     |__/|__/      |________/ \______/                                 
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract MPLC is ERC721A, Ownable {
    using Strings for uint256;

  uint256 public constant MAX_SUPPLY = 11111;
  uint256 public constant MAX_MINTS = 4;
  uint256 public constant PUBLIC_PRICE = 0.075 ether;
  uint256 public constant PRESALE_PRICE = 0.055 ether;

  bool public isPresaleActive = false;
  bool public isPublicSaleActive = false;
  bool public revealed = false;

  bytes32 public merkleRoot;
  mapping(address => uint256) public purchaseTxs;
  mapping(address => uint256) private _allowed;

  string private _baseURIextended;
  string public notRevealedUri;

  address[] private mintPayees = [
    0x1a84Ae75d0E82917211D01C7F3a0DBF5535F3E01,
    0x44814D1451D7542733A6cBad33183Cf705c82A15,
    0xC4bBAAB6c4072cd74610cd5f54ec0Ecf3f691685,
    0x4FC41c4Fe87752Af250BC92242F7f7a942112C71

  ];

  constructor() ERC721A("Mermaids Pink Lighthouse Club", "MPLC") {}

  function preSaleMint(bytes32[] calldata _proof, uint256 nMints)
    external
    payable
  {
    require(msg.sender == tx.origin, "Can't mint through another contract");
    require(isPresaleActive, "Presale not active");

    bytes32 node = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_proof, merkleRoot, node), "Not on allow list");
    require(nMints <= MAX_MINTS, "Exceeds max token purchase");
    require(totalSupply() + nMints <= MAX_SUPPLY, "Mint exceeds total supply");
    require(PRESALE_PRICE * nMints <= msg.value, "Sent incorrect ETH value");
    require(_allowed[msg.sender] + nMints <= MAX_MINTS, "Exceeds mint limit");

    // Keep track of mints for each address
    if (_allowed[msg.sender] > 0) {
      _allowed[msg.sender] = _allowed[msg.sender] + nMints;
    } else {
      _allowed[msg.sender] = nMints;
    }

    _safeMint(msg.sender, nMints);
  }

  function mint(uint256 nMints) external payable {
    require(msg.sender == tx.origin, "Can't mint through another contract");
    require(isPublicSaleActive, "Public sale not active");
    require(nMints <= MAX_MINTS, "Exceeds max token purchase");
    require(totalSupply() + nMints <= MAX_SUPPLY, "Mint exceeds total supply");
    require(PUBLIC_PRICE * nMints <= msg.value, "Sent incorrect ETH value");

    _safeMint(msg.sender, nMints);
  }

	function reveal() external onlyOwner {
		revealed = true;
	}

  function withdrawAll() external onlyOwner {
    require(address(this).balance > 0, "No funds to withdraw");
    uint256 contractBalance = address(this).balance;

    _withdraw(mintPayees[0], (contractBalance * 10) / 100);
    _withdraw(mintPayees[1], (contractBalance * 25) / 100);
    _withdraw(mintPayees[2], (contractBalance * 30) / 100);
    _withdraw(mintPayees[3], address(this).balance);
  }

  function reserveMint(uint256 nMints, uint256 batchSize) external onlyOwner {
    require(totalSupply() + nMints <= MAX_SUPPLY, "Mint exceeds total supply");
    require(nMints % batchSize == 0, "Can only mint a multiple of batchSize");

    for (uint256 i = 0; i < nMints / batchSize; i++) {
      _safeMint(msg.sender, batchSize);
    }
  }

  function setBaseURI(string calldata baseURI_) external onlyOwner {
    _baseURIextended = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIextended;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function togglePresale() external onlyOwner {
    isPresaleActive = !isPresaleActive;
  }

  function togglePublicSale() external onlyOwner {
    isPublicSaleActive = !isPublicSaleActive;
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require(success, "Transfer failed.");
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
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }
    
    function setNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

  receive() external payable {}
}