// SPDX-License-Identifier: MIT

// @title: Resonate
// @author: Mike Fucking Tamis

pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./Math.sol";
import "./IERC1271.sol";

contract ResonateNFT is
    ERC721,
    ERC721URIStorage,
    Ownable,
    ERC721Enumerable,
    ReentrancyGuard,
    IERC1271
{
    using Address for address payable;
    using SafeMath for uint256;
    using ECDSA for bytes32;

    event MintResonateSuccess(
        uint256 indexed _tokenId,
        string indexed _word,
        address _human
    );

    enum MintFailure {
        MaxPreSaleMint,
        IncorrectSignature,
        WordTaken
    }

    bool private _publicMinting = false;
    mapping(address => uint256) private _presaleMintAmount;

    event MintResonateFail(address _human, string _word, MintFailure _reason);

    uint256 public constant MAX_RESONATES = 10000;
    uint256 public constant MAX_PURCHASE = 6;
    uint256 public constant MAX_PRESALE_MINT = 3;
    uint256 public constant RESONATE_PRICE = 5E16;

    bytes4 internal constant MAGICVALUE = 0x1626ba7e;

    mapping(string => uint256) private _wordToToken;
    mapping(uint256 => string) private _tokenToWord;

    string private _tokenUriBase;

    address private _signingAddress;

    string private _immutableIPFSBucket;

    constructor() ERC721("Resonate", "RST") {}

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function _isValidSignature(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return ECDSA.recover(hash, signature) == _signingAddress;
    }

    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        override(IERC1271)
        returns (bytes4 magicValue)
    {
        if (_isValidSignature(hash, signature)) {
            return MAGICVALUE;
        }
        return 0xffffffff;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setPublicMinting() public onlyOwner {
        _publicMinting = true;
    }

    function setImmutableIPFSBucket(string memory immutableIPFSBucket_)
        public
        onlyOwner
    {
        require(
            bytes(_immutableIPFSBucket).length == 0,
            "This IPFS bucket is immutable and can only be set once."
        );
        _immutableIPFSBucket = immutableIPFSBucket_;
    }

    function immutableIPFSBucket() public view virtual returns (string memory) {
        return _immutableIPFSBucket;
    }

    function setTokenURI(string memory tokenUriBase_) public onlyOwner {
        _tokenUriBase = tokenUriBase_;
    }

    function setSigningAddress(address signingAddress_) public onlyOwner {
        _signingAddress = signingAddress_;
    }

    function baseTokenURI() public view virtual returns (string memory) {
        return _tokenUriBase;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI(), Strings.toString(tokenId)));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function mintHash(address human, string memory word)
        public
        pure
        returns (bytes32)
    {
        return prefixed(keccak256(abi.encodePacked(word, human)));
    }

    function _unsafeMintResonate(address human, string memory word) private {
        uint256 nextTokenId = totalSupply() + 1;
        _safeMint(human, nextTokenId);
        _wordToToken[word] = nextTokenId;
        _tokenToWord[nextTokenId] = word;
        emit MintResonateSuccess(nextTokenId, word, human);
    }

    function onlyOwnerMintResonate(address human, string[] memory words)
        public
        onlyOwner
    {
        for (
            uint256 i = 0;
            i < Math.min(words.length, MAX_RESONATES.sub(totalSupply()));
            i++
        ) {
            if (_wordToToken[words[i]] != 0) {
                emit MintResonateFail(human, words[i], MintFailure.WordTaken);
                continue;
            }
            _unsafeMintResonate(human, words[i]);
        }
    }

    function _mintSingleResonate(
        address human,
        string memory word,
        bytes memory signature
    ) internal virtual returns (bool) {
        if (_wordToToken[word] != 0) {
            emit MintResonateFail(human, word, MintFailure.WordTaken);
            return false;
        }
        if (!_isValidSignature(mintHash(human, word), signature)) {
            emit MintResonateFail(human, word, MintFailure.IncorrectSignature);
            return false;
        }

        if (!_publicMinting) {
            if (_presaleMintAmount[human] >= MAX_PRESALE_MINT) {
                emit MintResonateFail(human, word, MintFailure.MaxPreSaleMint);
                return false;
            }
            _presaleMintAmount[human] += 1;
        }
        _unsafeMintResonate(human, word);
        return true;
    }

    function getWordFromToken(uint256 index)
        public
        view
        virtual
        returns (string memory)
    {
        return _tokenToWord[index];
    }

    function getTokenFromWord(string memory word)
        public
        view
        virtual
        returns (uint256)
    {
        return _wordToToken[word];
    }

    function mintResonate(
        address payable human,
        string[] memory words,
        bytes[] memory signatures
    ) public payable virtual nonReentrant {
        uint256 payment = msg.value;
        require(words.length <= MAX_PURCHASE, "Purchasing more than max.");
        require(totalSupply() < MAX_RESONATES, "All Resonates purchased.");
        require(
            RESONATE_PRICE.mul(words.length) <= payment,
            "Hey, that's not the right price."
        );

        uint256 totalPurchase = 0;
        for (
            uint256 i = 0;
            i < Math.min(words.length, MAX_RESONATES.sub(totalSupply()));
            i++
        ) {
            if (_mintSingleResonate(human, words[i], signatures[i])) {
                totalPurchase++;
            }
        }

        human.transfer(payment.sub(totalPurchase.mul(RESONATE_PRICE)));
    }

    function withdrawAllEth(address payable payee) public virtual onlyOwner {
        payee.sendValue(address(this).balance);
    }
}
