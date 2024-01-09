// This contract is not supposed to be used in production
// It's strictly for testing purpose

pragma solidity ^0.8.4;

import "./ERC1155Supply.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./AccessControlMixin.sol";
import "./NativeMetaTransaction.sol";
import "./IMintableERC1155.sol";
import "./ContextMixin.sol";

contract RootNFTMetakey is
    ERC1155Supply,
    Pausable,
    Ownable,
    AccessControlMixin,
    NativeMetaTransaction,
    ContextMixin,
    IMintableERC1155
{
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;
    // Initial Contract URI
    string private CONTRACT_URI;

    constructor (
        string memory name_,
        string memory symbol_,
        string memory uri_,
        address mintableERC1155PredicateProxy
    )
      ERC1155(
            uri_
        )
    {
        _setupContractId("RootNFTMetakey");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PREDICATE_ROLE, mintableERC1155PredicateProxy);
        _initializeEIP712(uri_);
        name = name_;
        symbol = symbol_;
        CONTRACT_URI = "https://api.cypherverse.io/os/collections/metakey";
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external override only(PREDICATE_ROLE) {
        // Restrict minting of tokens to only the minter role, and only for 5 tokens
        require( ((id > uint(0)) && (id <= uint(5))), "RootNFTMetakey: INVALID_TOKEN_ID");
        require(((amount > uint(0)) && (amount == restTotalSupply(id, amount))) , "RootNFTMetakey: INVALID_TOKEN_AMOUNT");
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external override only(PREDICATE_ROLE) {
        // Restrict minting of tokens to only the minter role, and only for 5 tokens
        for (uint i = 0; i < ids.length; i++) {
            require(((ids[i] > uint(0)) && (ids[i] <= uint(5))), "RootNFTMetakey: INVALID_TOKEN_ID");
            require(((amounts[i] > uint(0)) && (amounts[i] == restTotalSupply(ids[i], amounts[i]))) , "RootNFTMetakey: INVALID_TOKEN_AMOUNT");
        }
        _mintBatch(to, ids, amounts, data);
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "RootNFTMetakey: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "RootNFTMetakey: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }

    // This is to support Native meta transactions
    // never use msg.sender directly, use _msgSender() instead
    function _msgSender()
        internal
        override (Context)
        view
        returns (address  sender)
    {
        return ContextMixin.msgSender();
    }

    function _msgData()
    internal
    override (Context)
    pure
    returns (bytes calldata) {
        return msg.data;
    }

        /**
     * Override isApprovedForAll to auto-approve OS's proxy contract
     */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override(ERC1155, IERC1155) view returns (bool isOperator) {
        // if OpenSea's ERC1155 Proxy Address is detected, auto-return true
       if (_operator == address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)) {
            return true;
        }
        // otherwise, use the default ERC1155.isApprovedForAll()
        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    /**
     * @notice  Make the SetTokenURI method visible for future upgrade of metadata
     * @dev Sets `_tokenURI` as the tokenURI for the `all` tokenId.
     */
    function setURI(string memory _tokenURI) public virtual onlyOwner() {
        _setURI(_tokenURI);
    }

    /**
     * @notice Method for reduce the friction with openSea allows to map the `tokenId`
     * @dev into our NFT Smart contract and handle some metadata offchain in OpenSea
    */
    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    /**
     * @notice Method for reduce the friction with openSea allows update the Contract URI
     * @dev This method is only available for the owner of the contract
     * @param _contractURI The new contract URI
     */
    function setContractURI(string memory _contractURI) public onlyOwner() {
        CONTRACT_URI = _contractURI;
    }

    /**
     * @notice Method for getting Max Supply for Token
     * @dev This method is for getting the Max Supply by token id
     * @param _id The token id
     */
    function maxSupply(uint256 _id) public pure returns (uint256 _maxSupply) {
        if (_id == 1) {
          _maxSupply = uint256(500);
        } else if (_id == 2)  {
          _maxSupply = uint256(749);
        } else if (_id == 3)  {
          _maxSupply = uint256(1000);
        } else if (_id == 4)  {
          _maxSupply = uint256(7500);
        } else if (_id == 5)  {
          _maxSupply = uint256(280);
        } else {
          revert("ChildNFTMetaKey: INVALID_TOKEN_ID");
        }
    }

    /**
     * @notice Method for getting OpenSea Version we Operate
     * @dev This method is for getting the Max Supply by token id
     */
    function openSeaVersion() public pure returns (string memory) {
        return "2.1.0";
    }

    /**
     * Compat for factory interfaces on OpenSea
     * Indicates that this contract can return balances for
     * tokens that haven't been minted yet
     */
    function supportsFactoryInterface() public pure returns (bool) {
        return true;
    }

    /**
     * @dev Implementation / Instance of paused methods() in the ERC1155.
     * @param status Setting the status boolean (True for paused, or False for unpaused)
     * See {ERC1155Pausable}.
     */
    function pause(bool status) public onlyOwner() {
        if (status) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
      * @dev Method, for verify the TotalSupply of the NFT, each time to mint a new NFT Token
      * @param _id The id of the NFT Token
      * @param _amount The amount of the NFT Token
      * @return The amount of the NFT Token to mint
      */
    function restTotalSupply(uint256 _id, uint256 _amount) public view returns (uint256) {
      uint256 subtotal = totalSupply(_id)+_amount;
      require(( subtotal <= maxSupply(_id)), "RootNFTMetakey: EXCEED MAX_AMOUNT");
      return _amount;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "RootNFTMetakey: token transfer while paused");
    }
}
