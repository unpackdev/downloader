// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMuonV02.sol";
import "./IMRC1155.sol";
import "./IERC20.sol";
import "./AccessControl.sol";
import "./IERC1155Receiver.sol";
import "./ECDSA.sol";


interface IBridgeToken is IMRC1155 {

}

contract MRC1155Bridge is AccessControl, IERC1155Receiver {
  
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  bytes32 public constant TOKEN_ADDER_ROLE = keccak256("TOKEN_ADDER");

  using ECDSA for bytes32;

  uint32 public constant APP_ID = 17;

  IMuonV02 public muon;

  // we assign a unique ID to each chain (default is CHAIN-ID)
  uint256 public network;

  // tokenId => tokenContractAddress
  mapping(uint256 => address) public tokens;
  mapping(address => uint256) public ids;

  // tokenId => isTokenMintable
  mapping(uint256 => bool) public mintable;

  event AddToken(address addr, uint256 tokenId, bool mintable);

  event Deposit(
    uint256 txId
  );

  event Claim(
    address indexed user,
    uint256 txId,
    uint256 fromChain
  );

  struct TX {
    uint256 tokenId;
    uint256[] ids;
    uint256[] amounts;
    uint256 toChain;
    address user;
  }
  uint256 public lastTxId = 0;

  mapping(uint256 => TX) public txs;
  
  mapping(uint256 => mapping(uint256 => bool)) public claimedTxs;

  // fee in native token
  uint256 public bridgeFee = 0.0006 ether;

  constructor(address _muon) {
    network = getCurrentChainID();
    muon = IMuonV02(_muon);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
  }

  function deposit(
    uint256[] calldata itemIds,
    uint256[] calldata amounts,
    uint256 toChain,
    uint256 tokenId
  ) public payable returns (uint256) {
    require(toChain != network, 'Self Deposit');
    require(tokens[tokenId] != address(0), '!tokenId');
    require(msg.value == bridgeFee, "!value");
    require(itemIds.length > 0, "!itemIds");
    require(itemIds.length == amounts.length, "amounts length != itemIds length");

    IBridgeToken token = IBridgeToken(tokens[tokenId]);
    
    if (mintable[tokenId]) {
      for (uint256 index = 0; index < itemIds.length; index++) {
        require(
          token.balanceOf(msg.sender, itemIds[index]) >= amounts[index],
          "!owner"
        );
        token.burn(address(msg.sender), itemIds[index], amounts[index]);
      }
    }else{
      for (uint256 index = 0; index < itemIds.length; index++) {
        require(
          token.balanceOf(msg.sender, itemIds[index]) >= amounts[index],
          "!owner"
        );
        token.safeTransferFrom(
          address(msg.sender),
          address(this),
          itemIds[index],
          amounts[index],
          '0x0'
        );
      }
    }

    uint256 txId = ++lastTxId;
    txs[txId] = TX({
      tokenId: tokenId,
      toChain: toChain,
      ids: itemIds,
      amounts: amounts,
      user: msg.sender
    });
    
    emit Deposit(txId);

    return txId;
  }


  function claim(
    uint256[] calldata itemIds,
    uint256[] calldata amounts,
    uint256[4] calldata txParams,
    bytes calldata _reqId,
    IMuonV02.SchnorrSign[] calldata _sigs
  ) public{
    claimFor(msg.sender, itemIds, amounts, txParams, _reqId, _sigs);
  }

  function claimFor(
    address user,
    uint256[] calldata itemIds,
    uint256[] calldata amounts,
    uint256[4] calldata txParams,
    bytes calldata _reqId,
    IMuonV02.SchnorrSign[] calldata _sigs
  ) public {

    // txParams[0] = fromChain
    // txParams[1] = toChain 
    // txParams[2] = tokenId 
    // txParams[3] = txId 

    require(!claimedTxs[txParams[0]][txParams[3]], 'already claimed');
    require(txParams[1] == network, '!network');
    require(_sigs.length > 0, '!sigs');
    require(itemIds.length == amounts.length, "amounts length != itemIds length");

    {
    // split encoding to avoid "stack too deep" error.
    bytes32 hash = keccak256(
      abi.encodePacked(
        abi.encodePacked(APP_ID),
        abi.encodePacked(txParams[3], txParams[2]),
        abi.encodePacked(txParams[0], txParams[1]),
        abi.encodePacked(user),
        abi.encodePacked(itemIds),
        abi.encodePacked(amounts)
      )
    );

    require(muon.verify(_reqId, uint256(hash), _sigs), '!verified');

    }

    IBridgeToken token = IBridgeToken(tokens[txParams[2]]);

    if (mintable[txParams[2]]) {
      for (uint256 index = 0; index < itemIds.length; index++) {
        token.mint(user, itemIds[index], amounts[index], '0x0');
      }
    } else {
      for (uint256 index = 0; index < itemIds.length; index++) {
        token.safeTransferFrom(address(this), user, itemIds[index], amounts[index], '0x0');
      }
    }

    claimedTxs[txParams[0]][txParams[3]] = true;
    emit Claim(user, txParams[3], txParams[0]);
  }

  function pendingTxs(uint256 fromChain, uint256[] calldata _ids)
    public
    view
    returns (bool[] memory unclaimedIds)
  {
    unclaimedIds = new bool[](_ids.length);
    for (uint256 i = 0; i < _ids.length; i++) {
      unclaimedIds[i] = claimedTxs[fromChain][_ids[i]];
    }
  }

  function getTx(uint256 _txId)
    public
    view
    returns (
      uint256 txId,
      uint256 tokenId,
      uint256 fromChain,
      uint256 toChain,
      address user,
      address nftContract,
      uint256[] memory itemIds,
      uint256[] memory amounts
    )
  {
    txId = _txId;
    tokenId = txs[_txId].tokenId;
    fromChain = network;
    toChain = txs[_txId].toChain;
    user = txs[_txId].user;
    nftContract = tokens[tokenId];
    itemIds = txs[_txId].ids;
    amounts = txs[_txId].amounts;
  }

  function addToken(uint256 tokenId, address tokenAddress,
    bool _mintable)
        external
        onlyRole(TOKEN_ADDER_ROLE){

        require(ids[tokenAddress] == 0, 'already exist');

        tokens[tokenId] = tokenAddress;
        mintable[tokenId] = _mintable;

        ids[tokenAddress] = tokenId;

        emit AddToken(tokenAddress, tokenId, _mintable);
  }

  function removeToken(uint256 tokenId, address tokenAddress)
    external onlyRole(TOKEN_ADDER_ROLE){
    require(ids[tokenAddress] == tokenId, 'id!=addr');
    ids[tokenAddress] = 0;
    tokens[tokenId] = address(0);
  }

  function getTokenId(address _addr) public view returns (uint256) {
    return ids[_addr];
  }

  function getCurrentChainID() public view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }

  function setNetworkID(uint256 _network) public onlyRole(ADMIN_ROLE) {
    network = _network;
  }

  function setBridgeFee(uint256 _val) public onlyRole(ADMIN_ROLE){
    bridgeFee = _val;
  }

  function setMuonContract(address _addr) public onlyRole(ADMIN_ROLE){
    muon = IMuonV02(_addr);
  }

  function adminWithdrawTokens(uint256 amount,
    address _to, address tokenAddress) public onlyRole(ADMIN_ROLE) {
    require(_to != address(0));
    if(tokenAddress == address(0)){
      payable(_to).transfer(amount);  
    }else{
      IERC20(tokenAddress).transfer(_to, amount);
    }
  }

  function emergencyWithdrawERC1155Tokens(
    address _tokenAddr,
    address _to,
    uint256 _id,
    uint256 _amount
  ) public onlyRole(ADMIN_ROLE) {
    IBridgeToken(_tokenAddr).safeTransferFrom(address(this), _to, _id, _amount, '0x0');
  }

  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes memory
  ) public virtual override returns(bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes memory
  ) public virtual override returns(bytes4) {
    return this.onERC1155BatchReceived.selector;
  }
}
