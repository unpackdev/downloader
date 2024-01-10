// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
                                                                                                                      
                                                                                                                      
                            $$$$$$$\  $$\                                 $$\                                $$$$$$\  
                            $$  __$$\ $$ |                                $$ |                              $$  __$$\ 
                            $$ |  $$ |$$ | $$$$$$\  $$$$$$$\   $$$$$$\  $$$$$$\    $$$$$$$\        $$$$$$\  $$ /  \__|
                            $$$$$$$  |$$ | \____$$\ $$  __$$\ $$  __$$\ \_$$  _|  $$  _____|      $$  __$$\ $$$$\     
                            $$  ____/ $$ | $$$$$$$ |$$ |  $$ |$$$$$$$$ |  $$ |    \$$$$$$\        $$ /  $$ |$$  _|    
                            $$ |      $$ |$$  __$$ |$$ |  $$ |$$   ____|  $$ |$$\  \____$$\       $$ |  $$ |$$ |      
                            $$ |      $$ |\$$$$$$$ |$$ |  $$ |\$$$$$$$\   \$$$$  |$$$$$$$  |      \$$$$$$  |$$ |      
                            \__|      \__| \_______|\__|  \__| \_______|   \____/ \_______/        \______/ \__|      
                                                                                                                      
                            $$\     $$\                        $$$$$$\                                                
                            $$ |    $$ |                      $$  __$$\                                               
                          $$$$$$\   $$$$$$$\   $$$$$$\        $$ /  $$ | $$$$$$\   $$$$$$\   $$$$$$$\                 
                          \_$$  _|  $$  __$$\ $$  __$$\       $$$$$$$$ |$$  __$$\ $$  __$$\ $$  _____|                
                            $$ |    $$ |  $$ |$$$$$$$$ |      $$  __$$ |$$ /  $$ |$$$$$$$$ |\$$$$$$\                  
                            $$ |$$\ $$ |  $$ |$$   ____|      $$ |  $$ |$$ |  $$ |$$   ____| \____$$\                 
                            \$$$$  |$$ |  $$ |\$$$$$$$\       $$ |  $$ |$$$$$$$  |\$$$$$$$\ $$$$$$$  |                
                            \____/ \__|  \__| \_______|      \__|  \__|$$  ____/  \_______|\_______/                  
                                                                        $$ |                                          
                                                                        $$ |                                          
                                                                        \__|                                          
                                                                                                                      
                                                               by coinmoonbase.com                                    
                                                            twitter.com/coinmoonbase                                  
*/

