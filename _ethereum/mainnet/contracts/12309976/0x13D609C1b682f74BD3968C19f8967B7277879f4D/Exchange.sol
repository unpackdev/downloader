pragma solidity ^0.6.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./ReentrancyGuard.sol";

contract ExchangeFromEthereum is IERC1155Receiver, ReentrancyGuard {
    //NftTokenInfo[] allNFT;
    address payable private backend;
    uint256 private gasUnlock;

    constructor(address payable _back) public {
        require(_back != address(0), "Wrong address");
        backend = _back;
        gasUnlock = 44800;
    }

    modifier onlyBackend {
        require(msg.sender == backend, "Only backend can call this function.");
        _;
    }

    struct NftTokenInfo {
        address tokenAddress;
        uint256 id;
        bool locked;
    }

    /*mapping(address => NftTokenInfo[]) public deposits;
    mapping(address => NftTokenInfo[]) public activeDeposits;*/
    mapping(address => NftTokenInfo[]) public deposits;

    event DepositNFT(address owner, address nftAddress, uint256 nftId);
    event WithdrawNFT(address nftAddress, uint256 nftId, address to);
    event Log(uint256 fee);

    function depositNft(address nftAddress, uint256 nftId) external payable nonReentrant{
        //uint256 gasBeg = gasleft();
        uint256 gasPrice = tx.gasprice;
        uint256 fee = gasUnlock * gasPrice;
        require(nftAddress != address(0), "Wrong NFT contract address");
        require(msg.value >= fee);
        NftTokenInfo memory token = NftTokenInfo(nftAddress, nftId, true);
        IERC1155(nftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            nftId,
            1,
            ""
        );
        backend.transfer(msg.value);
        deposits[msg.sender].push(token);
        //deposits[msg.sender].push(nft);
        //activeDeposits[msg.sender].push(nft);
        emit DepositNFT(msg.sender, nftAddress, nftId);
        emit Log(fee);
        //uint256 gasEnd = gasleft();
        //uint256 gas = gasBeg - gasEnd;
        //require(msg.value >= 2 * gas * tx.gasprice);
    }

    function withdrawNft(address nftAddress, uint256 nftId, address to) external nonReentrant {
        require(nftAddress != address(0));
        uint256 index = deposits[msg.sender].length;
        for(uint256 i=0; i<deposits[msg.sender].length; i++){
            if(deposits[msg.sender][i].tokenAddress == nftAddress && deposits[msg.sender][i].id == nftId){
                index = i;
            }
        }
        require(index != deposits[msg.sender].length, "Wrong initial values");
        /*require(
            index >= 0 && index < deposits[msg.sender].length,
            "Wrong index"
        );*/
        //address nftAddress = deposits[msg.sender][index].tokenAddress;
        //uint256 nftId = deposits[msg.sender][index].id;
        //require(nftAddress != address(0));
        require(!deposits[msg.sender][index].locked, "Unable to withdraw. Deposit all BEP20 tokens on the contract in Binance Smaert Chain");
        //require(!deposits[msg.sender][index].sent, "Deposit has already withdrawn");
        IERC1155(nftAddress).safeTransferFrom(
            address(this),
            to,
            nftId,
            1,
            ""
        );
        deposits[msg.sender][index].locked = true;
        //deposits[msg.sender][index].sent = true;
        /*uint256 actLeng = activeDeposits[msg.sender].length;
        if (index < actLeng  - 1)
            activeDeposits[msg.sender][index] = activeDeposits[msg.sender][actLeng - 1];
        activeDeposits[msg.sender].pop();*/
        emit WithdrawNFT(nftAddress, nftId, msg.sender);
    }

    function unlock (address owner, address nftAddress, uint256 nftId) external onlyBackend {
        require(nftAddress != address(0));
        uint256 index = deposits[owner].length;
        for(uint256 i=0; i<deposits[owner].length; i++){
            if(deposits[owner][i].tokenAddress == nftAddress && deposits[owner][i].id == nftId){
                index = i;
            }
        }
        require(index != deposits[owner].length, "Wrong initial values");
        deposits[owner][index].locked = false;
    }

    function changeBackAddress(address payable _back) external onlyBackend {
        require(_back != address(0));
        backend = _back;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    )
    external 
    override 
    returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    )
    external 
    override 
    returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4) external view override returns (bool){
        return false;
    }

    receive() external payable { }
}