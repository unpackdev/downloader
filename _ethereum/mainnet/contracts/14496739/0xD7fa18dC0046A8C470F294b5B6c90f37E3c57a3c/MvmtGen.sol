//    _____                                            __      ________                                   __  .__               
//   /     \   _______  __ ____   _____   ____   _____/  |_   /  _____/  ____   ____   ________________ _/  |_|__| ____   ____  
//  /  \ /  \ /  _ \  \/ // __ \ /     \_/ __ \ /    \   __\ /   \  ____/ __ \ /    \_/ __ \_  __ \__  \\   __\  |/  _ \ /    \ 
// /    Y    (  <_> )   /\  ___/|  Y Y  \  ___/|   |  \  |   \    \_\  \  ___/|   |  \  ___/|  | \// __ \|  | |  (  <_> )   |  \
// \____|__  /\____/ \_/  \___  >__|_|  /\___  >___|  /__|    \______  /\___  >___|  /\___  >__|  (____  /__| |__|\____/|___|  /
//         \/                 \/      \/     \/     \/               \/     \/     \/     \/           \/                    \/ 
//
// Movement Generation
// by Bettina Uhrweiller, Fabio Berger, Ayoub Ahmad, Valentin Liechti and Nathalie Berger

// SPDX-License-Identifier: MIT
import "./Context.sol";
import "./Ownable.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./IERC721Receiver.sol";
import "./ERC165.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./EnumerableSet.sol";
import "./EnumerableMap.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./IERC2981.sol";
import "./ERC721A.sol";

pragma experimental ABIEncoderV2;
pragma solidity ^0.8.4;

contract MvmtGen is ERC721A, IERC2981, Ownable {
    string public baseUri;
    uint256 public nextMintId;
    bool public saleActive;
    bool public metadataLocked;
    uint256 private royaltyFee = 7;
    uint256 public maxMintsPerTxn = 20; 
    uint256 public pricePerPiece;
    uint256 public maxNumberOfPieces;
    string public arweaveId;
    mapping(uint256 => bytes32) public tokenIdToHash;
    address payable public withdrawalAddress;
    address public oracleToken;
    address public oracleAccount;

    event Purchase(address sentTo, uint256 amount, uint256 startIndex);

    constructor(
        uint256 givenPricePerPiece,
        uint256 givenMaxNumberOfPieces,
        string memory givenArweaveId,
        address payable givenWithdrawalAddress,
        address givenOracleToken,
        address givenOracleAccount,
        string memory givenbaseUri
    ) ERC721A("Movement Generation by MVMT Squad", "MVMT") {
        pricePerPiece = givenPricePerPiece;
        maxNumberOfPieces = givenMaxNumberOfPieces;
        arweaveId = givenArweaveId;
        withdrawalAddress = givenWithdrawalAddress;
        oracleToken = givenOracleToken;
        oracleAccount = givenOracleAccount;
        baseUri = givenbaseUri;
    }

    function buy(uint256 numPieces) public payable {
        require(saleActive || msg.sender == owner(), "sale must be active");
        require(numPieces <= maxMintsPerTxn, "can't mint that many at once");
        require(
            msg.value == numPieces * pricePerPiece,
            "must send in correct amount"
        );
        _mint(numPieces, msg.sender);
    }

    // Artists get first 20 mints (4 each)
    function mintArtistProofs() public onlyOwner {
        require(nextMintId <= 1, "cant be more than one piece already existing");
        _mint(20, msg.sender);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");
        return (withdrawalAddress, (salePrice * royaltyFee) / 100);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setBaseUri(string memory newBaseUri) public onlyOwner {
        require(!metadataLocked, "metadata locked");
        baseUri = newBaseUri;
    }

    function lockBaseUri() public onlyOwner {
        metadataLocked = true;
    }

    function setRoyaltyFee(uint256 _royaltyFee) public onlyOwner {
        royaltyFee = _royaltyFee;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function piecesLeft() public view returns (uint256) {
        return maxNumberOfPieces - nextMintId;
    }

    function setSaleActive(bool isActive) public onlyOwner {
        saleActive = isActive;
    }

    function setArweaveId(string memory newArweaveId) public onlyOwner {
        require(!metadataLocked, "metadata locked");
        arweaveId = newArweaveId;
    }

    function arweaveUri(uint256 tokenId) public view returns (string memory) {
        bytes32 seed = tokenIdToHash[tokenId];
        require(!(seed == bytes32(0)), "no hash found");
        return string(abi.encodePacked("ar://", arweaveId, "/?seed=", seed));
    }

    function setWithdrawalAddress(address payable givenWithdrawalAddress)
        public
        onlyOwner
    {
        withdrawalAddress = givenWithdrawalAddress;
    }

    function setMaxNumberOfPieces(uint256 givenMaxNumberOfPieces)
        public
        onlyOwner
    {
        uint256 newMaxNumberOfPieces =
            _max(givenMaxNumberOfPieces, nextMintId);
        require(piecesLeft() >= 1, "must have pieces left");
        require(
            newMaxNumberOfPieces <= maxNumberOfPieces,
            "cant create more pieces"
        );
        maxNumberOfPieces = newMaxNumberOfPieces;
    }

    function withdrawEth() public {
        Address.sendValue(withdrawalAddress, address(this).balance);
    }

    function tokenInfo(uint256 tokenId) public view returns (address, bytes32) {
        return (ownerOf(tokenId), tokenIdToHash[tokenId]);
    }

    function getOwners(uint256 start, uint256 end)
        public
        view
        returns (address[] memory)
    {
        address[] memory re = new address[](end - start);
        for (uint256 i = start; i < end; i++) {
            re[i - start] = ownerOf(i);
        }
        return re;
    }

    function getTokenHashes(uint256 start, uint256 end)
        public
        view
        returns (bytes32[] memory)
    {
        bytes32[] memory re = new bytes32[](end - start);
        for (uint256 i = start; i < end; i++) {
            re[i - start] = tokenIdToHash[i];
        }
        return re;
    }

    function _mint(
    uint256 numPieces,
    address mintTo
    ) private {
        require(piecesLeft() >= numPieces, "not enough available");
        // require(msg.sender == tx.origin, "can not mint via contract");

        uint256 startIndex = nextMintId;
        uint256 endIndex = startIndex + numPieces;
        _safeMint(mintTo, numPieces);
        _assignPsuedoRandomHashes(startIndex, endIndex);
        nextMintId = endIndex;
        emit Purchase(mintTo, numPieces, startIndex);
    }

    function _assignPsuedoRandomHashes(uint256 startIndex, uint256 endIndex)
        private
    {
        for (uint256 i = startIndex; i < endIndex; i++) {
            tokenIdToHash[i] = _psuedoRandomHash(i);
        }
    }

    function _psuedoRandomHash(uint256 tokenId) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    tx.gasprice,
                    tokenId,
                    block.number,
                    block.timestamp,
                    blockhash(block.number - 1),
                    IERC20(oracleToken).balanceOf(oracleAccount)
                )
            );
    }

    function _max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }
}
