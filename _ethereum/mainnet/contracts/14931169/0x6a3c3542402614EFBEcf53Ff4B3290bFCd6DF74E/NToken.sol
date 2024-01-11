// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import "./IERC1155.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC165.sol";
import "./INToken.sol";
import "./ILendingPool.sol";
import "./WadRayMath.sol";
import "./Errors.sol";
import "./VersionedInitializable.sol";
import "./WrappedERC721.sol";
import "./SafeERC721.sol";
import "./Strings.sol";
import "./IERC721Receiver.sol";
import "./IERC1155Receiver.sol";

import "./IERC721Wrapper.sol";
import "./DataTypes.sol";

/**
 * @title Vinci ERC1155 NToken
 * @dev Implementation of the deposited NFT token for the Vinci Protocol
 * @author Vinci
 */
 contract NToken is
   VersionedInitializable,
   WrappedERC721, 
   IERC721Wrapper,
   IERC721Receiver,
   IERC1155Receiver,
   INToken

{
    // TODO ERC1155 or ERC1155Burnable?
    using WadRayMath for uint256;
    using Strings for uint256;
    using SafeERC721 for IERC721;

    uint256 public constant NTOKEN_REVISION = 0x2;
    bytes public constant EIP712_REVISION = bytes('1');

    bytes32 internal constant EIP712_DOMAIN =
    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');
    bytes32 public constant PERMIT_TYPEHASH =
    keccak256('Permit(address owner,address spender,uint256 tokenId,uint256 amount, uint256 nonce,uint256 deadline)');

    /// @dev owner => next valid nonce to submit with permit()
    mapping(address => uint256) public _nonces;

    bytes32 public DOMAIN_SEPARATOR; // TODO

    ILendingPool internal _pool;
    address internal _underlyingNFT;
    address private _claimAdmin;
    string internal _baseURI_;

    event BurnBatch(address user, address receiverOfUnderlying, uint256[] tokenIds, uint256[] amounts);

    modifier onlyLendingPool {
        require(_msgSender() == address(_pool), Errors.CT_CALLER_MUST_BE_LENDING_POOL);
        _;
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return NTOKEN_REVISION;
    }

    /**
    * @dev Returns the address of the current claim admin.
    */
    function claimAdmin() public view virtual returns (address) {
      return _claimAdmin;
    }

    /**
    * @dev Throws if called by any account other than the claim admin.
    */
    modifier onlyClaimAdmin() {
      require(claimAdmin() == _msgSender(), Errors.CT_CALLER_MUST_BE_CLAIM_ADMIN);
      _;
    }

    /**
    * @dev Set claim admin of the contract to a new account (`newAdmin`).
    * Can only be called by the current owner.
    */
    function setClaimAdmin(address newAdmin) public virtual override onlyLendingPool {
      _setClaimAdmin(newAdmin);
    }

    function _setClaimAdmin(address newAdmin) internal virtual {
      address oldAdmin = _claimAdmin;
      _claimAdmin = newAdmin;
      emit ClaimAdminUpdated(oldAdmin, newAdmin);
    }

    /** TODO check the initialize, implement _setName and _setSymbol, and use _setURI to set the _uri
     * @dev Initializes the NToken
     * @param pool The address of the lending pool where this nToken will be used
     * @param underlyingNFT The address of the underlying NFT of this nToken
     * @param nTokenName The name of the vToken
     * @param nTokenSymbol The symbol of the vToken
    */
    function initialize(
        ILendingPool pool,
        address underlyingNFT,
        string calldata nTokenName,
        string calldata nTokenSymbol,
        string calldata baseURI,
        bytes calldata params
    ) external override initializer {
        uint256 chainId;

        //solium-disable-next-line
        assembly {
        chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
        abi.encode(
            EIP712_DOMAIN,
            keccak256(bytes(nTokenName)),
            keccak256(EIP712_REVISION),
            chainId,
            address(this)
        )
        );

        _setName(nTokenName);
        _setSymbol(nTokenSymbol);

        _pool = pool;
        _underlyingNFT = underlyingNFT;
        _baseURI_ = baseURI;

        emit Initialized(
        underlyingNFT,
        address(pool),
        nTokenName,
        nTokenSymbol,
        baseURI,
        params
        );
    }

   function burn(
       address user,
       address receiverOfUnderlying,
       uint256 tokenId,
       uint256 amount
   ) external override onlyLendingPool {
     require(amount != 0, Errors.CT_INVALID_BURN_AMOUNT);
     _burn(tokenId);
     IERC721(_underlyingNFT).safeTransferFrom(address(this), receiverOfUnderlying, tokenId, "");

     emit Transfer(user, address(0), tokenId);
     emit Burn(user, receiverOfUnderlying, tokenId, amount);
   }

   function burnBatch(
       address user,
       address receiverOfUnderlying,
       uint256[] calldata tokenIds,
       uint256[] calldata amounts
   ) external override onlyLendingPool {
     require(tokenIds.length == amounts.length, Errors.CT_INVALID_BURN_AMOUNT);
     for(uint256 i = 0; i < tokenIds.length; ++i){
       if(amounts[i] != 0){
        _burn(tokenIds[i]);
       }
     }
     for(uint256 i = 0; i < tokenIds.length; ++i){
       uint256 id = tokenIds[i];
       IERC721(_underlyingNFT).safeTransferFrom(address(this), receiverOfUnderlying, id, "");
     }

     for(uint256 i = 0; i < tokenIds.length; ++i){
       emit Transfer(user, address(0), tokenIds[i]);
     }
     emit BurnBatch(user, receiverOfUnderlying, tokenIds, amounts);
   }

   function mint(
       address user,
       uint256 tokenId,
       uint256 amount
   ) external override onlyLendingPool returns (bool) {
     uint256 previousNFTAmount = super.balanceOf(user);
     require(amount != 0, Errors.CT_INVALID_MINT_AMOUNT);
     _safeMint(user, tokenId, "");
    emit Transfer(address(0), user, tokenId);
    emit Mint(user, tokenId, amount);

    return previousNFTAmount == 0;
   }

   function transferOnLiquidation(
    address from,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts
  ) external override onlyLendingPool {
    // Being a normal transfer, the Transfer() and BalanceTransfer() are emitted
    // so no need to emit a specific event here
    _safeBatchTransferFrom(from, to, tokenIds, amounts, '', false);

    for(uint256 i = 0; i < tokenIds.length; ++i){
      if(amounts[i] > 0) {
        emit Transfer(from, to, tokenIds[i]);
      }
    }
  }

  /**
   * @dev Returns the address of the underlying NFT of this nToken
   **/
  function UNDERLYING_ASSET_ADDRESS() public view override returns (address) {
    return _underlyingNFT;
  }

  /**
   * @dev Returns the address of the lending pool where this nToken is used
   **/
  function POOL() public view returns (ILendingPool) {
      return _pool;
  }

  function transferUnderlyingTo(address target, uint256 tokenId, uint256 amount)
    external
    override
    onlyLendingPool
    returns (uint256)
  {
    IERC721(_underlyingNFT).safeTransferFrom(address(this), target, tokenId, '');
    return amount;
  }

  function getLiquidationAmounts(address user, uint256 maxTotal, uint256[] calldata tokenIds, uint256[] calldata amounts) 
    external
    view
    override 
    returns(uint256, uint256[] memory)
  {
    require(user != address(0), "ERC721: balance query for the zero address");
    require(tokenIds.length == amounts.length, "ERC721: tokenIds and amounts length mismatch");
    uint256[] memory resultAmounts = new uint256[](tokenIds.length);
    uint256 remainTotal = maxTotal;
    uint256 i = 0;
    while(remainTotal > 0 && i < tokenIds.length) {
      if(_owners[tokenIds[i]] == user) {
        resultAmounts[i] = 1;
        remainTotal = remainTotal - 1;
      }
      else{
        resultAmounts[i] = 0;
      }
      ++i;
    }
    for(; i < tokenIds.length; ++i) {
      resultAmounts[i] = 0;
    }
    return(maxTotal - remainTotal, resultAmounts);
  }

  function lock(uint256 tokenId, uint16 lockType) public virtual override onlyLendingPool
  {
    revert('LV_NFT_LOCK_NOT_IMPLEMENTED');
  }

  function getUnlockTime(uint256 tokenId) public view virtual override returns(uint40)
  {
    require(_exists(tokenId), "NToken: query for nonexistent token");
    return _getUnlockTime(tokenId);
  }

  function _getUnlockTime(uint256 tokenId) internal view virtual returns(uint40)
  {
    return 0;
  }

  function getLockData(uint256 tokenId) public view virtual override returns(DataTypes.TimeLock memory)
  {
    require(_exists(tokenId), "NToken: query for nonexistent token");
    return _getLockData(tokenId);
  }

  function _getLockData(uint256 tokenId) internal view virtual returns(DataTypes.TimeLock memory lockData)
  {
    lockData.lockType = 0;
    lockData.expiration = 0;
  }

  function unlockedBalanceOfBatch(address user, uint256[] calldata tokenIds) public view virtual override returns(uint256[] memory amounts)
  {
    require(user != address(0), "NToken: balance query for the zero address");
    return _balanceOfBatch(user, tokenIds);
  }

  function tokensAndLocksByAccount(address user) public view virtual override returns(uint256[] memory tokenIds, DataTypes.TimeLock[] memory locks)
  {
    uint256 balance = balanceOf(user);
    uint256[] memory tokens = new uint256[](balance);
    DataTypes.TimeLock[] memory locks = new DataTypes.TimeLock[](balance);
    for(uint256 i = 0; i < balance; ++i){
      uint256 tokenId = _ownedTokens[user][i];
      tokens[i] = tokenId;
      locks[i] = _getLockData(tokenId);
    }
    return (tokens, locks);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, WrappedERC721) returns (bool) {
    return
      interfaceId == type(IERC721Receiver).interfaceId ||
      interfaceId == type(IERC1155Receiver).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function claimERC20Airdrop(
    address token,
    address to,
    uint256 amount
  ) external override onlyClaimAdmin {
    require(token != _underlyingNFT, Errors.CT_TOKEN_CAN_NOT_BE_UNDERLYING);
    require(token != address(this), Errors.CT_TOKEN_CAN_NOT_BE_SELF);
    IERC20(token).transfer(to, amount);
    emit ClaimERC20Airdrop(token, to, amount);
  }

  function claimERC721Airdrop(
    address token,
    address to,
    uint256[] calldata tokenIds
  ) external override onlyClaimAdmin {
    require(token != _underlyingNFT, Errors.CT_TOKEN_CAN_NOT_BE_UNDERLYING);
    require(token != address(this), Errors.CT_TOKEN_CAN_NOT_BE_SELF);
    for (uint256 i = 0; i < tokenIds.length; i++) {
      IERC721(token).safeTransferFrom(address(this), to, tokenIds[i]);
    }
    emit ClaimERC721Airdrop(token, to, tokenIds);
  }

  function claimERC1155Airdrop(
    address token,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes calldata data
  ) external override onlyClaimAdmin {
    require(token != _underlyingNFT, Errors.CT_TOKEN_CAN_NOT_BE_UNDERLYING);
    require(token != address(this), Errors.CT_TOKEN_CAN_NOT_BE_SELF);
    IERC1155(token).safeBatchTransferFrom(address(this), to, tokenIds, amounts, data);
    emit ClaimERC1155Airdrop(token, to, tokenIds, amounts, data);
  }

  function onERC721Received(
    address operator, 
    address from, 
    uint256 tokenId, 
    bytes calldata data
  ) external override returns (bytes4)
  {
    return this.onERC721Received.selector;
  }

  function onERC1155Received(
    address, 
    address, 
    uint256, 
    uint256, 
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address, 
    address, 
    uint256[] memory, 
    uint256[] memory, 
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  function _transfer(address from, address to, uint256 tokenId, bool validate) internal
  {
    uint256 fromNFTAmountBefore = super.balanceOf(from);
    uint256 toNFTAmountBefore = super.balanceOf(to);
    super._transfer(from, to, tokenId);
    if(validate) {
      _pool.finalizeNFTSingleTransfer(_underlyingNFT, from, to, tokenId, 1, fromNFTAmountBefore, toNFTAmountBefore);
    }
    emit BalanceTransfer(from, to, tokenId, 1);
  }

  function _transfer(address from, address to, uint256 tokenId) internal virtual override
  {
    _transfer(from, to, tokenId, true);
  }

  function _safeBatchTransferFrom(address from, address to, uint256[] calldata tokenIds, uint256[] calldata amounts, bytes memory data, bool validate) internal {
    address underlyingNFT = _underlyingNFT;
    ILendingPool pool = _pool;

    uint256 fromNFTAmountBefore = super.balanceOf(from);
    uint256 toNFTAmountBefore = super.balanceOf(to);
    for(uint256 i = 0; i < tokenIds.length; ++i){
      if(amounts[i] != 0){
        super._safeTransfer(from, to, tokenIds[i], data);
      }
    }
    if(validate){
      pool.finalizeNFTBatchTransfer(underlyingNFT, from, to, tokenIds, amounts, fromNFTAmountBefore, toNFTAmountBefore);
    }
    emit BalanceBatchTransfer(from, to, tokenIds, amounts);

  }

  function _safeBatchTransferFrom(address from, address to, uint256[] calldata tokenIds, uint256[] calldata amounts, bytes memory data) internal {
    _safeBatchTransferFrom(from, to, tokenIds, amounts, data, true);
  }

  

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
  {
    return IERC721Metadata(_underlyingNFT).tokenURI(tokenId);
  }

  function _baseURI() internal view virtual override returns (string memory)
  {
    return _baseURI_;
  }

  function contractURI() external view override returns (string memory) {
    string memory hexAddress = uint256(uint160(address(this))).toHexString(20);
    return string(abi.encodePacked(_baseURI(), hexAddress));
  }

}
