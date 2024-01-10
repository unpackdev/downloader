// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./MerkleProof.sol";
import "./IERC20.sol";
import "./IERC1155Receiver.sol";
import "./EnumerableSet.sol";


import "./IERC1155Tradable.sol";


contract MarketLite is AccessControl, IERC1155Receiver {

    using EnumerableSet for EnumerableSet.UintSet;

    event CreateTokenAndSale(address indexed sender, uint128 amount, uint128 deadline, uint256 price);
    event MintTokenAndSale(address indexed sender, uint128 amount, uint128 deadline, uint256 price);
    event UseTokenAndSale(address indexed sender, uint128 amount, uint128 deadline, uint256 price);
    event Redeem(address indexed account, uint256 tokenId, uint256 price);

    IERC20 private _peaceToken;
    IERC1155Tradable private _erc1155;
    EnumerableSet.UintSet private tokenIds;

    /// @notice if deadline is 0, tokens can be bought until they run out
    struct TokenSale {
        uint256 price;
        uint128 deadline;
        bytes32 merkleRoot;
        address[] buys;
    }

    bool private inRedeem;

    /// @dev in the form of tokenId => (account => bool)
    mapping(uint256 => mapping(address => bool)) private _userHasClaimed;

    /// @dev in the form of tokenId => TokenSale
    mapping(uint256 => TokenSale) private _tokenSales;

    /// @dev keeps track of who was in charge of creating a token
    mapping (uint256 => address) private _creators;
 
    bytes32 private constant SELLER_ROLE = keccak256("SELLER_ROLE");

    modifier lockRedeem{
        inRedeem = true;
        _;
        inRedeem = false;
    }

    constructor(address erc1155, address peaceToken, address admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(SELLER_ROLE, admin);
        _erc1155 = IERC1155Tradable(erc1155);
        _peaceToken = IERC20(peaceToken);
    }

    /***********************************|
    |    DEFAULT_ADMIN_ROLE Functions   |
    |__________________________________*/
    function setPeaceToken(address peaceToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _peaceToken = IERC20(peaceToken);
    }

    function setERC1155(address erc1155) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _erc1155 = IERC1155Tradable(erc1155);
    }

    function updateMerkleRoot(uint256 tokenId, bytes32 merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tokenIds.contains(tokenId), "No sell for tokenId");
        _tokenSales[tokenId].merkleRoot = merkleRoot;
    }

    function updatePrice(uint256 tokenId, uint256 price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tokenIds.contains(tokenId), "No sell for tokenId");
        require(price > 0, "Price is 0");
        _tokenSales[tokenId].price = price;
    }

    function updateDeadline(uint256 tokenId, uint128 deadline) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tokenIds.contains(tokenId), "No sell for tokenId");
        _tokenSales[tokenId].deadline = deadline;
    }

    function withdrawERC1155(uint256 tokenId, uint128 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _erc1155.safeTransferFrom(address(this), _msgSender(), tokenId, amount, "");
    }

    function withdrawERC20(address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(token).transfer(_msgSender(), IERC20(token).balanceOf(address(this)));
    }

    function withdrawOtherERC1155(address token, uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(token != address(_erc1155), "Call withdrawERC1155 instead");
        IERC1155(token).safeTransferFrom(address(this), _msgSender(), tokenId, IERC1155(token).balanceOf(address(this), tokenId), "");
    }

    function withdrawETH() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(_msgSender()).transfer(address(this).balance);
    }

    /***********************************|
    |    SELLER_ROLE Functions          |
    |__________________________________*/
    function createNextTokenAndSale(uint128 amount, uint128 deadline, uint256 price, bytes32 merkleRoot) external onlyRole(SELLER_ROLE) {
        uint256 tokenId = _erc1155.create(address(this), amount);

        // if erc1155 contract allows creation, this contract becomes to be a creator in the erc1155 contract
        // so we have to give sender the ability to change erc1155 token contract creator value
        _creators[tokenId] = _msgSender();

        _setNewSale(tokenId, price, deadline, merkleRoot);

        emit CreateTokenAndSale(_msgSender(), amount, deadline, price);
    }

    function mintTokenAndSale(uint256 tokenId, uint128 amount, uint128 deadline, uint256 price, bytes32 merkleRoot) external onlyRole(SELLER_ROLE) {
        _erc1155.mint(address(this), tokenId, amount);

        if(tokenIds.contains(tokenId)) _updateSell(tokenId, price, deadline, merkleRoot);
        else _setNewSale(tokenId, price, deadline, merkleRoot);

        // if erc1155 contract allows minting is because this contract is set as creator in the erc1155 contract
        // so we have to give sender the ability to change erc1155 token contract creator value
        _creators[tokenId] = _msgSender();

        emit MintTokenAndSale(_msgSender(), amount, deadline, price);
    }

    function useTokenAndSale(uint256 tokenId, uint128 deadline, uint256 price, bytes32 merkleRoot) external onlyRole(SELLER_ROLE) {
        require(!tokenIds.contains(tokenId), "Sale already created");
        uint128 balance = uint128(_erc1155.balanceOf(address(this), tokenId));
        require(balance > 0, "no token balance");
        _setNewSale(tokenId, price, deadline, merkleRoot);
        emit UseTokenAndSale(_msgSender(), balance, deadline, price);
    }

    function _setNewSale(uint256 tokenId, uint256 price, uint128 deadline, bytes32 merkleRoot) private {
        require(deadline == 0 || deadline > block.timestamp, "wrong deadline");
        require(price > 0, "Price is 0");
        TokenSale memory tokenSale = TokenSale(price, deadline, merkleRoot, new address[](0));
        _tokenSales[tokenId] = tokenSale;
        tokenIds.add(tokenId);
    }

    function _updateSell(uint256 tokenId, uint256 price, uint128 deadline, bytes32 merkleRoot) private {
        require(deadline == 0 || deadline > block.timestamp, "wrong deadline");
        require(price > 0, "Price is 0");
        _tokenSales[tokenId] = TokenSale(
            price, 
            deadline, 
            merkleRoot == "" ? _tokenSales[tokenId].merkleRoot : merkleRoot,
            _tokenSales[tokenId].buys
        );
    }

    /***********************************|
    |         Getter Functions          |
    |__________________________________*/
    function getPeaceToken() external view returns (address) {
        return address(_peaceToken);
    }

    function getERC1155() external view returns (address) {
        return address(_erc1155);
    }

    function getTokensInSale() external view returns (uint256[] memory) {
        return tokenIds.values();
    }

    function getTokenSale(uint128 tokenId) external view returns(TokenSale memory) {
        return _tokenSales[tokenId];
    }

    function hasUserClaimed(uint256 tokenId, address account) external view returns (bool) {
        return _userHasClaimed[tokenId][account];
    }

    function getTokenCreator(uint256 tokenId) external view returns (address) {
        return _creators[tokenId];
    }


    /***********************************|
    |         Creator Functions         |
    |__________________________________*/

    /**
    * @notice gives the ability to change creator's address in _erc1155
    * @dev Change the creator address for given tokens
    * @param _to   Address of the new creator
    * @param _id  Token ID to change creator
    */
    function setCreator(address _to, uint256 _id) public {
        require(_creators[_id] ==_msgSender(), "Only Creator");
        _creators[_id] = _to;
        uint256[] memory ids= new uint[](1);
        ids[0] = _id;
        _erc1155.setCreator(_to, ids);
    }

    /***********************************|
    |           Redeem Functions        |
    |__________________________________*/
    function redeem(uint256 tokenId, bytes32[] calldata proof) external lockRedeem {
        TokenSale storage tokenSale = _tokenSales[tokenId];
        address account = _msgSender();

        if(tokenSale.merkleRoot != "") {
            bytes32 leaf = keccak256(abi.encodePacked(account));
            require(_verify(tokenId, leaf, proof), "Invalid merkle proof");
        }
        
        require(!_userHasClaimed[tokenId][account], "User has already bought");
        require(tokenSale.deadline == 0 || tokenSale.deadline > block.timestamp, "Deadline ended");

        _userHasClaimed[tokenId][account] = true;
        tokenSale.buys.push(account);
        uint256 price = tokenSale.price;
        _peaceToken.transferFrom(account, address(this), price);
        _erc1155.safeTransferFrom(address(this), account, tokenId, 1, "");
        emit Redeem(account, tokenId, price);
    }

    function _verify(uint256 tokenId, bytes32 leaf, bytes32[] memory proof) private view returns (bool) {
        return MerkleProof.verify(proof, _tokenSales[tokenId].merkleRoot, leaf);
    }

    /**********Support for TokenERC1155 when transfering a token to this contract */
    function onERC1155Received(
        address /* operator */,
        address /* from */,
        uint256 /* id */,
        uint256 /* value */,
        bytes calldata /* data */
    ) external override pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    } 

    function onERC1155BatchReceived(
        address /* operator */,
        address /* from */,
        uint256[] calldata /* ids */,
        uint256[] calldata /* values */,
        bytes calldata /* data */
    ) external override pure returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    /**********Support for receiving ETH */
    receive() external payable {}

}