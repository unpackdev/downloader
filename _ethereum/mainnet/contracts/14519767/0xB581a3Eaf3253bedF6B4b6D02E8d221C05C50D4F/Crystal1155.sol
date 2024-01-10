//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./Address.sol";
import "./IERC165.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";


contract KingdomsOfEtherCrystal is IERC1155, IERC1155MetadataURI, EIP712, Ownable
{
    /* constants */
    string private tokenUri = "ipfs://QmcvfZ2w3FBCca1JWDYYqE9RfPjJ2rV7E2FZ5ZYN4Z2M2i";
    uint256 public constant TOKEN_ID = 1;
    string public constant NAME = "Ether Mines";
    string public constant SYMBOL = "COE";
    string public constant EIP712_VERSION = "1.0.0";

    /* state */
    address public signer; // for eip712 verification
    address public adventurers;

    uint private constant PUBLIC_POOL = 0;
    uint private constant PRIVATE_POOL = 1;
    uint private constant TOTAL_POOL = 2;
    uint64 private constant PUBLIC_POOL_CAPACITY = 500;
    uint64 private constant PRIVATE_POOL_CAPACITY = 500;
    uint64 private constant MAX_SUPPLY = 1500;
    uint private constant MAX_MINT_PER_ADDR = 1;
    struct Pool {
        uint64 supply;
        uint64 maxSupply;
    }

    bool public publicMint = false;
    Pool[] public supply;
    uint public maxMintPerAddress = MAX_MINT_PER_ADDR;
    mapping(address/*minter*/ => /*minted count*/uint) internal minters;

    string public name;
    string public symbol;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => bool)) internal _allowances;
    
    using Address for address;

    constructor() EIP712(NAME, EIP712_VERSION) Ownable() {
        name = NAME;
        symbol = SYMBOL;
        signer = msg.sender;
        supply.push(Pool({
            supply: 0,
            maxSupply: PUBLIC_POOL_CAPACITY
        }));
        supply.push(Pool({
            supply: 0,
            maxSupply: PRIVATE_POOL_CAPACITY
        }));
        supply.push(Pool({
            supply: 0,
            maxSupply: MAX_SUPPLY
        }));
    }


    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return supply[TOTAL_POOL].supply;
    }

    /**
     * @notice mint crystal token
     */
    function mint(uint256 _pool, bytes memory _signature) external returns (uint256 _tokenId) {
        require(verifySignature(msg.sender, _pool, _signature) == signer, INVALID_SIGNATURE);
        require(supply[_pool].supply < supply[_pool].maxSupply, SUPPLY_EXCEEDED);
        supply[_pool].supply += 1;
        require(supply[TOTAL_POOL].supply < supply[TOTAL_POOL].maxSupply, TOKENS_OVER);
        return _mint(msg.sender);
    }

    /**
     * @notice mint crystal token after public sale is enabled
     */
    function mintPublic() external returns (uint256 _tokenId) {
        require(publicMint, PUBLIC_MINT_NOT_STARTED);
        require(supply[TOTAL_POOL].supply < (supply[TOTAL_POOL].maxSupply - supply[PRIVATE_POOL].maxSupply), TOKENS_OVER);
        return _mint(msg.sender);
    }

    /**
     * @notice enable/disable public mint
     */
    function setPublicMint(bool _enabled) external onlyOwner() {
        publicMint = _enabled;
    }

    /**
     * @notice set max mint per address
     */
    function setMaxMintPerAddress(uint _maxMint) external onlyOwner() {
        maxMintPerAddress = _maxMint;
    }

    /**
     * @notice set max supply
     */
    function setMaxSupply(uint _pool, uint64 _maxSupply) external onlyOwner() {
        supply[_pool].maxSupply = _maxSupply;
    }

    /**
     * @notice set adventurers contract
     */
    function setAdventurers(address _adventurers) external onlyOwner() {
        adventurers = _adventurers;
    }

    /**
     * @notice set adventurers contract
     */
    function setUri(string memory _uri) external onlyOwner() {
        tokenUri = _uri;
    }

    /**
     * @notice set eip-712 signer
     */
    function setSigner(address _signer) external onlyOwner() {
        signer = _signer;
    }

    function _mint(address _to) internal returns (uint256 _tokenId) {
        require(minters[_to] < maxMintPerAddress, PASS_USED_UP);
        require(_to != address(0), ZERO_ADDRESS);
        supply[TOTAL_POOL].supply += 1;
        minters[_to] += 1;
        _balances[_to] += 1;
        emit TransferSingle(msg.sender, address(0), _to, TOKEN_ID, 1);
        return TOKEN_ID;
    }

    /* eip-712 */
    bytes32 private constant PASS_TYPEHASH = keccak256("MintPass(address wallet,uint256 pool)");

    function verifySignature(address _wallet, uint256 _pool, bytes memory _signature) public view returns (address _signer) {
        bytes32 _digest = _hashTypedDataV4(
            keccak256(abi.encode(PASS_TYPEHASH, _wallet, _pool))
        );
        _signer = ECDSA.recover(_digest, _signature);
    }

    function domainSeparatorV4() public view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address _account, uint256 _id) public view virtual override returns (uint256) {
        require(_id == TOKEN_ID, UNKNOWN_TOKEN);
        return _balances[_account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory _accounts, uint256[] memory _ids)
        public view virtual override
        returns (uint256[] memory)
    {
        require(_accounts.length == _ids.length, LENGTH_MISMATCH);
        uint256[] memory _batchBalances = new uint256[](_accounts.length);

        for (uint256 i = 0; i < _accounts.length; ++i) {
            _batchBalances[i] = balanceOf(_accounts[i], _ids[i]);
        }
        return _batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address _operator, bool _approved) public virtual override {
        _setApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address _owner,
        address _operator,
        bool _approved
    ) internal virtual {
        require(_owner != address(0), ZERO_ADDRESS);
        require(_operator != address(0), ZERO_ADDRESS);
        _allowances[_owner][_operator] = _approved;
        emit ApprovalForAll(_owner, _operator, _approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address _account, address _operator) public view virtual override returns (bool) {
        return _operator == adventurers || _allowances[_account][_operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public virtual override {
        require(
            _from == msg.sender || isApprovedForAll(_from, msg.sender),
            NOT_OWNER
        );
        require(_id == TOKEN_ID, UNKNOWN_TOKEN);
        _safeTransferFrom(_from, _to, _amount, _data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public virtual override {
        require(
            _from == msg.sender|| isApprovedForAll(_from, msg.sender),
            NOT_OWNER
        );
        require(_ids.length == _amounts.length, LENGTH_MISMATCH);
        require(_ids.length < 2, SINGLE_TOKEN);
        if (_ids.length == 1) {
            _safeTransferFrom(_from, _to, _amounts[0], _data);
        }
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _amount,
        bytes memory
    ) internal {
        address _operator = msg.sender;
        if (_operator != _from) {
            require(isApprovedForAll(_from, _operator), NOT_OWNER);
        }
        require(_from != address(0), ZERO_ADDRESS);
        require(_to != address(0), ZERO_ADDRESS);

        uint256 senderBalance = _balances[_from];
        require(senderBalance >= _amount, LOW_BALANCE);
        unchecked {
            _balances[_from] = senderBalance - _amount;
        }
        _balances[_to] += _amount;
        emit TransferSingle(msg.sender, _from, _to, TOKEN_ID, _amount);
    }

    /**
     * @dev See {IERC1155-uri}.
     */
    function uri(uint256) public view virtual returns (string memory _uri) {
        return tokenUri;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    /* errors */
    string private constant UNKNOWN_TOKEN = "ERC1155: unknown token";
    string private constant LENGTH_MISMATCH = "ERC1155: accounts and ids length mismatch";
    string private constant APPROVAL_FOR_SELF = "ERC1155: setting approval status for self";
    //string private constant NON_ERC1155_RECEIVER = "ERC1155: transfer to non ERC1155Receiver implementer";
    //string private constant ERC1155_REJECTED = "ERC1155: ERC1155Receiver rejected tokens";
    string private constant NOT_OWNER = "ERC1155: caller is not owner nor approved";
    string private constant LOW_BALANCE = "ERC1155: insufficient balance for transfer";
    string private constant SINGLE_TOKEN = "ERC1155: contract has only one token";
    string private constant PASS_USED_UP = "EIP712: minted already";
    string private constant INVALID_SIGNATURE = "EIP712: invalid signature";
    string private constant PUBLIC_MINT_NOT_STARTED = "public mint is not started";
    string private constant SUPPLY_EXCEEDED = "maximum supply exceded";
    string private constant UNAUTHORIZED = "unauthorized";
    string private constant ZERO_ADDRESS = "zero address";
    string public constant TOKENS_OVER = "tokens are over";
}
