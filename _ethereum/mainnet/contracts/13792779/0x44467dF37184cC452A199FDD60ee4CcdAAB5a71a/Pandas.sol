// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";

//   ██████                    ██████  
// ██████████  ████████████  ██████████
// ████████████            ████████████
// ████████                    ████████
//   ████                        ████  
//     ██    ██████    ██████    ██    
//   ██    ████████    ████████    ██  
//   ██    ████  ██    ██  ████    ██  
//   ██    ████████    ████████    ██  
//   ██    ██████        ██████    ██  
//   ██                            ██  
//   ██          ████████          ██  
//     ██          ████          ██    
//     ██      ██        ██      ██    
//       ██      ████████      ██      
//         ████            ████        
//             ████████████            

/// @title The Species Pandas
/// @dev Extends ERC721 Non-Fungible Token Standard basic implementation
contract Pandas is ERC721Enumerable, ReentrancyGuard, Ownable, PaymentSplitter {
  uint256 public constant MAX_SUPPLY = 1888;
  uint256 public constant MAX_PER_WHITELIST = 5;
  uint256 public constant MAX_PER_ADDRESS = 25;
  uint256 public constant PRICE = 0.0888 ether;
  uint256 public constant RESERVED_PANDAS = 100;

  bool public isSaleActive = false;
  bool public onlyWhitelist = false;

  string private _baseTokenURI;

  mapping(address => uint256) public whitelist;

  constructor(address[] memory _payees, uint256[] memory _shares)
    ERC721("The Species Pandas", "TSPANDA")
    PaymentSplitter(_payees, _shares)
  {}

  /// @notice Set some Pandas aside for the team and community wallet
  function reservePandas() public onlyOwner {
    _mint(RESERVED_PANDAS);
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string memory baseTokenURI) public onlyOwner {
    _baseTokenURI = baseTokenURI;
  }

  /// @notice Checks if address is whitelisted
  /// @param _user The number of rings from dendrochronological sample
  /// @return True or False
  function isWhitelisted(address _user) public view returns (bool) {
    return whitelist[_user] > 0;
  }

  /// @notice Get Pandas that belong to a given address
  /// @param _owner Address of the owners wallet
  /// @return List of Panda token ids
  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  /// @notice Pause sale if active, make active if paused
  function toggleSale() public onlyOwner {
    isSaleActive = !isSaleActive;
  }

  /// @notice Pause whitelist sale if active, make active if paused
  function toggleWhitelist() public onlyOwner {
    onlyWhitelist = !onlyWhitelist;
  }

  /// @notice Whitelist addresses
  /// @param _addresses List of wallet addresses that belong to those that are whitelisted
  function whitelistAddresses(address[] calldata _addresses) public onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      whitelist[_addresses[i]] = MAX_PER_WHITELIST + 1;
    }
  }

  /// @notice Mint Pandas during the whitelist only presale
  /// @param _quantity Amount of pandas to mint
  function whitelistMint(uint256 _quantity) public payable nonReentrant {
    require(onlyWhitelist, "Whitelist mint is not active");
    require(PRICE * _quantity == msg.value, "ETH amount is incorrect");
    require(isWhitelisted(msg.sender), "Address is not whitelisted");
    require(
      whitelist[msg.sender] - 1 >= _quantity,
      "Whitelist mint limited exceeded"
    );

    _mint(_quantity);
    whitelist[msg.sender] -= _quantity;
  }

  /// @notice Mint Pandas during public sale
  /// @param _quantity Amount of pandas to mint
  function mint(uint256 _quantity) public payable {
    require(isSaleActive, "Sale is not active");
    require(PRICE * _quantity == msg.value, "ETH amount is incorrect");
    require(
      balanceOf(_msgSender()) + _quantity <= MAX_PER_ADDRESS,
      "Total mint limit exceeded"
    );

    _mint(_quantity);
  }

  /// @notice Mint Pandas
  /// @param _quantity Amount of pandas to mint
  function _mint(uint256 _quantity) private {
    require(_quantity > 0, "Must mint at least 1 panda");
    uint256 supply = totalSupply();
    require(supply + _quantity <= MAX_SUPPLY, "Minting exceeds max supply");

    for (uint256 i = 0; i < _quantity; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }
}
