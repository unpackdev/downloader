// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";

contract Aether is ERC1155, Ownable {
    
    string public name;
    string public symbol;
    string public contractData;

    uint[] private availableTokens;
    uint private collection1;
    uint[] private collection2;
    uint private collection3;

    uint256 public publicCost = 0 ether;
    uint256 public privateCost = 0 ether;
    string public mintPhase = "closed";
    uint public privateMintAmount = 0;
    uint public publicMintAmount = 0;
    address public tokenAddress;
    address public burnAddress;

    mapping(address => uint) public addressMintedBalance;

    mapping(uint => string) public tokenURI;

    constructor() ERC1155("") {
        name = "Aether Industries";
        symbol = "AET";
    }

    function trade() public payable{
        uint _collection1 = ERC1155(tokenAddress).balanceOf(msg.sender, collection1);
        uint _collection2 = checkCollection2();
        uint _collection3 = ERC1155(tokenAddress).balanceOf(msg.sender, collection3);

        //collection 1 minting
        if((_collection1 + _collection2) > 0){
            _mint(msg.sender, 1, (_collection1 + _collection2), "");
            if(_collection1 > 0){
                ERC1155(tokenAddress).safeTransferFrom(msg.sender, burnAddress, collection1, _collection1, "");
            }
            if(_collection2 > 0){
                burnCollection2();
            }
        }

        //collection 2 minting
        if(_collection3 > 0){
            _mint(msg.sender, 2, _collection3, "");
            ERC1155(tokenAddress).safeTransferFrom(msg.sender, burnAddress, collection3, _collection3, "");
        }
    }

    function checkCollection2() public view returns(uint){
        uint owned = 0;
        for(uint i = 0; i < collection2.length; i++){
            if(ERC1155(tokenAddress).balanceOf(msg.sender, collection2[i]) > 0){
                owned = owned + 1;
            }
        }
        return owned;
    }

    function burnCollection2() public payable {
        for(uint i = 0; i < collection2.length; i++){
            ERC1155(tokenAddress).safeTransferFrom(msg.sender, burnAddress, collection2[i], 1, "");
        }
    }

    function mintBatch(uint[] memory _ids, uint[] memory _amounts) public payable {
        //if mint is closed then give error
        require(keccak256(abi.encodePacked(mintPhase)) != keccak256(abi.encodePacked("closed")), "Mint phase is closed");

        uint mintAmount = 0;
        for(uint i = 0; i < _ids.length; i++){
            require(verifyAvailibility(_ids[i], _amounts[i]), "Token that you wanted to mint is not available");
            mintAmount = mintAmount + _amounts[i];
        }

        //if you are the owner you can mint for free
        if (msg.sender != owner()) {
            uint ownerMintedCount = addressMintedBalance[msg.sender];
            if(keccak256(abi.encodePacked(mintPhase)) == keccak256(abi.encodePacked("private"))){
                require(ownerMintedCount + mintAmount <= privateMintAmount, "max NFT per address exceeded");
                require(msg.value >= privateCost * mintAmount, "insufficient funds");
            }
            if(keccak256(abi.encodePacked(mintPhase)) == keccak256(abi.encodePacked("public"))){
                require(ownerMintedCount + mintAmount <= publicMintAmount, "max NFT per address exceeded");
                require(msg.value >= publicCost * mintAmount, "insufficient funds");
            }
        }

        _mintBatch(msg.sender, _ids, _amounts, "");

        addressMintedBalance[msg.sender] = addressMintedBalance[msg.sender] + mintAmount;

        for(uint i = 0; i < _ids.length; i++){
            availableTokens[_ids[i]] = availableTokens[_ids[i]] - _amounts[i];
        }
    }

    function verifyAvailibility(uint _token, uint _amount) public view returns(bool) {
        if(availableTokens[_token] >= _amount && availableTokens[_token] != 0){
            return true;
        }

        return false;
    }

    function burn(uint _id, uint _amount) external {
        _burn(msg.sender, _id, _amount);
    }

    function burnBatch(uint[] memory _ids, uint[] memory _amounts) external {
        _burnBatch(msg.sender, _ids, _amounts);
    }

    function burnForMint(address _from, uint[] memory _burnIds, uint[] memory _burnAmounts, uint[] memory _mintIds, uint[] memory _mintAmounts) external onlyOwner {
        _burnBatch(_from, _burnIds, _burnAmounts);
        _mintBatch(_from, _mintIds, _mintAmounts, "");
    }

    function setURI(uint _id, string memory _uri) external onlyOwner {
        tokenURI[_id] = _uri;
        emit URI(_uri, _id);
    }

    function uri(uint _id) public override view returns (string memory) {
        return tokenURI[_id];
    }

    function setPrivateMintAmount(uint _amount) public onlyOwner {
        privateMintAmount = _amount;
    }

    function setPublicMintAmount(uint _amount) public onlyOwner {
        publicMintAmount = _amount;
    }

    function closeMinting() external onlyOwner {
        mintPhase = "closed";
    }

    function setPrivateMint() external onlyOwner {
        mintPhase = "private";
    }

    function setPublicMint() external onlyOwner {
        mintPhase = "public";
    }

    function setCollection1(uint _token) external onlyOwner {
        collection1 = _token;
    }

    function setCollection2(uint[] memory _collection) public onlyOwner{
        collection2 = _collection;
    }

    function setCollection3(uint _token) external onlyOwner {
        collection3 = _token;
    }

    function setPublicCost(uint256 _price) external onlyOwner {
        publicCost = (_price * 10 ** 18) / 100;
    }

    function setPrivateCost(uint256 _price) external onlyOwner {
        privateCost = (_price * 10 ** 18) / 100;
    }

    function setAvailableTokens(uint[] memory _tokens) public onlyOwner {
        availableTokens = _tokens;
    }

    function seeTokenAvailability(uint _id) public view onlyOwner returns(uint){
        return availableTokens[_id];
    }

    function setTokenAddress(address _address) public onlyOwner {
        tokenAddress = _address;
    }

    function setBurnAddress(address _address) public onlyOwner {
        burnAddress = _address;
    }

    function setContractURI(string memory _data) public onlyOwner {
        contractData = _data;
    }

    function contractURI() public view returns (string memory) {
        return contractData;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
