// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./Counters.sol";

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./IERC2981.sol";
import "./IVerifyAttestation.sol";
import "./DerivedERC2981RoyaltyUpgradeable.sol";
import "./OptimizedEnumerableUpgradeable.sol";

library AddressUtil {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract LaPrairieNFT is OptimizedEnumerableUpgradeable, UUPSUpgradeable, DerivedERC2981RoyaltyUpgradeable, OwnableUpgradeable {
    using AddressUtil for address;
    using Strings for uint256;

    using Counters for Counters.Counter;

    // Token data
    string constant _name = "Space Beyond by Carla Chan";
    string constant _symbol = "SBCC";
    string constant JSON_FILE = ".json";
    string constant _defaultTokenMetadata = "https://resources.carlachan.com/";
    string constant public _contractMetadataURI = "https://resources.carlachan.com/contracts/lpnft.json";
    string constant LPtypeId = "LP";
    uint256 constant private percentageMultiplier = 10000;
    address RoyaltyReceiver;

    string private _baseTokenMetadataURI;

    uint256 private constant _maxMintLimit = 366; //fixed NFT limit
    uint256 public mintFee;

    mapping(uint256 => uint256) private tokenIdToTicketId;
    mapping(uint256 => uint256) private ticketIdToTokenId;

    event BaseUriUpdate( string uri );
    event RoyaltyContractUpdate( address indexed newAddress );
    event MintFeeUpdate( uint price );
    event ReceiversUpdate( uint receiver1percentage, uint receiver2percentage );

    address private constant _primaryReceiver = 0xae623F8226Ff39Fd2AC5D79EbfE00995FD22a63b;
    address private constant _charity1Addr = 0x5E11F2DF9843a6e23A8E491c330437EED529cAd7;
    address private constant _charity2Addr = 0x28E5d3b9d5004c9CE21EDfCB91447314F25265C1;
    uint256 private _charity1Percentage;
    uint256 private _charity2Percentage;

    modifier mintLimit() {
        require(totalSupply() < _maxMintLimit, "Mint limit has been reached - mint time is over");
        _;
    }

    function getAttestorAddress() internal virtual pure returns(address){
        return 0x538080305560986811c3c1A2c5BCb4F37670EF7e;
    }

    function getIssuerAddress() internal virtual pure returns(address){
        return 0xD5905B36657Dd05a2EF4562267c59A36497A5268;
    }

    function getVerificationAddress() internal virtual pure returns(address){
        return 0x918a754ecefC27F243fbBBd4b93bB6C38a636371;
    }

    function initialize(address _rr) public initializer {
        // better stay revert string length less than 33 chars
        require(_rr != address(0),"addresses should not be 0");

        __Ownable_init();
        __UUPSUpgradeable_init();
        //__ERC721_init(_name, _symbol); // should call name/symbol init here

        _setRoyaltyContract( _rr );

        _tokenIdCounter.increment();

        _setRoyalty(10 * 100); // 10% royalty fee

        _updateMintFee(0.5 ether);

        _setTokenMetadataBaseURI(_defaultTokenMetadata);
        
        _receiversUpdate(
            12 * 100, // _charity1Percentage
            10 * 100  // _charity2Percentage
        );
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function receiversUpdate(uint receiver1percentage, uint receiver2percentage) public onlyOwner {
        _receiversUpdate(receiver1percentage, receiver2percentage);
    }

    function _receiversUpdate(uint receiver1percentage, uint receiver2percentage) internal {
        require((receiver1percentage + receiver2percentage) < 10000, "Too high percentage");
        _charity1Percentage = receiver1percentage;
        _charity2Percentage = receiver2percentage;
        emit ReceiversUpdate(receiver1percentage, receiver2percentage);
    }

    // its enough to test bu modifier onlyOwner, other checks, like isContract() , is contain upgradeTo() method implemented by UUPSUpgradeable
    function _authorizeUpgrade(address) internal override onlyOwner {}

    // For OpenSea
    function contractURI() public pure returns (string memory) {
        return _contractMetadataURI;
    }

    function updateMintFee(uint256 newMintFee) public onlyOwner {
        _updateMintFee(newMintFee);
    }

    function _updateMintFee(uint256 newMintFee) internal {
        mintFee = newMintFee;
        emit MintFeeUpdate(newMintFee);
    }

    function getRemainingMintable() public view returns (uint256) {
        return _maxMintLimit - totalSupply();
    }

    function setTokenMetadataBaseURI(string memory _newMetadataURI) public onlyOwner {
        _setTokenMetadataBaseURI(_newMetadataURI);
    }

    function _setTokenMetadataBaseURI(string memory _newMetadataURI) internal {
        _baseTokenMetadataURI = _newMetadataURI;
        emit BaseUriUpdate(_newMetadataURI);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (OptimizedEnumerableUpgradeable, DerivedERC2981RoyaltyUpgradeable) returns (bool) {
        return OptimizedEnumerableUpgradeable.supportsInterface(interfaceId) ||
               DerivedERC2981RoyaltyUpgradeable.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    } 

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token"); 
        return string(abi.encodePacked(_baseTokenMetadataURI, block.chainid.toString(), "/", contractAddress(), "/", tokenId.toString(), JSON_FILE));
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external virtual override view
            returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "Token doesnt exist.");
        receiver = RoyaltyReceiver;
        royaltyAmount = (_getRoyalty() * salePrice) / 10000;
    }

    function setRoyaltyContract(address newAddress) external onlyOwner {
        _setRoyaltyContract( newAddress );
    }

    function _setRoyaltyContract(address newAddress) internal {
        require(newAddress.isContract(), "Only Contract allowed");
        emit RoyaltyContractUpdate(newAddress);
        RoyaltyReceiver = newAddress;
    }

    function setRoyaltyValue(uint256 value) public onlyOwner {
        _setRoyalty( value );
    }

    function withdraw() public onlyOwner {
        _pay(address(this).balance, _msgSender());
    }

    /**
    * Helper function so the dapp can determine if an attestation is valid, and can be used to mint, and where it will mint to
    **/
    function testAttestation(bytes memory attestation) public view returns (address subject, bool isValid, uint256 ticketId, uint256 tokenId, bool isMinted) {
        bytes memory tokenBytes;
        bytes memory typeId;
        IVerifyAttestation verifier = IVerifyAttestation(getVerificationAddress());
        (subject, tokenBytes, typeId, isValid) = verifier.verifyTicketAttestation(attestation, getAttestorAddress(), getIssuerAddress());
        if (isValidTicketType(typeId)) {
            require (tokenBytes.length < 33, "Ticket ID overflow");
            ticketId = bytesToUint(tokenBytes);
            tokenId = ticketIdToTokenId[ticketId];
            isMinted = _exists(tokenId);
        } else {
            isValid = false;
            isMinted = false;
        }
    }

    function isValidTicketType(bytes memory typeId) private pure returns(bool) {
        return (keccak256(abi.encodePacked((typeId))) == 
                    keccak256(abi.encodePacked((LPtypeId)))); 
    }

    function reserve(uint256 reserveCount, address reserveAddress) public onlyOwner {
        require((_tokenIdCounter.current() + reserveCount) < _maxMintLimit, "Reserve amount too high");
        require(reserveAddress != address(0), "Bad reserve address");        
        for (uint i = 0; i < reserveCount; i++) {
            _safeMint(reserveAddress, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function mint(bytes memory attestation) public mintLimit {
        uint256 tokenId = _tokenIdCounter.current();
        require (tokenId > 1, "Minting has not started");
        bytes memory tokenBytes;
        bytes memory typeId;
        bool isValid;
        address subject;
        IVerifyAttestation verifier = IVerifyAttestation(getVerificationAddress());
        (subject, tokenBytes, typeId, isValid) = verifier.verifyTicketAttestation(attestation, getAttestorAddress(), getIssuerAddress());
        require (isValid, "Attestation not valid");
        require (isValidTicketType(typeId), "Incorrect attestation type used");
        // avoid situation when ticketID exceed uint256
        require (tokenBytes.length < 33, "Ticket ID overflow");
        uint256 ticketId = bytesToUint(tokenBytes);
        require (ticketIdToTokenId[ticketId] == 0, "Attestation already used");
        _safeMint(subject, tokenId);
        tokenIdToTicketId[tokenId] = ticketId;
        ticketIdToTokenId[ticketId] = tokenId;
        _tokenIdCounter.increment();
    }

    function getTicketId(uint256 tokenId) public view returns(uint256) {
        return tokenIdToTicketId[tokenId];
    }

    function getTokenId(uint256 ticketId) public view returns(uint256) {
        return ticketIdToTokenId[ticketId];
    }

    function mintDirect() public payable mintLimit {
        uint256 tokenId = _tokenIdCounter.current();
        require (tokenId > 1, "Minting has not started");
        require (msg.value == mintFee, "Mint Fee not valid use mintFee()");
        _safeMint(msg.sender, tokenId);
        _tokenIdCounter.increment();
        payReceivers(msg.value);
    }

    function payReceivers(uint256 value) internal {
        uint256 charity1Amount = (value * _charity1Percentage) / percentageMultiplier;
        uint256 charity2Amount = (value * _charity2Percentage) / percentageMultiplier;

        _pay(value - (charity1Amount + charity2Amount), _primaryReceiver);
        _pay(charity1Amount, _charity1Addr);
        _pay(charity2Amount, _charity2Addr);
    }

    // we have to use call, not transfer, because of receiver can be a multisig
    function _pay(uint256 amount, address receiver) internal {
        (bool sent, ) = receiver.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function contractAddress() internal view returns (string memory) {
        return Strings.toHexString(uint160(address(this)), 20);
    }

    //Truncates if input is greater than 32 bytes; we onl0y handle 32 byte values.
    function bytesToUint(bytes memory b) private pure returns (uint256 conv)
    {
        if (b.length < 0x20) //if b is less than 32 bytes we need to pad to get correct value
        {
            bytes memory b2 = new bytes(32);
            uint startCopy = 0x20 + 0x20 - b.length;
            assembly
            {
                let bcc := add(b, 0x20)
                let bbc := add(b2, startCopy)
                mstore(bbc, mload(bcc))
                conv := mload(add(b2, 32))
            }
        }
        else
        {
            assembly
            {
                conv := mload(add(b, 32))
            }
        }
    }
}

contract LaPrairieNFTLocalhost is LaPrairieNFT {
    function getAttestorAddress() internal override pure returns(address){
        return 0x5f7bFe752Ac1a45F67497d9dCDD9BbDA50A83955;
    }

    function getIssuerAddress() internal override pure returns(address){
        return 0xbf9Ae773d7D724b9632564fbE2c782Cc2Ed8817c;
    }

    function getVerificationAddress() internal override pure returns(address){
        return 0xb79A899dfB642bd3Ea01B5cBF6872bE03D05DFee;
    }
}

contract LaPrairieNFTTestNet is LaPrairieNFT {
    function getAttestorAddress() internal override pure returns(address){
        return 0x538080305560986811c3c1A2c5BCb4F37670EF7e;
    }

    function getIssuerAddress() internal override pure returns(address){
        return 0xD5905B36657Dd05a2EF4562267c59A36497A5268;
    }

    function getVerificationAddress() internal override pure returns(address){
        return 0x760C4F792Ed6457798018dF992c8C425027d4E1c;
    }
}

contract LaPrairieNFTProduction is LaPrairieNFT {
    function getAttestorAddress() internal override pure returns(address){
        return 0x538080305560986811c3c1A2c5BCb4F37670EF7e;
    }

    function getIssuerAddress() internal override pure returns(address){
        return 0x67B590991CE6506bE7F7e629dBc1519eCBAA4480;
    }

    function getVerificationAddress() internal override pure returns(address){
        return 0xfEA88F5f78b7c74E969DE5c79De50452C509a076;
    }
} 