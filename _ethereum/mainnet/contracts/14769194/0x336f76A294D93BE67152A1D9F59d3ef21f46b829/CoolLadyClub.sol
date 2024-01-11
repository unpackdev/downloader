//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//╢╣╢▒╢▒╢▒╢▒╢╢╣▒▒╢▒╢▒╢▒╢▒╢▒▒▒▒╢▒╢▒╢▒╢▒╢▒▒▒▒▒▒▒▒╢▒╢▒╢▒╢▒▒▒▒▒▒╢▒╢▒╢▒╢▒╢╢╣╢╣╢▒╢▒╢▒╢╢╢
//╢╣╢▒╢▒╢▒╢▒╢╢╢╢╣╢▒╢▒╢▒╢▒╢▒▒▒▒▒▒╢▒╢▒╢▒╢▒▒▒▒▒▒▒▒╢▒╢▒╢▒▒▒▒▒▒▒▒╢▒╢╣╢▒╢▒╢╢╢╢╣╢▒╢▒╢▒╢▒╢
//╢╣╢▒╢▒╢▒╢▒╢▒╢╢╣╢╣╢▒╢▒╢▒▒▒▒▒▒▒▒╢▒╢▒╢▒╢▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢╣╢▒╢▒╢▒╢╢╢╢╢╢▒╢▒╢▒╢▒╢
//╢╣╢▒╢▒╢▒╢▒╢▒╢╢╣╢▒╢╣╢▒╢▒▒▒▒▒▄███▌╢▒█████▒▒▒▄████▄▒▒███▒▒▒╢╣╢▒╢▒╢▒╢▒╢╢╣╢╣╢▒╢▒╢▒╢▒╢
//╢╣╢▒╢▒╢▒╢▒╢▒╢╢▒╢▒╢▒╢▒╢▒▒▒▒███▀▒▀▒███▒███▒███▀▀██▌▒███▒╢▒╢▒╢▒╢▒╢▒╢▒╢╢╢╢╢╢▒╢▒╢╢╢▒╢
//▒▒╢▒╢▒╣╣╢▒╢▒╢╢▒╢▒╢▒╢▒╢▒╣▒▒██▌▒▒▒▐██▌╢███▒███▒▒███▒███╢▒▒╢▒╢▒╢▒╢▒╢▒╢╢╢╢╢╣▒╢▒╢▒╢▒╢
//▒▒╢▒╢▒╢▒╢▒╣╢╣╢▒╢▒╢▒╢▒╢▒╢▒▒███▄▄▌▒███▒███▒███▄▄██▌▒███▒▒▒╢▒╢▒╢▒╢▒╢╣╣▒▒▒▒▒▒╢▒╢▒╢▒╢
//▒▒╢▒╢▒╢▒╢▒▒▒▒▒▒╢▒╢▒╢▒╢▒╢▒▒▒▀███▌▒▒████▀░▒▒▀████▀╢╢█████▒╢▒╢▒╢▒╢▒▒▒▒▒▒▒▒▒▒╢▒╢▒╢▒╢
//▒▒▒▒╢▒╢▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢╢╢▒▒███╣▒▒▒▒███▌▒▒█████▄╢███▒▒██▌▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢▒╢▒╢▒╢
//▒▒▒▒╢▒╢▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒███▒▒▒╢█████▒▒███▀███▒██████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢▒╢▒╢▒╢
//▒▒▒▒╢▒╢▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒███▒▒▒▒██▒██▌▒███╢███▒▒████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢▒╢▒╢▒╢
//▒▒▒▒▒▒╢▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒███▒▒▒███████▒███▄███▒▒▐██▌▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢▒╢▒╢▒╢
//╢▒╢▒╢▒╢▒╢▒╢▒╣▒▒╢▒╢▒╢▒╢▒╢▒▒█████▒███▀███▒█████▀▒▒▒▐██▌▒▒▒▒▒╢▒╢▒╢▒╢▒╣▒╣╢▒╢▒╢▒╢▒╢▒╢
//╢▒╢▒╢▒╢▒╢▒╢▒╢▒▒╢▒╢▒╢▒╢▒▒▒▒▒▒▄███▒███▒▒▒██▌▒██▌▒█████▄▒▒▒▒▒╢▒╢▒╢▒╢▒╢▒▒╢▒╢▒╢▒╢▒╢▒╢
//╢╣╢▒╢▒╢▒╢▒╢▒╣▒▒╢▒╢▒╢▒╢▒▒▒▒▐███▀▀▒███▒▒▒██▌▒███▒███▀███▒▒▒▒╢▒╢▒╢▒╢▒╣▒╣╢▒╢▒╢▒╢▒╢▒╢
//╢▒╢▒╢▒╢▒╢▒╢▒╢▒▒╢▒▒▒▒▒▒▒▒▒▒███▒╢▒╢███▒▒▒██▌▒███▒██████▒▒▒▒▒╢▒╢▒╢▒╢▒╢▒╢╢▒╢▒╢▒╢▒╢▒╢
//╢╢╢▒╢▒╢▒╢▒╢▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒███▄▒▒╣███▒▒▒███▒███▒███▒███▒▒▒▒▒▒▒▒╢╢╢▒╢▒╢╢▒╢▒╢▒╢▒╢▒╢
//╢▒╢▒╢▒╢▒╢▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▀████╢█████╢▀█████▒▒██████▀▒▒▒▒▒▒▒▒╢▒▒▒╣╢╣╢▒╢▒╢▒╢▒╢▒╣
//╢▒╢▒╢▒╢▒╢▒▒▒▒▒▒▒▒▒▒╢▒▒▒╢╣╣▒▒╢▒▒▒▒▒▒▒▒▒╣▒▒▒▒▒▒╢▒╢▒╢▒╢▒▒▒▒▒▒▒▒╢▒╢▒╢▒▒▒▒▒▒╢▒╢▒╢▒╢▒╢
//▒▒╢▒╢▒╢▒╢▒▒▒▒▒▒▒▒▒▒▒▒╢╢╢▒╢▒▒╢▒╢▒▒▒▒▒▒▒╢▒▒▒▒╢▒╢▒╢▒╢▒╢▒╢╢▒▒▒▒▒▒▒╢▒╢▒▒▒▒▒▒▒▒╢▒╢▒╢▒╢
//▒▒╢▒╢▒╢▒╢▒▒▒▒▒▒▒▒╢▒╢▒╢▒╢▒╣▒╣╢╣▒▒▒▒▒▒▒▒╢▒▒╢▒╢▒╢▒╢▒╢▒╢▒╣╢▒╢▒▒▒╢▒╢▒╢▒▒▒▒▒▒╢▒╢▒╢▒╢▒╢

