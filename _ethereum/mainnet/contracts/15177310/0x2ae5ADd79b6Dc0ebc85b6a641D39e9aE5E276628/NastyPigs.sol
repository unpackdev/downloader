//                                   &&
//                                  &&&
//                                 &&&&&
//                              &  &&&&&&&  @&&&&&&&&&&&&&&&&&&&
//                             &&& *&&&&&&&   &&&&&&&&&&&&&&&&&&&&&&&&&
//                             &&&@  &&&&&&&&  &&&&&&&&&&&&&&&&&&&&&&&&&&&&#
//                             &&&&&&  @&&&&&&  &&&&&&&&&&&&&&&&&  &&&&&&&&&&&
//                         &&   @&&&&&&  &&&&&  @&&  &&&&&&&&&&&&&&@   &&&&&&&&&
//                       &&&&&&&               &&*  &&&&&&&&&&&&&&&&&&&   (&&&&&
//                     &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%
//                   &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%    &&
//                 &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&,   &
//               ,&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&/           @&
//              &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@   &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
//             &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&  &&&*&&&&&&    &&&&&&&&&&  &&&&&&&&&&&&&&&&&&&  &&
//            &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&               &&&&&&&&&&&&&  &&&  *&&
//          &&&&&&&&&&&&&&&&&&&&&&&        .&&&&&&&&&&&&& &&&&&&&&   &&&&&&   &&&&&&&&&&&    &&&   &&
//         &&&&&&&&&&&&&&&         .//////   &&&&&&&&&&&&&  &&&&&&&&    &   &&&&&&&&&&   #  /&&&&@&&
//        &&&&&&&&&&&&&.   //*   /////////           &&&&&&&&&&&&&&&&&&%  &&&&&&      &&&  #&&&&&&
//       &&&&&&&&&&&&&   ///   ////  /////        &&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&&%
//      &&&&&&&&&&&&&  ////   ///   /////       &&&&&&&&&&&&&&&&&&&&&&&&&&&  &&&&&&&&&
//      &&&        &  ////    ///  ////       &    %&@&&&&&&&&&&# &&&&&&&&&&&  &&&&
//     &&&&  ////.    ///     /// ////     //   //,       %&  &&&&% &&&&&&&&&&&
//    &&&&&  ,/////  ////     ///////      //   ///  &&&   ////        &&&&&&&&&&&&
//   &&&&     ////// ////    ,/////       ///   ///     /////   &&&&        &&
//  .&.       ///////////    /////        ///   ///   ////       &&&&&&&&&&
//  &         ///////////    ////         ///  ///* //// ///////// /&&&&&&&&&&&&
//            //// //////    ////         /// ////    ////   ////  &&&&&&&&&&&&&&&&&
//            ,//// /////    ////        /////////         ////   *&&&&&&&&&&&&
//             ////  /////   ////        ///   ///       ////        &&&&&
//             ////     /    ///         ///   ///    /////           &
//             ////          ///         ///         ///

//                    Bear? Bull? Nahhhh... Today, the Pig Market begins.

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract NastyPigs is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;
    uint256 public maxMintAmountPerWallet = 5;

    bool public paused = true;
    bool public whitelistMintEnabled = false;
    bool public revealed = false;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTx,
        string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        setCost(_cost);
        maxSupply = _maxSupply;
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(!whitelistClaimed[_msgSender()], "Address already claimed!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");
        require(
            balanceOf(msg.sender) <= maxMintAmountPerWallet,
            "Max mint for this address"
        );

        _safeMint(_msgSender(), _mintAmount);
    }

    function updateMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
        require(paused, "The contract is not paused!");
        maxMintAmountPerWallet = _maxPerWallet;
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex
        ) {
            TokenOwnership memory ownership = _ownerships[currentTokenId];

            if (!ownership.burned) {
                if (ownership.addr != address(0)) {
                    latestOwnerAddress = ownership.addr;
                }

                if (latestOwnerAddress == _owner) {
                    ownedTokenIds[ownedTokenIndex] = currentTokenId;

                    ownedTokenIndex++;
                }
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool n, ) = payable(0x8a81AE1ACc3369Ff35451615Ec48686F5DE38ff9).call{
            value: (address(this).balance * 1800) / 10000
        }("");
        require(n);
        (bool v, ) = payable(0x85Eb579a5c80B98095BF3AA0d184A5696758B702).call{
            value: (address(this).balance * 2195) / 10000
        }("");
        require(v);
        (bool m1, ) = payable(0x900823372b9364ec46c8D371F162A2FAe7916F0f).call{
            value: (address(this).balance * 2813) / 10000
        }("");
        require(m1);
        (bool rl, ) = payable(0x9Fb7325ECD0d060e9c9673655db745Aab2E70c2E).call{
            value: (address(this).balance * 2228) / 10000
        }("");
        require(rl);
        (bool hs, ) = payable(0x91770567D9362b6Bb8a2fC041451D7f0b3b78607).call{
            value: (address(this).balance * 4280) / 10000
        }("");
        require(hs);
        (bool co, ) = payable(0x5230a24Fbe5311815Fb562f29DB2a023af6Ec440).call{
            value: address(this).balance
        }("");
        require(co);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
