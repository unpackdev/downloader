/*

     ██╗██████╗     ████████╗██╗  ██╗███████╗    ██╗    ██╗ █████╗ ██╗   ██╗██╗   ██╗
     ██║██╔══██╗    ╚══██╔══╝██║  ██║██╔════╝    ██║    ██║██╔══██╗██║   ██║╚██╗ ██╔╝
     ██║██████╔╝       ██║   ███████║█████╗      ██║ █╗ ██║███████║██║   ██║ ╚████╔╝ 
██   ██║██╔═══╝        ██║   ██╔══██║██╔══╝      ██║███╗██║██╔══██║╚██╗ ██╔╝  ╚██╔╝  
╚█████╔╝██║            ██║   ██║  ██║███████╗    ╚███╔███╔╝██║  ██║ ╚████╔╝    ██║   
 ╚════╝ ╚═╝            ╚═╝   ╚═╝  ╚═╝╚══════╝     ╚══╝╚══╝ ╚═╝  ╚═╝  ╚═══╝     ╚═╝   
                                                                                     
                                        ██╗  ██╗                                     
                                        ╚██╗██╔╝                                     
                                         ╚███╔╝                                      
                                         ██╔██╗                                      
                                        ██╔╝ ██╗                                     
                                        ╚═╝  ╚═╝                                     
                                                                                     
                                 █████╗ ███████╗███████╗                             
                                ██╔══██╗██╔════╝╚══███╔╝                             
                                ███████║███████╗  ███╔╝                              
                                ██╔══██║╚════██║ ███╔╝                               
                                ██║  ██║███████║███████╗                             
                                ╚═╝  ╚═╝╚══════╝╚══════╝                             
                                                                                     
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./MerkleProof.sol";

contract JpTheWavyASZ is ERC721, Ownable, ERC2981 {
    string private _baseTokenURI;

    uint256 public maxSupply;
    uint256 private constant _price = 0.06 ether;
    uint256 private _tokenId;
    uint256 private _mintLimitPerAddress = 1;

    bytes32 private _merkleRoot;

    bool public isPublicActive;
    bool public isPreActive;
    mapping(address => uint256) private _amountMinted;

    event MintAmount(
        uint256 _mintAmountLeft,
        uint256 _totalSupply,
        address _minter
    );

    constructor(
        string memory _uri,
        uint256 _maxSupply,
        bytes32 merkleRoot_
    ) ERC721("ASZ", "ASZ") {
        setBaseTokenURI(_uri);
        setMaxSupply(_maxSupply);
        setRoyaltyInfo(_msgSender(), 750); // 750 == 7.5%
        setMerkleProof(merkleRoot_);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "JTWASZ: Must mint within max supply"
        );
        require(_mintAmount > 0, "JTWASZ: Must mint at least 1");
        _;
    }
    modifier saleCompliance(bool _isSaleActive) {
        require(_isSaleActive, "JTWASZ: The sale is not Active yet");
        require(
            _amountMinted[_msgSender()] < _mintLimitPerAddress,
            "JTWASZ: Already reached mint limit"
        );
        require(msg.value == _price, "JTWASZ: The mint price is not right");
        _;
    }

    // mint
    /**
     * @dev _tokenId and _amountMinted are called before _safeMint
     *      because of Checks-Effects-Interactions
     */

    function devMint(uint256 _mintAmount)
        public
        onlyOwner
        mintCompliance(_mintAmount)
    {
        address to = owner();
        for (uint256 i = 0; i < _mintAmount; i++) {
            mint_(to);
        }
    }

    function publicMint()
        public
        payable
        mintCompliance(1)
        saleCompliance(isPublicActive)
    {
        address to = _msgSender();
        _amountMinted[to] += 1;
        mint_(to);
        emit MintAmount(0, totalSupply(), to);
    }

    function preMint(bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(1)
        saleCompliance(isPreActive)
    {
        address to = _msgSender();
        require(_verify(to, _merkleProof), "JTWASZ: Invalid Merkle Proof");

        _amountMinted[to] += 1;
        mint_(to);
        emit MintAmount(0, totalSupply(), to);
    }

    function mint_(address _to) private {
        _tokenId += 1;
        _safeMint(_to, _tokenId);
    }

    // setter

    function setBaseTokenURI(string memory _newTokenURI) public onlyOwner {
        _baseTokenURI = _newTokenURI;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setMintLimit(uint256 _newMintLimit) public onlyOwner {
        _mintLimitPerAddress = _newMintLimit;
    }

    function setMerkleProof(bytes32 _newMerkleRoot) public onlyOwner {
        _merkleRoot = _newMerkleRoot;
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFee)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _royaltyFee);
    }

    // toggle

    function togglePublicActive() public onlyOwner {
        isPublicActive = !isPublicActive;
    }

    function togglePreActive() public onlyOwner {
        isPreActive = !isPreActive;
    }

    // view

    function totalSupply() public view returns (uint256) {
        return _tokenId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function mintableAmount(address _address, bytes32[] calldata _merkleProof)
        public
        view
        returns (uint256)
    {
        if (
            _verify(_address, _merkleProof) &&
            _amountMinted[_address] < _mintLimitPerAddress
        ) return _mintLimitPerAddress - _amountMinted[_address];
        else return 0;
    }

    function amountMinted(address _address) public view returns (uint256) {
        return _amountMinted[_address];
    }

    function _verify(address _address, bytes32[] calldata _merkleProof)
        private
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_address));

        return MerkleProof.verify(_merkleProof, _merkleRoot, leaf);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // withdraw

    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "withdraw is failed!!");
    }

    /**
     * @dev For receiving eth just in case someone try to send it.
     */

    receive() external payable {}
}
