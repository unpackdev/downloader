/**
 *Submitted for verification at Etherscan.io on 2023-12-01
*/

//SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface INonFungibleToken is IERC165 {

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IFractionalAsset is INonFungibleToken {

    /**
        Returns The URI To An Image Representing `tokenId`
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
        Returns The URI Associated With The Collection
     */
    function URI() external view returns (string memory);

    /**
        Returns The Name Of A Collection
     */
    function name() external view returns (string memory);

    /**
        Returns The Symbol (Ticker) Of A Collection
     */
    function symbol() external view returns (string memory);

    /**
        Returns The Number Of Fractions This NFT Is Split Into
     */
    function numFractions() external view returns (uint256);

    /**
        Initializes The FractionalAsset
     */
    function __init__(
        string[] calldata strings,
        uint256[] calldata values,
        address[] calldata addrs
    ) external;
}

interface IDatabase {
    function isVerified(address account) external view returns (bool);
    function isAuthorized(address account) external view returns (bool);
}

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
contract Clones {

    /**
        @dev Deploys and returns the address of a clone of address(this
        Created by DeFi Mark To Allow Clone Contract To Easily Create Clones Of Itself
        Without redundancy
     */
    function clone() external returns(address) {
        return _clone(address(this));
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function _clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }
}

library Address {

    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

}

contract FractionalAssetData is Context {

    /**
        Master Database Which Interacts With KYC And Auth Databases
     */
    IDatabase public constant Database = IDatabase(0x238a94E37a1bAde56Cfcc5dbE7f48DA88aa9Db19);

    /**
        Is Initialized
     */
    bool internal initialized;

    /**
        Name For NFT Compatibility
     */
    string internal _name;

    /**
        Symbol For NFT Compatibility
     */
    string internal _symbol;

    /**
        Current Token ID For Tracking Purposes
     */
    uint256 internal _currentTokenID;

    /**
        Mapping From Mint Tokens To Cost
     */
    mapping ( address => uint256 ) public mintCost;

    /**
        Mapping From A TokenID To An Address Which Dictates Ownership Of That Specific ID
     */
    mapping(uint256 => address) internal _owners;

    /**
        List Of Registered Owners Containing At Least 1 Fractional Asset
     */
    address[] internal _registeredOwners;

    /**
        Mapping Between An Owner And Their Index In The `_registeredOwners` List
     */
    mapping( address => uint256 ) internal _ownerIndex;

    /**
        Mapping From Owner Address To The Number Of Fractional Assets They Own In Total
        Ensures NFT Compatibility
     */
    mapping(address => uint256) internal _balances;

    /**
        Mapping from token ID to approved address
     */
    mapping(uint256 => address) internal _tokenApprovals;

    /**
        Mapping from owner to operator approvals
    */
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    /**
        Returns The URI Of The Images Associated With Each Collection
     */
    string internal baseURI;

    /**
        Number Of Fractions NFT Is Split Into
     */
    uint256 internal nFractions;

    /**
        Whether Or Not Minting Is Enabled
     */
    bool public mintingEnabled;

    /**
        Whether Or Not An Allowlist Is Enabled
     */
    bool public allowlistEnabled;

    /**
        Recipient of Mint Funds
     */
    address public mintRecipient;

    // Mapping from owner to excluded rewards
    mapping(address => uint256) totalExcluded;

    // total dividends for tracking
    uint256 internal dividendsPerNFT;

    // total rewards received
    uint256 public totalRewards;

    // Reward Token
    address public rewardToken;

    // precision value
    uint256 internal constant precision = 10**18;

    // Merkle Root
    bytes32 internal merkleRoot;

    /**
        Ensures `account` is KYC Verified Before Permitting
        Access To Certain Functionality
     */
    modifier isVerified(address account) {
        require(
            account != address(0),
            'Zero Address'
        );
        require(
            Database.isVerified(account),
            'Account Not KYC Verified'
        );
        _;
    }

    /**
        Ensures Caller Is Authorized To Call Restricted Functions
     */
    modifier onlyAuthorized() {
        require(
            Database.isAuthorized(_msgSender()) == true,
            'Not Authorized To Call'
        );
        _;
    }

    /**
        Events To Support Data Tracking
     */
    event BaseURIChange(string oldURI, string newURI);

}