import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract CoolLadyClub is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    uint256 public maxSupply = 1999;
    uint256 public publicSalePrice = 0.04 ether;
    uint256 public presalePrice = 0.02 ether;
    uint256 public maxMintPerTx = 5;
    uint256 public oldHoldersTokensClaimed;
    uint256 public totalMintOnPublic;
    uint256 public totalMintOnPresale;
    uint256 public devMintAmount = 30;
    uint256 public maxSupplyForPublic = 1454;
    uint256 public maxSupplyForPresale = 500;

    bytes32 public whitelistMerkleRoot;
    
    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;

    bool public isPublicSaleMintable = false;
    bool public isClaimable = false;
    bool public isRevealed = false;
    bool public isPresaleMintable = false;

    mapping(address => uint8) public whiteTokens;
    mapping(address => uint256) public claimableToken;

    address dev = 0xEDB8150008916A0c777E34BB996Da853F052bD17;
    address st = 0x73dF0C88f3B0e553D8bef7605f5750E07A8C36A8;
    address cm1 = 0x18456ce597e8469472dCb76e9144A151681cDC52;
    address cm2 = 0x1BEC0E6266e97f0C7C42aa720959e46598DD8Ce1;
    address cw = 0x3d6e8B7E3E14066bc7E28341db27969f5798b1C1;
    address pm = 0x665eb043B445Eb9D0e5D9C127DD55233D343FA6D;
    

    event IsClaimable(bool claimable);
    event IsMintable(bool mintable);
    event IsPresaleMintable(bool presaleMintable);
    event NotRevealedURI(string notRevealedUri);

    constructor(string memory _initNotRevealedURI) ERC721A("Cool Lady Club", "CLC") {
        setNotRevealedURI(_initNotRevealedURI);
    }

     modifier isPublicSaleActive() {
        require(
            isPublicSaleMintable, 
            "'CLC' is not mintable now."
        );
        _;
    }

     modifier isPresaleActive() {
        require(
            isPresaleMintable, 
            "'CLC' is not mintable for presale now."
        );
        _;
    }

    modifier isClaimActive() {
        require(
            isClaimable, 
            "'CLC' is not claimable now."
        );
        _;
    }

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender, 
            "The caller is another contract"
        );
        _;
    }

    modifier isPaymentSufficientPublicSale(uint256 amount) {
        require(
            msg.value == amount * publicSalePrice,
            "Not enough ETH transferred to mint a 'Cool Lady'."
        );
        _;
    }

    modifier isPaymentSufficientPresale() {
        require(
            msg.value >= presalePrice,
            "Not enough ETH transferred to mint a 'Cool Lady'."
        );
        _;
    }

   modifier isNotExceedMaxMintPerTx(uint256 amount) {
        require(
            amount <= maxMintPerTx,
            "Mint amount of 'Cool Lady' exceeds max limit per transaction for public sale."
        );
        _;
    }

    function mint(uint256 _mintAmount)
        external
        payable
        callerIsUser
        isPublicSaleActive
        isPaymentSufficientPublicSale(_mintAmount)
        isNotExceedMaxMintPerTx (_mintAmount)
    {
        require(_mintAmount > 0);
        require(totalMintOnPublic + _mintAmount <= maxSupplyForPublic - totalMintOnPresale, "Not enough remaining supply for public");
        _safeMint(msg.sender, _mintAmount);
        totalMintOnPublic = totalMintOnPublic + _mintAmount;
    }

    function claim(uint256 _claimAmount) 
        external
        isClaimActive
        callerIsUser 
    {
        require(claimableToken[msg.sender] > 0, "not eligible for claim");
        require(_claimAmount > 0);
        require(_claimAmount <= claimableToken[msg.sender], "do not have this much claimable token");
        require(_claimAmount + totalSupply() <= maxSupply, "do not mint CLC over the max supply");
        _safeMint(msg.sender, _claimAmount);
        oldHoldersTokensClaimed = oldHoldersTokensClaimed + _claimAmount;
        claimableToken[msg.sender] = claimableToken[msg.sender] - _claimAmount;
    }

    function presaleMint(bytes32[] calldata merkleProof, uint8 _premintAmount)
        external
        payable
        callerIsUser
        isPresaleActive
    {
        require(MerkleProof.verify(merkleProof, whitelistMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Address not in the whitelist");
        require(msg.value >= presalePrice * _premintAmount, "Ether value sent is below the price");
        require(whiteTokens[msg.sender] + _premintAmount <= 2, "Max per wallet reached");
        require(_premintAmount > 0 && _premintAmount <= 2, "You can mint min 1, maximum 2 Tpkens");
        require(totalMintOnPresale + _premintAmount <= maxSupplyForPresale, "Cannot exceeds max supply");
        _safeMint(msg.sender, _premintAmount);
        whiteTokens[msg.sender] += _premintAmount;
        totalMintOnPresale = totalMintOnPresale + _premintAmount;
        refundIfOver(presalePrice * _premintAmount);
    }

    function preMinted(address owner) external view returns (uint8) {
        return whiteTokens[owner];
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
        payable(msg.sender).transfer(msg.value - price);
        }
    }

    function addHolders(address[] memory addresses, uint256[] memory claimableTokens)
        external
        onlyOwner
    {
        require(addresses.length == claimableTokens.length, "addresses and tokenid length mismatch");

        for (uint256 i = 0; i < addresses.length; i++) {
            claimableToken[addresses[i]] = claimableTokens[i];
        }
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
        {
        return _ownershipOf(tokenId);
        }

    function setClaimable (bool _isClaimable) 
        external 
        onlyOwner 
    {
        isClaimable = _isClaimable;

        emit IsClaimable(isClaimable);
    }

    function setPublicSaleMintable (bool _isPublicSaleMintable) 
        external 
        onlyOwner 
    {
        isPublicSaleMintable = _isPublicSaleMintable;

        emit IsMintable(isPublicSaleMintable);
    }

    function setPresaleMintable (bool _isPresaleMintable) 
        external 
        onlyOwner
    {
        isPresaleMintable = _isPresaleMintable;

        emit IsPresaleMintable(isPresaleMintable);
    }

    function _baseURI() 
        internal 
        view 
        override 
        returns (string memory) 
    {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) 
        external 
        onlyOwner 
    {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) 
        public 
        onlyOwner 
    {
        notRevealedUri = _notRevealedURI;
 
        emit NotRevealedURI(_notRevealedURI);
    }

    function reveal(bool _state) 
        external 
        onlyOwner 
    {
        isRevealed = _state;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (isRevealed == false) {
        return notRevealedUri;
    }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function joinStrings(string memory a, string memory b)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, b));
    }

    function setWhiteMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function withdrawAll() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _withdraw(dev, (balance * 15) / 100);
        _withdraw(st, (balance * 15) / 100);
        _withdraw(cm1, (balance * 15) / 100);
        _withdraw(cm2, (balance * 10) / 100);
        _withdraw(cw, (balance * 5) / 100);
        _withdraw(pm, (balance * 40) / 100);
        
        _withdraw(owner(), address(this).balance);
    }

    function devMint(uint256 _mintAmount) 
        external 
        onlyOwner
    {
        require(totalSupply() + _mintAmount <= devMintAmount, "Mint amount is more than maximum devmint amount");
        require(_mintAmount % maxMintPerTx == 0, "can only mint a multiple of the maxMintAmount");
        uint256 batch = _mintAmount / maxMintPerTx;
        for (uint256 i = 0; i < batch; i++) {
        _safeMint(msg.sender, maxMintPerTx);
        }
    }
}



