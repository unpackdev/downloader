//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./console.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";
import "./ERC721.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract WeLockLove is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;
     using SafeERC20 for IERC20;
    mapping(uint256 => uint256) public prices;
    mapping(uint256 => uint256) public prices_fiat;
    string private _baseTokenURI = "ar://00000/";
    bytes32 private whitelist;
    bytes32 private reservation;
    uint256 public step = 0;
    address public token_contract;
    address public PayProvider;
    bool private IsMintAuthorized = false;
    bool private pausedPhysical = true;
    bool private FiatMinting = false;
    bool public MetadataFreeze = false;
    string public _contractURI = "";

    constructor() ERC721("WeLockLove", "WLL") {
        prices[1] = 738 ether;
        prices[2] = 18 ether;
        prices[3] = 1.94 ether;
        prices[4] = 0.465 ether;
        prices_fiat[1] = 1000000000000;
        prices_fiat[2] = 25000000000;
        prices_fiat[3] = 2500000000;
        prices_fiat[4] = 600000000;
        token_contract = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    }
    modifier onlyProvider() {
        require(msg.sender == PayProvider, "Not Provider");
        _;
    }
   function togglePausePhysical() external onlyOwner
    {
        pausedPhysical = !pausedPhysical;
    }
    function togglePauseFiatMint() external onlyOwner
    {
        FiatMinting = !FiatMinting;
    }
  function toggleMint() external onlyOwner
    {
        IsMintAuthorized = !IsMintAuthorized;
    }
    function PhysicalEventSale(uint256 _senttokenId, address _mintTo) public onlyProvider {
        require(IsMintAuthorized, "Mint is not authorized");
        require(!pausedPhysical, "Physical mint is paused");
        uint256 catId = getCategory(_senttokenId);
        require(catId > 2, "Not authorized to mint this collection");
        _safeMint(_mintTo, _senttokenId);
    }

    function MintReserved(uint256 _tokenId, bytes32[] calldata proof, address _mintTo) public payable {
        require(IsMintAuthorized, "Mint is not authorized");
        require(step == 1, "Mint is closed");
        if(msg.sender == PayProvider){
                require(hasReserved(_mintTo, _tokenId, proof));
            }else{
                require(hasReserved(msg.sender, _tokenId, proof));
            }    

        uint256 price = prices[getCategory(_tokenId)];
        require(msg.value >= price, "Not enough ether sent");

        _safeMint(_mintTo, _tokenId);
    }

      function MintReservedFiat(uint256 _tokenId, bytes32[] calldata sigs, address _mintTo) public  {
            require(IsMintAuthorized, "Mint is not authorized");
            require(step == 1, "Mint is closed");
            require(FiatMinting, "Mint in FIAT is not authorized");
            if(msg.sender == PayProvider){
                require(hasReserved(_mintTo, _tokenId, sigs));
            }else{
                require(hasReserved(msg.sender, _tokenId, sigs));
            }    
            uint256 price = prices_fiat[getCategory(_tokenId)];

        IERC20(token_contract).safeTransferFrom(msg.sender, address(this), price);
        _safeMint(_mintTo, _tokenId);
        }

    function MintWL(uint256 _tokenId, bytes32[] calldata wlProof, address _mintTo) public payable {
        require(IsMintAuthorized, "Mint is not authorized");
        require(step == 2, "Mint is closed");
         if(step == 2){
            if(msg.sender == PayProvider){
                require(isWhitelisted(_mintTo, wlProof), "Not whitelisted");
            }else{
                require(isWhitelisted(msg.sender, wlProof), "Not whitelisted");
            }
        }
      
        uint256 price = prices[getCategory(_tokenId)];
        require(msg.value >= price, "Not enough ether sent");
        _safeMint(_mintTo, _tokenId);
    }

    function MintWLFiat(uint256 _tokenId, bytes32[] calldata wlProof, address _mintTo) public {
        require(IsMintAuthorized, "Mint is not authorized");
        require(step == 2 || step == 3, "Mint is closed");
        if(step == 2){
            if(msg.sender == PayProvider){
                require(isWhitelisted(_mintTo, wlProof), "Not whitelisted");
            }else{
                require(isWhitelisted(msg.sender, wlProof), "Not whitelisted");
            }
        }
        require(FiatMinting, "Mint in FIAT is not authorized");

        uint256 price = prices_fiat[getCategory(_tokenId)];
        IERC20(token_contract).safeTransferFrom(msg.sender, address(this), price);
        _safeMint(_mintTo, _tokenId);
    }

      function MintWild(uint256 _tokenId, address _mintTo) public payable {
        require(IsMintAuthorized, "Mint is not authorized");
        require(step == 3, "Mint is closed");
        uint256 price = prices[getCategory(_tokenId)];
        require(msg.value >= price, "Not enough ether sent");
        _safeMint(_mintTo, _tokenId);
    }

    function gift(uint256 _tokenId, address _to) public onlyOwner {
        _safeMint(_to, _tokenId);
    }

    function hasReserved(
        address account,
        uint256 tokenId,
        bytes32[] calldata proof
    ) internal view returns (bool) {
        return _verify(_leaf(account, tokenId), proof, reservation);
    }

    function isWhitelisted(address account, bytes32[] calldata proof)
        internal
        view
        returns (bool)
    {
        return _verify(_leaf(account), proof, whitelist);
    }
    function setWhitelist(bytes32 whitelistroot) public onlyOwner {
        whitelist = whitelistroot;
    }
    function setReservation(bytes32 reservationRoot) public onlyOwner {
        reservation = reservationRoot;
    }
    function setPrice(uint256 category, uint256 newPrice) public onlyOwner {
        prices[category] = newPrice;
    }
    function setPriceFiat(uint256 category, uint256 newPrice) public onlyOwner {
        prices_fiat[category] = newPrice;
    }
    function setToken_contract(address _sentTokenContract) public onlyOwner {
        token_contract = _sentTokenContract;
    }
    function switchStep(uint256 newStep) public onlyOwner {
        step = newStep;
    }
    function UpdatePayProvider(address _newPayProvider) public onlyOwner
    {
        PayProvider = _newPayProvider;
    }
    function getPrice(uint256 category) public view returns (uint256) {
        return prices[category];
    }
    function getPriceFiat(uint256 category) public view returns (uint256) {
        return prices_fiat[category];
    }
    function getCategory(uint256 tokenId) public pure returns (uint256) {
        require(tokenId > 0 && tokenId < 916, "Invalid tokenId");

        if (tokenId <= 2) {
            return 1;
        } else if (tokenId > 2 && tokenId <= 16) {
            return 2;
        } else if (tokenId > 16 && tokenId <= 119) {
            return 3;
        } else if (tokenId > 119 && tokenId <= 915) {
            return 4;
        }
        return 0;
    }
    event PermanentURI(string _value, uint256 indexed _id);
    function FreezeMetadata() external onlyOwner{
        MetadataFreeze = true;
        for (uint256 i = 1; i < 915; i++) {
            if(_exists(i)){
            emit PermanentURI(tokenURI(i), i);  
            }
        }
    }
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    function setContractURI(string memory newContractURI) public onlyOwner {
        _contractURI = newContractURI;
    }
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        require(!MetadataFreeze, "Metadata are frozen");
        _baseTokenURI = newBaseURI;
    }
    function _baseUri() internal view virtual returns (string memory) {
        return _baseTokenURI;
    }
    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }
    function _leaf(address account, uint256 tokenId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(tokenId, account));
    }
    function _verify(
        bytes32 leaf,
        bytes32[] memory proof,
        bytes32 root
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory currentBaseURI = _baseUri();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }
    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if(balance > 0){
            Address.sendValue(payable(owner()), balance);
        }

        balance = IERC20(token_contract).balanceOf(address(this));
        if(balance > 0){
            IERC20(token_contract).safeTransfer(owner(), balance);
        }
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
