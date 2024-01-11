// SPDX-License-Identifier: MIT
/*
                                                                         .
                                                                        @88>
 .d``            .u    .                             .u    .            %8P          u.
 @8Ne.   .u    .d88B :@8c        u          .u     .d88B :@8c            .     ...ue888b
 %8888:u@88N  ="8888f8888r    us888u.    ud8888.  ="8888f8888r         .@88u   888R Y888r
  `888I  888.   4888>'88"  .@88 "8888" :888'8888.   4888>'88"         ''888E`  888R I888>
   888I  888I   4888> '    9888  9888  d888 '88%"   4888> '             888E   888R I888>
   888I  888I   4888>      9888  9888  8888.+"      4888>               888E   888R I888>
 uW888L  888'  .d888L .+   9888  9888  8888L       .d888L .+      .     888E  u8888cJ888
'*88888Nu88P   ^"8888*"    9888  9888  '8888c. .+  ^"8888*"     .@8c    888&   "*888*P"
~ '88888F`        "Y"      "888*""888"  "88888%       "Y"      '%888"   R888"    'Y"
   888 ^                    ^Y"   ^Y'     "YP'                   ^*      ""
   *8E
   '8>
    "
*/
pragma solidity ^0.8.9;

import "./ERC1155Supply.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";


contract PraerSeriesOne is ERC1155Supply, ERC2981, Ownable, ReentrancyGuard {

    string public name;
    string public symbol;

    uint256 public constant ELECTION = 0;
    uint256 public constant WILLKOMM = 1;
    uint256 public constant WRTSAME = 2;
    uint256 public constant PEGASUS = 3;
    uint256 public constant SHUSH = 4;

    uint256 public constant MAX_TOKEN_SUPPLY = 2000;
    uint256 public constant TOKEN_PRICE = 0.05 ether;
    uint256 public constant COLLECTION_PRICE = 0.2 ether;
    uint96 public constant ROYALTY = 600; // 6%

    bool public pausedTokenMint;
    mapping (uint256 => string) public tokenURI;

    constructor(
        string memory defaultUri,
        string memory ELECTIONUri,
        string memory WILLKOMMUri,
        string memory WRTSAMEUri,
        string memory PEGASUSUri,
        string memory SHUSHUri,
        uint[] memory ids,
        uint[] memory amounts

    ) ERC1155(defaultUri) {

        name = "Praeter Substantiam";
        symbol = "PRAER";

        tokenURI[ELECTION] = ELECTIONUri;
        tokenURI[WILLKOMM] = WILLKOMMUri;
        tokenURI[WRTSAME] = WRTSAMEUri;
        tokenURI[PEGASUS] = PEGASUSUri;
        tokenURI[SHUSH] = SHUSHUri;

        _setDefaultRoyalty(owner(), ROYALTY);
        mintInitial(ids, amounts);
        pausedTokenMint = true;
    }

    // URI

    function uri(uint256 tokenId) public view override returns (string memory) {
        if (bytes(tokenURI[tokenId]).length == 0) {
            return super.uri(tokenId);
        }
        return tokenURI[tokenId];
    }

    function setURI(uint256 tokenId, string memory newTokenURI) public onlyOwner {
        tokenURI[tokenId] = newTokenURI;
    }

    function contractURI() public view returns (string memory) {
        return super.uri(0);
    }

    // MINTING

    function mintItem(uint256 id, uint256 amount) public payable notPausedTokenMint {
        require(msg.value >= (TOKEN_PRICE * amount), "INSUFFICIENT_FUNDS");
        require(totalSupply(id) + amount <= MAX_TOKEN_SUPPLY, "TOKEN_SUPPLY_REACHED");
        _mint(msg.sender, id, amount, "");
    }

    function mintBatch(uint256[] memory ids, uint256[] memory amounts) public payable notPausedTokenMint {
        require(msg.value >= (TOKEN_PRICE * sumArray(amounts)), "INSUFFICIENT_FUNDS");

        for (uint256 index = 0; index < ids.length; index++) {
            require(totalSupply(ids[index]) + amounts[index] <= MAX_TOKEN_SUPPLY, "DEFICIENT_SUPPLY");
        }
        _mintBatch(msg.sender, ids, amounts, "");
    }

    function mintCollection() public payable notPausedTokenMint {
        require(msg.value >= COLLECTION_PRICE, "INSUFFICIENT_FUNDS");

        uint256[] memory collection = new uint256[](5);
        uint[] memory amounts = new uint256[](5);

        for (uint256 index = 0; index < 5; index++) {
            require(totalSupply(index) + 1 <= MAX_TOKEN_SUPPLY, "DEFICIENT_COLLECTION");
            collection[index] = index;
            amounts[index] = 1;
        }
        _mintBatch(msg.sender, collection, amounts, "");
    }

    function mintInitial(uint256[] memory ids, uint256[] memory amounts) public onlyOwner {
        for (uint256 index = 0; index < ids.length; index++) {
            require(totalSupply(ids[index]) + amounts[index] <= MAX_TOKEN_SUPPLY, "DEFICIENT_SUPPLY");
        }
        _mintBatch(owner(), ids, amounts, "");
    }

    // CONTRACT MANAGEMENT

    function pauseTokenMint() public onlyOwner {
        pausedTokenMint = true;
    }

    function unpauseTokenMint() public onlyOwner {
        pausedTokenMint = false;
    }

    function getAllTokenSupply() external view returns(uint256[] memory) {
        uint[] memory result = new uint[](5);
        for(uint i = 0; i < 5; i++) {
            result[i] = totalSupply(i);
        }
        return result;
    }

    function withdraw(uint256 value) external onlyOwner nonReentrant{
        require(address(this).balance > value, "INSUFFICIENT_BALANCE");
        bool sent;
        if (value == 0) {
            (sent, /*bytes memory data*/) = owner().call{value: (address(this).balance)}("");
        } else {
            (sent, /*bytes memory data*/) = owner().call{value: value}("");
        }
        require(sent, "FAILED_WITHDRAW");
    }

    // MODIFIER

    modifier notPausedTokenMint() {
        require(pausedTokenMint == false, "PAUSED_TOKEN_MINT");
        _;
    }

    // UTIL

    function sumArray(uint256[] memory array) internal pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 index = 0; index < array.length; index++) {
            sum += array[index];
        }
        return sum;
    }

    // OVERRIDES

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function renounceOwnership() public view override onlyOwner {
        revert();
    }

}