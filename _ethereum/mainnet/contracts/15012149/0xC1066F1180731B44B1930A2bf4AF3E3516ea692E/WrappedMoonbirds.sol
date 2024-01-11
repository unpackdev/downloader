// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721EnumerableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";

interface MoonbirdsInterface{
    
    function toggleNesting(uint256[] calldata tokenIds) external;

    function safeTransferWhileNesting(address from, address to, uint256 tokenId) external;

    function nestingPeriod(uint256 tokenId) external view returns (bool nesting, uint256 current, uint256 total);
}

interface XNFTInterface{
    
    struct Order{
        address pledger;
        address collection;
        uint256 tokenId;
        uint256 nftType;
        bool isWithdraw;
    }

    struct LiquidatedOrder{
        address liquidator;
        uint256 liquidatedPrice;
        address xToken;
        uint256 liquidatedStartTime;
        address auctionAccount;
        uint256 auctionPrice;
        bool isPledgeRedeem;
        address auctionWinner;
    }

    struct CollectionNFT{
        bool isCollectionWhiteList;
        uint256 auctionDuration;
        uint256 redeemProtection;
        uint256 increasingMin;
    }

    function allOrders(uint256 orderId) external view returns(Order memory order);

    function allLiquidatedOrder(uint256 orderId) external view returns(LiquidatedOrder memory liquidatedOrder);

    function collectionWhiteList(address collection) external view returns(CollectionNFT memory collectionNFT);

    function isOrderLiquidated(uint256 orderId) external view returns(bool);

    function auctionDurationOverAll() external view returns(uint256);
}

interface IMerkleDistributor {
    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index, address airDropToken) external view returns (bool);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof, address airDropToken) external;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account, uint256 amount);
}

