// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC2981ContractWideRoyalties.sol";
import "./IOperatorFilter.sol";
import "./MerkleProof.sol";
import "./IlluminaNFT.sol";


contract KeyNFT is ERC721, Ownable, ERC2981ContractWideRoyalties {
    using Counters for Counters.Counter;

    address public treasury;
    string private keyURI;
    string private baseURI;
    bytes32 public merkleRootHash;
    uint256 illuminasToBeCollected;
    bool private mintable = false;
    uint256 constant KEY_BASE_SUPPLY = 1375;

    IlluminaNFT illuminaNft;
    IOperatorFilter operatorFilter;

    Counters.Counter private _tokenIds;
    mapping(address => bool) _whitelistClaimed;
    mapping (address => bool) private _redeemedForKey;

    event MintToken(uint256 tokenId, address purchaser);
    event RootHashSet();
    event BatchMinted();

    constructor(address _treasury, uint256 _value, address _illuminaAddress , uint256 _illuminasToBeCollected, string memory _keyBaseURI,
    address _operatorFilter) ERC721("KeyNFT", "KNFT") {
        operatorFilter = IOperatorFilter(_operatorFilter);
        treasury = _treasury;
        _setRoyalties(_treasury, _value);
        illuminaNft = IlluminaNFT(_illuminaAddress);
        illuminasToBeCollected = _illuminasToBeCollected;
        baseURI = _keyBaseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setRoyalties(address recipient, uint256 value) public onlyOwner {
        _setRoyalties(recipient, value);
    }

     function setMintable(bool _mintable) external onlyOwner {
        mintable = _mintable;
    }

    function setilluminasToBeCollected(uint256 _illuminasToBeCollected) external onlyOwner {
        illuminasToBeCollected = _illuminasToBeCollected;
    }

    function getilluminasToBeCollected() public view returns (uint256) {
        return illuminasToBeCollected;
    }

    function setMerkleRootHash(bytes32 _rootHash) public onlyOwner {
        merkleRootHash = _rootHash;

        emit RootHashSet();
    }

    function contractURI() public view returns (string memory) {
        return keyURI;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        keyURI = _contractURI;
    }

    function setBaseURI(string memory _blackSquareBaseURI) external onlyOwner {
        baseURI = _blackSquareBaseURI;
    }

    function getKeyMaxSupply () internal pure returns (uint256) {
        return KEY_BASE_SUPPLY;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

     function getCurrentTokenId() external view returns (uint256) {
        return _tokenIds.current();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        if (
            from != address(0) &&
            to != address(0) &&
            !_mayTransfer(msg.sender, tokenId)
        ) {
            revert("ERC721OperatorFilter: illegal operator");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _mayTransfer(address operator, uint256 tokenId)
        private
        view
        returns (bool)
    {
        IOperatorFilter filter = operatorFilter;
        if (address(filter) == address(0)) return true;
        if (operator == ownerOf(tokenId)) return true;
        return filter.mayTransfer(msg.sender);
    }

    function mintAndDrop(address[] memory recipients) public onlyOwner {

        for (uint256 i = 0; i < recipients.length; i++) {
            require(_tokenIds.current() <= getKeyMaxSupply(), 'Max Amount of Keys minted');
            _tokenIds.increment();
            _mint(recipients[i], _tokenIds.current());

        }

        emit BatchMinted();
    }

    function getTokensHeldByUser(address user) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(user);
        uint256[] memory tokenIds = new uint256[](balance);
        uint256[] memory emptyTokens = new uint256[](0);
        uint256 j = 0;
        for (uint256 i = 1; i <= _tokenIds.current(); i++ ) {
            address tokenOwner = ownerOf(i);

            if (tokenOwner == user) {
                tokenIds[j] = i;
                j++;
            }
        }
        if (tokenIds.length > 0) {
            return tokenIds;
        }  else {
            return emptyTokens;
        }
    }
    

    function claimToken(bytes32[] calldata _merkleProof) public {
        require(mintable == true, 'No tokens can be minted at the moment');

        require(_tokenIds.current() <= getKeyMaxSupply(), 'Max Amount of Keys minted');

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

        require(MerkleProof.verify(_merkleProof, merkleRootHash, leaf), 'Invalid Proof');

        _tokenIds.increment();

        require(!_whitelistClaimed[_msgSender()], 'Address already claimed');

        _mint(_msgSender(), _tokenIds.current());

        emit MintToken(_tokenIds.current(), _msgSender());

        _whitelistClaimed[_msgSender()] = true;
    }

    function getIlluScoreFromKey() public view returns (uint256) {
        uint256 balance = illuminaNft.balanceOf(_msgSender());

        return balance;
    }


    function redeemIlluminasForKey() public {

        require(!_redeemedForKey[_msgSender()], 'Illumina: Already Claimed a Key');

        require(_tokenIds.current() <= getKeyMaxSupply(), 'Max Amount of Keys minted');

        uint256 balance = illuminaNft.balanceOf(_msgSender());
        require(balance >= illuminasToBeCollected, 'Not enough Illuminas held');

        _tokenIds.increment();
        _mint(_msgSender(), _tokenIds.current());

        emit MintToken(_tokenIds.current(), _msgSender());

        illuminaNft.burnIllumina(_msgSender(), illuminasToBeCollected);

        _redeemedForKey[_msgSender()] = true;
    }
}