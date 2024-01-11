// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";


contract Therapets  is Initializable, EIP712Upgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable {
  using StringsUpgradeable for uint256;

    string private constant SIGNING_DOMAIN = "Therapets";
    string private constant SIGNATURE_VERSION = "1";
    address private constant verified_signer = 0xA2F2a3d534aAF5FDDCd9F23aF0F4A594Cce376cE;
    mapping (uint256 => bool) public redeemed;

    string baseURI;
    string public baseExtension;
    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmount;
    bool public paused;
    bool public revealed;
    string public notRevealedUri;
    uint256 public nftPerAddressLimit;
    mapping(address => uint256) public addressMintedBalance;
    bool public onlyWhitelisted;
    mapping (address => uint)  AllowList;


    function initialize() initializer public {
        __ERC721_init("TherapetsNFT", "THPTS");
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
        __Ownable_init();
        baseExtension = ".json";
        baseURI = "nft_finals/";
        notRevealedUri = "ipfs://QmYjWpmSDo1YvmxTzacVLQPfNqgRXutcDWDfyRhL7sH92x/";
        cost = 0.05 ether;
        maxSupply = 2222;
        maxMintAmount = 20;
        nftPerAddressLimit = 10;
        paused = false;
        revealed = false;
        onlyWhitelisted = true;
    }

    function mint(uint256 _mintAmount, uint256 id, bytes memory signature) public payable{
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "Mint amount too low.");
        require(supply + _mintAmount <= maxSupply, "Mint amount over supply.");


        if (msg.sender != owner()) {
            if(onlyWhitelisted == true) {
                require(check(id, signature) == verified_signer, "Whitelist check failed invalid");
                require(redeemed[id] != true, "Already redeemed!");
                redeemed[id] = true;
            }
            
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
            require(_mintAmount <= maxMintAmount, "Mint amount too large.");
            require(msg.value >= cost * _mintAmount, "Value too low!");
            require(!paused, "Contract paused");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }

    function giveawaysMint(uint256 _mintAmount) public payable{
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "Mint amount too low.");
        require(supply + _mintAmount <= maxSupply, "Mint amount over supply.");


        if (msg.sender != owner()) {
        

            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
            require(numberOfFreeMints(msg.sender) > 0, "out of free mints");
            require(_mintAmount <= maxMintAmount, "Mint amount too large.");
            require(!paused, "Contract paused");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            AllowList[msg.sender]--;
            _safeMint(msg.sender, supply + i);
        }
    }

    function addAllowList(address[] calldata _users,uint[] calldata _Number) public
        returns (uint)
   {
        for (uint i = 0; i < _users.length; i++) {
            AllowList[_users[i]] = _Number[i];
        }

       return _users.length;
   }

    function numberOfFreeMints(address User) public view returns (uint){
        return AllowList[User];
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
        tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }


  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }


    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        if(revealed == false) {
            return notRevealedUri;
        }
        
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }


    //only owner
    function reveal() public onlyOwner {
        revealed = true;
    }
    
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
        if(onlyWhitelisted){
            cost = 50000000000000000;
        }else{
            cost = 60000000000000000;
        }
    }
  
    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }
    

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function pause() public onlyOwner {
        if(paused) {
            paused = false;
        }else{
            paused = true;
        }
    }


    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
  
    function check(uint256 id, bytes memory signature) public view returns (address){
        return _verify(id, signature);
    }

    function _verify(uint256 id, bytes memory signature) internal view returns (address){
        bytes32 digest = _hash(id);
        return ECDSAUpgradeable.recover(digest, signature);
    }

    function _hash(uint256 id) internal view returns (bytes32){
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Web3Struct(uint256 id)"),id)
        ));
    }
}