// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


import "./Ownable.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract DefinityLegend is Ownable, ERC721A, PaymentSplitter {

    using Strings for uint;

    enum Step {
        Before,
        WhitelistSale,
        PublicSale,
        SoldOut,
        Reveal
    }

    string public baseURI;

    Step public sellingStep;

    uint public  MAX_SUPPLY = 25000;

    uint public wlSalePrice = 0 ether;
    uint public publicSalePrice = 0 ether;

    bytes32 public merkleRootWL;

    uint public MAX_PER_WALLET_WL = 15;
    uint public MAX_PER_WALLET_PUBLIC = 5;

    mapping(address => uint) public amountNFTsperWalletWhitelistSale;
    mapping(address => uint) public amountNFTsperWalletPublicSale;


    uint private teamLength;

    constructor(address[] memory _team, uint[] memory _teamShares, bytes32 _merkleRootWL , string memory _baseURI) ERC721A("DefinityLegend", "DefinityLegend")
    PaymentSplitter(_team, _teamShares) {
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
        require(sellingStep == Step.WhitelistSale, "Whitelist sale is not activated");
        require(isWhiteListed(msg.sender, _proof), "Not whitelisted");
        require(amountNFTsperWalletWhitelistSale[msg.sender] + _quantity <= MAX_PER_WALLET_WL, "You already minted your NFTs on the Whitelist Sale");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enought funds");
        amountNFTsperWalletWhitelistSale[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function publicSaleMint(address _account, uint _quantity) external payable callerIsUser {
        uint price = publicSalePrice;
        require(sellingStep == Step.PublicSale, "Public sale is not activated");
        require(amountNFTsperWalletPublicSale[msg.sender] + _quantity <= MAX_PER_WALLET_PUBLIC, "You already minted your NFTs.");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enought funds");
        amountNFTsperWalletPublicSale[msg.sender] += _quantity;
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

    function setMaxPerWalletWL(uint _MAX_PER_WALLET_WL) external onlyOwner {
        MAX_PER_WALLET_WL = _MAX_PER_WALLET_WL;
    }

    function setMaxPerWalletPublic(uint _MAX_PER_WALLET_PUBLIC) external onlyOwner {
        MAX_PER_WALLET_PUBLIC = _MAX_PER_WALLET_PUBLIC;
    }


    function setWLSalePrice(uint _wlSalePrice) external onlyOwner {
        wlSalePrice = _wlSalePrice;
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