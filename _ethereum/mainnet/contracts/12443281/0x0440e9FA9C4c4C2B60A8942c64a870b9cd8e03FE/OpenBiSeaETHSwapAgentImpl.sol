// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact alex@cfc.io if you like to use code
pragma solidity ^0.6.8;

import "./IERC20Query.sol";
import "./IERC721Query.sol";
import "./IERC1155Query.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC1155Receiver.sol";
import "./IERC1155.sol";

import "./Context.sol";
import "./SafeERC20.sol";

contract OpenBiSeaETHSwapAgentImpl is Context,IERC721Receiver,IERC1155Receiver {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(address => bool) public registeredERC;
    mapping(bytes32 => bool) public filledBSCTx;

    address payable public owner;
    uint256 public swapFee;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SwapPairRegister(address indexed sponsor,address indexed erc20Addr, string name, string symbol, uint8 decimals);
    event SwapPair721Register(address indexed sponsor,address indexed erc721Addr, string name, string symbol, string baseURI);
    event SwapPair1155Register(address indexed sponsor,address indexed erc1155Addr, string uri);
    event SwapStarted(address indexed erc20Addr, address indexed fromAddr, uint256 amount, uint256 feeAmount);
    event Swap721Started(address indexed erc721Addr, address indexed fromAddr, uint256 tokenId, uint256 feeAmount);
    event Swap1155Started(address indexed erc1155Addr, address indexed fromAddr, uint256 tokenId, uint256 amount, uint256 feeAmount);
    event SwapFilled(address indexed erc20Addr, bytes32 indexed bscTxHash, address indexed toAddress, uint256 amount);
    event Swap721Filled(address indexed erc721Addr, bytes32 indexed bscTxHash, address indexed toAddress, uint256 tokenId);
    event Swap1155Filled(address indexed erc1155Addr, bytes32 indexed bscTxHash, address indexed toAddress, uint256 tokenId, uint256 amount);

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor(uint256 fee) public {
        swapFee = fee;
        owner = _msgSender();
        _status = _NOT_ENTERED;
    }
    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier notContract() {
        require(!isContract(msg.sender), "contract is not allowed to swap");
        require(msg.sender == tx.origin, "no proxy contract is allowed");
       _;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    /**
        * @dev Leaves the contract without owner. It will not be possible to call
        * `onlyOwner` functions anymore. Can only be called by the current owner.
        *
        * NOTE: Renouncing ownership will leave the contract without an owner,
        * thereby removing any functionality that is only available to the owner.
        */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Returns set minimum swap fee from ERC20 to BEP20
     */
    function setSwapFee(uint256 fee) onlyOwner external {
        swapFee = fee;
    }

    function register1155SwapPairToBSC(address erc1155Addr) external returns (bool) {
        require(!registeredERC[erc1155Addr], "already registered");

        string memory uri = IERC1155Query(erc1155Addr).uri(0);

        require(bytes(uri).length>0, "empty uri");

        registeredERC[erc1155Addr] = true;

        emit SwapPair1155Register(msg.sender, erc1155Addr, uri);
        return true;
    }

    function register721SwapPairToBSC(address erc721Addr) external returns (bool) {
        require(!registeredERC[erc721Addr], "already registered");

        string memory name = IERC721Query(erc721Addr).name();
        string memory symbol = IERC721Query(erc721Addr).symbol();
        string memory baseURI = IERC721Query(erc721Addr).baseURI();

        require(bytes(name).length>0, "empty name");
        require(bytes(symbol).length>0, "empty symbol");

        registeredERC[erc721Addr] = true;

        emit SwapPair721Register(msg.sender, erc721Addr, name, symbol, baseURI);
        return true;
    }

    function registerSwapPairToBSC(address erc20Addr) external returns (bool) {
        require(!registeredERC[erc20Addr], "already registered");

        string memory name = IERC20Query(erc20Addr).name();
        string memory symbol = IERC20Query(erc20Addr).symbol();
        uint8 decimals = IERC20Query(erc20Addr).decimals();

        require(bytes(name).length>0, "empty name");
        require(bytes(symbol).length>0, "empty symbol");

        registeredERC[erc20Addr] = true;

        emit SwapPairRegister(msg.sender, erc20Addr, name, symbol, decimals);
        return true;
    }

    function fillBSC2ETHSwap(bytes32 bscTxHash, address erc20Addr, address toAddress, uint256 amount) onlyOwner external returns (bool) {
        require(!filledBSCTx[bscTxHash], "bsc tx filled already");
        require(registeredERC[erc20Addr], "not registered token");

        filledBSCTx[bscTxHash] = true;
        IERC20(erc20Addr).safeTransfer(toAddress, amount);

        emit SwapFilled(erc20Addr, bscTxHash, toAddress, amount);
        return true;
    }

    function fill721BSC2ETHSwap(bytes32 bscTxHash, address erc721Addr, address toAddress, uint256 tokenId) onlyOwner external returns (bool) {
        require(!filledBSCTx[bscTxHash], "bsc tx filled already");
        require(registeredERC[erc721Addr], "not registered token");

        filledBSCTx[bscTxHash] = true;
        IERC721(erc721Addr).safeTransferFrom(address(this), toAddress, tokenId);

        emit Swap721Filled(erc721Addr, bscTxHash, toAddress, tokenId);
        return true;
    }

    function fill1155BSC2ETHSwap(bytes32 bscTxHash, address erc1155Addr, address toAddress, uint256 tokenId, uint256 amount) onlyOwner external returns (bool) {
        require(!filledBSCTx[bscTxHash], "bsc tx filled already");
        require(registeredERC[erc1155Addr], "not registered token");

        filledBSCTx[bscTxHash] = true;

        IERC1155(erc1155Addr).safeTransferFrom(address(this), toAddress, tokenId, amount, "0x0");

        emit Swap1155Filled(erc1155Addr, bscTxHash, toAddress, tokenId, amount);
        return true;
    }


    function swapETH2BSC(address erc20Addr, uint256 amount) payable external nonReentrant returns (bool) {
        require(registeredERC[erc20Addr], "not registered token");
        require(msg.value == swapFee, "swap fee not equal");

        IERC20(erc20Addr).safeTransferFrom(msg.sender, address(this), amount);
        if (msg.value != 0) {
            owner.transfer(msg.value);
        }

        emit SwapStarted(erc20Addr, msg.sender, amount, msg.value);
        return true;
    }
    function swap721ETH2BSC(address erc721Addr, uint256 tokenId) payable external nonReentrant returns (bool) {
        require(registeredERC[erc721Addr], "not registered token");
        require(msg.value == swapFee, "swap fee not equal");

        IERC721(erc721Addr).safeTransferFrom(msg.sender, address(this), tokenId);
        if (msg.value != 0) {
            owner.transfer(msg.value);
        }

        emit Swap721Started(erc721Addr, msg.sender, tokenId, msg.value);

        return true;
    }

    function swap1155ETH2BSC(address erc1155Addr, uint256 tokenId, uint256 amount) payable external nonReentrant returns (bool) {
        require(registeredERC[erc1155Addr], "not registered token");
        require(msg.value == swapFee, "swap fee not equal");

        IERC1155(erc1155Addr).safeTransferFrom(msg.sender, address(this), tokenId, amount, "0x0");
        if (msg.value != 0) {
            owner.transfer(msg.value);
        }

        emit Swap1155Started(erc1155Addr, msg.sender, tokenId, amount, msg.value);

        return true;
    }
    /**
    * Always returns `IERC721Receiver.onERC721Received.selector`.
   */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
    external
    override
    returns(bytes4)
    {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
    external
    override
    returns(bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return this.supportsInterface(interfaceId);
    }
}