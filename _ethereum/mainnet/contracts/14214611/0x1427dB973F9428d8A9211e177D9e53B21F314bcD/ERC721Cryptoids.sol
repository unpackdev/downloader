//SPDX-License-Identifier: Unlicense

//  ▄▄· ▄▄▄   ▄· ▄▌ ▄▄▄·▄▄▄▄▄      ▪  ·▄▄▄▄  .▄▄ · 
// ▐█ ▌▪▀▄ █·▐█▪██▌▐█ ▄█•██  ▪     ██ ██▪ ██ ▐█ ▀. 
// ██ ▄▄▐▀▀▄ ▐█▌▐█▪ ██▀· ▐█.▪ ▄█▀▄ ▐█·▐█· ▐█▌▄▀▀▀█▄
// ▐███▌▐█•█▌ ▐█▀·.▐█▪·• ▐█▌·▐█▌.▐▌▐█▌██. ██ ▐█▄▪▐█
// ·▀▀▀ .▀  ▀  ▀ • .▀    ▀▀▀  ▀█▄▀▪▀▀▀▀▀▀▀▀•  ▀▀▀▀ 


pragma solidity ^0.8.0;

import "Ownable.sol";
import "Counters.sol";
import "ERC721.sol";
import "Strings.sol";
import "EIP712Whitelist.sol";


