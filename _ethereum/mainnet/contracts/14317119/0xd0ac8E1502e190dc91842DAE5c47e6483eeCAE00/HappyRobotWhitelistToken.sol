// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./Counters.sol";
import "./Utils.sol";

/**
 * @title HappyRobotWhitelistToken
 * HappyRobotWhitelistToken - ERC1155 contract that whitelists an operator address, has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract HappyRobotWhitelistToken is ERC1155, Ownable {
  using Counters for Counters.Counter;

  uint8  constant TOKEN_ID = 1;

  uint16 private tokenSupply = 0;

  // Contract name
  string public name;

  // Contract symbol
  string public symbol;

  uint8 constant SALE_STATUS_NONE = 0;
  uint8 saleStatus = SALE_STATUS_NONE;

  address[] private minters;
  mapping(address => uint8) mintsMap;
  mapping(address => uint8) burnsMap;

  uint16 private totalMints = 0;
  uint16 private totalBurns = 0;

  uint8 private maxPerWallet = 2;
  uint16 private maxWLTokens = 300;
  uint256 private mintFee = 0.075 ether;

  address payable constant public walletMaster = payable(0x4846063Ec8b9A428fFEe1640E790b8F825D4AbF0);
  address payable constant public walletDevTeam = payable(0x52BD82C6B851AdAC6A77BC0F9520e5A062CD9a78);
  address payable constant public walletArtist = payable(0x22d57ccD4e05DD1592f52A4B0f909edBB82e8D26);

  address proxyRegistryAddress;

  event MintedWLToken(address _owner, uint16 _quantity, uint256 _totalOwned);

  constructor(
    string memory _uri, address _proxyRegistryAddress
  ) ERC1155(_uri) {
    name = "HRF Token";
    symbol = "HRFTOKEN";

    proxyRegistryAddress = _proxyRegistryAddress;
  }

  /**
  * Require msg.sender to be the master or dev team
  */
  modifier onlyMaster() {
    require(isMaster(msg.sender), "Happy Robot Whitelist Token: You are not a Master");
    _;
  }

  /**
  * require none sale status
  */
  modifier onlyNonSaleStatus() {
    require(saleStatus == SALE_STATUS_NONE, "Happy Robot Whitelist Token: It is sale period");
    _;
  }

  /**
  * get account is master or not
  * @param _account address
  * @return true or false
  */
  function isMaster(address _account) public pure returns (bool) {
    return walletMaster == payable(_account) || walletDevTeam == payable(_account);
  }

  /**
  * get token amount
  * @return token amount
  */
  function totalSupply() public view returns (uint16) {
    return tokenSupply;
  }

  /**
  * get uri
  * @return uri
  */
  function tokenUri() public view returns (string memory) {
    return ERC1155.uri(TOKEN_ID);
  }

  /**
  * set token uri
  * @param _uri token uri
  */
  function setURI(string memory _uri) public onlyOwner {      
    _setURI(_uri);
  }

  /**
  * get token quantity of account
  * @param _account account
  * @return token quantity of account
  */
  function quantityOf(address _account) public view returns (uint256) {
    return balanceOf(_account, TOKEN_ID);
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
   */
  function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }

    return ERC1155.isApprovedForAll(_owner, _operator);
  }

  /**
  * get max wl tokens per wallet
  * @return max wl tokens per wallet
  */
  function getMaxPerWallet() public view returns (uint8) {
    return maxPerWallet;
  }

  /**
  * set max wl tokens per wallet
  * @param _maxPerWallet max wl tokens per wallet
  */
  function setMaxPerWallet(uint8 _maxPerWallet) public onlyMaster {
    maxPerWallet = _maxPerWallet;
  }

  /**
  * get whitelist token mint fee
  * @return whitelist token mint fee
  */
  function getMintFee() public view returns (uint256) {
    return mintFee;
  }

  /**
  * set whitelist token mint fee
  * @param _mintFee mint fee
  */
  function setMintFee(uint256 _mintFee) public onlyMaster {
    mintFee = _mintFee;
  }

  /**
  * get sale status
  * @return sale status
  */
  function getSaleStatus() public view returns (uint8) {
    return saleStatus;
  }

  /**
  * set sale status
  * @param _saleStatus sale status
  */
  function setSaleStatus(uint8 _saleStatus) public onlyMaster {
    saleStatus = _saleStatus;
  }

  /**
  * get max wl tokens
  * @return max wl tokens
  */
  function getMaxWLTokens() public view returns (uint16) {
    return maxWLTokens;
  }

  /**
  * set max wl tokens
  * @param _maxWLTokens max wl tokens
  */
  function setMaxWLTokens(uint8 _maxWLTokens) public onlyMaster {
    maxWLTokens = _maxWLTokens;
  }

  /**
  * get whitelist token minters
  */
  function getMinters() public view returns (address[] memory) {
    return minters;
  }

  /**
  * check if _account is in the whitelist token minters
  * @param _account address
  * @return 
  */
  function existInMinters(address _account) public view returns (bool) {
    for (uint256 i = 0; i < minters.length; i++) {
      if (minters[i] == _account)
        return true;
    }
    return false;
  }

  /**
  * add an address into the whitelist
  * @param _account address
  */
  function addToMinters(address _account) internal {
    // if already registered, skip
    for (uint16 i = 0; i < minters.length; i++) {
      if (minters[i] == _account)   return;
    }

    // add address to the list
    minters.push(_account);
  }

  /**
  * remove an address from the minter list
  * @param _account address
  */
  function removeFromMinters(address _account) internal {
    // find index of _from
    uint256 index = 0xFFFF;
    uint256 len = minters.length;
    for (uint256 i = 0; i < len; i++) {
        if (minters[i] == _account) {
            index = i;
            break;
        }
    }

    // remove it
    if (index != 0xFFFF && len > 0) {
        minters[index] = minters[len - 1];
        minters.pop();
    }
  }

  /**
  * get number of total minted whitelist tokens
  * @return number of total minted whitelist tokens
  */
  function getTotalMinted() public view returns (uint16) {
    return totalMints;
  }

  /**
  * get number of total burned whitelist tokens
  * @return number of total burned whitelist tokens
  */
  function getTotalBurned() public view returns (uint16) {
    return totalBurns;
  }

  /**
  * get number of minted count for account
  * @param _account address
  * @return number of minted count for account
  */
  function getMints(address _account) public view returns (uint8) {
    return mintsMap[_account];
  }

  /**
  * get number of burned count for account
  * @param _account address
  * @return number of burned count for account
  */
  function getBurns(address _account) public view returns (uint8) {
    return burnsMap[_account];
  }

  /**
  * get number of owned whitelist token(including burned count) for account
  * @param _account address
  * @return number of owned whitelist token(including burned count) for account
  */
  function getOwned(address _account) public view returns (uint8) {
    unchecked {
      return uint8(quantityOf(_account)) + burnsMap[_account];
    }
  }

  /**
  * check if mint is possible for account
  * @param _account account
  * @param _quantity quantity
  * @return true or false
  */
  function canMintForAccount(address _account, uint16 _quantity) internal view returns (bool) {
    if (isMaster(_account)) return true;
    
    unchecked {
      uint8 balance = uint8(quantityOf(_account));
      uint8 totalOwned = balance + burnsMap[_account];

      return totalOwned + _quantity - 1 < maxPerWallet;
    }
  }

  /**
  * mint whitelist token
  * @param _quantity token amount
  */
  function mint(uint8 _quantity) external payable onlyNonSaleStatus {

    require(canMintForAccount(msg.sender, _quantity) == true, "Happy Robot Whitelist Token: Maximum whitelist token mint  already reached for the account");
    require(totalSupply() + _quantity - 1 < maxWLTokens, "Happy Robot Whitelist Token: Maximum whitelist token already reached");
    
    if (!isMaster(msg.sender)) {
        require(msg.value > mintFee * _quantity - 1, "Happy Robot Whitelist Token: Not enough ETH sent");

        // perform mint
        mint(msg.sender, _quantity);

        unchecked {
            uint256 fee = mintFee * _quantity;

            uint256 feeForDev = (uint256)(fee / 200); // 0.5% to the dev
            walletDevTeam.transfer(feeForDev);

            uint256 feeForArtist = (uint256)(fee / 40); // 2.5% to the dev
            walletArtist.transfer(feeForArtist);

            // return back remain value
            uint256 remainVal = msg.value - fee;
            address payable caller = payable(msg.sender);
            caller.transfer(remainVal);
        }

    } else {   // no price for master wallet
        // perform mint
        mint(msg.sender, _quantity);

        // return back the ethers
        address payable caller = payable(msg.sender);
        caller.transfer(msg.value);
    }
  }

  /**
  * mint tokens
  * @param _to address to mint
  * @param _quantity token quantity
  */
  function mint(address _to, uint8 _quantity) internal {
    _mint(_to, TOKEN_ID, _quantity, '');
    addToMinters(_to);

    unchecked {
      totalMints += _quantity;
      mintsMap[_to] += _quantity; // add mints map
      tokenSupply += _quantity;
    }

    // trigger whitelist token minted event
    emit MintedWLToken(_to, _quantity, totalMints);
  }

  /**
  * burn token
  * @param _from address to burn
  * @param _quantity token quantity
  */
  function burn(address _from, uint8 _quantity) public onlyOwner {
    _burn(_from, TOKEN_ID, _quantity);

    unchecked {
      totalBurns += _quantity;
      burnsMap[_from] += _quantity; // add burns map
      tokenSupply -= _quantity;
    }
  }

  /**
  * withdraw balance to only master wallet
  */
  function withdrawAll() external onlyMaster {
    address payable to = payable(msg.sender);
    to.transfer(address(this).balance);
  }
}
