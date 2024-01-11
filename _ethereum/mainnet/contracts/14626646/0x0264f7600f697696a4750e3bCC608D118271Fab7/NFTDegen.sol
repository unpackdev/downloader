// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

struct Nft {
    string metadataHash;
    string name;
    bool isForSale;
    address payable previousOwner;
    address payable minter;
    address payable owner;
    uint32 likes;
    uint256 voucherBalance;
    uint256 id;
    uint256 minPrice;
}

contract NFTDegen is ERC1155, Ownable {
    bool public paused = false;
    address public originalOwner;
    address contractAddress = address(this);
    string public symbol = "NFTDEGEN";
    string public name = "NFT Degenerator";
    string public baseTokenURI = ""; // https://docs.opensea.io/docs/metadata-standards
    string public contractURI = ""; // https://docs.opensea.io/docs/contract-level-metadata
    uint256 public totalSupply = 10000;
    uint256 public mintFee = 0.006 ether; // ≈ $20
    uint256 public totalTokens = 0;

    mapping(uint256 => Nft) public tokens;
    mapping(string => bool) private tokenNameExist;
    mapping(string => bool) private metadataHashesExist;


    // -------------------------------
    //  Events
    // -------------------------------

    event PermanentURI(string _value, uint256 indexed _id);
    event SetPaused(bool _paused);
    event SetMintFee(uint256 _mintFee);
    event SetBaseTokenURI(string _baseTokenURI);
    event SetContractURI(string _contractURI);
    event RedeemVoucher(address indexed _to, uint256 indexed _id);
    event AddLike(
        uint256 indexed _id,
        address indexed _from,
        address indexed _to,
        uint256 _amount
    );
    event MintToken(uint256 indexed _id, address indexed _to, string _hash, string _name);
    event BuyToken(uint256 indexed _id, uint256 _price);
    event OfferTokenForSale(uint256 indexed _id, uint256 _minPrice);
    event ChangeTokenSalePrice(uint256 indexed _id, uint256 _minPrice);
    event CancelTokenForSale(uint256 indexed _id);


    // -------------------------------
    //   Initialization
    //    - keep track of original owner
    //    - set baseTokenURI (ipfs hash will be appended in uri function)
    // -------------------------------

    constructor() ERC1155("") {
        originalOwner = msg.sender;
        setBaseTokenURI("ipfs://");
    }


    // -------------------------------
    //   Modifiers
    // -------------------------------

    modifier onlyNotPaused() {
        require(!paused, "Only not when not paused");
        _;
    }

    modifier onlyTokenExists(uint256 _id) {
        Nft memory token = tokens[_id];
        require(token.id > 0 && token.id == _id, "Only when token exists");
        _;
    }

    modifier onlyTokenOwner(uint256 _id) {
        Nft memory token = tokens[_id];
        uint256 balance = balanceOf(msg.sender, _id);
        require(token.owner == msg.sender && balance >= 1, "Only token owner");
        _;
    }

    // -------------------------------
    //   Owner Contract Functions
    // -------------------------------

    // Important for OpenSea to scrape token metadata // https://docs.opensea.io/docs/contract-level-metadata
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        _setURI(_baseTokenURI);
        baseTokenURI = _baseTokenURI;
        emit SetBaseTokenURI(_baseTokenURI);
    }

    function setPaused(bool _paused) external onlyOwner {
        require(_paused != paused, "New value required");
        paused = _paused;
        emit SetPaused(_paused);
    }

    function setMintFee(uint256 _mintFee) public onlyOwner {
        mintFee = _mintFee;
        emit SetMintFee(_mintFee);
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
        emit SetContractURI(_contractURI);
    }


    // -------------------------------
    //   Getters View Only
    // -------------------------------

    function tokenUriFromMetadataHash(string memory _hash)
        internal
        view
        returns (string memory)
    {
        return string(abi.encodePacked(baseTokenURI, _hash));
    }

    // Important for OpenSea to scrape contract-level metadata https://docs.opensea.io/docs/metadata-standards
    function uri(uint256 _id) public view override returns (string memory) {
        if (!tokenExists(_id)) return "";
        return tokenUriFromMetadataHash(tokens[_id].metadataHash);
    }

    function getNextTokenId() public view returns (uint256) {
        return totalTokens + 1;
    }

    function tokenExists(uint256 _id) public view returns (bool) {
        Nft memory nft = tokens[_id];
        return bool(nft.id > 0 && nft.id == _id);
    }

    function isOwner(uint256 _id) public view returns (bool) {
        return bool(tokens[_id].owner == msg.sender);
    }

    function allTokens() public view returns (Nft[] memory) {
        Nft[] memory _tokens = new Nft[](totalTokens);
        for (uint256 i = 0; i < totalTokens; i++) {
            _tokens[i] = tokens[i + 1];
        }
        return _tokens;
    }

    // -------------------------------
    //   Public Override
    // -------------------------------

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public virtual override {
        super.safeTransferFrom(_from, _to, _id, _amount, _data);
        Nft memory nft = tokens[_id];
        nft.previousOwner = nft.owner;
        nft.owner = payable(_to);
        tokens[_id] = nft;

        if (nft.isForSale) {
          _cancelTokenForSale(_id);
        }
    }


    // -------------------------------
    //   Internal Core Functions
    // -------------------------------

    function _mintToken(
        uint256 _id,
        address _to,
        string memory _hash,
        string memory _name
    ) internal onlyNotPaused {
        // TODO: test minting to different address
        require(msg.value >= mintFee, "Mint fee required");
        require(tokenExists(_id) != true, "Token already exists");
        require(metadataHashesExist[_hash] != true, "Hash already exists");
        require(_id == (totalTokens + 1), "Token ID incorrect");
        require(bytes(_hash).length != 0, "Metadata Hash required");
        require(bytes(_name).length != 0, "Name required");
        require(tokenNameExist[_name] != true, "Name already exists");
        require(_id <= totalSupply, "All tokens minted");

        _mint(_to, _id, 1, "");

        payable(owner()).transfer(mintFee);

        totalTokens = _id;
        metadataHashesExist[_hash] = true;
        tokenNameExist[_name] = true;

        Nft memory nft = Nft({
            id: _id,
            metadataHash: _hash,
            name: _name,
            previousOwner: payable(address(0)),
            minter: payable(msg.sender),
            owner: payable(_to),
            voucherBalance: msg.value - mintFee,
            likes: 0,
            isForSale: false,
            minPrice: 0
        });

        tokens[_id] = nft;

        emit PermanentURI(tokenUriFromMetadataHash(_hash), _id);
        emit MintToken(_id, nft.owner, _hash, _name);
    }

    function _cancelTokenForSale(uint256 _id) internal {
      Nft memory nft = tokens[_id];
      require(nft.isForSale, "Not for sale");
      nft.isForSale = false;
      nft.minPrice = 0;
      tokens[_id] = nft;
      setApprovalForAll(contractAddress, false);
      emit CancelTokenForSale(_id);
    }


    // -------------------------------
    //   External Core Functions
    // -------------------------------

    function mintToken(uint256 _id, address _to, string memory _hash, string memory _name) external payable {
        _mintToken(_id, _to, _hash, _name);
    }

    function offerTokenForSale(uint256 _id, uint256 _minPrice) external onlyTokenOwner(_id) onlyNotPaused {
      Nft memory nft = tokens[_id];
      require(!nft.isForSale, "Already for sale");
      require(_minPrice > 0, "Minimum price required");
      nft.isForSale = true;
      nft.minPrice = _minPrice;
      tokens[_id] = nft;
      setApprovalForAll(contractAddress, true);
      emit OfferTokenForSale(_id, _minPrice);
    }

     function changeTokenSalePrice(uint256 _id, uint256 _minPrice) external onlyTokenOwner(_id) onlyNotPaused {
      Nft memory nft = tokens[_id];
      require(nft.isForSale, "Not for sale");
      require(_minPrice > 0, "Minimum price required");
      require(_minPrice != nft.minPrice, "Different price required");
      nft.minPrice = _minPrice;
      tokens[_id] = nft;
      emit ChangeTokenSalePrice(_id, _minPrice);
    }


    function cancelTokenForSale(uint256 _id) external onlyTokenOwner(_id) onlyNotPaused {
      _cancelTokenForSale(_id);
    }

    function buyToken(uint256 _id) external payable onlyNotPaused  {
      Nft memory nft = tokens[_id];
      require(nft.isForSale, "Not for sale");
      require(msg.value >= nft.minPrice, "Minimum price not met");
      require(msg.sender != nft.owner, "Already owner");
      nft.isForSale = false;
      nft.minPrice = 0;
      tokens[_id] = nft;
      nft.owner.transfer(msg.value);
      this.safeTransferFrom(nft.owner, msg.sender, _id, 1, ""); // sets new owner;
      setApprovalForAll(contractAddress, false);
      emit BuyToken(_id, msg.value);
    }

    function addLike(uint256 _id)
        external
        payable
        onlyTokenExists(_id)
        onlyNotPaused
    {
        require(!isOwner(_id), "Only non-owner can like");
        (bool success, uint256 value) = SafeMath.tryDiv(mintFee, 1000);
        require(msg.value >= value, "Wrong minimum value");
        require(success, "Can't get like value");
        Nft memory nft = tokens[_id];
        nft.owner.transfer(msg.value);
        tokens[_id].likes++;
        emit AddLike(_id, msg.sender, nft.owner, value);
    }

    function redeemVoucher(uint256 _id) external onlyTokenOwner(_id) {
        Nft memory nft = tokens[_id];
        require(nft.voucherBalance > 0, "No voucher");
        nft.owner.transfer(nft.voucherBalance);
        tokens[_id].voucherBalance = 0;
        emit RedeemVoucher(msg.sender, _id);
    }
}
