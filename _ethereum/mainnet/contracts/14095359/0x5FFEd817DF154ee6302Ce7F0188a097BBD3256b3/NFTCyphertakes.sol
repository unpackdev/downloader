pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./AccessControlMixin.sol";
import "./NativeMetaTransaction.sol";
import "./ContextMixin.sol";


contract NFTCyphertakes is
    ERC721URIStorage,
    Pausable,
    Ownable,
    AccessControlMixin,
    NativeMetaTransaction,
    ContextMixin
{
    // Minter Role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // Initial BASE_TOKEN_URI
    string private BASE_TOKEN_URI;
    // Initial Contract URI
    string private CONTRACT_URI;

    constructor(
        string memory name_,
        string memory symbol_,
        address minterRole
    ) public ERC721(name_, symbol_) {
        _setupContractId("NFTCyphertakes");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, minterRole);
        _initializeEIP712(name_);
        BASE_TOKEN_URI = "https://api.cypherverse.io/os/collections/cyphertakes/";
        CONTRACT_URI = "https://api.cypherverse.io/os/collections/cyphertakes";
    }

    modifier TokenId(uint256 tokenId_) {
        // Restrict minting of tokens to only the minter role, and only for 5 tokens
        require( ((tokenId_ > uint(0))), "NFTCyphertakes: INVALID_TOKEN_ID");
        _;
    }

    // This is to support Native meta transactions
    // never use msg.sender directly, use _msgSender() instead
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    function _msgData()
        internal
        override (Context)
        pure
        returns (bytes calldata)
    {
        return msg.data;
    }


    /**
     * Override isApprovedForAll to auto-approve OS's proxy contract
     */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }

        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    /**
     * @notice  Make the SetTokenURI method visible for future upgrade of metadata
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public virtual only(DEFAULT_ADMIN_ROLE) TokenId(tokenId)  {
        _setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @notice Method for reduce the friction with openSea allows to map the `tokenId`
     * @dev into our NFT Smart contract and handle some metadata offchain in OpenSea
    */
    function baseTokenURI() public view returns (string memory) {
        return BASE_TOKEN_URI;
    }

    /**
     * @notice Method for reduce the friction with openSea allows update the Base Token URI
     * @dev This method is only available for the owner of the contract
     * @param _baseTokenURI The new base token URI
     */

    function setBaseTokenURI(string memory _baseTokenURI) public only(DEFAULT_ADMIN_ROLE) {
        BASE_TOKEN_URI = _baseTokenURI;
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
    function setContractURI(string memory _contractURI) public only(DEFAULT_ADMIN_ROLE) {
        CONTRACT_URI = _contractURI;
    }

    /**
     * @dev Implementation / Instance of paused methods() in the ERC721.
     * @param status Setting the status boolean (True for paused, or False for unpaused)
     * See {ERC721Pausable}.
     */
    function pause(bool status) public only(DEFAULT_ADMIN_ROLE) {
        if (status) {
            _pause();
        } else {
            _unpause();
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
     * @notice Example function to handle minting tokens on matic chain
     * @dev Minting can be done as per requirement,
     * This implementation allows only admin to mint tokens but it can be changed as per requirement
     * Should verify if token is withdrawn by checking `withdrawnTokens` mapping
     * @param user user for whom tokens are being minted
     * @param tokenId tokenId to mint
     */
    function mint(address user, uint256 tokenId, string memory _tokenURI) public TokenId(tokenId) only(MINTER_ROLE) {
        require((bytes(_tokenURI).length >= 5), "NFTCyphertakes: TOKEN_URI_TOO_SHORT");
        _mint(user, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual TokenId(tokenId) {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(!paused(), "ERC721Pausable: token transfer while paused");

        super._beforeTokenTransfer(from, to, tokenId);
    }
}
