pragma solidity ^0.6.3;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
pragma experimental ABIEncoderV2;

contract Unibond is Ownable, IERC721Receiver {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    struct SwapCollection {
        uint256 swapId; // swap id
        uint256 tokenId; // UniV3 NFT id
        address payable creator; // address of swap creator
        address payToken; // address of pay token
        uint256 amount; // token/ETH amount,
        uint8 assetType; // 0 : erc20 token, 1 : ETH
        bool isOpen; // true: open to swap, false: closed
    }

    address public constant UNIV3_NFT_POISTION_MANAGER =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    uint256 public listIndex;
    mapping(uint256 => SwapCollection) public swapList; // SwapList Stae
    mapping(address => bool) public supportTokens;

    bool public emergencyStop;
    address payable public feeCollector;

    event SwapCreated(
        uint256 swapId,
        uint256 tokenId,
        address creator,
        address payToken,
        uint256 amount,
        uint8 assetType
    );
    event SwapCompleted(uint256 swapId);
    event SwapClosed(uint256 swapId);

    modifier onlyNotEmergency() {
        require(emergencyStop == false, "Unibond: emergency stop");
        _;
    }

    constructor() public {
        listIndex = 0;
        emergencyStop = false;
        feeCollector = msg.sender;
    }

    // @dev enable swap
    function clearEmergency() external onlyOwner {
        emergencyStop = false;
    }

    // @dev add support tokens
    function addBatchSupportTokens(address[] calldata _tokens)
        external
        onlyOwner
    {
        for (uint16 i = 0; i < _tokens.length; i++)
            supportTokens[_tokens[i]] = true;
    }

    // @dev remove tokens from list
    function removeBatchSupportTokens(address[] calldata _tokens)
        external
        onlyOwner
    {
        for (uint16 i = 0; i < _tokens.length; i++)
            supportTokens[_tokens[i]] = false;
    }

    // @dev disable swap
    function stopEmergency() external onlyOwner {
        emergencyStop = true;
    }

    // @dev update fee wallet address
    function updateFeeWallet(address payable _feeCollector) external onlyOwner {
        feeCollector = _feeCollector;
    }

    // @dev create a swap
    function createSwap(
        uint256 _tokenId,
        address _payToken,
        uint256 _amount,
        uint8 _assetType
    ) external onlyNotEmergency {
        IERC721 _posManager = IERC721(UNIV3_NFT_POISTION_MANAGER);
        require(
            _posManager.ownerOf(_tokenId) == msg.sender,
            "Unibond: seller have no asset"
        );
        require(
            _posManager.isApprovedForAll(msg.sender, address(this)) == true,
            "Unibond: Asset is not approved for create"
        );
        require(
            supportTokens[_payToken] == true,
            "Unibond: this token is not supported"
        );

        _posManager.safeTransferFrom(msg.sender, address(this), _tokenId, "");

        uint256 _id = listIndex;
        swapList[_id].swapId = _id;
        swapList[_id].tokenId = _tokenId;
        swapList[_id].creator = msg.sender;
        swapList[_id].payToken = _payToken;
        swapList[_id].amount = _amount;
        swapList[_id].assetType = _assetType;
        swapList[_id].isOpen = true;

        _incrementListId();

        emit SwapCreated(
            _id,
            _tokenId,
            msg.sender,
            _payToken,
            _amount,
            _assetType
        );
    }

    // @dev accept swap with erc20 token
    function swapWithToken(uint256 _swapId) external onlyNotEmergency {
        IERC721 _posManager = IERC721(UNIV3_NFT_POISTION_MANAGER);
        SwapCollection storage _list = swapList[_swapId];
        require(_list.assetType == 0, "Unibond: You should swap with ETH");
        require(
            IERC20(_list.payToken).balanceOf(msg.sender) >= _list.amount,
            "Unibond: Not enough balance"
        );
        require(
            supportTokens[_list.payToken] == true,
            "Unibond: this token is not supported"
        );
        uint256 fee = _list.amount.mul(175).div(10000);
        uint256 amount = _list.amount.sub(fee);
        IERC20(_list.payToken).safeTransferFrom(
            msg.sender,
            _list.creator,
            amount
        );
        IERC20(_list.payToken).safeTransferFrom(msg.sender, feeCollector, fee);
        _posManager.safeTransferFrom(
            address(this),
            msg.sender,
            _list.tokenId,
            ""
        );
        _list.isOpen = false;

        emit SwapCompleted(_swapId);
    }

    // @dev accept swap with ETH
    function swapWithETH(uint256 _swapId) external payable onlyNotEmergency {
        IERC721 _posManager = IERC721(UNIV3_NFT_POISTION_MANAGER);
        SwapCollection storage _list = swapList[_swapId];
        require(_list.assetType == 1, "Unibond: You should swap with token");
        require(msg.value >= _list.amount, "Unibond: Not enough balance");
        uint256 fee = msg.value.mul(175).div(10000);
        uint256 amount = msg.value.sub(fee);
        _list.creator.transfer(amount);
        feeCollector.transfer(fee);
        _posManager.safeTransferFrom(
            address(this),
            msg.sender,
            _list.tokenId,
            ""
        );
        _list.isOpen = false;

        emit SwapCompleted(_swapId);
    }

    // @dev close opend swap
    function closeSwap(uint256 _swapId) external {
        IERC721 _posManager = IERC721(UNIV3_NFT_POISTION_MANAGER);
        SwapCollection storage _list = swapList[_swapId];
        require(_list.isOpen == true, "Unibond: swap is already closed");
        require(_list.creator == msg.sender, "Unibond: not your list");
        _posManager.safeTransferFrom(
            address(this),
            _list.creator,
            _list.tokenId,
            ""
        );
        _list.isOpen = false;
        emit SwapClosed(_swapId);
    }

    function viewSwap(uint256 _swapId)
        public
        view
        returns (SwapCollection memory)
    {
        return swapList[_swapId];
    }

    function _incrementListId() internal {
        listIndex = listIndex.add(1);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
