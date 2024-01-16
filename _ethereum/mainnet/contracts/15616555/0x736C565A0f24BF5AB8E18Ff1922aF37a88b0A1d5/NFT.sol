// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


import "./Ownable.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract Restless is Ownable, ERC721A, PaymentSplitter {

    using Strings for uint;

    enum Step {
        Before,
        WhitelistSale,
        VIP,
        PublicSale,
        SoldOut,
        Reveal
    }

    string public baseURI;

    Step public sellingStep;

    uint public  MAX_SUPPLY = 4132;
    uint public  MAX_TOTAL_WL = 3132;
    uint public  MAX_TOTAL_VIP = 1000;

    uint public MAX_PER_WALLET_WL = 3;
    uint public MAX_PER_WALLET_VIP = 3;

    uint public wlSalePrice = 0.049 ether;
    uint public VIPPrice = 0 ether;
    uint public publicSalePrice = 0.059 ether;

    bytes32 public merkleRootWL;
    bytes32 public merkleRootVIP;

    uint public WLsaleStartTime = 1664203500;
    uint public VIPStartTime = 1664217900;

    mapping(address => uint) public amountNFTsperWalletVIP;
    mapping(address => uint) public amountNFTsperWalletWhitelistSale;

    uint private teamLength;

    constructor(address[] memory _team, uint[] memory _teamShares, bytes32 _merkleRootVIP, bytes32 _merkleRootWL , string memory _baseURI) ERC721A("Restless", "RSTL")
    PaymentSplitter(_team, _teamShares) {
        merkleRootVIP = _merkleRootVIP;
        merkleRootWL = _merkleRootWL;
        baseURI = _baseURI;
        teamLength = _team.length;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

   function whitelistMint(address _account, uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        uint price = wlSalePrice;
        require(price != 0, "Price is 0");
        require(currentTime() >= WLsaleStartTime, "Whitelist Sale has not started yet");
        require(currentTime() < WLsaleStartTime + 240 minutes, "Whitelist Sale is finished");
        require(sellingStep == Step.WhitelistSale, "Whitelist sale is not activated");
        require(isWhiteListed(msg.sender, _proof), "Not whitelisted");
        require(amountNFTsperWalletWhitelistSale[msg.sender] + _quantity <= MAX_PER_WALLET_WL, "You can only get 4 NFTs on the Whitelist Sale");
        require(totalSupply() + _quantity <= MAX_TOTAL_WL, "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enought funds");
        amountNFTsperWalletWhitelistSale[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function vipMint(address _account, uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        uint price = VIPPrice;
        require(currentTime() >= VIPStartTime, "VIP Sale has not started yet");
        require(currentTime() < VIPStartTime + 240 minutes, "VIP Sale is finished");
        require(sellingStep == Step.VIP, "VIP sale is not activated");
        require(isOg(msg.sender, _proof), "Not on the VIP list");
        require(amountNFTsperWalletVIP[msg.sender] + _quantity <= MAX_PER_WALLET_VIP, "You can only get 1 NFT on the VIP Sale");
        require(totalSupply() + _quantity <= MAX_TOTAL_VIP, "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enought funds");
        amountNFTsperWalletVIP[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function publicSaleMint(address _account, uint _quantity) external payable callerIsUser {
        uint price = publicSalePrice;
        require(price != 0, "Price is 0");
        require(sellingStep == Step.PublicSale, "Public sale is not activated");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enought funds");
        _safeMint(_account, _quantity);
    }

    function gift(address _to, uint _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached max Supply");
        _safeMint(_to, _quantity);
    }

    function lowerSupply (uint _MAX_SUPPLY) external onlyOwner{
        require(_MAX_SUPPLY < MAX_SUPPLY, "Cannot increase supply!");
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function setMaxTotalWL(uint _MAX_TOTAL_WL) external onlyOwner {
        MAX_TOTAL_WL = _MAX_TOTAL_WL;
    }

    function setMaxTotalVIP(uint _MAX_TOTAL_VIP) external onlyOwner {
        MAX_TOTAL_VIP = _MAX_TOTAL_VIP;
    }

    function setMaxPerWalletWL(uint _MAX_PER_WALLET_WL) external onlyOwner {
        MAX_PER_WALLET_WL = _MAX_PER_WALLET_WL;
    }

    function setMaxPerWalletVIP(uint _MAX_PER_WALLET_VIP) external onlyOwner {
        MAX_PER_WALLET_VIP = _MAX_PER_WALLET_VIP;
    }

    function setWLSaleStartTime(uint _WLsaleStartTime) external onlyOwner {
        WLsaleStartTime = _WLsaleStartTime;
    }

    function setVIPStartTime(uint _VIPStartTime) external onlyOwner {
        VIPStartTime = _VIPStartTime;
    }

    function setWLSalePrice(uint _wlSalePrice) external onlyOwner {
        wlSalePrice = _wlSalePrice;
    }

    function setVIPPrice(uint _VIPPrice) external onlyOwner {
        VIPPrice = _VIPPrice;
    }

    function setPublicSalePrice(uint _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function currentTime() internal view returns(uint) {
        return block.timestamp;
    }

    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    //Whitelist
    function setMerkleRootWL(bytes32 _merkleRootWL) external onlyOwner {
        merkleRootWL = _merkleRootWL;
    }

    function isWhiteListed(address _account, bytes32[] calldata _proof) internal view returns(bool) {
        return _verifyWL(leaf(_account), _proof);
    }

    function leaf(address _account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verifyWL(bytes32 _leaf, bytes32[] memory _proof) internal view returns(bool) {
        return MerkleProof.verify(_proof, merkleRootWL, _leaf);
    }
    //VIP
    function setMerkleRootVIP(bytes32 _merkleRootVIP) external onlyOwner {
        merkleRootVIP = _merkleRootVIP;
    }

    function isOg(address _account, bytes32[] calldata _proof) internal view returns(bool) {
        return _verifyVIP(leaf(_account), _proof);
    }

    function _verifyVIP(bytes32 _leaf, bytes32[] memory _proof) internal view returns(bool) {
        return MerkleProof.verify(_proof, merkleRootVIP, _leaf);
    }

    //ReleaseALL
    function releaseAll() external onlyOwner {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }

    receive() override external payable {
        revert('Only if you mint');
    }

}