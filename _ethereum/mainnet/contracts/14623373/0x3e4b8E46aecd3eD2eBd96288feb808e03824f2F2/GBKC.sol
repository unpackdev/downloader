// SPDX-License-Identifier: MIT
/*

Green Bud Killers Club — 4:20 Collection
https://greenbudkillers.club/

    .===. (
    |   |  )
    |   | (
    |   | )
    |   \@/'
  ,'    //.
 :~~~~~//~~;      
  `.  // .'
gb`-------'kc

*/
pragma solidity ^0.8.9;

import "./GBKCRef.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract OwnableDelegateProxy { }

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}



contract GBKC is Ownable, GBKCRef {
    using ECDSA for bytes32;

    uint256 public MAX_SUPPLY = 421;  //must be +1
    uint256 public PRICE = 0.042 ether;
    uint256 public constant PRESALE_PRICE = 0.024 ether;
    uint256 public constant PRESALE_LIMIT = 11; //must be +1

    address public whiteListSigningAddress = address(0x7b56cAe86937A995fa0EC462fB9C19EA206DFc69);

    address proxyRegistryAddress;

    enum Status {CLOSED, PRESALE, SALE}
    Status public state = Status.CLOSED;

    string public baseTokenURI;


    constructor(string memory baseURI, address _proxyRegistryAddress)
    GBKCRef("GreenBudKillersClub", "GBKC", 15)
    {
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

    function setPrice(uint256 newPrice) external onlyOwner {
        PRICE = newPrice;
    }

    function setMaxSupply(uint256 newMax) external onlyOwner {
        MAX_SUPPLY = newMax;
    }


    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }


    function numMinted(address addr) public view returns (uint256) {
        return _numberMinted(addr);
    }


    function airdropTo(address[] calldata _wallets, uint8[] calldata _num) external onlyOwner {
        require(_wallets.length == _num.length, "arrays length mismatch");
        uint256 totalNum = 0;
        uint256 airdropNum = _wallets.length;
        for(uint256 i = 0; i < airdropNum; i++) {
            totalNum += _num[i];
        }

        require(totalSupply() + totalNum < MAX_SUPPLY, "exceed max supply");


        for(uint256 i = 0; i < airdropNum; i++) {
            _safeMint(_wallets[i], _num[i]);
        }
    }

    function mint(uint256 _numToMint, bytes calldata _signature, address payable _refferer) external payable saleIsOpen {
        if(!hasParent(_msgSender())){
            addParent(_refferer);
        }
        mint(_numToMint, _signature);
    }

    function mint(uint256 _numToMint, bytes calldata _signature) public payable saleIsOpen {

        require(_numToMint > 0 && _numToMint < 16, "max limit to mint"); //15 per mint
        require(totalSupply() + _numToMint < MAX_SUPPLY, "sold out");
        require(msg.value == getPrice(_numToMint), "sended value must equal price");
        require(msg.sender == tx.origin, "no contract calls");

       

        if(state == Status.PRESALE) {
            require((_numToMint + _numberMinted(msg.sender)) < PRESALE_LIMIT, "minting more than allowed on presale");
            require(
                whiteListSigningAddress ==
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            bytes32(uint256(uint160(msg.sender)))
                        )
                    ).recover(_signature),
                "you are not whitelisted"
            );
        }


        // solhint-disable-next-line
        _safeMint(_msgSender(), _numToMint);
        if(hasParent(_msgSender())){
            payToParents(msg.value);
        }

    }

    function getPrice(uint256 _count) public view returns (uint256) {
        if(state == Status.PRESALE){
            return PRESALE_PRICE * _count;
        }
        return PRICE * _count;
    }


    function setWhiteListSigningAddress(address _signingAddress) external onlyOwner {
        whiteListSigningAddress = _signingAddress;
    }


    function setSaleState(uint newState) external onlyOwner {
        state = Status(newState);
    }


    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
    }

    //Whitelist opensea proxy
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}