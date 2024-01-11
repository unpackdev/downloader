// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.12;

import "./StringsUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SignatureCheckerUpgradeable.sol";

contract PackWoodERC1155V1 is ERC1155Upgradeable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;
    
    // token count
    uint256 public tokenCounter;

    // buy price for sereum
    uint256 private tokenPrice;
    
    // before uri
    string internal _before;

    // after uri
    string internal _after;

    // child address
    address public childAddress;

    // name
    string public name;

    // symbol
    string public symbol;

    // smart contract community address
    address public SmartContractCommunity;

    // commuity fee
    uint256 internal commuintyFee;

    // order data
    struct Order{
        uint256[3] tokenIds;
        uint256[3] random;
        bytes32 data;
        bytes32 signKey;
    }
    
    // airdrop order
    struct AirdropOrder{
        address user;
        uint256 tokenId;
    }

    /**
     * @dev Emitted when user buys the sereum.
    */

    event buyTokenDetails(address from, address to, uint256 tokenId1, uint256 tokenId2, uint256 tokenId3, uint256 tokenId1Amt, uint256 tokenId2Amt, uint256 tokenId3Amt, uint256 price);
    

    // constructor initialisation section

    function initialize() public initializer {
       __ERC1155_init("https://liveassets.monsterbuds.io/Packwood-serum-uri/{id}-token-uri.json");
       _before = "https://liveassets.monsterbuds.io/Packwood-serum-uri/";
       _after = "-token-uri.json";
       __Ownable_init(msg.sender);

       name = "WTF is this";
       symbol = "BLNT";

       tokenCounter = 0;
       tokenPrice = 78540000000000000;   //0.07854

       SmartContractCommunity = 0x7f62Db798f29a6B074fE6b1B5027d883831cf1D7;
       commuintyFee = 10;
    }

    // modifier
    modifier onlyChild() {
        require(msg.sender == childAddress, "PackWoodERC1155: caller is not child address");
        _;
    }

    /**
     * @dev updates the Child Address.
     * 
     * @param _address updated child address.
     *  
     * Requirements:
     * - only owner can update value.
    */

    function updateChildAddress(address _address) external onlyOwner returns(bool){
        childAddress = _address;
        return true;
    }

    /**
     * @dev updates the community Fee percent.
     * 
     * @param _percent updated child address.
     *  
     * Requirements:
     * - only owner can update value.
    */

    function updateCommunityFee(uint256 _percent) external onlyOwner returns(bool){
        commuintyFee = _percent;
        return true;
    }

    /**
     * @dev fee calaculation.
    */
    function feeCalulation(uint256 _totalPrice) private view returns (uint256) {
        uint256 fee = commuintyFee * _totalPrice; // change commuity fee
        uint256 fees = fee / 100;
        return fees;
    }

    /**
     * @dev updates the skt community wallet Address.
     * 
     * @param nextOwner updated skt community wallet address.
     *  
     * Requirements:
     * - only owner can update value.
    */

    function updateSKTCommunityWallet(address payable nextOwner) external onlyOwner returns (address){
        require(nextOwner != address(0x00), "$PackWoodERC1155: cannot be zero address");
        SmartContractCommunity = nextOwner; // update commuinty wallet
        return SmartContractCommunity;
    }

     /**
     * @dev updates the total price.
     * 
     * @param _num updated price for each copy of token.
     *  
     * Requirements:
     * - only owner can update value.
    */

    function updatePrice(uint256 _num) external onlyOwner returns(bool){
        tokenPrice = _num;
        return true;
    }

    /**
     * @dev updates the default Token URI. 
     *
     * @param before_ token uri before part.
     * @param after_ token uri after part.
     *
     * Requirements:
     * - only owner can update default URI.
    */

    function setTokenUri(string memory before_, string memory after_) external onlyOwner returns(bool){
        _before = before_;
        _after = after_;
        return true;
    }

    /**
     * @dev Token URI. 
     *
     * @param id token uri before part.
     *
     * returns:
     * - token URI.
    */

    function uri(uint256 id) public view virtual override returns (string memory) { 
        return string(abi.encodePacked(_before, StringsUpgradeable.toString(id), _after));
    }


    /**
     * @dev mints the token. 
     *
     * @param _amount token uri before part.
     *
     * Requirements:
     * - only owner can mint.
    */
    function mintToken(uint256 _amount) external onlyOwner returns(uint256){
        tokenCounter += 1;
        _mint(msg.sender, tokenCounter, _amount, "");
        return tokenCounter;
    }
    
    /**
     * @dev burns the token. 
     *
     * @param _account token account.
     * @param _tokenId token id
     *
     * Requirements:
     * - only child contract can call it.
    */

    function burnToken(address _account, uint256 _tokenId) external onlyChild returns(bool){
        _burn(_account , _tokenId, 1);
        return true;
    }
    
    /**
     * @dev buy the token amount. 
     *
     * @param order order for buying token.
     * @param signature signature
     *
     * returns:
     * - bool.
     *
     * Emits a {buyTokenDetails} event.
    */

    function buyToken(Order memory order, bytes memory signature) payable external returns(bool){
        bool status = SignatureCheckerUpgradeable.isValidSignatureNow(owner(), order.signKey, signature);
        require(status == true, "$PackWoodERC1155: cannot purchase the token");
        
        uint256 amount = order.random[0] + order.random[1] + order.random[2];
        require(tokenPrice * amount == msg.value, "PackWoodERC1155: Price is incorrect");

        bytes32 hashT = keccak256(abi.encodePacked(amount, msg.sender));
        bytes32 hashV = keccak256(abi.encodePacked(order.tokenIds[0], order.tokenIds[1], order.tokenIds[2]));
        bytes32 hashTo = keccak256(abi.encodePacked(hashT, hashV));

        require(hashTo == order.data, "PackWoodERC1155: data is incorrect");

        commuintyFee = feeCalulation(msg.value);
        payable(SmartContractCommunity).transfer(commuintyFee);
        payable(owner()).transfer((msg.value - commuintyFee));
    
        for(uint256 i = 0; i < order.tokenIds.length; i++){
            if(order.random[i] > 0){
                _safeTransferFrom(owner(), msg.sender, order.tokenIds[i], order.random[i], "");
            } 
        }

        emit buyTokenDetails(owner(), msg.sender, order.tokenIds[0], order.tokenIds[1], order.tokenIds[2], order.random[0], order.random[1], order.random[2], msg.value);

        return true;
    }

    function whitelistedAirdrop(AirdropOrder[] calldata _airdrop) external onlyOwner returns(bool){
        for(uint256 i = 0; i < _airdrop.length; i++){
            _safeTransferFrom(owner(), _airdrop[i].user, _airdrop[i].tokenId, 1, "");
        }
        return true;
    }

}