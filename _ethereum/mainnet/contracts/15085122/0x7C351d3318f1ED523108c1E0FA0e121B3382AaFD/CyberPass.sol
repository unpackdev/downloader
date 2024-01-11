// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC1155Supply.sol";
import "./Strings.sol";
import "./ICyber.sol";

contract CyberPass is ERC1155Supply, Pausable, Ownable {

  string public name = "Cyber Pass";
  string public symbol = "Cyber Pass";

  mapping(address => bool) controllers;

  uint256 public constant PASS = 1;

  ICyber public cyberAddress;
  
  string public beginning_uri;
  string public ending_uri;

  uint256 public cyberCostPerPass;
  uint256 public totalCyberPassSupply;

  constructor(
    uint256 _cyberCostPerPass,
    address _cyberAddress,
    string memory _beginning_uri,
    string memory _ending_uri
  ) ERC1155("") {

    cyberCostPerPass = _cyberCostPerPass;
    cyberAddress = ICyber(_cyberAddress);
    totalCyberPassSupply = 2500;

    beginning_uri = _beginning_uri;
    ending_uri = _ending_uri;

    controllers[msg.sender] = true;
  }

  function mint(address minterAddress, uint256 itemId, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    require(totalSupply(itemId) + amount <= totalCyberPassSupply, "total supply reached");
    _mint(minterAddress, itemId, amount, "");
  }

  function burn(address burnerAddress, uint256 itemId, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can burn");
    _burn(burnerAddress, itemId, amount);
  }

  function mintCyberPass(uint256 amount) external whenNotPaused {
    require(totalSupply(PASS) + amount <= totalCyberPassSupply, "total supply reached");
    cyberAddress.burn(msg.sender, cyberCostPerPass * amount * 1 ether);
    _mint(msg.sender, PASS, amount, "");
  }
  
  /**
    @param _mode: 
    1) cyberCostPerPass;
    2) totalCyberPassSupply;
    anything else - will result in revert()
    @param _value: corresponding value
  */
  function setValues(uint256 _mode, uint256 _value) external onlyOwner {
    if(_mode == 1) cyberCostPerPass = _value;
    if(_mode == 2) totalCyberPassSupply = _value;
    else revert("WRONG_MODE");
  }

  function setCyberAddress(address _cyberAddress) external onlyOwner {
    cyberAddress = ICyber(_cyberAddress);
  }

  /**
      @param _mode: 
      1 - replace beinning of URI
      2 - replce ending of URI
      anything else - will result in revert()
      @param _new_uri: corresponding value
    */
  function setURI(uint256 _mode, string memory _new_uri) external onlyOwner {
      if (_mode == 1) beginning_uri = _new_uri;
      else if (_mode == 2) ending_uri = _new_uri;
      else revert("setURI: WRONG_MODE");
  }

  function uri(uint256 _tokenId) public view virtual override returns (string memory) {
    require(exists(_tokenId), "id does not exist");
    return string(
      abi.encodePacked(beginning_uri, Strings.toString(_tokenId), ending_uri)
    );
  }

  /**
   * allows another contract to burn tokens
   * @param _from the holder of the tokens to burn
   * @param _ids [1]
   * @param _amounts amount to burn of each id
   */
  function burnBatch(address _from, uint256[] memory _ids, uint256[] memory _amounts) external {
    require(controllers[msg.sender], "Only controllers can burn");
    _burnBatch(_from, _ids, _amounts);
  }

  /**
   * enables an address to mint / burn
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /**
   * disables an address from minting / burning
   * @param controller the address to disbale
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

}