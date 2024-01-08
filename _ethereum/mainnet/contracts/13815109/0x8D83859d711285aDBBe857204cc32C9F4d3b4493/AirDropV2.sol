// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.12;

import "./ERC721URIStorageUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./SignatureCheckerUpgradeable.sol";

contract AirDropV2 is ERC721URIStorageUpgradeable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;

    // array of token ids
    uint256[] private tokenIds;

    // count of tokens
    uint256 public tokenCounter;

    // array of token ids
    string[] private tokenUris;

    //emit token id and uri
    event tokenDetails(uint256 IDs, string URIs);

    // mapping user address with status
    mapping(address => bool) public holders;

    // emit when new holder is added
    event AddHolder(address user, bool status);

    // emit when Jerry is purchased
    event buyJerry(
        address indexed sellerAddress,     // sender address
        address indexed buyerAddress,       // buyer address
        uint256 indexed tokenId,           // purchase token id
        uint256 price                      // price of token id
    );

    // address of smart contract community
    address SmartContractCommunity;

    // address of SKT wallet
    address feeSKTWallet;

    // purchase mode
    bool private buyONorOFFstatus;

    // fee margin
    uint256 feeMargin;

    // structure for order
    struct Order{
        address buyer;
        address owner; 
        uint256 token_id;
        string tokenUri;
        uint256 expiryTimestamp;
        uint256 price;
        bytes32 signKey;
        bytes32 signature;
    }
  
    /**
     * @dev adds 484 users at one time.
     *
     * Requirements
     * - array must have 484 address.
     * - only owner must call this method.
     *
     * Emits a {AddHolder} event.
    */
    
    function addUserStatus(address[484] calldata _users, bool _status) onlyOwner external {
        for(uint i = 0; i < 484; i++){
            holders[_users[i]] = _status;
            emit AddHolder(_users[i], _status);        
        }
    }

    /**
     * @dev checks where user address can use free mint.
     *
     * Returns
     * - status in boolean.
    */

    function checkUserStatus(address _users) external view returns(bool){
        require(_users != address(0x00), "$MONSTERBUDS: Not applied to zero address");
        return holders[_users];
    }

    /**
     * @dev this method concate the string with token id to create new Uri.
     *
     * Returns
     * - status in boolean.
    */

    function uriConcate(string memory _before, uint256 _token_id, string memory _after) private pure returns (string memory){
        string memory token_uri = string( abi.encodePacked(_before, _token_id.toString(), _after));
        return token_uri;
    }

    /**
     * @dev mint new air drop nft and send to recipients. 
     *
     * Returns
     * - token id.
    */

    function airDropNft() external returns(uint256){
        require(holders[msg.sender] == true, "$MONSTERBUDS: User has already claimed or not applicable for Air Drop Nft");

        uint256 newItemId;
        string memory uri;
        holders[msg.sender] = false;
                
        newItemId = tokenCounter;
        _safeMint(msg.sender, newItemId); // mint new seed
        uri = uriConcate("https://liveassets.monsterbuds.io/Jerry-token-uri/JerryNFT-", newItemId, ".json"); 
        _setTokenURI(newItemId, uri); // set uri to new seed
        tokenCounter = tokenCounter + 1;

        emit tokenDetails(newItemId, uri);
        return newItemId;
    }

    /**
     * @dev It destroy the contract and returns all balance of this contract to owner.
     *
     * Returns
     * - only owner can call this method.
    */ 

    function selfDestruct() 
        public 
        onlyOwner{
    
        payable(owner()).transfer(address(this).balance);
        //selfdestruct(payable(address(this)));
    }

    /**
     * @dev calculates the 2.5 percent fees
    */

    function feeCalulation(uint256 _totalPrice) private view returns (uint256) {
        uint256 fee = feeMargin * _totalPrice;
        uint256 fees = fee / 1000;
        return fees;
    }


    /**
     * @dev sets the status of Buy Tokens function.
    */

    function updateBuyStatusAndFeeMargin(bool _status, uint256 _feeMargin) external onlyOwner returns (bool){
        buyONorOFFstatus = _status;
        feeMargin = _feeMargin;
        return true;
    }

    /**
     * @dev updates the wallets
    */

    function updateWallets(address payable _smartContractCommunity, address payable _sktWallet) external onlyOwner returns (bool){
        require(_smartContractCommunity != address(0) && _sktWallet != address(0), "$MONSTERBUDS: cannot be zero address");
        SmartContractCommunity = _smartContractCommunity; // update commuinty wallet
        feeSKTWallet = _sktWallet;
        return true;
    }

    /**
     * @dev matches the price and order
     * 
     * @param order structure about token order details.
     *
     * Returns
     * - bool.
     *
     * Emits a {buyTransfer} event.
    */

    function orderCheck(Order memory order) private returns(bool){
        address payable owner = payable(ownerOf(order.token_id));
        bytes32 hashS = keccak256(abi.encodePacked(msg.sender));
        bytes32 hashR = keccak256(abi.encodePacked(owner));
        bytes32 hashT = keccak256(abi.encodePacked(order.price));
        bytes32 hashV = keccak256(abi.encodePacked(order.token_id));
        bytes32 hashP = keccak256(abi.encodePacked(order.expiryTimestamp));
        bytes32 sign  = keccak256(abi.encodePacked(hashV, hashP, hashT, hashR, hashS));

        require(order.expiryTimestamp >= block.timestamp, "MONSTERBUDS: expired time");
        require(sign == order.signKey, "$MONSTERBUDS: ERROR");
        require(order.price == msg.value, "MONSTERBUDS: Price is incorrect");

        uint256 feeAmount = feeCalulation(msg.value);
        payable(feeSKTWallet).transfer(feeAmount); // transfer 5% ethers of msg.value to skt fee wallet
        payable(SmartContractCommunity).transfer(feeAmount); // transfer 5% ethers of msg.value to commuinty

        uint256 remainAmount = msg.value - (feeAmount + feeAmount);
        payable(order.owner).transfer(remainAmount); // transfer remaining 90% ethers of msg.value to owner of token
        _transfer(order.owner, msg.sender, order.token_id); // transfer the ownership of token to buyer

        emit buyJerry(order.owner, msg.sender, order.token_id, msg.value);
        return true;
    }

    /**
     * @dev user can purchase the token.
     * 
     * @param order structure about token order details.
     * @param signature signature to verify. 
     *
     * Returns
     * - bool.
    */

    function purchase(Order memory order, bytes memory signature) external payable returns(bool){

        require(buyONorOFFstatus == true, "$MONSTERBUDS: Marketplace for buying is closed");
        bool status = SignatureCheckerUpgradeable.isValidSignatureNow(owner(), order.signature, signature);
        require(status == true, "$MONSTERBUDS: cannot purchase the token");
        orderCheck(order);
        return true;
    }
}