contract CryptoidsERC721 is ERC721, EIP712Whitelist {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    
    uint256 public constant maxSupply = 8000;
    uint256 public constant genesisSupply = 1000;

    bool public genesisPhase = true;
    bool public isPresaleActive = false;
    bool public isSaleActive = false;

    uint256 public reserved = 80;
    uint256 public genesisPrice = 0.12 ether;
    uint256 public price = 0.1 ether;

    string private _baseTokenURI;
    address private _withdrawer;

    mapping(address => uint256) private _freeMinter;

    constructor(string memory name, string memory symbol, string memory baseURI, address withdrawer, address signer) 
        ERC721(name, symbol) 
        EIP712Whitelist() 
    {
        setWhitelistSigningAddress(signer);
        setBaseURI(baseURI);
        setWithdrawer(withdrawer);
    }

    function _mintOne(address _to)
        internal
        returns (uint256)
    {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(_to, newTokenId);
        return newTokenId;
    }

    function genesisPresale(bytes calldata signature, uint256 nonce)
        external
        payable
        requiresWhitelist(signature, nonce)
        returns (uint256)
    {
        /**
        * @dev Genesis presale
        * @param signature Signed message for whitelisted users
        * @param nonce Nonce associated with the signed message
        * 
        * - The Cryptoids Genesis cost 0.12 per mint.
        * - One per transaction and per signature.
        * - The contract is constructed to optimize gas.
        */
        require( genesisPhase, "Genesis phase is not active" );
        require( isPresaleActive, "Presale are not active" );
        require( _tokenIdCounter.current() < genesisSupply, "Exceeds genesis tokens supply" );
        require( msg.value >= genesisPrice, "Ether sent is not correct");
        useNonce(nonce);
        
        return _mintOne(msg.sender);
    }

    function genesisSale(uint256 num)
        external
        payable
    {
        /**
        * @dev Genesis sale
        * @param num Number of token to mint
        * 
        * - The Cryptoids Genesis cost 0.12 per mint.
        * - Maximum 4 tokens per transaction
        * - The contract is constructed to optimize gas.
        */
        require( genesisPhase, "Genesis phase is not active" );
        require( isSaleActive, "Sale are not active" );
        require( num <= 4, "You can only mint a maximum of 4 tokens per transaction" );
        require( _tokenIdCounter.current() + num <= genesisSupply, "Exceeds genesis token supply" );
        require( msg.value >= genesisPrice * num, "Ether sent is not correct" );

        for(uint256 i=0; i < num; i++){
            _mintOne(msg.sender);
        }
    }

    function normalPresale(uint256 num, bytes calldata signature, uint256 nonce)
        external
        payable
        requiresWhitelist(signature, nonce)
    {
        /**
        * @dev Normal presale
        * @param num Number of token to mint
        * @param signature Signed message for whitelisted users
        * @param nonce Nonce associated with the signed message
        * 
        * - Maximum two mint per transaction and one transaction per signature.
        * - The contract is constructed to optimize gas.
        */
        require( !genesisPhase, "Can't normal mint during genesis phase" );
        require( isPresaleActive, "Presale are not active");
        require( num <= 2, "Only two mint allowed during presale");
        require( _tokenIdCounter.current() + num <= maxSupply, "Exceeds maximum token supply" );
        require( msg.value >= price * num, "Ether sent is not correct" );
        useNonce(nonce);

        for(uint256 i=0; i < num; i++){
            _mintOne(msg.sender);
        }
    }

    function normalSale(uint256 num)
        external
        payable
    {
        /**
        * @dev Normal sale
        * @param num Number of token to mint
        * 
        * - Maximum 2 tokens per transaction
        * - Maximum 4 tokens per wallet
        * - The contract is constructed to optimize gas.
        */
        require( !genesisPhase, "Can't normal mint during genesis phase" );
        require( isSaleActive, "Sale are not active");
        require( num <= 2, "You can only mint a maximum of 2 tokens per transaction" );
        require( balanceOf(msg.sender) + num <= 4, "Maximum 4 eggs per wallet");
        require( _tokenIdCounter.current() + num <= maxSupply, "Exceeds maximum token supply" );
        require( msg.value >= price * num, "Ether sent is not correct" );

        for(uint256 i=0; i < num; i++){
            _mintOne(msg.sender);
        }
    }

    function freeMint(uint256 num)
        external
    {
        /**
        * @dev Free mint
        * @param num Number of token to mint
        * 
        * - One mint per transaction
        * - The contract is constructed to optimize gas.
        */
        uint256 resNum = _freeMinter[msg.sender];
        require(resNum > 0, "No free mint allowed for your address");
        require(num <= resNum, "Can't mint more than reserved");
        require(_tokenIdCounter.current() + num <= maxSupply, "Exceeds maximum token supply" );
        if (genesisPhase) {
            require(_tokenIdCounter.current() + num <= genesisSupply, "Exceeds genesis token supply" );
        }
        _freeMinter[msg.sender] = resNum - num;

        for(uint256 i=0; i < num; i++){
            _mintOne(msg.sender);
        }
    }

    function airDrop(address _to) 
        external 
        onlyOwner
        returns (uint256)
    {
        require( !genesisPhase, "Can't air drop during genesis phase" );
        require( reserved > 0, "Exceeds reserved tokens supply" );

        uint256 newTokenId = maxSupply + 81 - reserved;
        _safeMint(_to, newTokenId);
        reserved--;

        return newTokenId;
    }

    function tokensOfOwner(address _owner) 
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerBalance = balanceOf(_owner);
        if (ownerBalance == 0) {
            return new uint256[](0);
        }

        uint256[] memory ownerTokens = new uint256[](ownerBalance);
        uint256 ownerIndex = 0;
        for (uint256 tokenId=1; tokenId <= _tokenIdCounter.current(); tokenId++){
            if (_owner == ownerOf(tokenId)){
                ownerTokens[ownerIndex] = tokenId;
                ownerIndex++;
                if (ownerIndex == ownerBalance) break;
            }
        }

        if (ownerIndex != ownerBalance){
            for (uint256 tokenId = maxSupply + 1; tokenId <= maxSupply + 81 - reserved; tokenId++){
                if (_owner == ownerOf(tokenId)){
                    ownerTokens[ownerIndex] = tokenId;
                    ownerIndex++;
                    if (ownerIndex == ownerBalance) break;
                }
            }
        }
        return ownerTokens;
    }

    function setFreeMinter(address freeMinter, uint256 num)
        external
        onlyOwner
    {
        _freeMinter[freeMinter] = num;
    }

    function setMintPrice(uint256 newPrice)
        external
        onlyOwner 
    {
        price = newPrice;
    }

    function setBaseURI(string memory baseURI) 
        public 
        onlyOwner
    {
        _baseTokenURI = baseURI;
    }

    function _baseURI() 
        internal 
        view
        override 
        returns (string memory) 
    {
        return _baseTokenURI;
    }

    function toggleGenesisPhase() 
        external 
        onlyOwner
    {
        genesisPhase = !genesisPhase;
    }

    function toggleSale() 
        external 
        onlyOwner 
    {
        isSaleActive = !isSaleActive;
    }
    
    function togglePresale() 
        external 
        onlyOwner 
    {
        isPresaleActive = !isPresaleActive;
    }

    function totalSupply()
        external
        view
        returns (uint256)
    {
        return _tokenIdCounter.current() + 80 - reserved;
    }

    function setWithdrawer(address withdrawer)
        public 
        onlyOwner
    {
        _withdrawer = withdrawer;
    }

    function withdrawAll() 
        external 
        payable 
        onlyOwner 
    {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance is 0");
        payable(_withdrawer).transfer(balance);
    }
}