contract WrappedMoonbirds is IMerkleDistributor, IERC721ReceiverUpgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable, IERC1155ReceiverUpgradeable{

    using StringsUpgradeable for uint256;

    bool public mintPause;
    bool public redeemPause;
    
    address public moonbirds;
    address public xNFT;

    string public baseURI;

    // airdropToken => ercType
    mapping(address => uint256) tokenToErcMap;
    mapping(address => bool) public tokenMap;
    mapping(address => bytes32) public merkleRootMap;
    mapping(address => mapping(uint256 => uint256)) private claimedBitMap;

    function initialize(address _moonbirds, address _xNFT) external initializer{
        moonbirds = _moonbirds;
        xNFT = _xNFT;

        __ERC721_init("WrappedMoonbirds", "WRAPPEDMOONBIRDS");
        __Ownable_init();
    }

    modifier whenMintNotPaused() {
        require(!mintPause, "Mint Pausable: paused");
        _;
    }

    modifier whenRedeemNotPaused() {
        require(!redeemPause, "Redeem Pausable: paused");
        _;
    }

    function setMoonbirds(address _moonbirds) external onlyOwner{
        moonbirds = _moonbirds;
    }

    function setXNFT(address _xNFT) external onlyOwner{
        xNFT = _xNFT;
    }

    function setMintPause(bool _mintPause) external onlyOwner{
        mintPause = _mintPause;
    }

    function setRedeemPause(bool _redeemPause) external onlyOwner{
        redeemPause = _redeemPause;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner{
        baseURI = _baseURI;
    }

    function setTokenToErcMap(address airDropToken, uint256 ercType) external onlyOwner{
        tokenToErcMap[airDropToken] = ercType;
    }

    function setTokenMap(address airDropToken, bool isSupport) external onlyOwner{
        tokenMap[airDropToken] = isSupport;
    }

    function setMerkleRootMap(address airDropToken, bytes32 merkleRoot) external onlyOwner{
        merkleRootMap[airDropToken] = merkleRoot;
    }

    function claim(address airdopContract, bytes memory byteCode) external onlyOwner{
        (bool result, ) = airdopContract.call(byteCode);
        require(result, "claim error");
    }

    function mint(address to, uint256 tokenId) internal whenMintNotPaused{
        _safeMint(to, tokenId);
    }

    function redeemMoonbirds(uint256 tokenId) external whenRedeemNotPaused{
        require(ownerOf(tokenId) == msg.sender, "you are not the owner");
        MoonbirdsInterface mb = MoonbirdsInterface(moonbirds);
        (bool nesting, , ) = mb.nestingPeriod(tokenId);
        if(nesting){
            mb.safeTransferWhileNesting(address(this), msg.sender, tokenId);
        }else{
            IERC721Upgradeable(moonbirds).safeTransferFrom(address(this), msg.sender, tokenId);
        }
        _burn(tokenId);
    }

    function toggleNesting(uint256 tokenId) external{
        require(ownerOf(tokenId) == msg.sender, "you are not the owner");
        MoonbirdsInterface moonbirdsInterface = MoonbirdsInterface(moonbirds);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        moonbirdsInterface.toggleNesting(tokenIds);
    }

    function pledgingToggleNesting(uint256 orderId) external{
        XNFTInterface xNFTInterface = XNFTInterface(xNFT);
        XNFTInterface.Order memory order = xNFTInterface.allOrders(orderId);
        require(!order.isWithdraw, "order has been withdrawn");
        address receiver;
        if(xNFTInterface.isOrderLiquidated(orderId)){
            XNFTInterface.LiquidatedOrder memory liquidatedOrder =  xNFTInterface.allLiquidatedOrder(orderId);
            XNFTInterface.CollectionNFT memory collectionNFT = xNFTInterface.collectionWhiteList(order.collection);
            uint256 auctionDuration;
            if(collectionNFT.auctionDuration != 0){
                auctionDuration = collectionNFT.auctionDuration;
            }else{
                auctionDuration = xNFTInterface.auctionDurationOverAll();
            }
            if(block.timestamp > liquidatedOrder.liquidatedStartTime + auctionDuration){
                if(liquidatedOrder.auctionAccount == address(0)){
                    receiver = liquidatedOrder.liquidator;
                }else{
                    receiver = liquidatedOrder.auctionAccount;
                }
            }else{
                receiver = order.pledger;
            }
        }else{
            receiver = order.pledger;
        }
        require(msg.sender == receiver, "you do not have permission to operate");
        MoonbirdsInterface moonbirdsInterface = MoonbirdsInterface(moonbirds);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = order.tokenId;
        moonbirdsInterface.toggleNesting(tokenIds);
    }

    function exist(uint256 tokenId) external view returns(bool){
        return _exists(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function isClaimed(uint256 index, address airDropToken) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[airDropToken][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index, address airDropToken) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[airDropToken][claimedWordIndex] = claimedBitMap[airDropToken][claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof, address airDropToken) external override {
        require(tokenMap[airDropToken], "no support");
        require(tokenToErcMap[airDropToken] != 0 );
        require(msg.sender == account, "msg.sender is not account");
        require(!isClaimed(index, airDropToken), 'Drop already claimed');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProofUpgradeable.verify(merkleProof, merkleRootMap[airDropToken], node), 'Invalid proof');

        // Mark it claimed and send the token.
        _setClaimed(index, airDropToken);
        if(tokenToErcMap[airDropToken] == 20){
            require(IERC20Upgradeable(airDropToken).transfer(account, amount), 'ERC20 Transfer failed');
        }else if(tokenToErcMap[airDropToken] == 721){
            IERC721EnumerableUpgradeable(airDropToken).safeTransferFrom(address(this), account, amount);
        }else if(tokenToErcMap[airDropToken] == 1155){
            IERC1155Upgradeable(airDropToken).safeTransferFrom(address(this), account, amount, 1, "");
        }else{
            revert("ercType is error");
        }

        emit Claimed(index, account, amount);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4){
        if(msg.sender == moonbirds){
            if (!_exists(tokenId)){
                mint(from, tokenId);
            }
        }
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external override pure returns (bytes4){
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived( address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external override pure returns(bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}