contract FractionalAsset is FractionalAssetData, IFractionalAsset, Clones {

  using Address for address;

  // Event Declarations
event Mint(address indexed to, uint256 indexed tokenId);
event MintingEnabled();
event MintingDisabled();
event AllowlistEnabled();
event AllowlistDisabled();
event MerkleRootSet(bytes32 newRoot);
event Withdrawal(address indexed token, address indexed to, uint256 amount);
event MintCostSet(address indexed token, uint256 newCost);
event RewardsDeposited(uint256 amount);
event RewardsClaimed(address indexed user, uint256 amount);

  /**
      Initializes The FractionalAsset
   */
  function __init__(
      string[] calldata strings,
      uint256[] calldata values,
      address[] calldata addrs
  ) external override {
      require(
          !initialized,
          'Already Initialized'
      );
      initialized = true;
      _name = strings[0];
      _symbol = strings[1];
      baseURI = strings[2];
      nFractions = values[0];
      for (uint i = 0; i < values[1]; i++) {
          mintCost[addrs[i]] = values[2 + i];
      }
      rewardToken = addrs[values[1]];
      mintRecipient = addrs[values[1] + 1];
  }
  
  /**
      Sets The Base URI, Updating Images For ALL Collections
   */
  function setBaseURI(string calldata newURI) external onlyAuthorized {
      emit BaseURIChange(baseURI, newURI);
      baseURI = newURI;
  }

  function enableMinting() external onlyAuthorized {
      mintingEnabled = true;
      emit MintingEnabled();
  }

  function setMintRecipient(address newRecipient) external onlyAuthorized {
      mintRecipient = newRecipient;
  }

  function disableMinting() external onlyAuthorized {
      mintingEnabled = false;
      emit MintingDisabled();
  }

  function enableAllowlist() external onlyAuthorized {
      allowlistEnabled = true;
      emit AllowlistEnabled();
  }

  function disableAllowlist() external onlyAuthorized {
      allowlistEnabled = false;
      emit AllowlistDisabled();
  }

  function setMerkleRoot(bytes32 root) external onlyAuthorized {
      merkleRoot = root;
      emit MerkleRootSet(root);
  }

  function withdrawETH(address to) external onlyAuthorized {
      (bool s,) = payable(to).call{value: address(this).balance}("");
      require(s);
      emit Withdrawal(address(0), to, address(this).balance);
  }

  function withdrawToken(address token, address to) external onlyAuthorized {
      IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)));
      emit Withdrawal(token, to, IERC20(token).balanceOf(address(this)));
  }

  function setCost(address mintToken, uint256 newCost) external onlyAuthorized {
      mintCost[mintToken] = newCost;
      emit MintCostSet(mintToken, newCost);
  }

  function ownerMint(address to, uint256 num) external onlyAuthorized {
      for (uint i = 0; i < num;) {
          _safeMint(to, _currentTokenID);
          unchecked { ++i; }
      }
  }

  function batchClaim(address[] calldata users) external onlyAuthorized {
      uint len = users.length;
      for (uint i = 0; i < len;) {
          _claimRewards(users[i]);
          unchecked { ++i; }
      }
  }

  function depositRewards(uint256 amount) external onlyAuthorized {
      require(
          _currentTokenID > 0,
          'Zero Tokens'
      );
      require(
          IERC20(rewardToken).allowance(msg.sender, address(this)) >= amount,
          'Insufficient Allowance'
      );
      require(
          IERC20(rewardToken).balanceOf(msg.sender) >= amount,
          'Insufficient Balance'
      );
      require(
          IERC20(rewardToken).transferFrom(msg.sender, address(this), amount),
          'Error TransferFrom'
      );
      unchecked {
          totalRewards += amount;
          dividendsPerNFT += ( amount * precision ) / _currentTokenID;
      }
      emit RewardsDeposited(amount);
  }

  function claimRewards() external {
      require(
          _balances[msg.sender] > 0,
          'Zero Balance'
      );
      _claimRewards(msg.sender);
  }

  function mint(address token, address to, uint256 num, bytes32[] calldata proof) external payable {
      require(
          mintingEnabled,
          'Minting Is Disabled'
      );
      require(
          to != address(0),
          'Zero Address'
      );
      require(
          num > 0,
          'Zero Num'
      );
      if (allowlistEnabled) {
          require(
              MerkleProof.verify(
                  proof,
                  merkleRoot,
                  keccak256(abi.encodePacked(_msgSender()))
              ),
              "User Is Not Whitelisted"
          );
      }

      require(
          mintCost[token] > 0,
          'Invalid Mint Token'
      );
      uint totalCost = mintCost[token] * num;

      if (token == address(0)) {
          require(
              msg.value >= totalCost,
              'Insufficient Value'
          );

          // add logic to swap to USDC if ETH
          (bool s,) = payable(mintRecipient).call{value: msg.value}("");
          require(s, 'Mint Recipient Transfer Failure');

      } else {
          require(
              IERC20(token).balanceOf(msg.sender) >= totalCost,
              'Insufficient Balance'
          );
          require(
              IERC20(token).allowance(msg.sender, address(this)) >= totalCost,
              'Insufficient Allowance'
          );
          require(
              IERC20(token).transferFrom(msg.sender, mintRecipient, totalCost),
              'Error Transfer From'
          );
      }
      
      for (uint i = 0; i < num;) {
          _safeMint(to, _currentTokenID);
          unchecked { ++i; }
      }
  }

  /**
      Cumulative Dividends For A Number Of Tokens
   */
  function getCumulativeDividends(uint256 share) internal view returns (uint256) {
      return ( share * dividendsPerNFT ) / precision;
  }

  /**
      Pending Rewards For `account`
   */
  function pendingRewards(address account) public view returns (uint256) {
      if(_balances[account] == 0){ return 0; }
      if (totalRewards == 0) { return 0; }

      uint256 accountTotalDividends = getCumulativeDividends(_balances[account]);
      uint256 accountTotalExcluded = totalExcluded[account];

      if(accountTotalDividends <= accountTotalExcluded){ return 0; }

      return accountTotalDividends - accountTotalExcluded;
  }

  /**
      Total Supply of NFT
   */
  function totalSupply() external view returns (uint256) {
      return _currentTokenID;
  }

  /**
      Name Of The Collection
   */
  function name() external view override returns (string memory) {
      return _name;
  }

  /**
      Symbol (ticker) Of The Collection
   */
  function symbol() external view override returns (string memory) {
      return _symbol;
  }

  /**
      Returns The Number Of Fractions This NFT Is Split Into
   */
  function numFractions() external view override returns (uint256) {
      return nFractions;
  }

  /**
      Returns The URI To An Image Representing This Fractional Asset
   */
  function tokenURI(uint256) external view override returns (string memory) {
      return baseURI;
  }

  /**
      Returns The URI To An Image Representing This Fractional Asset
   */
  function URI() external view override returns (string memory) {
      return baseURI;
  }

  /**
   * @dev Returns the number of tokens in ``owner``'s account.
   */
  function balanceOf(address owner) external view override returns (uint256 balance) {
      return _balances[owner];
  }

  /**
   * @dev Returns the owner of the `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function ownerOf(uint256 tokenId) public view returns (address owner) {
      require(
          _exists(tokenId),
          'Token Does Not Exist'
      );
      return _owners[tokenId];
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId
  ) external override {
      require(
          _isApprovedOrOwner(_msgSender(), tokenId), 
          "Transfer caller is not owner nor approved"
      );
      _safeTransfer(from, to, tokenId, new bytes(0));
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId,
      bytes calldata data
  ) public override {
      require(
          _isApprovedOrOwner(_msgSender(), tokenId), 
          "Transfer caller is not owner nor approved"
      );
      _safeTransfer(from, to, tokenId, data);
  }

  /**
   * @dev Transfers `tokenId` token from `from` to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
      address from,
      address to,
      uint256 tokenId
  ) external override {
      require(
          _isApprovedOrOwner(_msgSender(), tokenId), 
          "Transfer caller is not owner nor approved"
      );
      _transfer(from, to, tokenId);
  }

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
   *
   * Requirements:
   *
   * - The caller must own the token or be an approved operator.
   * - `tokenId` must exist.
   *
   * Emits an {Approval} event.
   */
  function approve(address to, uint256 tokenId) external override {
      address owner = ownerOf(tokenId);
      require(
          to != owner, 
          "ERC721: approval to current owner"
      );
      require(
          _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
          "ERC721: approve caller is not owner nor approved for all"
      );
      _approve(to, tokenId);
  }

  /**
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(uint256 tokenId) public view override returns (address operator) {
      require(
          _exists(tokenId), 
          "Non Existent Token"
      );
      return _tokenApprovals[tokenId];
  }

  /**
   * @dev Approve or remove `operator` as an operator for the caller.
   * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
   *
   * Requirements:
   *
   * - The `operator` cannot be the caller.
   *
   * Emits an {ApprovalForAll} event.
   */
  function setApprovalForAll(address operator, bool _approved) external override {
      _setApprovalForAll(_msgSender(), operator, _approved);
  }

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}
   */
  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
      return _operatorApprovals[owner][operator];
  }

  /**
      Claims Reward For User
   */
  function _claimRewards(address user) internal {

      // return if zero balance
      if (_balances[user] == 0) {
          return;
      }

      // fetch pending rewards
      uint pending = pendingRewards(user);
      uint bal = IERC20(rewardToken).balanceOf(address(this));
      if (pending > bal) {
          pending = bal;
      }

      // return if no rewards
      if (pending == 0) {
          return;
      }
      
      // reset total rewards
      totalExcluded[user] = getCumulativeDividends(_balances[user]);

      // transfer reward to user
      IERC20(rewardToken).transfer(user, pending);
      emit RewardsClaimed(user, pending);
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * `_data` is additional data, it has no specified format and it is sent in call to `to`.
   *
   * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
   * implement alternative mechanisms to perform token transfer, such as signature-based.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeTransfer(
      address from,
      address to,
      uint256 tokenId,
      bytes memory _data
  ) internal {
      _transfer(from, to, tokenId);
      require(
          _checkOnERC721Received(from, to, tokenId, _data), 
          "ERC721: Transfer to non ERC721Receiver implementer"
      );
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address and must be KYC Verified
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
      address from,
      address to,
      uint256 tokenId
  ) internal isVerified(to) {
      
      // Ensure State
      require(
          ownerOf(tokenId) == from,
          "ERC721: transfer from incorrect owner"
      );
      require(
          _balances[from] > 0, 
          'Zero Balance'
      );

      // Clear approvals from the previous owner
      _approve(address(0), tokenId);

      // claim rewards for from
      _claimRewards(from);

      // Register Owner If Zero Balance Update
      if (_balances[to] == 0) {
          _registerOwner(to);
      } else {
          _claimRewards(to);
      }

      // Reassign Total Balances
      unchecked {
          _balances[from] -= 1;
          _balances[to] += 1;
      }

      // Reassign Ownership
      _owners[tokenId] = to;

      // Remove Owner If New Balance Is Zero
      if (_balances[from] == 0) {
          _removeOwner(from);
      }

      // reset reward allocations
      totalExcluded[from] = getCumulativeDividends(_balances[from]);
      totalExcluded[to] = getCumulativeDividends(_balances[to]);

      emit Transfer(from, to, tokenId);
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(
      address to,
      uint256 tokenId
  ) internal isVerified(to) {
      _mint(to, tokenId);
      require(
          _checkOnERC721Received(address(0), to, tokenId, ""),
          "ERC721: transfer to non ERC721Receiver implementer"
      );
  }

  /**
   * @dev Mints `tokenId` and transfers it to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - `to` cannot be the zero address.
   *
   * Emits a {Transfer} event.
   */
  function _mint(address to, uint256 tokenId) internal {
      require(!_exists(tokenId), "ERC721: token already minted");
      require(_currentTokenID < nFractions, 'All NFTs Have Been Minted');

      // Register Owner If Zero Balance Update
      if (_balances[to] == 0) {
          _registerOwner(to);
      }

      // set ownership
      _owners[tokenId] = to;

      // increment balance of minter plus the current token ID
      unchecked {
          _balances[to]++;
          _currentTokenID++;
      }

      // set excluded
      totalExcluded[to] = getCumulativeDividends(_balances[to]);

      emit Transfer(address(0), to, tokenId);
      emit Mint(to, tokenId);
  }

  /**
      Registers `owner` in registeredOwner List
   */
  function _registerOwner(address owner) internal {
      _ownerIndex[owner] = _registeredOwners.length;
      _registeredOwners.push(owner);
  }

  /**
      Removes `owner` from registeredOwner List
   */
  function _removeOwner(address owner) internal {

      // set last element index to be removed index
      _ownerIndex[
          _registeredOwners[_registeredOwners.length - 1]
      ] = _ownerIndex[owner];

      // set removed element to be last element
      _registeredOwners[
          _ownerIndex[owner]
      ] = _registeredOwners[_registeredOwners.length - 1];

      // pop off last element
      _registeredOwners.pop();
      delete _ownerIndex[owner];
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal {
      _tokenApprovals[tokenId] = to;
      emit Approval(ownerOf(tokenId), to, tokenId);
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
      return _owners[tokenId] != address(0);
  }

  /**
   * @dev Approve `operator` to operate on all of `owner` tokens
   *
   * Emits a {ApprovalForAll} event.
   */
  function _setApprovalForAll(
      address owner,
      address operator,
      bool approved
  ) internal {
      require(
          owner != operator, 
          "Caller Cannot Approve Itself"
      );
      _operatorApprovals[owner][operator] = approved;
      emit ApprovalForAll(owner, operator, approved);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
      require(
          _exists(tokenId), 
          "Non Existent Token"
      );
      address owner = ownerOf(tokenId);
      return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
      address from,
      address to,
      uint256 tokenId,
      bytes memory _data
  ) private returns (bool) {
      if (to.isContract()) {
          try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
              return retval == IERC721Receiver.onERC721Received.selector;
          } catch (bytes memory reason) {
              if (reason.length == 0) {
                  revert("ERC721: transfer to non ERC721Receiver implementer");
              } else {
                  assembly {
                      revert(add(32, reason), mload(reason))
                  }
              }
          }
      } else {
          return true;
      }
  }

  /**
      Returns A List Of All Accounts With A Fractional Asset Balance Greater Than 0
   */
  function listAllOwners() external view returns (address[] memory) {
      return _registeredOwners;
  }

  /**
      Returns A List Of All Token IDs Belonging To `user`
   */
  function listIDsOwnedByUser(address user) external view returns (uint256[] memory) {
      // If Zero Balance Return Empty List
      uint balance = _balances[user];
      uint256[] memory arr = new uint256[](balance);
      if (balance <= 0) {
          return arr;
      }
      uint count = 0;
      // Loop Through All IDs To Create List
      for (uint i = 0; i < _currentTokenID;) {
          if (_owners[i] == user) {
              arr[count] = i;
              unchecked {
                  ++count;
              }
          }
          unchecked { ++i; }
      }
      return arr;
  }


  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
      return interfaceId == type(IERC165).interfaceId ||
          interfaceId == type(INonFungibleToken).interfaceId ||
          interfaceId == type(IFractionalAsset).interfaceId;
  }

  /**
      Converts A Uint Into a String
  */
  function uint2str(uint _i) internal pure returns (string memory) {
      if (_i == 0) {
          return "0";
      }
      uint j = _i;
      uint len;
      while (j != 0) {
          len++;
          j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len;
      while (_i != 0) {
          k = k-1;
          uint8 temp = (48 + uint8(_i - _i / 10 * 10));
          bytes1 b1 = bytes1(temp);
          bstr[k] = b1;
          _i /= 10;
      }
      return string(bstr);
  }
}