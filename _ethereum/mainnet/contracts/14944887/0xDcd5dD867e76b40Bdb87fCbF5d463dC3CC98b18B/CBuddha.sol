// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract CBuddha is Ownable, ERC721Enumerable {
    using ECDSA for bytes32;

    uint public immutable MAX_TOTAL_SUPPLY;     // 9490
    uint public immutable MAX_COMMUNITY_TOKEN_ID; // 9990
    uint public immutable PRE_MINT_END_TIME;
    uint public immutable MINT_END_TIME;
    uint  _priceToMint;
    uint _idCounter = 1;
    uint _communityIdCounter;
    address _verifyAddress;

    string _baseUri;
    string  _contractUri;

    mapping(uint => uint) _destinies;
    // record for public offering
    mapping(address => uint) _mintRecord;
    // record for pre mint
    mapping(address => bool) _preMintRecord;

    event Destiny(address indexed owner, uint tokenId, uint destiny);
    event PriceToMintChanged(uint newPriceToMint, uint prePriceToMint);
    event VerifyAddressChanged(address newVerifyAddress, address preVerifyAddress);

    constructor(
        uint priceToMint,
        uint maxTotalSupply,
        uint communityTotalSupply,
        uint preMintEndTime,
        uint mintEndTime,
        address verifyAddress
    )ERC721("C Buddha", "CB"){
        require(priceToMint > 0, "zero price");
        _priceToMint = priceToMint;
        require(maxTotalSupply > 0, "zero total supply");
        MAX_TOTAL_SUPPLY = maxTotalSupply;
    unchecked{
        _communityIdCounter = maxTotalSupply + 1;
    }
        require(communityTotalSupply > 0, "zero community total supply");
        MAX_COMMUNITY_TOKEN_ID = maxTotalSupply + communityTotalSupply;
        _verifyAddress = verifyAddress;
        require(preMintEndTime > block.timestamp, "invalid pre mint end time");
        require(mintEndTime > preMintEndTime, "invalid mint end time");
        PRE_MINT_END_TIME = preMintEndTime;
        MINT_END_TIME = mintEndTime;
    }

    function preMint(bytes calldata signature) external {
        require(block.timestamp < PRE_MINT_END_TIME, "pre mint ends");
        address minter = msg.sender;
        require(!_preMintRecord[minter], "already pre minted");
        _preMintRecord[minter] = true;
        // verify signature
        require(
            _verifyAddress == keccak256(abi.encodePacked(minter)).toEthSignedMessageHash().recover(signature),
            "invalid signature");

        // pre mint for one
        uint currentTokenId = _idCounter;
    unchecked{
        ++_idCounter;
    }
        require(currentTokenId <= MAX_TOTAL_SUPPLY, "exceed max total supply");
        _mintWithDestiny(minter, currentTokenId);
    }

    function mintByCommunity(address[] calldata receivers) external onlyOwner {
        uint len = receivers.length;
        require(len > 0, "zero len");

        uint currentCommunityTokenId = _communityIdCounter;
        for (uint i = 0; i < len; ++i) {
            _mintWithDestiny(receivers[i], currentCommunityTokenId);
        unchecked{
            ++currentCommunityTokenId;
        }
        }
        require(currentCommunityTokenId - 1 <= MAX_COMMUNITY_TOKEN_ID, "exceed max community token id");
        _communityIdCounter = currentCommunityTokenId;
    }

    function mint(uint amount) external payable {
        uint currentTimestamp = block.timestamp;
        require(currentTimestamp >= PRE_MINT_END_TIME, "mint not start");
        require(currentTimestamp < MINT_END_TIME, "mint ends");

        // check mint record
        address minter = msg.sender;
        uint mintRecord = _mintRecord[minter] + amount;
        require(mintRecord <= 10, "exceed max limit to mint");
        if (amount != 10) {
            _mintRecord[minter] = mintRecord;
        } else {
            // buy 10 and mint 11
            _mintRecord[minter] = 11;
        }

        // mint
        uint currentTokenId = _idCounter;
        uint endTokenId = currentTokenId + amount;
        if (amount != 10) {
            // buy 10 and mint 11
        unchecked{
            --endTokenId;
        }
        }
        require(endTokenId <= MAX_TOTAL_SUPPLY, "exceed max total supply");
        for (; currentTokenId <= endTokenId; ++currentTokenId) {
            _mintWithDestiny(minter, currentTokenId);
        }
        _idCounter = currentTokenId;

        uint refund = msg.value - _priceToMint * amount;
        if (refund > 0) {
            payable(minter).transfer(refund);
        }
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseUri = baseURI;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setPriceToMint(uint newPriceToMint) external onlyOwner {
        uint prePriceToMint = _priceToMint;
        _priceToMint = newPriceToMint;
        emit PriceToMintChanged(newPriceToMint, prePriceToMint);
    }

    function setVerifyAddress(address newVerifyAddress) external onlyOwner {
        address preVerifyAddress = _verifyAddress;
        _verifyAddress = newVerifyAddress;
        emit VerifyAddressChanged(newVerifyAddress, preVerifyAddress);
    }

    function setContractURI(string memory newContractUri) external onlyOwner {
        _contractUri = newContractUri;
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function getMintRecord(address account) public view returns (uint){
        return _mintRecord[account];
    }

    function getPriceToMint() public view returns (uint){
        return _priceToMint;
    }

    function getDestiny(uint tokenId) public view returns (uint){
        require(_exists(tokenId), "nonexistent token");
        return _destinies[tokenId];
    }

    function getVerifyAddress() public view returns (address){
        return _verifyAddress;
    }

    function getPreMintRecord(address account) public view returns (bool){
        return _preMintRecord[account];
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function _mintWithDestiny(address minter, uint tokenId) private {
        uint destiny = _reincarnate(minter, tokenId);
        _destinies[tokenId] = destiny;
        _mint(minter, tokenId);
        emit Destiny(minter, tokenId, destiny);
    }

    function _reincarnate(address owner, uint tokenId) private view returns (uint){
        return uint(keccak256(
                abi.encodePacked(
                    owner,
                    block.timestamp,
                    blockhash(block.number - tokenId % 256)
                )
            )
        );
    }
}