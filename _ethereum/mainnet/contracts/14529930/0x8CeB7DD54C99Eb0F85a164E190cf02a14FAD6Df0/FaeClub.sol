// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract FaeClub is ERC721A, Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    // ======== Supply =========
    uint256 public MaxSupply = 10000;
    uint256 public envoySupply = 500;
    uint256 public fusionSupply = 500;


    // ========= Price =========
    uint256 public mintPrice = 0.088 ether;

    bool public whitelistStart = false;

    bool public publicStart = false;
    uint256 public walletMintMax = 2000;

    // ======== Metadata =========
    address private singer;
    string private _baseTokenURI;


    address public envoyAddress;
    
    enum FaeRole{
        Envoy,
        Fusion,
        Environment,
        Animal,
        Garden,
        Unknow
    }

    // ======== approved =========
    bool private isOpenSeaProxyActive = true;


    constructor(address _singer)
        ERC721A("FaeClub", "Fae Club", 10000, MaxSupply)
    {
        singer = _singer;
    } 

    modifier eoaOnly() {
        require(tx.origin == msg.sender, "EOA Only");
        _;
    }

    // ======== Minting =========
    function envoyMint(address _envoyAddress)
        external
        onlyOwner
    {
        require(totalSupply() == 0, "Supply error");
        envoyAddress = _envoyAddress;
        _safeMint(envoyAddress, envoySupply);
    }

    function mintFusionToAddress(address[] calldata _tos,uint256[] calldata nums)
        external
        onlyOwner
    {
        require(totalSupply()>=MaxSupply.sub(fusionSupply),"supply error");
        require(_tos.length == nums.length, "Length error");
        for(uint256 i = 0 ; i < _tos.length; i++){
            uint256 _number = nums[i];
            address _to = _tos[i];
            require(totalSupply().add(_number) <= MaxSupply, "Exceed max token supply");
            _safeMint(_to, _number);
        }       
    }

    function mintToAddress(address[] calldata _tos,uint256[] calldata nums)
        external
        onlyOwner
    {
        require(_tos.length == nums.length, "Length error");
        for(uint256 i = 0 ; i < _tos.length; i++){
            uint256 _number = nums[i];
            address _to = _tos[i];
            require(totalSupply().add(_number) <= MaxSupply.sub(fusionSupply), "Exceed max token supply");
            _safeMint(_to, _number);
        }       
    }

    function whitelistMint(address _to,uint256 _number,bytes memory _signature)
        external
        payable
        nonReentrant
        eoaOnly
    {
        require(whitelistStart, "Not yet started");

        require(_verifySignature(_signature), "Signature error");

        require(numberMinted(_to).add(_number) <= walletMintMax, "Exceed wallet max");

        require(totalSupply().add(_number) <= MaxSupply.sub(fusionSupply), "Exceed max token supply");

        require(msg.value == mintPrice.mul(_number),"Eth value error");

        _safeMint(_to, _number);
    }

    function publicMint(uint256 _number)
        external
        payable
        nonReentrant
        eoaOnly
    {
        require(publicStart, "Not yet started");

        require(numberMinted(msg.sender).add(_number) <= walletMintMax, "Exceed wallet max");

        require(totalSupply().add(_number) <= MaxSupply.sub(fusionSupply), "Exceed max token supply");

        require(msg.value == mintPrice.mul(_number),"Eth value error");

        _safeMint(msg.sender, _number);
    }



    function faeRole(uint256 tokenId) public view returns (FaeRole) {

        require(tokenId <= totalSupply() && tokenId > 0, "Not exist token");
        if(tokenId<=envoySupply){
            return FaeRole.Envoy;
        }else if(tokenId> MaxSupply.sub(fusionSupply)){
            return FaeRole.Fusion;
        }else if(tokenId%3==0){
            return FaeRole.Environment;
        }else if(tokenId%3==1){
            return FaeRole.Animal;
        }else if(tokenId%3==2){
            return FaeRole.Garden;
        }else{
            return FaeRole.Unknow;
        }
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }


    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setWalletMintMax(uint256 _walletMintMax) external onlyOwner {
        walletMintMax = _walletMintMax;
    }

    function setWhitelistStart(bool _whitelistStart) external onlyOwner {
        whitelistStart = _whitelistStart;
    }


    function setPublicStart(bool _publicStart) external onlyOwner {
        publicStart = _publicStart;
    }

    function setSinger(address _singer) external onlyOwner {
        singer = _singer;
    }


    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }


    function _verifySignature(bytes memory signature)
        internal
        view
        returns (bool)
    {
        require(signature.length == 65);
        uint8 v;
        bytes32 r;
        bytes32 s;

        assembly {
        // first 32 bytes, after the length prefix
            r := mload(add(signature, 32))
        // second 32 bytes
            s := mload(add(signature, 64))
        // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(signature, 96)))
        }

        return ecrecover(keccak256(abi.encode(msg.sender)), v, r, s) == singer;
    }

    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive) public onlyOwner {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }


    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if(operator == envoyAddress){
            return true;
        }
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        ProxyRegistry proxyRegistry = ProxyRegistry(0xa5409ec958C83C3f309868babACA7c86DCB077c1);

        if (isOpenSeaProxyActive && address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    
}


interface OwnableDelegateProxy {
}
interface ProxyRegistry {
    function proxies(address) external view returns (OwnableDelegateProxy);
}