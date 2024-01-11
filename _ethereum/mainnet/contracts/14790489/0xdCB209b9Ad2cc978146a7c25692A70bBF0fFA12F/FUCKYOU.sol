

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
 
import "ERC1155Burnable.sol";
import "ERC1155.sol";
import "AccessControl.sol";
import "SafeMath.sol";
import "Ownable.sol";
import "Counters.sol";

contract FUCKYOU is ERC1155, Ownable, ERC1155Burnable {
    using SafeMath for uint256;

    using Counters for Counters.Counter;

    Counters.Counter private _countTracker;
    string public name;
    string public symbol;

    uint256 public constant TIER_ONE = 0.03 ether;
    uint256 public constant TIER_TWO = 0.09 ether;
    uint256 public constant TIER_THREE = 0.9 ether;
    mapping(uint => string) private _uris;
    address public multiSigOwner;
    uint256[] public maxSupply = [6000,3000,1000];
    uint256[] public tokensMinted = [0,0,0];

    constructor(
        string memory _name, 
        string memory _symbol, 
        address _multiSigOwner
    ) ERC1155("") {
        setMultiSig(_multiSigOwner);
        name = _name;
        symbol = _symbol;
        
    }

    function setMultiSig(address _multiSig) public onlyOwner {
        multiSigOwner = _multiSig;
    }


    function uri(uint256 tokenId) override public view returns (string memory) {
        return(_uris[tokenId]);
    }

    function setTokenURI(uint256 tokenId, string memory tokenUri) public onlyOwner {
        _uris[tokenId] = tokenUri;
    }



    function currentPrice(uint256 _tokenId) public view returns (uint256) {
        if (_tokenId == 2) {
            return TIER_THREE;
        } else if(_tokenId == 1){
            return TIER_TWO;
        } else {
            return  TIER_ONE;
        }
    }


    
    function totalSupply() public view returns (uint256) {
        return _countTracker.current();
    }
    

    function getTokenSupply(uint256 _id) public view returns (uint256) {
        uint256 maxMinted = maxSupply[_id];
        uint256 minted = tokensMinted[_id];
        if (maxMinted > minted) {
            return(maxMinted - minted);
        } else {
            return(0);
        }
    }
 

    function mint(address account, uint256 id, uint256 amount)
        external 
        payable
    {
        require(amount > 0, "Mint count should be greater than zero");
        require(getTokenSupply(id) >= amount, "Not enough Supply, try to mint less");
        uint256 totalPrice = currentPrice(id).mul(amount);

        require(msg.value >= totalPrice, "Insufficient funds");
        
        tokensMinted[id] += amount;

        
        for (uint256 i = 0; i < amount; i++) {
            _countTracker.increment();
        }

        _mint(account, id, amount, "");
    }


    function ownerMint(address account, uint256 id, uint256 amount)
        public
        virtual
        onlyOwner
    {
        require(amount > 0, "Mint count should be greater than zero");
        require(getTokenSupply(id) >= amount, "Not enough Supply, try to mint less");
        
        tokensMinted[id] += amount;

        for (uint256 i = 0; i < amount; i++) {
            _countTracker.increment();
            }
        _mint(account, id, amount, "");
    }



    function withdrawAll() public {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance is Zero");
        _withdraw(multiSigOwner, balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Transfer failed.");
    }



}