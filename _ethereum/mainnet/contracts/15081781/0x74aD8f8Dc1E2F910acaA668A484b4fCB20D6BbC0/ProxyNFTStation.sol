// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// imports
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Holder.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./Counters.sol";

// interfaces
import "./IProxyNFTStation.sol";

contract ProxyNFTStation is IProxyNFTStation, ERC721Holder, ERC1155Holder, Ownable {

    using Counters for Counters.Counter;

    Counters.Counter private _depositIds;

    // ============ Public  ============    

    // interfaceID
    bytes4 public constant ID_ERC721 = 0x80ac58cd;  // ERC721    
    bytes4 public constant ID_ERC1155 = 0xd9b67a26; // ERC1155    

    // OpenLuck executors
    mapping(address => bool) public executors;

    // store user deposited nfts, support multiple executors (executor-address => depositId => NFT)    
    mapping(address => mapping(uint256 => DepositNFT)) public deposits;


    modifier onlyExecutor() {
        require(executors[msg.sender] == true, "Lucks: onlyExecutor");
        _;
    }

    // ======== Constructor =========

    /**
     * @notice Constructor
     * @param _executor address
     */
    constructor(address _executor) {
       executors[_executor]= true;
    }

    // ============ Public functions ============

    function getNFT(address executor, uint256 depositId) public view override returns(DepositNFT memory){
        return deposits[executor][depositId];
    }

    function deposit(address user, address nft, uint256[] memory tokenIds, uint256[] memory amounts, uint256 endTime) override external payable onlyExecutor 
        returns(uint256 depositId) { 

        // transfer nft to this contract
        _transferNFTs(nft, user, address(this), tokenIds, amounts);    

        // store deposit record
        _depositIds.increment();
        depositId = _depositIds.current();

        deposits[msg.sender][depositId] = DepositNFT(user, nft, tokenIds, amounts, endTime);
        
        emit Deposit(msg.sender, depositId, user, nft, tokenIds, amounts, endTime);   
    }

    function withdraw(uint256 depositId, address to) override external onlyExecutor {

        require(deposits[msg.sender][depositId].tokenIds.length > 0, "Invalid depositId");

        address nft = deposits[msg.sender][depositId].nftContract;
        uint256[] memory tokenIds = deposits[msg.sender][depositId].tokenIds;
        uint256[] memory amounts = deposits[msg.sender][depositId].amounts;

        // update storage
        delete deposits[msg.sender][depositId];

        // transfer out nft
        _transferNFTs(nft, address(this), to, tokenIds, amounts);

        emit Withdraw(msg.sender, depositId, to, nft, tokenIds, amounts);   
    }


    // ============ Internal functions ============

    /**
     * @notice batch transfer NFTs (seller/winner <-> protocol)
     * @param nft NFT contract address
     * @param from sender
     * @param to reciever
     * @param tokenIds tokenId array
     * @param amounts amounts array (ERC721 can be null)
     */
    function _transferNFTs(address nft, address from, address to, uint256[] memory tokenIds, uint256[] memory amounts) internal
    {
        require(nft != from && from != to, "Invalid address");

        if (IERC165(nft).supportsInterface(ID_ERC721)) {
            // transfer ERC721
            for (uint256 i = 0; i < tokenIds.length; i++) {
                IERC721(nft).transferFrom(from, to, tokenIds[i]);
            }
        } else if (IERC165(nft).supportsInterface(ID_ERC1155)) {
            // transfer ERC1155
            require(tokenIds.length == amounts.length, "Invalid ids & amounts");
            IERC1155(nft).safeBatchTransferFrom(from, to, tokenIds, amounts, "");
        } 
        else {
            revert("Unsupport NFT");
        }
    }

    
    // ============ only Owner ============

    /**
     * @notice for enmergency case
     * for user to redeem
     * in case of cross chain withdraw suck nft, enable to redeem back to seller nft after endTime
    */
    function redeem(address executor, uint256 depositId, address to) override external onlyOwner {
        
        require(deposits[executor][depositId].tokenIds.length > 0, "Invalid depositId");
        require(block.timestamp > deposits[executor][depositId].endTime, "Not time to redeem");
        require(deposits[executor][depositId].user == to , "Invalid redeem to");

        address nft = deposits[executor][depositId].nftContract;
        uint256[] memory tokenIds = deposits[executor][depositId].tokenIds;
        uint256[] memory amounts = deposits[executor][depositId].amounts;

        // update storage
        delete deposits[executor][depositId];

        // transfer back nft to user
        _transferNFTs(nft, address(this), to, tokenIds, amounts);

        emit Redeem(msg.sender, depositId, to, nft, tokenIds, amounts);   
    }


    //  ============ onlyOwner  functions  ============

    /**
    @notice set operator
     */
    function setExecutor(address executor) external onlyOwner {
        executors[executor] = true;
    }
} 