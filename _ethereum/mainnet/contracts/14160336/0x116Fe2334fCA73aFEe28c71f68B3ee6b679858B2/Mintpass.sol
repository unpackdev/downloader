// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Pausable.sol";
import "./ECDSA.sol";
import "./ERC2981ContractWideRoyalties.sol";

/// @title MSO Mintpass
/// @author Arenzel (Discord arenzel#6979)
/// @notice Collection of minpass for Martial Spirit Odyssey, released in January 2022
contract Mintpass is ERC1155, Ownable, Pausable, ERC2981ContractWideRoyalties {

  /*** CONFIGS ***/

  /// @notice Name + symbol of the token, will be displayed on etherscan, opensea, etc.
  string public name = "MSO MINTPASS #1";
  string public symbol = "MSOM1";

  /// @notice Max amount of token to be ever minted
  uint256 public totalSupply = 5000;

  /// @notice Token price
  uint public price = 0.2 ether;

  /// @notice Maximum amount of tokens allowed per address
  uint public maxAmountPerAddress = 5;

  /// @notice Maximum amount of tokens allowed per transaction
  uint public maxAmountPerTransaction = 5;

  /// @notice Token that can be minted through this contract
  uint256 public constant MINTPASS = 0;

  /// @notice Since we're minting undivisible token (NFT), we fix this number to 0
  uint8 public constant decimals = 0;


  /*** SUPPLY MANAGEMENT ***/

  /// @notice Supplies
  uint private constant FOUNDER_SUPPLY = 250;
  uint private constant GIVE_AWAY_SUPPLY = 50;
  uint private constant PUBLIC_SALE_SUPPLY = 4700;

  /// @notice Keeping track of subset of the total token supply
  using Counters for Counters.Counter;
  Counters.Counter private founderTokenIds;
  Counters.Counter private giveAwayTokenIds;
  Counters.Counter private publicSaleTokenIds;

  function founderTokenLeft() public view returns (uint) {
    return FOUNDER_SUPPLY - founderTokenIds.current();
  }

  function giveAwayTokenLeft() public view returns (uint) {
    return GIVE_AWAY_SUPPLY - giveAwayTokenIds.current();
  }

  function publicSaleTokenLeft() public view returns (uint) {
    return PUBLIC_SALE_SUPPLY - publicSaleTokenIds.current();
  }


  /*** ROYALTIES ***/

  // @notice MSO wallet
  address private constant MSO_DEPLOYER_WALLET = 0x61B7d4738696799c787F25aDDBD8Ef2C06660bE2;

  /// @notice ERC2981 compliant royalties, 7.5% for MSO
  /// @dev Using 2 decimals notation: 10000 = 100, 0 = 0
  uint private constant MSO_ROYALTIES = 750;


  /*** CONSTRUCTOR ***/

  constructor() ERC1155("ipfs://Qmd7ePiefD3g7mt9nXh7oYb6zWsErFNVZYJCqGUJVZmenv") {
    _setRoyalties(MSO_DEPLOYER_WALLET, MSO_ROYALTIES);
  }


  /*** CONFIG FUNCTIONS ***/

  function setName(string memory _name) external onlyOwner {
      name = _name;
  }

  function setSymbol(string memory _symbol) external onlyOwner {
      symbol = _symbol;
  }

  function setPrice(uint _price) external onlyOwner {
      price = _price;
  }

  function setMaxAmountPerAddress(uint _amountPerAddress) external onlyOwner {
      maxAmountPerAddress = _amountPerAddress;
  }

  function setMaxAmountPerTransaction(uint _amountPerTransaction) external onlyOwner {
      maxAmountPerTransaction = _amountPerTransaction;
  }


  /*** UTILITY FUNCTIONS ***/

  /// @notice To display contract-level metadata on OpenSea
  function contractURI() public pure returns (string memory) {
    return "ipfs://QmR1G18MSRfGhcYhXPwKVgKVXMEekQpXxCDV7hZ9wvgovt";
  }

  /// @notice Withdraw eth from the contract to the owner's wallet
  function withdraw() external onlyOwner {
      payable(msg.sender).transfer(address(this).balance);
  }


  /*** CORE FUNCTIONS ***/

  /// @notice Mint function for founders.
  function founderMint(uint _amount, address _to) external onlyOwner {
    require(founderTokenLeft() > 0, "Sorry fighter: there is no more founder token left.");
    require(founderTokenLeft() - _amount >= 0, "Not enough founder token left");

    for (uint256 index = 0; index < _amount; index++) {
      founderTokenIds.increment();
    }

    _mint(_to, MINTPASS, _amount, "");
  }

  /// @notice Mint function for founders.
  function giveAwayMint(uint _amount, address _to) external onlyOwner {
    require(giveAwayTokenLeft() > 0, "Sorry fighter: there is no more giveAway token left.");
    require(giveAwayTokenLeft() - _amount >= 0, "Not enough giveAway token left");

    for (uint256 index = 0; index < _amount; index++) {
      giveAwayTokenIds.increment();
    }

    _mint(_to, MINTPASS, _amount, "");
  }

  /// @notice Pay the price and grab your token!
  function publicMint(uint _amount) external payable whenNotPaused {
      require(publicSaleTokenLeft() > 0, "No more tokens are available");
      require(publicSaleTokenLeft() - _amount >= 0, "Not enough token left");
      require(_amount <= maxAmountPerTransaction, "Amount of token exceeds the max amount of mintpass per transaction limit");
      require(balanceOf(msg.sender, MINTPASS) + _amount <= maxAmountPerAddress, "You already hold the maximum amount of mintpass");
      require(msg.value == price * _amount, "Oops! An incorrect quantity of ETH was sent! Please ensure you paid the right price. :)");

      for (uint256 index = 0; index < _amount; index++) {
        publicSaleTokenIds.increment();
      }
      _mint(msg.sender, MINTPASS, _amount, "");
  }


  /*** BURN FUNCTIONS ***/

  /// @notice Giving the ability for a owner to destroy its token(s).
  function burn(uint _amount) external whenNotPaused {
      _burn(msg.sender, MINTPASS, _amount);
  }

  /// @notice The mintpass is supposed to be burnt on usage
  /// @param _target: the wallet from which tokens should be burnt
  /// @param _amount: how many tokens should be used/burnt
  function useAndBurn(
    address _target,
    uint _amount,
    bytes memory _signature
  ) external whenNotPaused {
    require(signatureIsValid(_signature), "Invalid signature: please call this function from an authorized contract");
    require(balanceOf(_target, MINTPASS) - _amount >= 0, "The target wallet doesnt have enought tokens to use");

    _burn(_target, MINTPASS, _amount);
  }


  /*** SIGNATURE FUNCTION ***/

  /// @notice We use offchain signature to greenlist futur smartcontracts that should be able to interract with this one

  /// @dev Public key of the wallet used to generate signature
  address private constant MSO_SIGNER_WALLET = 0xD806dCbC945778273992a6054CB23955DADa429A;

  function signatureIsValid(bytes memory _signature) private view returns (bool) {
    bytes32 _signedMessageHash = ECDSA.toEthSignedMessageHash(
      keccak256(abi.encodePacked(
        msg.sender,
        address(this)
      ))
    );

    address recoveredAddress = ECDSA.recover(_signedMessageHash, _signature);

    return recoveredAddress == MSO_SIGNER_WALLET;
  }


  /*** EMERGENCY FUNCTIONS ***/

  /// @notice Block execution of public mint/burn function
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice Resuming activity: back to mint baby!
  function unpause() external onlyOwner {
    _unpause();
  }


  /*** TECHNICAL FUNCTIONS ***/

  /// @dev As both ERC1155 and ERC2981Base include supportsInterface we need to override both.
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981Base) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}