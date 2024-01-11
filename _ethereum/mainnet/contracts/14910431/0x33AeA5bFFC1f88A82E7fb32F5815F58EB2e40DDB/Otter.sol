// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC1155BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";


contract Otter is Initializable, ERC1155Upgradeable, OwnableUpgradeable, PausableUpgradeable, ERC1155BurnableUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    event OttersRevealed(bool revealed);
    mapping(address => uint[]) otterBalances;
    mapping(address => uint8) whitelist; // 1 is normal whitelist, 2 is OG 
    mapping (address => bool) freeMints;
    mapping (address => bool) redeemedBundle;
    uint256 public totalOttersAvailable;
    bool revealed;
    uint256 otterPrice;
    uint256 bundlePrice;
    string baseUri;
    bool hasRan;
    bool publicMintIsOpen;

    uint256 private maxOtters;
    uint publicMintingTimestamp;
    bytes32 public merkleRootWL;
    bytes32 public merkleRootOG;
    
    modifier canAffordBundlePrice {
        require(msg.value >= bundlePrice, "Don't have enough ETH for the bundle.");
        _;
    }

    modifier canAffordBatchPrice(uint _numOtters) {
        require(msg.value >= getCostOfOtterMint(_numOtters), "Transaction does not contain enough ETH to mint.");
        _;
    }

    modifier hasntReachedMaxOtters(uint _numOtters) {
        require(getOtters(msg.sender).length + _numOtters <= maxOtters, "This address has reached the max otter limit.");
        _;
    }

    modifier hasRedeemedFreeOtter {
        require(!freeMints[msg.sender], "Please redeem your free otter first.");
        _;
    }

    modifier mintHasntSoldOut {
        require(_tokenIdCounter.current() <= totalOttersAvailable, "This collection has minted out.");
        _;
    }

    modifier publicMintingIsOpen {
        require(isPublicMintOpen() || whitelistTypeOfAddress(msg.sender) > 0, "Public is not yet able to mint.");
        _;
    }

    modifier onlyRunsOnce {
        require(!hasRan, "Can only run this function once.");
        _;
    }

    function initialize() initializer public {
        baseUri = "https://play.reef.game/rest/otter?id=";
        __ERC1155_init(baseUri);
        __Ownable_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __UUPSUpgradeable_init();
        _tokenIdCounter.increment();
        maxOtters = 5;
        otterPrice                       =  30000000 gwei;
        bundlePrice                       =  30000000 gwei;
        revealed = false;
        totalOttersAvailable = 2500;
        publicMintingTimestamp = block.timestamp + 24 hours;
        hasRan = false;
        publicMintIsOpen = false;
        merkleRootWL = 0xe910048c574917708fbab96b13854a674744df77d28d3cc7ec8cee0bca9b8a5d;
        merkleRootOG = 0x33b6d7c67aff6a8cd0754cbcea94c3bf161dffae3b334365a35bf1bc5da46f12;
    }

    function buildWhitelist(address[] memory _addrs, uint8[] memory _whitelistTypes) public onlyOwner {
        // whitelist
        require(_addrs.length == _whitelistTypes.length, "Input arrays must be equal.");
        for (uint i = 0; i < _addrs.length; i++) {
            whitelist[_addrs[i]] = _whitelistTypes[i];
            // freeMints[_addrs[i]] = true;
        }
    }

    // FOR NEW DEPLOY
    // Normal mints (cost 0.03 ETH)
    function mintOtter() payable publicMintingIsOpen hasntReachedMaxOtters(1) canAffordBatchPrice(1) hasRedeemedFreeOtter mintHasntSoldOut public returns(uint _id) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(msg.sender, tokenId, 1, "");
        otterBalances[msg.sender].push(tokenId);
        //payable(owner()).transfer(msg.value);
        owner().call{value: msg.value}("");
        return tokenId;
    }

    // mint many otter at once
    function mintOtterBatch(uint32 _numOtters) payable publicMintingIsOpen hasntReachedMaxOtters(_numOtters) canAffordBatchPrice(_numOtters) hasRedeemedFreeOtter mintHasntSoldOut public returns(uint256[] memory _ids) {
        uint256[] memory tokenIds = new uint256[](_numOtters);
        uint256[] memory tokenAmounts = new uint256[](_numOtters);

        for(uint256 i = 0; i < _numOtters; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            tokenIds[i] = tokenId;
            tokenAmounts[i] = 1;
            _tokenIdCounter.increment();
            otterBalances[msg.sender].push(tokenId);
        }
        
        _mintBatch(msg.sender, tokenIds, tokenAmounts, "");
        //payable(owner()).transfer(msg.value);
        owner().call{value: msg.value}("");
        return tokenIds;
    }

    function mintOtterBatchInternal(uint32 _numOtters) hasntReachedMaxOtters(_numOtters) mintHasntSoldOut internal returns(uint256[] memory _ids) {
        uint256[] memory tokenIds = new uint256[](_numOtters);
        uint256[] memory tokenAmounts = new uint256[](_numOtters);

        for(uint256 i = 0; i < _numOtters; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            tokenIds[i] = tokenId;
            tokenAmounts[i] = 1;
            _tokenIdCounter.increment();
            otterBalances[msg.sender].push(tokenId);
        }
        
        _mintBatch(msg.sender, tokenIds, tokenAmounts, "");
        //payable(owner()).transfer(msg.value);
        owner().call{value: msg.value}("");
        return tokenIds;
    }

    function mintOtterBatchInit() public onlyRunsOnce onlyOwner {
        uint256 _numOtters = 100;
        uint256[] memory tokenIds = new uint256[](_numOtters);
        uint256[] memory tokenAmounts = new uint256[](_numOtters);

        for(uint256 i = 0; i < _numOtters; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            tokenIds[i] = tokenId;
            tokenAmounts[i] = 1;
            _tokenIdCounter.increment();
            otterBalances[owner()].push(tokenId);
        }
        
        _mintBatch(owner(), tokenIds, tokenAmounts, "");
        hasRan = true;
    }

    // Free mints 
    function redeemFreeOtter(bytes32[] calldata _merkleProof) mintHasntSoldOut public {
        require(whitelist[msg.sender] == 0, "User is already whitelisted.");

        bool isNormalWhitelisted = checkWhitelistNormal(_merkleProof);
        bool isOGWhitelisted = checkWhitelistOG(_merkleProof);
        
        // return isNormalWhitelisted;
        
        require(isNormalWhitelisted || isOGWhitelisted, "User not admitted to whitelist.");

        // if (isOGWhitelisted) {
        //     whitelist[msg.sender] = 2;
        //     freeMints[msg.sender] = true;
        // } 
        // else if (isNormalWhitelisted) {
        //     whitelist[msg.sender] = 1;
        //     freeMints[msg.sender] = true;
        // }
        // require(freeMints[msg.sender], "You do not have any free redemptions left.");
        
        if (isOGWhitelisted) {
            whitelist[msg.sender] = 2;
            mintOtterBatchInternal(2);
            freeMints[msg.sender] = false;
        }
        else if (isNormalWhitelisted) {
            whitelist[msg.sender] = 1;
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _mint(msg.sender, tokenId, 1, "");
            otterBalances[msg.sender].push(tokenId);
            freeMints[msg.sender] = false;
        }
    }

    function redeemWhitelistBundle() payable canAffordBundlePrice hasRedeemedFreeOtter mintHasntSoldOut public returns(uint256[] memory _ids) {
        require(!redeemedBundle[msg.sender], "This account has already redeemed a bundle.");
        if (whitelist[msg.sender] == 2) {
            redeemedBundle[msg.sender] = true;
            return mintOtterBatchInternal(3);
        }
        else if (whitelist[msg.sender] == 1) {
            redeemedBundle[msg.sender] = true;
            return mintOtterBatchInternal(2);
        }
    }

    function changeMaxOtters(uint256 _newMax) public onlyOwner {
        maxOtters = _newMax;
    }

    function changeTotalOttersAvailable(uint256 _newMax) public onlyOwner {
        totalOttersAvailable = _newMax;
    }

    function provideTokenVoucher(address _addr) public onlyOwner {
        freeMints[_addr] = true;
    }

    function resetBundle(address _addr) public onlyOwner {
        redeemedBundle[_addr] = false;
    }

    function toggleOtterReveal() public onlyOwner {
        revealed = !revealed;
        emit OttersRevealed(revealed);
    }

    function manuallyOpenPublicMint() public onlyOwner {
        publicMintIsOpen = true;
    }

    function changeWLMerkleRoot(bytes32 _wl, bytes32 _og) public onlyOwner {
        merkleRootWL = _wl;
        merkleRootOG = _og;
    }

    // VIEWS
    function checkWhitelistNormal(bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProofUpgradeable.verify(_merkleProof, merkleRootWL, leaf);
    }

    function checkWhitelistOG(bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProofUpgradeable.verify(_merkleProof, merkleRootOG, leaf);
    }

    function isPublicMintOpen() public view returns (bool) {
        return publicMintIsOpen || block.timestamp >= publicMintingTimestamp;
    }

    function getLastIdMinted() public view returns(uint) {
        return _tokenIdCounter.current() - 1;
    }

    function getAvailableOtters(address _addr) public view returns(uint) {
        return maxOtters - getOtters(_addr).length;
    }

    function contractURI() public view returns (string memory) {
        return "https://play.reef.game/rest/otter-metadata";
    }

    function ottersAreRevealed() public view returns (bool) {
        return revealed;
    }

    function whitelistTypeOfAddress(address _addr) public view returns(uint8) {
        return whitelist[_addr];
    }
    
    function hasOtterVoucher(address _addr) public view returns(bool) {
        return freeMints[_addr];
    }
    
    function hasRedeemedBundle(address _addr) public view returns(bool) {
        return redeemedBundle[_addr];
    }

    function getCostOfOtterMint(uint256 _numOtters) public view returns (uint256) {
        return _numOtters * otterPrice;
    }

    function getOtters(address _addr) public view returns (uint[] memory)  {
        return otterBalances[_addr];
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseUri, StringsUpgradeable.toHexString(id)));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
