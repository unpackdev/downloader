//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Frooties
/// @author Frooties Team (fbsloXBT)

import "./ERC721A.sol";

contract Frooties is ERC721A {
  /// @notice Base URI storing the metadata
  string public baseURI = "https://metadata.thefrooties.com/";
  /// @notice Price to pay per NFT
  uint256 public price = 0.05 ether;
  /// @notice Maximum supply
  uint256 public maxSupply = 1111;
  /// @notice Amount reserved for the team
  uint256 public reservedAmount = 50;
  /// @notice Sale supply (maxSupply - reserved for admin)
  uint256 public saleSupply = maxSupply - reservedAmount;
  /// @notice Governance address
  address public admin;
  /// @notice Address used to sign whitelist permits
  address public whitelistSigner;
  /// @notice Mapping of amounts minted per address
  mapping(address => uint256) public amounts;

  /// @notice Start timestamp for whitelist mint
  uint256 public whitelistTimestamp = 1651845600; //Fri May 06 2022 16:00:00 GMT+0200
  /// @notice Start timestamp for public mint
  uint256 public publicTimestamp = 1651870800;    //Fri May 06 2022 23:00:00 GMT+0200
  /// @notice Start timestamp for reserve mint
  uint256 public reserveTimestamp = 1651874400;   //Fri May 06 2022 24:00:00 GMT+0200


  constructor(address newAdmin, address newWhitelistSigner) ERC721A("Frooties", "FROOTIES") {
    admin = newAdmin;
    whitelistSigner = newWhitelistSigner;
  }

  /// @notice Verify caller is admin
  modifier onlyOwner(){
    require(msg.sender == admin, "Only owner");
    _;
  }

  /**
   * @notice Perform basic checks (max supply, limit per address, payment)
   * @param quantity Number of NFTs to mint
   */
  modifier mintChecks(uint256 quantity){
    require(totalSupply() + quantity <= saleSupply, "Sale supply reached");
    require(msg.value >= quantity * price, "Insufficient payment");
    amounts[msg.sender] += quantity;
    if (block.timestamp >= publicTimestamp){
      require(amounts[msg.sender] <= 3, "Max 3");
    } else {
      require(amounts[msg.sender] <= 2, "Max 2");
    }
    _;
  }

  /**
   * @notice Mint tokens
   * @param quantity Number of NFTs to mint
   */
  function mint(uint256 quantity) external payable mintChecks(quantity) {
    require(block.timestamp >= publicTimestamp, "Public mint not active");
    _safeMint(msg.sender, quantity);
  }

  /**
   * @notice Mint tokens using permit signature
   * @param quantity Number of NFTs to mint
   */
  function whitelistMint(uint256 quantity, bytes memory signature) external payable mintChecks(quantity) {
    require(block.timestamp >= whitelistTimestamp, "Whitelist mint not active");

    bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, address(this)));
    bytes32 prefixHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    address signer = recoverSigner(prefixHash, signature);
    require(signer == whitelistSigner, "Signer does not match");

    _safeMint(msg.sender, quantity);
  }

  /**
   * @notice Mint tokens for free
   * @param quantity Number of NFTs to mint
   */
  function reserveMint(uint256 quantity) external onlyOwner {
    require(block.timestamp >= reserveTimestamp, "Reserve mint not active");
    require(amounts[address(0)] + quantity <= reservedAmount, "Max 50");
    require(totalSupply() + quantity <= maxSupply, "Max supply reached");

    amounts[address(0)] += quantity;
    _safeMint(msg.sender, quantity);
  }

  /**
   * @notice Call any address (usefull for withdrawing ETH or retrieving tokens)
   * @dev Will not revert on failure
   * @param to Addresss to call
   * @param value ETH amount in wei
   * @param signature Function signature
   * @param data Calldata to include
   */
  function call(address to, uint256 value, string memory signature, bytes memory data) external onlyOwner {
    bytes memory callData;
    if (bytes(signature).length == 0) {
        callData = data;
    } else {
        callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }
    to.call{value: value}(callData);
  }

  /**
   * @notice Used to transfer entire ETH balance to admin
   */
  function transferOut() external onlyOwner {
    payable(admin).send(address(this).balance);
  }

  /**
   * @notice Override default _baseURI function
   * @return baseURI as a string
   */
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  /**
   * @notice Update baseURI
   */
  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  /**
   * @notice Update starting times if needed
   */
   function seTimestamp(uint256 newWhitelistTimestamp, uint256 newPublicTimestamp, uint256 newReserveTimestamp) external onlyOwner {
     whitelistTimestamp = newWhitelistTimestamp;
     publicTimestamp = newPublicTimestamp;
     reserveTimestamp = newReserveTimestamp;
   }

   /**
    * @notice Update admin addresses
    */
    function setGovernance(address newAdmin, address newWhitelistSigner) external onlyOwner {
      admin = newAdmin;
      whitelistSigner = newWhitelistSigner;
    }

  /**
   * @notice Recover signer address from signature
   * @param hash Hash of the message signed
   * @param signature The signature from validators
   * @return The address of the signer, address(0) if signature is invalid
   */
   function recoverSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
     bytes32 r;
     bytes32 s;
     uint8 v;

     if (signature.length != 65) {
         return (address(0));
     }

     assembly {
         r := mload(add(signature, 0x20))
         s := mload(add(signature, 0x40))
         v := byte(0, mload(add(signature, 0x60)))
     }

     if (v < 27) {
         v += 27;
     }

     if (v != 27 && v != 28) {
         return (address(0));
     } else {
         return ecrecover(hash, v, r, s);
     }
   }
}
