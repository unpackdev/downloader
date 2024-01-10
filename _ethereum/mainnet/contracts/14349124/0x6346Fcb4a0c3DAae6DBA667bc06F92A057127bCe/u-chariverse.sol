pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./Math.sol";

abstract contract OpenSeaCompatible is Ownable,ERC721Enumerable{
    string private _contractURI;
    function contractURI() public view returns (string memory){
        return _contractURI;
    }
    function setContractURI(string memory _contractUri) public onlyOwner{
        _contractURI = _contractUri;
    }
    function walletOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
}

abstract contract SafeWithdrawals is Ownable{
    function withdrawTokens(address tokenAddress,address receiver) public onlyOwner{
        IERC20 token = IERC20(tokenAddress);
        token.transfer(receiver, token.balanceOf(address(this)));
    }
    function _withdrawETH(address receiver) internal{
        (bool sent,) = receiver.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
    function withdrawETH(address receiver) public onlyOwner{
        _withdrawETH(receiver);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



contract UkraineChariverseKids is 
    OpenSeaCompatible,
    SafeWithdrawals
    {
    address public mintValueReceiver;
    uint256 public price = 0.25 ether;
	uint256 public constant MAX_SUPPLY = 7777;
	string private _baseTokenURI;

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }
    function setReceiver(address _mintValueReceiver) public onlyOwner {
        mintValueReceiver = _mintValueReceiver;
    }
    function _baseURI() internal view override returns (string memory){
        return _baseTokenURI;
    }
    function setBaseUri(string memory baseURI) public onlyOwner{
        _baseTokenURI = baseURI;
    }
	    
    constructor(string memory baseTokenURI_)
        ERC721("UkraineChariverseKids", "UKID") {
        _baseTokenURI = baseTokenURI_;
        mintValueReceiver = msg.sender;
    }


    function mintChariverseItem(address to, uint count) public payable {
        require(count*price<=msg.value, "not enough payment");
        for(uint i = 0; i < count; i++){
            _safeMint(to, totalSupply());
        }
        _withdrawETH(mintValueReceiver);
    }
}