//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IERC20.sol";
import "./ChainlinkClient.sol";
import "./LinkTokenInterface.sol";
import "./LCNFT.sol";

contract LCMarketPlace is ChainlinkClient {
    using Chainlink for Chainlink.Request;
    
    uint256 constant private ORACLE_PAYMENT = 1 * LINK_DIVISIBILITY;
    LinkTokenInterface internal LinkToken;
    
    struct orderDetails {
        uint256 tokenId;
        address buyer;
        address seller;
        uint256 totalPrice;
        uint256 qty;
        uint256 time;
    }
    mapping(address => orderDetails[]) public orderLogs;
    mapping(bytes32 => bool) public isWhitelisted;
    address public contractOwner;

    struct onSaleItem {
        uint256 tokenId;
        address owner;
        bool sold;
        bool onSale;
        uint256 timeOnsale;
        uint256 price;
        uint256 qty;
    }
    mapping(uint256 => onSaleItem) public saleItems;


    uint256 public deployTime;
    LCNFT public nft;

    constructor(address nftCreation) {
        nft = LCNFT(nftCreation);
        contractOwner = msg.sender;
        deployTime = block.timestamp;
        
        // This will change as per network. (Different for both chain IDs)
        setChainlinkToken(0x514910771AF9Ca656af840dff83E8264EcF986CA);
        LinkToken = LinkTokenInterface(0x514910771AF9Ca656af840dff83E8264EcF986CA);
    }
    
    event RequestWhitelist(
        bytes32 indexed requestId,
        uint256 indexed data 
    );

    event PutTokenOnSale(
        uint256 tokenId,
        uint256 price,
        uint256 qty,
        address tokenOwner
    );
    event BuyToken(
        uint256 tokenId,
        uint256 qty,
        address buyer,
        uint256 tokenPrice,
        address tokenOwner,
        orderDetails newOrder
    );

    event RemoveTokenFromSale(
        uint256 tokenId,
        address tokenOwner,
        bool isOnSale
    );
    event ChangeSaleTokenStatus(uint256 tokenId, bool isSold);

    modifier checkTokenOwner(uint256 tokenId) {
        require(
            nft.balanceOf(msg.sender, tokenId) != 0,
            "You donot own the token"
        );
        _;
    }
    modifier onlyOwner() {
        require(
            msg.sender == contractOwner,
            "You are not permitted to call this function"
        );
        _;
    }
    modifier tokenNotSoldAlready(uint256 tokenId) {
        require(!saleItems[tokenId].sold, "Token is already sold!");
        _;
    }
    
    function addressToString(address _address) public pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(address(_address))));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = '0';
        _string[1] = 'x';
        for(uint i = 0; i < 20; i++) {
            _string[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }

    
    function requestWhitelistForUser() public
    {
        
        bytes32 specId = "06f27392951947a6b1e89d7d16f26340"; //Mainnet oracle specId
        address _oracle = 0x466Dd67a459CAbE83d6Cc3D86B2E44A056c14a34; //Mainnet oracle address
        
        Chainlink.Request memory req = buildChainlinkRequest(specId, address(this), this.fulfillBytes.selector);
        
        string memory url1 = "https://node.liquidcraft.io/api/v1/user/getAddress/"; //Production Server URL
        string memory url2 =  addressToString(msg.sender);
        
        string memory query = string(abi.encodePacked(url1, url2));
        
        req.add("get", query);

        string[] memory path = new string[](1);
        path[0] = "data";
        
        req.addStringArray("path", path);
        sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
    }
    
    function fulfillBytes(bytes32 _requestId, uint256 _data) public recordChainlinkFulfillment(_requestId)
    {
        emit RequestWhitelist(_requestId, _data);
        
        if(_data == 1) isWhitelisted[_requestId] = true;
        else isWhitelisted[_requestId] = false;
    }
    
    function withdraw(address _recipient) external onlyOwner {
        LinkToken.transfer(_recipient, LinkToken.balanceOf(address(this)));
    }
    
    
    function removeTokenFromSale(uint256 tokenId) external returns (bool) {
        require(
            nft.balanceOf(msg.sender, tokenId) != 0,
            "You donot own the token"
        );
        saleItems[tokenId].onSale = false;
        emit RemoveTokenFromSale(tokenId, msg.sender, false);
        //from node side =>nft.setApprovalForAll(address(this),false);
        return true;
    }

    function changeSaleTokenStatus(uint256 tokenId, bool status)
        internal
        tokenNotSoldAlready(tokenId)
        returns (bool)
    {
        require(
            nft.balanceOf(msg.sender, tokenId) != 0,
            "You donot own the token so you cannot change the status"
        );
        saleItems[tokenId].sold = status;
        emit ChangeSaleTokenStatus(tokenId, status);
        return true;
    }

    function putTokenOnSale(
        uint256 tokenId,
        uint256 _qty,
        uint256 value
    ) external checkTokenOwner(tokenId) returns (bool) {
        require(
            nft.balanceOf(msg.sender, tokenId) >= _qty,
            "You have insufficient token qty."
        );

        onSaleItem memory newItem = onSaleItem({
            tokenId: tokenId,
            owner: msg.sender,
            sold: false,
            onSale: true,
            timeOnsale: block.timestamp,
            price: value,
            qty: _qty
        });
        saleItems[tokenId] = newItem;
        emit PutTokenOnSale(tokenId, value, _qty, msg.sender);
        return true;
    }

    function buyToken(uint256 tokenId, uint256 _qty, bytes32 _requestId)
        external
        payable
        tokenNotSoldAlready(tokenId)
    {
        
        if(doesWhitelistPeriodExist() == true) {
            require(isWhitelisted[_requestId], "caller is not whitelisted.");
            delete isWhitelisted[_requestId];
        }
        
        onSaleItem storage saleItem = saleItems[tokenId];
        // check wether tokens is in buyable list or not!
        require(saleItem.timeOnsale != 0, "Token is not buyable!");

        // onSaleItem storage item = saleItem;
        require(!saleItem.sold, "Token is already sold!");
        require(saleItem.onSale, "Token is not on sale!");
        require(
            nft.isApprovedForAll(saleItem.owner, address(this)),
            "Token is not approved to tranfer!"
        );
        require(
            nft.balanceOf(msg.sender, tokenId) + _qty <= 10,
            "Purchase limit exceeded."
        );

        orderDetails memory newOrder = orderDetails({
            tokenId: tokenId,
            buyer: msg.sender,
            seller: saleItem.owner,
            totalPrice: saleItem.price,
            qty: _qty,
            time: block.timestamp
        });
        orderLogs[msg.sender].push(newOrder);

        require(msg.value >= saleItem.price * _qty, "Insufficient ether value");

        address creator = nft.getCreator(tokenId);
        uint256 royalty = nft.getRoyalty(tokenId, creator);

        uint256 tokenSendToCreator = (msg.value * royalty) / 100;
        uint256 tokenSendToSeller = (msg.value - tokenSendToCreator);
        
        emit BuyToken(
            tokenId,
            _qty,
            msg.sender,
            saleItem.price,
            saleItem.owner,
            newOrder
        );
        
        saleItem.qty -= _qty;

        (
            bool isSendToSeller, /*bytes memory data*/

        ) = payable(saleItem.owner).call{value: tokenSendToSeller}("");
        require(isSendToSeller, "Send to seller failed");
        (
            bool isSendToCreator, /*bytes memory data*/

        ) = payable(creator).call{value: tokenSendToCreator}("");
        require(isSendToCreator, "Send to creator failed");

        nft.safeTransferFrom(saleItem.owner, msg.sender, tokenId, _qty, "");

    }

    // Time will change as per your requirements.
    function doesWhitelistPeriodExist() public view returns (bool) {
        if (block.timestamp > 1637697600) return false;
        else return true;
    }
}
