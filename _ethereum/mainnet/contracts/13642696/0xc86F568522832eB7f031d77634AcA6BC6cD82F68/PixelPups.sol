// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./console.sol";

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";

import "./ECDSA.sol";

contract PixelPups is ERC721Enumerable, Ownable{

    IERC1155 public OPENSEA_STORE = IERC1155(0x495f947276749Ce646f68AC8c248420045cb7b5e);
    //IERC1155 public OPENSEA_STORE = IERC1155(0x88B48F654c30e99bc2e4A1559b4Dcf1aD93FA656);
    mapping(uint256 => bool) public _creators;

    string public baseTokenURI;

    uint256 public numSoldPub = 0;
    uint256 public numSoldWL = 0;
    uint256 public numBred = 0;

    bool public onSale = false;
    bool public canBreed = false;

    //Presale
    address public _signerAddress = 0xF6bA99F2E6ce96B74d4df667C01c5ed2EF249be2;

    bool public onSaleWhitelist = false;
    mapping(address => uint256) public mintedWL;

    uint256 public price = 0.03 ether;
    uint256 public priceWL = 0.025 ether;

    uint256 public maxTokensPurchase = 10;

    uint public MAX_PUBLIC_TOKENS = 7150;
    uint public MAX_WL_TOKENS = 350;

    constructor() ERC721("Pixel Pups", "PXLPUP") {
        baseTokenURI = "ipfs://QmVvkfAgZLggNxfEQuSn4jG2vG96ykS8uPc4zvvLCzz9D8/";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function mintWhitelist(uint256 _amount, bytes32 hash, uint8 _signatureV, bytes32 _signatureR, bytes32 _signatureS) public payable {
        require(onSaleWhitelist || msg.sender == owner(), "Whitelist sale must be active");
        require(msg.value >= priceWL * _amount, "Ether value sent is not correct");
        require(numSoldWL + _amount <= MAX_WL_TOKENS , "Purchase would exceed max supply of Tokens");
        require(mintedWL[msg.sender] < 2 || msg.sender == owner(), "Purchase would exceed max tokens for presale");

        address signer = ECDSA.recover(hash, _signatureV,  _signatureR,  _signatureS);

        require(signer == _signerAddress, "Invalid signature");
        
        for(uint i; i < _amount; i++){
            mintedWL[msg.sender]++;
            _safeMint(msg.sender, MAX_PUBLIC_TOKENS + numSoldWL + 1);
            numSoldWL = numSoldWL + 1;
        }
    }

    function mint(uint numberOfTokens) public payable {
        require(onSale || msg.sender == owner(), "Sale must be active to mint");
        require(msg.value >= (price * numberOfTokens), "Ether value sent is not correct");
        require(numberOfTokens <= maxTokensPurchase, "Exceed Max Per");
        require(numSoldPub + numberOfTokens <= MAX_PUBLIC_TOKENS, "Exceed Max Supply");
        
        for(uint i = 0; i < numberOfTokens; i++){
            if(numSoldPub <= MAX_PUBLIC_TOKENS)
            {
                _safeMint(msg.sender, numSoldPub + 1);
                numSoldPub = numSoldPub + 1;
            }
        }
    }

    function breedDoges(uint256 maleTokenID, uint256 femaleTokenID) public{
        require(canBreed, 'You cannot breed yet!');
        require(isValidDoge(maleTokenID), "Non Valid Male Doge");
        require(isValidDoge(femaleTokenID), "Non Valid Female Doge");

        OPENSEA_STORE.safeTransferFrom(msg.sender, address(this), maleTokenID, 1, "");
        OPENSEA_STORE.safeTransferFrom(msg.sender, address(this), femaleTokenID, 1, "");

        _safeMint(msg.sender, MAX_WL_TOKENS + MAX_PUBLIC_TOKENS + numBred + 1);
        numBred = numBred + 1;        
    }

    //Read Functions
    function isValidDoge(uint256 _id) view internal returns(bool) {
        uint256 creator = (_id >> 96);
        return _creators[creator];
	}

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }

    //Setter Functions
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function changeOnSale() public onlyOwner() {
        onSale = !onSale;
    }

    function changeOnSaleWhitelist() public onlyOwner(){
        onSaleWhitelist = !onSaleWhitelist;
    }

    function changeCanBreed() public onlyOwner(){
        canBreed = !canBreed;
    }

    function setPrice(uint256 _price) public onlyOwner(){
        price = _price;
    }

    function setOpensea(address _opensea) public onlyOwner(){
        OPENSEA_STORE = IERC1155(_opensea);
    }

    function _addCreator(address _toAdd) public onlyOwner(){
        uint256 newCreator = uint256(uint160(_toAdd));
        _creators[newCreator] = true;
    }

    //Utilities
    function withdrawAll() public onlyOwner() {
        require(payable(msg.sender).send(address(this).balance));
    }

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4) {
		require(msg.sender == address(OPENSEA_STORE), "Doge: not opensea asset");
		return IERC1155Receiver.onERC1155Received.selector;
	}
}