import "./ERC721.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract PlanetsOfTheApes is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private mintedNftIds;

    bytes32 private merkleRoot;

    uint256 public constant MAX_SUPPLY = 5000;
    uint256 private constant PRICE = 0.09 ether;
    uint256 private constant RESERVED_AMOUNT = 50;
    uint256 private constant MAX_MINTS_PER_ADDRESS_WHITELIST_MINT = 1;
    uint256 private constant MAX_MINTS_PER_ADDRESS_REGULAR_MINT = 10;
    uint256 public reservedMintedAlready;

    uint256 public whitelistMintStartDate = 99999999999; // 16 November 5138 09:46:39
    uint256 public regularMintStartDate = 99999999999; // 16 November 5138 09:46:39

    string private baseUri = 'https://api.coinmoonbase.com/v1/nft/metadata/pota/';
    string private baseExtension = '.json';

    mapping(address => uint256) public mintedNftsByAddress;

    constructor() ERC721('Planets of the Apes', 'POTA') {}

    modifier onlyEOA() {
        require(msg.sender == tx.origin, 'Only EOA');
        _;
    }

    function isWhitelistMintOpen() public view returns (bool) {
        return
            block.timestamp >= whitelistMintStartDate &&
            block.timestamp <= regularMintStartDate;
    }

    function isRegularMintOpen() public view returns (bool) {
        return block.timestamp >= regularMintStartDate;
    }

    function mintRegular(uint256 _amount) external payable onlyEOA {
        require(isRegularMintOpen(), 'Regular mint sale is not open.');
        require(
            _amount > 0  && (_amount <= MAX_MINTS_PER_ADDRESS_REGULAR_MINT),
            'Amount to be minted has to be between 1 and 10.'
        );
        require(
            totalSupply() + _amount <= mintableSupply(),
            'Max Supply reached.'
        );
        require(
            mintedNftsByAddress[msg.sender] + _amount <=
                MAX_MINTS_PER_ADDRESS_REGULAR_MINT,
            'Max NFTs minted for this address.'
        );
        require(msg.value == _amount * PRICE, 'Incorrect price sent.');

        mintedNftsByAddress[msg.sender] += _amount;
        _mintNFT(msg.sender, _amount);
    }

    function mintReserved(address receiver, uint256 _amount)
        external
        onlyOwner
    {
        require(totalSupply() + _amount <= MAX_SUPPLY, 'Max Supply reached.');
        require(
            reservedMintedAlready + _amount <= RESERVED_AMOUNT,
            'Max of reserved NFTs reached.'
        );
        reservedMintedAlready += _amount;
        _mintNFT(receiver, _amount);
    }

    function mintWhitelist(bytes32[] calldata _proof) external payable onlyEOA {
        require(isWhitelistMintOpen(), 'Whitelist mint sale is not open.');
        require(
            mintedNftsByAddress[msg.sender] + 1 <=
                MAX_MINTS_PER_ADDRESS_WHITELIST_MINT,
            'Already minted 1 NFT during whitelist sale.'
        );
        require(verifyWhitelist(_proof), 'Not whitelisted.');
        require(totalSupply() + 1 <= mintableSupply(), 'Max Supply reached.');
        require(msg.value == PRICE, 'Incorrect price sent.');
        mintedNftsByAddress[msg.sender] += 1;
        _mintNFT(msg.sender, 1);
    }

    function _mintNFT(address _to, uint256 _amount) private {
        uint256 _id;
        for (uint256 i = 0; i < _amount; i++) {
            mintedNftIds.increment();
            _id = mintedNftIds.current();
            _mint(_to, _id);
        }
    }

    function mintableSupply() private view returns (uint256) {
        return MAX_SUPPLY - (RESERVED_AMOUNT - reservedMintedAlready);
    }

    function setBaseExtension(string memory _newBaseExtension)
        external
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setBaseUri(string memory _newBaseUri) external onlyOwner {
        baseUri = _newBaseUri;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function setWhitelistMintStartDate(uint256 _date) external onlyOwner {
        whitelistMintStartDate = _date;
    }

    function setRegularMintStartDate(uint256 _date) external onlyOwner {
        regularMintStartDate = _date;
    }

    function tokenURI(uint256 _nftId)
        public
        view
        override
        returns (string memory)
    {
        string memory _nftURI = 'NFT with that ID does not exist.';
        if (_exists(_nftId)) {
            _nftURI = string(
                abi.encodePacked(baseUri, _nftId.toString(), baseExtension)
            );
        }
        return _nftURI;
    }

    function totalSupply() public view returns (uint256) {
        return mintedNftIds.current();
    }

    function verifyWhitelist(bytes32[] memory _proof)
        private
        view
        returns (bool)
    {
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 _ownerNftCount = balanceOf(_owner);
        uint256[] memory _ownedNftIds = new uint256[](_ownerNftCount);
        uint256 _currentNftId = 1;
        uint256 _ownedNftIndex = 0;
        while (_ownedNftIndex < _ownerNftCount && _currentNftId <= MAX_SUPPLY) {
            address _currentNftOwner = ownerOf(_currentNftId);
            if (_currentNftOwner == _owner) {
                _ownedNftIds[_ownedNftIndex] = _currentNftId;
                _ownedNftIndex++;
            }
            _currentNftId++;
        }
        return _ownedNftIds;
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, 'No ether left to withdraw');
        (bool success, ) = (msg.sender).call{value: balance}('');
        require(success, 'Transfer failed.');
    }
}
