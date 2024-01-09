// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract OwnableDelegateProxy { }

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}



contract ManekiVerse is ERC721, Ownable {
    using ECDSA for bytes32;

    uint256 public constant MAX_ELEMENTS = 7778; //Must be +1
    uint256 public constant PRICE = 0.07 ether;
    uint256 public constant PRESALE_PRICE = 0.04 ether;
    address public whiteListSigningAddress = address(135432234);
    address proxyRegistryAddress;



    enum Status {CLOSED, PRESALE, SALE}
    Status public state = Status.CLOSED;

    uint256 private tokenSupply = 1;
    
    string public baseTokenURI;

 
    constructor(string memory baseURI, address _proxyRegistryAddress) ERC721("ManekiVerse", "MNKV"){
        setBaseURI(baseURI);
        proxyRegistryAddress = _proxyRegistryAddress;
    }


    modifier saleIsOpen {
       require (state != Status.CLOSED, "sales closed");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }


    function totalSupply() public view returns (uint256) {
        return tokenSupply - 1;
    }


    function adminMint(address[] calldata _wallets) external onlyOwner {
        uint256 _tokenSupply = tokenSupply;
        uint256 num = _wallets.length;
        require(totalSupply() + num < MAX_ELEMENTS, "A: exceed limit"); 

     
        for(uint256 i = 0; i < num; i++) {      
            require(rawOwnerOf(_tokenSupply) == address(0), "owner must be 0");

            _mint(_wallets[i], _tokenSupply);
            // solhint-disable-next-line
            unchecked {
                _tokenSupply++;
            }

        }
        tokenSupply = _tokenSupply;
    }

    function mint(uint256 _numToMint, uint256 _timestamp, bytes calldata _signature) external payable saleIsOpen {

        uint256 _tokenSupply = tokenSupply;
        require(_numToMint > 0 && _numToMint < 11, "max exceed"); //10 per mint
        require(totalSupply() + _numToMint < MAX_ELEMENTS, "sold out");
        require(msg.value == price(_numToMint), "value < price");
        require(msg.sender == tx.origin, "no contract calls");


        address wallet = msg.sender;
        require(block.timestamp > _timestamp - 31, "Out of time");

        if(state == Status.PRESALE){
            
            require(
            whiteListSigningAddress ==
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        bytes32(uint256(uint160(msg.sender)))
                    )
                ).recover(_signature),
            "not allowed"
        );
        }
        
      
        for(uint8 i = 0; i < _numToMint; i++){
            uint256 tokenIdToMint = _tokenSupply;
            require(rawOwnerOf(tokenIdToMint) == address(0) && tokenIdToMint > 0 && tokenIdToMint < MAX_ELEMENTS, "Token already minted");

            _mint(wallet, tokenIdToMint);
            unchecked {
                _tokenSupply++;
            }
            
        }
        tokenSupply = _tokenSupply;

    }

    function price(uint256 _count) public view returns (uint256) {
        if(state == Status.PRESALE){
            return PRESALE_PRICE * _count;
        }
 
        return PRICE * _count;
    }


    function setWhiteListSigningAddress(address _signingAddress) external onlyOwner {
        whiteListSigningAddress = _signingAddress;
    }
    

    function setSaleState(uint newState) external onlyOwner{
        state = Status(newState);
    }
    

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed.");
    }

  
    function isApprovedForAll(
        address owner,
        address operator
    )
    public
    view
    override
    returns (bool)
    {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner)) == operator) {
        return true;
    }

    return super.isApprovedForAll(owner, operator);
  }


   
}