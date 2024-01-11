// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./AccessControl.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./ERC2981.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";

contract TrashBagNinja is ERC721URIStorage, ERC2981, EIP712, Ownable, AccessControl  {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");
  bytes32 public constant NFTLOCK_ROLE = keccak256("NFTLOCK_ROLE");

  string private constant SIGNING_DOMAIN = "TrashBagNinja-Voucher";
  string private constant SIGNATURE_VERSION = "1";

  uint256 public MAX_TOKEN = 10010;
  mapping (address => uint256[]) private _nftOfWallet;
  mapping (uint256 => uint256) private _nftIndex;
  mapping (address => uint256) private pendingWithdrawals;
  mapping (address => mapping(uint256 => bool)) private _airdropList;

  mapping (address => bool) private _nftLocker;
  mapping (uint256 => uint256) public nftState; // 0:res 1:lock 2:minted

  constructor(string memory name, string memory symbol)
    ERC721(name, symbol)
    EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
    _setupRole(MINTER_ROLE, msg.sender);
    _setupRole(AIRDROP_ROLE, msg.sender);
    _setupRole(NFTLOCK_ROLE, msg.sender);
  }

  struct NFTVoucher {
    uint256 tokenId;
    uint256 minPrice;
    string uri;
    bytes signature;
  }

  struct NFTHolder {
    address signer;
    address buyer;
    string uri;
  }

  uint256[] private _MINTED_NFT;
  uint256[] private _HOLD_NFT;
  mapping (uint256 => NFTHolder) private _nftHold;

  function setNFTLocker(address[] memory addresslists, bool flag) public onlyOwner {
    uint256 new_len = addresslists.length;
    if (flag == true) {
      for(uint256 i=0; i<new_len; i++) {
        _setupRole(NFTLOCK_ROLE, addresslists[i]);
      }
    }
    else {
      for(uint256 i=0; i<new_len; i++) {
        _revokeRole(NFTLOCK_ROLE, addresslists[i]);
      }
    }
  }

  function setAirDropAll(address[] memory addresslists, bool flag) public onlyOwner {
    uint256 new_len = addresslists.length;
    if (flag == true) {
      for(uint256 i=0; i<new_len; i++) {
        _setupRole(AIRDROP_ROLE, addresslists[i]);
      }
    }
    else {
      for(uint256 i=0; i<new_len; i++) {
        _revokeRole(AIRDROP_ROLE, addresslists[i]);
      }
    }
  }

  function setAirDrop(address sender, uint256 tokenID, bool flag) public onlyOwner {
    _airdropList[sender][tokenID] = flag;
  }

  function getAirDropState(address sender, uint256 tokenID) public view returns (bool) {
    if (hasRole(AIRDROP_ROLE, sender) || _airdropList[sender][tokenID]==true) {
      return true;
    }
    return false;
  }

  function getMintedNft() public view returns(uint256[] memory) {
    return _MINTED_NFT;
  }

  function getHoldNft() public view returns(uint256[] memory) {
    return _HOLD_NFT;
  }

  function lockNFTs(uint256[] memory tokenIDs, bool flag) public {
    require(hasRole(NFTLOCK_ROLE, msg.sender), "Sender unauthorized");
    uint256 new_len = tokenIDs.length;
    if (flag == true) {
      for(uint256 i=0; i<new_len; i++) {
        if (nftState[tokenIDs[i]] != 2) {
          nftState[tokenIDs[i]] = 1;
        }
      }
    }
    else {
      for(uint256 i=0; i<new_len; i++) {
        if (nftState[tokenIDs[i]] != 2) {
          nftState[tokenIDs[i]] = 0;
        }
      }
    }
  }
  
  function redeem(address redeemer, NFTVoucher[] calldata vouchers) public payable {
    uint256 sum = 0;
    uint256 v_len = vouchers.length;
    for (uint256 i=0; i<v_len; i++) {
      sum = sum + vouchers[i].minPrice;
    }
    require(msg.value >= sum, "Insufficient funds to redeem");

    for (uint256 i=0; i<v_len; i++) {
      address signer = _verify(vouchers[i]);
      if (hasRole(MINTER_ROLE, signer) && nftState[vouchers[i].tokenId]==0) {
        _mint(signer, vouchers[i].tokenId);
        _setTokenURI(vouchers[i].tokenId, vouchers[i].uri);
        nftState[vouchers[i].tokenId] = 2;
        
        _transfer(signer, redeemer, vouchers[i].tokenId);
        _nftOfWallet[redeemer].push(vouchers[i].tokenId);
        _nftIndex[vouchers[i].tokenId] = _nftOfWallet[redeemer].length - 1;
        _MINTED_NFT.push(vouchers[i].tokenId);

        pendingWithdrawals[signer] += msg.value;
      }
    }
  }

  function lazyredeem(address redeemer, NFTVoucher[] calldata vouchers) public payable {
    uint256 sum = 0;
    uint256 v_len = vouchers.length;
    for (uint256 i=0; i<v_len; i++) {
      sum = sum + vouchers[i].minPrice;
    }
    require(msg.value >= sum, "Insufficient funds to redeem");

    for (uint256 i=0; i<v_len; i++) {
      address signer = _verify(vouchers[i]);
      if (hasRole(MINTER_ROLE, signer) && nftState[vouchers[i].tokenId]==0) {
        _nftHold[vouchers[i].tokenId] = NFTHolder(signer, redeemer, vouchers[i].uri);
        
        nftState[vouchers[i].tokenId] = 2;
        
        _HOLD_NFT.push(vouchers[i].tokenId);
        _MINTED_NFT.push(vouchers[i].tokenId);

        pendingWithdrawals[signer] += msg.value;
      }
    }
  }

  function releaseLazyredeem() public onlyOwner {
    uint256 v_len = _HOLD_NFT.length;
    for (uint256 i=0; i<v_len; i++) {
      _mint(_nftHold[_HOLD_NFT[i]].signer, _HOLD_NFT[i]);
      _setTokenURI(_HOLD_NFT[i], _nftHold[_HOLD_NFT[i]].uri);
      _transfer(_nftHold[_HOLD_NFT[i]].signer, _nftHold[_HOLD_NFT[i]].buyer, _HOLD_NFT[i]);
      _nftOfWallet[_nftHold[_HOLD_NFT[i]].buyer].push(_HOLD_NFT[i]);
      _nftIndex[_HOLD_NFT[i]] = _nftOfWallet[_nftHold[_HOLD_NFT[i]].buyer].length - 1;
    }
    delete _HOLD_NFT;
  }

  function airdrop(address redeemer, NFTVoucher[] calldata vouchers) public {
    uint256 v_len = vouchers.length;
    for (uint256 i=0; i<v_len; i++) {
      address signer = _verify(vouchers[i]);
      if (hasRole(MINTER_ROLE, signer) && (hasRole(AIRDROP_ROLE, msg.sender) || _airdropList[msg.sender][vouchers[i].tokenId]==true)) {
        _mint(signer, vouchers[i].tokenId);
        _setTokenURI(vouchers[i].tokenId, vouchers[i].uri);
        nftState[vouchers[i].tokenId] = 2;
        
        _transfer(signer, redeemer, vouchers[i].tokenId);
        _nftOfWallet[redeemer].push(vouchers[i].tokenId);
        _nftIndex[vouchers[i].tokenId] = _nftOfWallet[redeemer].length - 1;
        _MINTED_NFT.push(vouchers[i].tokenId);
      }
    }
  }

  function withdraw() public {
    require(hasRole(MINTER_ROLE, msg.sender), "Only authorized minters can withdraw");
    
    address payable receiver = payable(msg.sender);

    uint amount = pendingWithdrawals[receiver];
    pendingWithdrawals[receiver] = 0;
    receiver.transfer(amount);
  }

  function withDrawAll() external onlyOwner {
    address payable tgt = payable(owner());
    (bool success1, ) = tgt.call{value:address(this).balance}("");
    require(success1, "Failed to Withdraw VET");
  }

  function availableToWithdraw() public view returns (uint256) {
    return pendingWithdrawals[msg.sender];
  }

  function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
    return _hashTypedDataV4(keccak256(abi.encode(
      keccak256("NFTVoucher(uint256 tokenId,uint256 minPrice,string uri)"),
      voucher.tokenId,
      voucher.minPrice,
      keccak256(bytes(voucher.uri))
    )));
  }

  function _verify(NFTVoucher calldata voucher) internal view returns (address) {
    bytes32 digest = _hash(voucher);
    return ECDSA.recover(digest, voucher.signature);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "VIP181: transfer caller is not owner nor approved");
    _transfer(from, to, tokenId);
    _nftOfWallet[to].push(tokenId);
    if (_nftOfWallet[from].length > 1) {
      uint256 lastNftId = _nftOfWallet[from][_nftOfWallet[from].length - 1];
      _nftOfWallet[from][_nftIndex[tokenId]] = lastNftId;
    }
    _nftOfWallet[from].pop();
    _nftIndex[tokenId] = _nftOfWallet[to].length - 1;
  }

  function walletOfOwner(address wallet) public view returns(uint256[] memory) {
    return _nftOfWallet[wallet];
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
